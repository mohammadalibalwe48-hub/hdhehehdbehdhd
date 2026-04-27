import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import 'auth_page.dart';
import 'home_page.dart';

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  StreamSubscription<AuthState>? _sub;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = AuthService.currentUser;
    _sub = AuthService.onAuthStateChange.listen((event) {
      if (!mounted) return;
      setState(() => _user = event.session?.user);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: _user == null ? const AuthPage() : const HomePage(),
    );
  }
}
