import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/main_scaffold.dart';
import 'screens/player_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const MainScaffold(),
    ),
    GoRoute(
      path: '/player/:id',
      name: 'player',
      builder: (context, state) => PlayerScreen(
        meditationId: state.pathParameters['id'] ?? '',
      ),
    ),
  ],
);