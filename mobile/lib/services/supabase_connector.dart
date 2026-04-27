import 'dart:convert';

import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Postgres response codes that are not retryable — indicate a bug or RLS
/// violation rather than a transient error. We drop the offending transaction
/// so the upload queue can make forward progress instead of looping forever.
final List<RegExp> _fatalResponseCodes = [
  RegExp(r'^22...$'), // Data Exception
  RegExp(r'^23...$'), // Integrity Constraint Violation
  RegExp(r'^42501$'), // Insufficient Privilege (RLS)
];

/// Bridges PowerSync with the existing Supabase auth + REST stack.
///
/// * `fetchCredentials` returns the Supabase JWT so PowerSync can authenticate
///   against the instance URL defined in [SupabaseConfig.powersyncUrl].
/// * `uploadData` replays client-side writes (made against the local SQLite DB)
///   back to Supabase via the same REST client the rest of the app uses.
class SupabaseConnector extends PowerSyncBackendConnector {
  SupabaseConnector();

  Future<void>? _refreshFuture;

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    await _refreshFuture;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return null;

    final expiresAt = session.expiresAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);

    return PowerSyncCredentials(
      endpoint: SupabaseConfig.powersyncUrl,
      token: session.accessToken,
      userId: session.user.id,
      expiresAt: expiresAt,
    );
  }

  @override
  void invalidateCredentials() {
    _refreshFuture = Supabase.instance.client.auth
        .refreshSession()
        .timeout(const Duration(seconds: 5))
        .then((_) => null, onError: (_) => null);
  }

  /// Re-hydrate Postgres-native types that we serialize to text in SQLite
  /// (so they fit in the PowerSync schema) back into their proper shape
  /// before sending to Supabase. Right now: decode `lessons.weekdays` from
  /// a JSON string back into a `List<int>` so the Postgres `INTEGER[]`
  /// column accepts it. Also convert `lesson_exceptions.is_deleted` from
  /// 0/1 integer back to boolean.
  Map<String, dynamic> _decodeForUpload(
      String table, Map<String, dynamic> data) {
    final out = Map<String, dynamic>.of(data);
    if (table == 'lessons') {
      final w = out['weekdays'];
      if (w is String && w.isNotEmpty) {
        try {
          out['weekdays'] = (jsonDecode(w) as List<dynamic>)
              .map((e) => (e as num).toInt())
              .toList();
        } catch (_) {/* leave as-is, Supabase will reject and we'll drop it */}
      }
    } else if (table == 'lesson_exceptions') {
      final d = out['is_deleted'];
      if (d is int) out['is_deleted'] = d == 1;
    }
    return out;
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;

    final rest = Supabase.instance.client.rest;
    CrudEntry? lastOp;

    try {
      for (final op in transaction.crud) {
        lastOp = op;
        final table = rest.from(op.table);
        switch (op.op) {
          case UpdateType.put:
            final data = _decodeForUpload(op.table, op.opData!);
            data['id'] = op.id;
            await table.upsert(data);
            break;
          case UpdateType.patch:
            await table
                .update(_decodeForUpload(op.table, op.opData!))
                .eq('id', op.id);
            break;
          case UpdateType.delete:
            await table.delete().eq('id', op.id);
            break;
        }
      }
      await transaction.complete();
    } on PostgrestException catch (e) {
      final code = e.code;
      if (code != null &&
          _fatalResponseCodes.any((re) => re.hasMatch(code))) {
        // Drop the transaction; retrying won't help.
        // ignore: avoid_print
        print('[powersync] dropping fatal upload error on $lastOp: $e');
        await transaction.complete();
      } else {
        rethrow; // retryable — PowerSync will call uploadData again
      }
    }
  }
}
