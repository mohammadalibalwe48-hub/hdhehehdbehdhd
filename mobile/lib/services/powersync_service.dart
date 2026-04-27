import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/schema.dart';
import 'supabase_config.dart';
import 'supabase_connector.dart';

/// Global PowerSync database — the single source of truth the UI reads from.
///
/// Writes go here first (instant, works offline) and PowerSync replays them
/// to Supabase in the background. Changes from Supabase (web app, other
/// devices) stream in the opposite direction and trigger live updates on any
/// `watch()` subscriptions.
///
/// Call [PowerSyncService.init] once at app startup (after Supabase.initialize),
/// then [PowerSyncService.connect] / [PowerSyncService.disconnect] in response
/// to auth state changes.
class PowerSyncService {
  PowerSyncService._();

  static late final PowerSyncDatabase db;
  static SupabaseConnector? _connector;
  static bool _initialized = false;

  static Future<String> _dbPath() async {
    const name = 'lessons.db';
    if (kIsWeb) return name;
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, name);
  }

  /// Open the local SQLite database and apply the schema. Safe to call once.
  static Future<void> init() async {
    if (_initialized) return;
    final path = await _dbPath();
    db = PowerSyncDatabase(schema: lessonsSchema, path: path);
    await db.initialize();
    _initialized = true;

    // Auto-connect / disconnect in response to Supabase auth changes so a
    // fresh user's data starts syncing as soon as they log in, and stops the
    // moment they sign out.
    Supabase.instance.client.auth.onAuthStateChange.listen((state) async {
      switch (state.event) {
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.tokenRefreshed:
          await connect();
          break;
        case AuthChangeEvent.signedOut:
          await disconnect();
          break;
        default:
          break;
      }
    });

    // If a session already exists (e.g. user launched the app while logged in),
    // connect immediately.
    if (Supabase.instance.client.auth.currentSession != null) {
      await connect();
    }
  }

  /// Start streaming data between local SQLite and the PowerSync instance.
  static Future<void> connect() async {
    if (!_isConfigured()) {
      // ignore: avoid_print
      print(
          '[powersync] skipping connect: SupabaseConfig.powersyncUrl is not set.');
      return;
    }
    _connector ??= SupabaseConnector();
    await db.connect(connector: _connector!);
  }

  /// Stop syncing. Local reads/writes continue to work against the cached DB.
  static Future<void> disconnect() async {
    await db.disconnect();
  }

  /// Wipe the local DB — call this after a sign-out so a different user
  /// logging in on the same device doesn't see the previous user's lessons.
  static Future<void> signOutAndClear() async {
    await disconnect();
    await db.disconnectAndClear();
  }

  static bool _isConfigured() {
    const url = SupabaseConfig.powersyncUrl;
    return url.isNotEmpty && !url.contains('YOUR_POWERSYNC_INSTANCE_URL');
  }
}
