import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'services/local_db.dart';
import 'services/supabase_config.dart';
import 'services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  await LocalDb.instance.init();
  await SyncService.instance.init();
  runApp(const LessonsApp());
}
