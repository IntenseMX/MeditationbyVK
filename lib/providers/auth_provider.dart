import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'dart:async';

enum AuthStatus { loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool isAdmin;

  const AuthState({required this.status, this.user, this.errorMessage, this.isAdmin = false});

  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.authenticated(User u, {bool isAdmin = false})
      : this(status: AuthStatus.authenticated, user: u, isAdmin: isAdmin);
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);
  const AuthState.error(String msg) : this(status: AuthStatus.error, errorMessage: msg);
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;
  StreamSubscription<User?>? _sub;

  @override
  AuthState build() {
    _authService = AuthService();

    // Cleanup subscription when provider disposed
    ref.onDispose(() {
      _sub?.cancel();
    });

    // Defer initialization to avoid modifying state during widget tree build
    Future<void>(() => _init());
    return const AuthState.loading();
  }

  Future<void> _init() async {
    try {
      // Listen for auth changes
      _sub = _authService.authStateChanges.listen((user) async {
        if (user != null) {
          try {
            final token = await user.getIdTokenResult(true);
            final isAdmin = (token.claims?["admin"] == true);
            state = AuthState.authenticated(user, isAdmin: isAdmin);
          } catch (_) {
            state = AuthState.authenticated(user);
          }
        } else {
          state = const AuthState.unauthenticated();
        }
      });

      // Do not auto sign-in anonymously; preserve existing admin/user session
      final existing = _authService.currentUser;
      if (existing != null) {
        state = AuthState.authenticated(existing);
      } else {
        state = const AuthState.unauthenticated();
      }

      // Refresh token to read admin claim
      final user = _authService.currentUser;
      if (user != null) {
        final token = await user.getIdTokenResult(true);
        final isAdmin = (token.claims?["admin"] == true);
        state = AuthState.authenticated(user, isAdmin: isAdmin);
      }
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


