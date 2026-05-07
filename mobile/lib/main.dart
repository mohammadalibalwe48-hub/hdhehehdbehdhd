import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'services/local_db.dart';
import 'services/notifications_service.dart';
import 'services/settings_service.dart';
import 'services/supabase_config.dart';
import 'services/sync_service.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    // Native splash + portrait lock are mobile-only; both packages throw on web.
    FlutterNativeSplash.preserve(widgetsBinding: binding);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  await SettingsService.instance.init();
  if (!kIsWeb) {
    // sqflite + path_provider + flutter_local_notifications are mobile-only.
    // On web we let the UI render and read straight from Supabase; the local
    // SQLite cache, write queue, and on-device notifications are intentionally
    // disabled (the browser tab is online-only).
    await LocalDb.instance.init();
    await NotificationsService.instance.init();
    await SyncService.instance.init();

    final uid = Supabase.instance.client.auth.currentUser?.id;
    NotificationsService.instance.bindToLocalDb(uid);
    Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      final newUid = Supabase.instance.client.auth.currentUser?.id;
      NotificationsService.instance.bindToLocalDb(newUid);
    });
  }

  runApp(const LessonsApp());
  if (!kIsWeb) {
    // Hand off from the OS-level splash to the Flutter animated splash.
    FlutterNativeSplash.remove();
  }
}
