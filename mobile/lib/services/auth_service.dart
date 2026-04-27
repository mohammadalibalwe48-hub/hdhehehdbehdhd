import 'package:supabase_flutter/supabase_flutter.dart';

/// Uses the same username→fake-email scheme as the web app so accounts
/// created on the website can log in on the APK and vice versa.
///
/// Cache clean-up after sign-out is handled by SyncService reacting to the
/// `signedOut` auth event, so we don't need to touch the local DB here.
class AuthService {
  AuthService._();
  static final SupabaseClient _client = Supabase.instance.client;

  static String usernameToEmail(String username) {
    final normalized = username.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_');
    return '$normalized@lessons.app';
  }

  static User? get currentUser => _client.auth.currentUser;

  static Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;

  static Future<void> signIn(String username, String password) async {
    await _client.auth.signInWithPassword(
      email: usernameToEmail(username),
      password: password,
    );
  }

  static Future<void> signUp(String username, String password) async {
    await _client.auth.signUp(
      email: usernameToEmail(username),
      password: password,
      data: {'username': username.trim()},
    );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
