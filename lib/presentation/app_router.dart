import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/animation_constants.dart';
import 'screens/splash_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/player_screen.dart';

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

final appRouter = GoRouter(
  initialLocation: '/splash',
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
      path: '/',
      name: 'home',
      pageBuilder: (context, state) => _buildPageWithTransition(
        child: const MainScaffold(),
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