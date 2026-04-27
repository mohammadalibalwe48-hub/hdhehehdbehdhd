import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'local_db.dart';

/// Keeps the local SQLite cache and the Supabase backend in sync.
///
/// Responsibilities:
///   * On startup + on auth state change → do a full pull from Supabase into
///     the local cache so reads are instant.
///   * Subscribe to Supabase Realtime on `lessons` / `lesson_exceptions` for
///     the current user so changes made on the website (or another device)
///     stream into the local DB live.
///   * Drain the `pending_ops` queue whenever internet is available. Each
///     queued op is replayed against Supabase via the existing REST client.
///   * Redrain on connectivity restore.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final SupabaseClient _sb = Supabase.instance.client;
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  StreamSubscription<AuthState>? _authSub;
  RealtimeChannel? _lessonsChannel;
  RealtimeChannel? _exceptionsChannel;
  bool _isFlushing = false;
  bool _didInitialPull = false;

  /// Called once at app startup, after Supabase is initialized.
  Future<void> init() async {
    _authSub = _sb.auth.onAuthStateChange.listen((state) async {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
          await _onLogin();
          break;
        case AuthChangeEvent.signedOut:
          await _onLogout();
          break;
        default:
          break;
      }
    });

    _connSub = _connectivity.onConnectivityChanged.listen((results) async {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        // Best-effort: when the device comes back online, push pending writes
        // and pull any changes we missed while offline.
        await _flushPending();
        await _pullAll();
      }
    });

    if (_sb.auth.currentSession != null) {
      await _onLogin();
    }
  }

  Future<void> _onLogin() async {
    _didInitialPull = false;
    await _pullAll();
    await _subscribeRealtime();
    await _flushPending();
  }

  Future<void> _onLogout() async {
    await _unsubscribeRealtime();
    await LocalDb.instance.clear();
    _didInitialPull = false;
  }

  /// Manual pull — also called on connectivity restore.
  Future<void> _pullAll() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final lessons = await _sb
          .from('lessons')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      final lessonIds = (lessons as List)
          .map((e) => (e as Map<String, dynamic>)['id'] as String)
          .toList();
      await LocalDb.instance.replaceLessonsFromServer(
        (lessons).cast<Map<String, dynamic>>(),
        userId: uid,
      );

      if (lessonIds.isEmpty) {
        await LocalDb.instance.replaceExceptionsFromServer(const []);
      } else {
        final exc = await _sb
            .from('lesson_exceptions')
            .select()
            .inFilter('lesson_id', lessonIds);
        await LocalDb.instance
            .replaceExceptionsFromServer((exc as List).cast<Map<String, dynamic>>());
      }
      _didInitialPull = true;
    } catch (e) {
      // Likely offline — we'll retry when connectivity comes back. The local
      // cache keeps the UI alive in the meantime.
      if (kDebugMode) {
        // ignore: avoid_print
        print('[sync] pull failed (probably offline): $e');
      }
    }
  }

  Future<void> _subscribeRealtime() async {
    await _unsubscribeRealtime();
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;

    _lessonsChannel = _sb
        .channel('public:lessons:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'lessons',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: _onLessonChange,
        )
        .subscribe();

    // Exceptions aren't owned by user_id directly (they're owned via lesson_id),
    // so we subscribe to all rows and filter client-side on lesson_id membership.
    _exceptionsChannel = _sb
        .channel('public:lesson_exceptions:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'lesson_exceptions',
          callback: _onExceptionChange,
        )
        .subscribe();
  }

  Future<void> _unsubscribeRealtime() async {
    if (_lessonsChannel != null) {
      await _sb.removeChannel(_lessonsChannel!);
      _lessonsChannel = null;
    }
    if (_exceptionsChannel != null) {
      await _sb.removeChannel(_exceptionsChannel!);
      _exceptionsChannel = null;
    }
  }

  void _onLessonChange(PostgresChangePayload payload) {
    LocalDb.instance.applyRealtime(
      table: 'lessons',
      event: payload.eventType.name.toUpperCase(),
      newRecord: payload.newRecord.isEmpty ? null : payload.newRecord,
      oldRecord: payload.oldRecord.isEmpty ? null : payload.oldRecord,
    );
  }

  void _onExceptionChange(PostgresChangePayload payload) {
    LocalDb.instance.applyRealtime(
      table: 'lesson_exceptions',
      event: payload.eventType.name.toUpperCase(),
      newRecord: payload.newRecord.isEmpty ? null : payload.newRecord,
      oldRecord: payload.oldRecord.isEmpty ? null : payload.oldRecord,
    );
  }

  // ---------------------------------------------------------------------------
  // Pending-ops queue flush. Each op is applied via the REST client; on
  // success we remove it, on a retryable failure we stop and try again later.
  // ---------------------------------------------------------------------------

  Future<void> flushNow() => _flushPending();

  Future<void> _flushPending() async {
    if (_isFlushing) return;
    if (_sb.auth.currentUser == null) return;
    _isFlushing = true;
    try {
      while (true) {
        final ops = await LocalDb.instance.listPendingOps();
        if (ops.isEmpty) break;
        final op = ops.first;
        final done = await _apply(op);
        if (!done) return; // transient — try again on next trigger
        await LocalDb.instance.deletePendingOp(op['id'] as int);
      }
    } finally {
      _isFlushing = false;
    }
  }

  /// Returns true if the op is fully resolved (either applied or permanently
  /// discarded). Returns false on a transient error (network/etc) so the
  /// caller should pause and retry later.
  Future<bool> _apply(Map<String, Object?> op) async {
    final kind = op['op'] as String;
    final table = op['table_name'] as String;
    final rowId = op['row_id'] as String;
    final payloadRaw = op['payload'] as String?;
    final payload = payloadRaw == null
        ? null
        : (jsonDecode(payloadRaw) as Map<String, dynamic>);

    try {
      final t = _sb.from(table);
      switch (kind) {
        case 'insert':
          await t.insert(payload!);
          break;
        case 'update':
          await t.update(payload!).eq('id', rowId);
          break;
        case 'upsert':
          await t.upsert(payload!, onConflict: 'lesson_id,exception_date');
          break;
        case 'delete':
          await t.delete().eq('id', rowId);
          break;
      }
      return true;
    } on PostgrestException catch (e) {
      // Fatal Postgres errors: bad data / constraint / RLS. Drop the op so
      // the queue can make progress; surfacing to the user happens via the
      // normal UI update path (row simply won't exist on the server).
      final fatal = _isFatalCode(e.code) || _isFatalMessage(e.message);
      if (fatal) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('[sync] dropping fatal op $kind $table $rowId: $e');
        }
        return true;
      }
      return false;
    } catch (_) {
      // Almost certainly a network / transport error. Keep the op queued.
      return false;
    }
  }

  static bool _isFatalCode(String? code) {
    if (code == null) return false;
    return RegExp(r'^22...$').hasMatch(code) ||
        RegExp(r'^23...$').hasMatch(code) ||
        code == '42501';
  }

  static bool _isFatalMessage(String? msg) {
    if (msg == null) return false;
    final m = msg.toLowerCase();
    return m.contains('violates') || m.contains('permission denied');
  }

  Future<void> dispose() async {
    await _connSub?.cancel();
    await _authSub?.cancel();
    await _unsubscribeRealtime();
  }

  @visibleForTesting
  bool get didInitialPull => _didInitialPull;
}
