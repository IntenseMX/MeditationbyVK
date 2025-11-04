import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/animation_constants.dart';
import 'screens/splash_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/player_screen.dart';
import 'screens/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/admin/meditations_list_screen.dart';
import 'screens/admin/meditation_editor_screen.dart';
import 'screens/admin/categories_screen.dart';
import 'screens/admin/activity_screen.dart';
import 'screens/themes_screen.dart';

/// Custom page transition with fade and slide animation
Page<dynamic> _buildPageWithTransition({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Main slide animation (right to left on forward)
      final slideAnimation = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: AnimationCurves.standardEasing,
        ),
      );

      // Secondary fade animation (quick exit for background screen)
      final secondaryFadeAnimation = Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(
        CurvedAnimation(
          parent: secondaryAnimation,
          curve: const Interval(0.0, 0.3, curve: Curves.easeOut), // Fade out in first 30%
        ),
      );

      // Fade animation
      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: AnimationCurves.standardEasing,
        ),
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: secondaryFadeAnimation,
            child: child,
          ),
        ),
      );
    },
    transitionDuration: AnimationDurations.screenTransition,
  );
}

/// Special transition for player screen - fade only to let Hero animation shine
Page<dynamic> _buildPlayerTransition({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Simple fade - let the Hero animation do the heavy lifting
      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Interval(0.3, 1.0, curve: AnimationCurves.emphasized), // Delayed start
        ),
      );

      // Backdrop scrim for depth
      final scrimAnimation = Tween<double>(
        begin: 0.0,
        end: 0.5,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: AnimationCurves.standardEasing,
        ),
      );

      return Stack(
        children: [
          // Dark backdrop that fades in
          FadeTransition(
            opacity: scrimAnimation,
            child: Container(color: Colors.black),
          ),
          // Player content fades in after Hero settles
          FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        ],
      );
    },
    transitionDuration: AnimationDurations.long2, // 750ms for smooth Hero + content
  );
}

/// Fade-through style transition (good for context change like splash → home)
Page<dynamic> _buildFadeThroughPage({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeIn = CurvedAnimation(parent: animation, curve: AnimationCurves.standardEasing);
      final scaleIn = Tween<double>(begin: 0.92, end: 1.0).animate(fadeIn);

      return FadeTransition(
        opacity: fadeIn,
        child: ScaleTransition(scale: scaleIn, child: child),
      );
    },
    transitionDuration: AnimationDurations.screenTransition,
  );
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    // Admin gate for admin and admin-related routes + basic auth guard for main tabs
    final path = state.matchedLocation;
    final isProtectedAdminRoute =
        path.startsWith('/admin') || path.startsWith('/meditations') || path.startsWith('/categories');
    final container = ProviderScope.containerOf(context, listen: false);
    final authState = container.read(authProvider);
    // Guard main app tabs if no user session present
    final isMainTab = path == '/' || path == '/discover' || path == '/progress' || path == '/profile';
    if (isMainTab && authState.user == null) {
      return '/splash';
    }
    // Admin-only routes
    if (isProtectedAdminRoute) {
      if (authState.status != AuthStatus.authenticated || authState.isAdmin == false) {
        return '/login';
      }
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const SplashScreen(),
        state: state,
      ),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const LoginScreen(),
        state: state,
      ),
    ),
    // Minimal admin landing (guarded by redirect)
    GoRoute(
      path: '/admin',
      name: 'admin',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const AdminDashboardScreen(),
        state: state,
      ),
    ),
    GoRoute(
      path: '/admin/activity',
      name: 'admin_activity',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const AdminActivityScreen(),
        state: state,
      ),
    ),
    GoRoute(
      path: '/meditations',
      name: 'meditations_list',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const MeditationsListScreen(),
        state: state,
      ),
    ),
    GoRoute(
      path: '/meditations/new',
      name: 'meditation_new',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const MeditationEditorScreen(),
        state: state,
      ),
    ),
    GoRoute(
      path: '/meditations/:id',
      name: 'meditation_edit',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: MeditationEditorScreen(
          meditationId: state.pathParameters['id'],
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: '/categories',
      name: 'categories',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const CategoriesScreen(),
        state: state,
      ),
    ),
    GoRoute(
      path: '/',
      name: 'home',
      pageBuilder: (context, state) => _buildFadeThroughPage(
        child: const MainScaffold(initialIndex: 0),
        state: state,
      ),
    ),
    GoRoute(
      path: '/themes',
      name: 'themes',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const ThemesScreen(),
        state: state,
      ),
    ),
    GoRoute(
      path: '/discover',
      name: 'discover',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const MainScaffold(initialIndex: 1),
        state: state,
      ),
    ),
    GoRoute(
      path: '/progress',
      name: 'progress',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const MainScaffold(initialIndex: 2),
        state: state,
      ),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const MainScaffold(initialIndex: 3),
        state: state,
      ),
    ),
    GoRoute(
      path: '/player/:id',
      name: 'player',
      pageBuilder: (context, state) => _buildPlayerTransition(
        child: PlayerScreen(
          meditationId: state.pathParameters['id'] ?? '',
        ),
        state: state,
      ),
    ),
  ],
);