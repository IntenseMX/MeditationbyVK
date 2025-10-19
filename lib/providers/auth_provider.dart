import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({required this.status, this.user, this.errorMessage});

  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.authenticated(User u)
      : this(status: AuthStatus.authenticated, user: u);
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);
  const AuthState.error(String msg) : this(status: AuthStatus.error, errorMessage: msg);
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = AuthService();
    _init();
    return const AuthState.loading();
  }

  Future<void> _init() async {
    try {
      final existing = _authService.currentUser;
      if (existing != null) {
        state = AuthState.authenticated(existing);
        return;
      }
      final cred = await _authService.signInAnonymously();
      state = AuthState.authenticated(cred.user!);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);


