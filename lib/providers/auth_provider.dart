import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'dart:async';

enum AuthStatus { initial, guest, authenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool isAdmin;

  const AuthState({required this.status, this.user, this.errorMessage, this.isAdmin = false});

  const AuthState.initial() : this(status: AuthStatus.initial);
  const AuthState.guest(User u) : this(status: AuthStatus.guest, user: u);
  const AuthState.authenticated(User u, {bool isAdmin = false})
      : this(status: AuthStatus.authenticated, user: u, isAdmin: isAdmin);
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
    return const AuthState.initial();
  }

  Future<void> _init() async {
    try {
      // Listen for auth changes
      _sub = _authService.authStateChanges.listen((user) async {
        if (user != null) {
          try {
            final token = await user.getIdTokenResult(true);
            final isAdmin = (token.claims?["admin"] == true);
            if (user.isAnonymous) {
              state = AuthState.guest(user);
            } else {
              state = AuthState.authenticated(user, isAdmin: isAdmin);
            }
          } catch (_) {
            if (user.isAnonymous) {
              state = AuthState.guest(user);
            } else {
              state = AuthState.authenticated(user);
            }
          }
        } else {
          state = const AuthState.initial();
        }
      });

      // Initial check without creating sessions
      await checkAuthState();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> checkAuthState() async {
    final existing = _authService.currentUser;
    if (existing == null) {
      state = const AuthState.initial();
      return;
    }
    if (existing.isAnonymous) {
      state = AuthState.guest(existing);
      return;
    }
    try {
      final token = await existing.getIdTokenResult(true);
      final isAdmin = (token.claims?["admin"] == true);
      state = AuthState.authenticated(existing, isAdmin: isAdmin);
    } catch (_) {
      state = AuthState.authenticated(existing);
    }
  }

  Future<void> signInAnonymously() async {
    try {
      final cred = await _authService.signInAnonymously();
      final user = cred.user;
      if (user != null) {
        state = AuthState.guest(user);
      } else {
        state = const AuthState.initial();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      final cred = await _authService.signInWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      if (user != null) {
        try {
          final token = await user.getIdTokenResult(true);
          final isAdmin = (token.claims?["admin"] == true);
          state = AuthState.authenticated(user, isAdmin: isAdmin);
        } catch (_) {
          state = AuthState.authenticated(user);
        }
      } else {
        state = const AuthState.initial();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final cred = await _authService.signInWithGoogle();
      final user = cred.user;
      if (user != null) {
        try {
          final token = await user.getIdTokenResult(true);
          final isAdmin = (token.claims?["admin"] == true);
          state = AuthState.authenticated(user, isAdmin: isAdmin);
        } catch (_) {
          state = AuthState.authenticated(user);
        }
      } else {
        state = const AuthState.initial();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signInWithApple() async {
    try {
      final cred = await _authService.signInWithApple();
      final user = cred.user;
      if (user != null) {
        try {
          final token = await user.getIdTokenResult(true);
          final isAdmin = (token.claims?["admin"] == true);
          state = AuthState.authenticated(user, isAdmin: isAdmin);
        } catch (_) {
          state = AuthState.authenticated(user);
        }
      } else {
        state = const AuthState.initial();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      final cred = await _authService.signUpWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      if (user != null) {
        try {
          final token = await user.getIdTokenResult(true);
          final isAdmin = (token.claims?["admin"] == true);
          state = AuthState.authenticated(user, isAdmin: isAdmin);
        } catch (_) {
          state = AuthState.authenticated(user);
        }
      } else {
        state = const AuthState.initial();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AuthState.initial();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);


