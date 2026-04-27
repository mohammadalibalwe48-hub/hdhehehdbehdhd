/// Supabase project configuration. Matches the same project as the web app
/// so accounts and lessons are shared between the website and the APK.
///
/// [powersyncUrl] points at the PowerSync Cloud instance that mirrors this
/// Supabase project into the local SQLite database on device. Set this to the
/// URL shown in the PowerSync dashboard after you create an instance. Leaving
/// it as the placeholder disables syncing — the app will still work but data
/// will not flow between devices.
class SupabaseConfig {
  static const String url = 'https://vvgrzmbjrkbfnebftagy.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ2Z3J6bWJqcmtiZm5lYmZ0YWd5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcyNDEwMzcsImV4cCI6MjA5MjgxNzAzN30.HG0HSJQ6_4UnGOxbq6MevsI_4RFzmoNnk9nD5sxMfpg';

  /// PowerSync Cloud instance URL. Looks like
  /// `https://xxxxxxxxxxxxxxxxxx.powersync.journeyapps.com`.
  static const String powersyncUrl =
      'https://YOUR_POWERSYNC_INSTANCE_URL.powersync.journeyapps.com';
}
