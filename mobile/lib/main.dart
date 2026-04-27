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
  // Keep the native splash on screen while we boot Supabase + the local DB.
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  await SettingsService.instance.init();
  await LocalDb.instance.init();
  await NotificationsService.instance.init();
  await SyncService.instance.init();

  // Bind notifications to the current user's lesson stream so scheduled
  // reminders update automatically whenever lessons change.
  final uid = Supabase.instance.client.auth.currentUser?.id;
  NotificationsService.instance.bindToLocalDb(uid);
  Supabase.instance.client.auth.onAuthStateChange.listen((state) {
    final newUid = Supabase.instance.client.auth.currentUser?.id;
    NotificationsService.instance.bindToLocalDb(newUid);
  });

  runApp(const LessonsApp());
  // Hand off from the OS-level splash to the Flutter animated splash.
  FlutterNativeSplash.remove();
}
