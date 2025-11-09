import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:meditation_by_vk/core/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meditation_by_vk/providers/auth_provider.dart';
import '../../providers/meditations_list_provider.dart';
import '../../providers/category_provider.dart';
import '../../core/constants.dart';
import 'package:meditation_by_vk/core/animation_constants.dart';
import 'package:meditation_by_vk/presentation/widgets/zen_background.dart';
import 'package:meditation_by_vk/presentation/widgets/breathing_glow.dart';
import 'package:meditation_by_vk/presentation/widgets/auth/auth_dialog.dart';
import 'package:meditation_by_vk/presentation/screens/home_screen.dart';

String? _imageAt(List<dynamic> list, int index) {
  if (index < 0 || index >= list.length) return null;
  final item = list[index];
  try {
    final url = item.imageUrl as String?;
    if (url != null && url.isNotEmpty) return url;
  } catch (_) {}
  return null;
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _showCtas = false;
  late AnimationController _shimmerController;
  // Exit timeline
  late AnimationController _exitController;
  late Animation<double> _logoExitScale;
  late Animation<double> _logoExitLift;
  late Animation<double> _glowExitScale;
  late Animation<double> _glowExitOpacity;
  late Animation<double> _titleExitOpacity;
  late Animation<double> _subtitleExitOpacity;
  bool _isExiting = false;
  bool _hideOriginalLogo = false;
  OverlayEntry? _logoOverlay;
  final GlobalKey _logoKey = GlobalKey();
  static const double _buttonAreaHeight = 140;
  static const double _contentAreaHeight = 220;
  static const double _logoBaseYOffset = (_contentAreaHeight + _buttonAreaHeight) / 2 - 12;
  static const double _homeWarmupOffscreenPos = -10000.0;
  static const Duration _homeWarmupDelay = Duration(milliseconds: 500);
  static const int _homePrecacheImageCount = 3;
  static const Duration _homePrecacheTimeout = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _animationController.forward();

    _shimmerController = AnimationController(vsync: this, duration: SplashAnimationConfig.shimmerSweep)..repeat();

    // Exit animations (idle at t=0)
    _exitController = AnimationController(vsync: this, duration: SplashExitConfig.exit);
    _logoExitScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: SplashExitConfig.logoPopScale).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: SplashExitConfig.logoPopScale, end: SplashExitConfig.logoEndScale).chain(CurveTween(curve: AnimationCurves.emphasizedDecelerate)),
        weight: 80,
      ),
    ]).animate(_exitController);
    _logoExitLift = Tween<double>(begin: 0.0, end: SplashExitConfig.logoLiftY)
        .chain(CurveTween(curve: AnimationCurves.emphasized))
        .animate(_exitController);
    _glowExitScale = Tween<double>(begin: 1.0, end: SplashExitConfig.glowEndScale)
        .chain(CurveTween(curve: AnimationCurves.emphasized))
        .animate(_exitController);
    _glowExitOpacity = Tween<double>(begin: 1.0, end: SplashExitConfig.glowEndOpacity)
        .chain(CurveTween(curve: AnimationCurves.standardEasing))
        .animate(_exitController);
    _titleExitOpacity = Tween<double>(begin: 1.0, end: SplashExitConfig.titleEndOpacity)
        .chain(CurveTween(curve: AnimationCurves.standardEasing))
        .animate(_exitController);
    _subtitleExitOpacity = Tween<double>(begin: 1.0, end: SplashExitConfig.subtitleEndOpacity)
        .chain(CurveTween(curve: AnimationCurves.standardEasing))
        .animate(_exitController);

    // Aggressive fallback: show CTAs after configured delay NO MATTER WHAT
    Future.delayed(SplashAnimationConfig.ctaFallbackDelay, () {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('[SPLASH] Force-enabling CTAs');
      }
      setState(() {
        _showCtas = true;
      });
    });

    // Background: Try loading data, but don't block CTAs
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      try {
        // Prime providers to ensure streams start
        ref.read(trendingMeditationsProvider);
        ref.read(recentlyAddedMeditationsProvider);
        ref.read(recommendedMeditationsProvider);
        ref.read(categoriesStreamProvider);

        await Future.wait([
          ref.read(trendingMeditationsProvider.future),
          ref.read(recentlyAddedMeditationsProvider.future),
          ref.read(recommendedMeditationsProvider.future),
          ref.read(categoriesStreamProvider.future),
        ], eagerError: true).timeout(const Duration(seconds: 2));

        if (kDebugMode) {
          debugPrint('[SPLASH] Data loaded successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[SPLASH] Data load failed: $e');
        }
      }

      // Ensure auth state checked (no side effects)
      if (mounted) {
        ref.read(authProvider.notifier).checkAuthState();
      }

      // Light-weight: Precache a few Home images to avoid first visible decode jank
      if (!mounted) return;
      Future<void>(() async {
        try {
          final trending = ref.read(trendingMeditationsProvider).asData?.value ?? const <dynamic>[];
          final recent = ref.read(recentlyAddedMeditationsProvider).asData?.value ?? const <dynamic>[];
          final recommended = ref.read(recommendedMeditationsProvider).asData?.value ?? const <dynamic>[];

          final Set<String> urls = <String>{};
          for (int i = 0; i < _homePrecacheImageCount; i++) {
            final t = _imageAt(trending, i);
            if (t != null) urls.add(t);
            final r = _imageAt(recent, i);
            if (r != null) urls.add(r);
            final rec = _imageAt(recommended, i);
            if (rec != null) urls.add(rec);
          }

          if (urls.isEmpty) return;
          final tasks = <Future<void>>[];
          for (final u in urls) {
            tasks.add(precacheImage(NetworkImage(u), context).catchError((_) {}));
          }
          await Future.wait(tasks).timeout(_homePrecacheTimeout, onTimeout: () => <void>[]);
        } catch (_) {
          // Silent: precache is best-effort only
        }
      });
    });

    // Warm up Home by building it offscreen to compile shaders and initialize controllers
    Future.delayed(_homeWarmupDelay, () {
      if (!mounted) return;

      final overlay = Overlay.of(context);
      if (overlay == null) return;

      final screenSize = MediaQuery.of(context).size;

      late OverlayEntry warmupEntry;
      warmupEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: _homeWarmupOffscreenPos,
          top: _homeWarmupOffscreenPos,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenSize.width,
              maxHeight: screenSize.height,
            ),
            child: const ProviderScope(
              overrides: [],
              child: HomeScreen(),
            ),
          ),
        ),
      );

      overlay.insert(warmupEntry);

      // Remove after first frame to avoid lingering resources
      WidgetsBinding.instance.addPostFrameCallback((_) {
        warmupEntry.remove();
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shimmerController.dispose();
    _exitController.dispose();
    _logoOverlay?.remove();
    _logoOverlay = null;
    super.dispose();
  }

  Future<void> _playExitAndNavigate(BuildContext context) async {
    if (_isExiting) return;
    setState(() {
      _isExiting = true;
      _showCtas = false; // let CTAs fade away via AnimatedSwitcher
    });
    _shimmerController.stop();
    
    // Step 1: Play lift animation (900ms)
    await _exitController.forward();
    if (!mounted) return;
    
    // Step 2: Create overlay with logo at current position
    final logoBox = _logoKey.currentContext?.findRenderObject() as RenderBox?;
    if (logoBox != null && mounted) {
      final logoPosition = logoBox.localToGlobal(Offset.zero);
      final logoSize = logoBox.size;
      
      // Get screen metrics for precise end position (matches HomeScreen padding/safe-area)
      final mediaQuery = MediaQuery.of(context);
      final screenSize = mediaQuery.size;
      const endSize = Size(40, 40);
      const horizontalPadding = 20.0; // matches HomeScreen padding
      const topPadding = 20.0;        // matches HomeScreen padding
      const double landingAdjustY = 10.0; // subtle optical tweak
      final endLeft = screenSize.width - horizontalPadding - endSize.width;
      final endTop = mediaQuery.padding.top + topPadding + landingAdjustY;
      final endPosition = Offset(endLeft, endTop);
      
      _logoOverlay = OverlayEntry(
        builder: (context) => AnimatedLogoOverlay(
          startPosition: logoPosition,
          startSize: logoSize,
          endPosition: endPosition,
          endSize: endSize,
          onComplete: () {
            _logoOverlay?.remove();
            _logoOverlay = null;
          },
        ),
      );
      
      Overlay.of(context).insert(_logoOverlay!);
      
      // Step 3: Hide original logo immediately
      setState(() => _hideOriginalLogo = true);
      
      // Step 4: Start navigation immediately (screens fade beneath flying logo)
      context.go('/');
    } else {
      // Fallback: just navigate
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final hasUser = authState.user != null;
    final isGuest = hasUser && authState.status == AuthStatus.guest;
    
    if (kDebugMode) {
      debugPrint('[SPLASH BUILD] _showCtas=$_showCtas, hasUser=$hasUser, isGuest=$isGuest');
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          const Positioned.fill(child: ZenBackground()),
          Center(
            child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final appColors = Theme.of(context).extension<AppColors>();
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with breathing glow
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        FadeTransition(
                          opacity: _glowExitOpacity,
                          child: ScaleTransition(
                            scale: _glowExitScale,
                            child: BreathingGlow(size: 180, color: appColors?.pop ?? Theme.of(context).colorScheme.primary),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _exitController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _logoExitLift.value),
                              child: Transform.scale(scale: _logoExitScale.value, child: child),
                            );
                          },
                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 1200),
                            curve: AnimationCurves.emphasizedDecelerate,
                            offset: _showCtas ? const Offset(0, -0.06) : Offset.zero,
                            child: Transform.translate(
                              offset: const Offset(0, _logoBaseYOffset),
                              child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RepaintBoundary(
                                  child: Opacity(
                                    opacity: _hideOriginalLogo ? 0.0 : 1.0,
                                    child: Container(
                                      key: _logoKey,
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(24),
                                        color: appColors?.pop ?? Theme.of(context).colorScheme.error,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                                            blurRadius: 24,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          'UP',
                                          style: TextStyle(
                                            color: appColors?.onPop ?? Theme.of(context).colorScheme.onError,
                                            fontSize: 64,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FadeTransition(
                                  opacity: _subtitleExitOpacity,
                                  child: Text(
                                    'by VK',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                              ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Content block (CLARITY + tagline) - NOW OUTSIDE LOGO TRANSFORMS
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1200),
                      curve: AnimationCurves.emphasizedDecelerate,
                      margin: EdgeInsets.only(top: _showCtas ? 80 : 0),
                      child: SizedBox(
                      height: _contentAreaHeight,
                      child: AnimatedSwitcher(
                        duration: AnimationDurations.ctaReveal + const Duration(milliseconds: 120),
                        switchInCurve: AnimationCurves.emphasizedDecelerate,
                        switchOutCurve: AnimationCurves.emphasizedDecelerate,
                        transitionBuilder: (child, animation) {
                          final curved = CurvedAnimation(parent: animation, curve: AnimationCurves.emphasizedDecelerate);
                          final slide = Tween<Offset>(
                            begin: const Offset(0, 0.02),
                            end: Offset.zero,
                          ).animate(curved);
                          return FadeTransition(opacity: curved, child: SlideTransition(position: slide, child: child));
                        },
                        child: _showCtas
                            ? Column(
                                key: const ValueKey('content'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 16),
                                  FadeTransition(
                                    opacity: _titleExitOpacity,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Text(
                                          'CLARITY',
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 2,
                                                color: Theme.of(context).colorScheme.onBackground,
                                              ),
                                        ),
                                        AnimatedBuilder(
                                          animation: _shimmerController,
                                          builder: (context, child) {
                                            return ShaderMask(
                                              shaderCallback: (Rect bounds) {
                                                final t = _shimmerController.value;
                                                final w = bounds.width;
                                                final start = (t * (1.0 + SplashAnimationConfig.shimmerWidth)) - SplashAnimationConfig.shimmerWidth;
                                                final from = (start * w).clamp(0.0, w);
                                                final to = ((start + SplashAnimationConfig.shimmerWidth) * w).clamp(0.0, w);
                                                return LinearGradient(
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.white.withOpacity(0.8),
                                                    Colors.transparent,
                                                  ],
                                                  stops: const [0.0, 0.5, 1.0],
                                                  transform: GradientRotation(0),
                                                ).createShader(Rect.fromLTWH(from, 0, math.max(1.0, to - from), bounds.height));
                                              },
                                              blendMode: BlendMode.srcATop,
                                              child: Opacity(
                                                opacity: 0.12,
                                                child: Text(
                                                  'CLARITY',
                                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                                        fontSize: 32,
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 2,
                                                        color: Colors.white,
                                                      ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  FadeTransition(
                                    opacity: _subtitleExitOpacity,
                                    child: Text(
                                      'Your reset begins here',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              )
                            : Column(
                                key: const ValueKey('loading-content'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    ),
                    const SizedBox(height: 12),
                    // Button area - NOW OUTSIDE LOGO TRANSFORMS!
                    SizedBox(
                      height: _buttonAreaHeight,
                      child: AnimatedOpacity(
                        opacity: _showCtas ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        child: Builder(
                          builder: (context) {
                            if (kDebugMode) {
                              debugPrint('[SPLASH BUTTONS] IgnorePointer.ignoring=${!_showCtas}');
                            }
                            return IgnorePointer(
                              ignoring: !_showCtas,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                if (hasUser && !isGuest) ...[
                                  AnimatedOpacity(
                                    duration: SplashAnimationConfig.ctaItemDuration + const Duration(milliseconds: 120),
                                    opacity: _showCtas ? 1 : 0,
                                    curve: AnimationCurves.emphasizedDecelerate,
                                    child: AnimatedSlide(
                                      duration: SplashAnimationConfig.ctaItemDuration + const Duration(milliseconds: 120),
                                      offset: _showCtas ? Offset.zero : const Offset(0, 0.02),
                                      curve: AnimationCurves.emphasizedDecelerate,
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            if (kDebugMode) {
                                              debugPrint('[SPLASH] Continue button pressed!');
                                            }
                                            await _playExitAndNavigate(context);
                                          },
                                          child: const Text('Continue'),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  AnimatedOpacity(
                                    duration: SplashAnimationConfig.ctaItemDuration + const Duration(milliseconds: 120),
                                    opacity: _showCtas ? 1 : 0,
                                    curve: AnimationCurves.emphasizedDecelerate,
                                    child: AnimatedSlide(
                                      duration: SplashAnimationConfig.ctaItemDuration + const Duration(milliseconds: 120),
                                      offset: _showCtas ? Offset.zero : const Offset(0, 0.02),
                                      curve: AnimationCurves.emphasizedDecelerate,
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () async {
                                            await ref.read(authProvider.notifier).signOut();
                                          },
                                          child: const Text('Sign Out'),
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  AnimatedOpacity(
                                    duration: SplashAnimationConfig.ctaItemDuration + const Duration(milliseconds: 120),
                                    opacity: _showCtas ? 1 : 0,
                                    curve: AnimationCurves.emphasizedDecelerate,
                                    child: AnimatedSlide(
                                      duration: SplashAnimationConfig.ctaItemDuration + const Duration(milliseconds: 120),
                                      offset: _showCtas ? Offset.zero : const Offset(0, 0.02),
                                      curve: AnimationCurves.emphasizedDecelerate,
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            if (kDebugMode) {
                                              debugPrint('[SPLASH] Guest button pressed!');
                                            }
                                            if (!hasUser) {
                                              await ref.read(authProvider.notifier).signInAnonymously();
                                              final postState = ref.read(authProvider);
                                              if (postState.user == null) {
                                                if (!mounted) return;
                                                final msg = postState.errorMessage ?? 'Guest sign-in failed.';
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                                return;
                                              }
                                            }
                                            if (!mounted) return;
                                            await _playExitAndNavigate(context);
                                          },
                                          child: const Text('Continue as Guest'),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  AnimatedOpacity(
                                    duration: SplashAnimationConfig.ctaItemDuration + const Duration(milliseconds: 120),
                                    opacity: _showCtas ? 1 : 0,
                                    curve: AnimationCurves.emphasizedDecelerate,
                                    child: AnimatedSlide(
                                      duration: SplashAnimationConfig.ctaItemDuration + const Duration(milliseconds: 120),
                                      offset: _showCtas ? Offset.zero : const Offset(0, 0.02),
                                      curve: AnimationCurves.emphasizedDecelerate,
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () {
                                            if (kDebugMode) {
                                              debugPrint('[SPLASH] Sign In button pressed!');
                                            }
                                            showDialog(
                                              context: context,
                                              useRootNavigator: true,
                                              builder: (context) => const AuthDialog(),
                                            );
                                          },
                                          child: const Text('Sign In'),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isGuest)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Currently in guest mode',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onBackground.withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      ],
    ),
  );
  }
}

/// Animated overlay that flies the logo from splash to home screen
class AnimatedLogoOverlay extends StatefulWidget {
  const AnimatedLogoOverlay({
    super.key,
    required this.startPosition,
    required this.startSize,
    required this.endPosition,
    required this.endSize,
    required this.onComplete,
  });

  final Offset startPosition;
  final Size startSize;
  final Offset endPosition;
  final Size endSize;
  final VoidCallback onComplete;

  @override
  State<AnimatedLogoOverlay> createState() => _AnimatedLogoOverlayState();
}

class _AnimatedLogoOverlayState extends State<AnimatedLogoOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _tAnimation;
  late Animation<double> _sizeAnimation;
  late Animation<double> _borderRadiusAnimation;
  late Animation<double> _fontSizeAnimation;

  // Path shaping constants (no magic numbers)
  static const double _arcHeightMax = 120.0;
  static const double _arcHeightFactor = 0.25; // fraction of linear distance

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: AnimationDurations.long4, // 1200ms
      vsync: this,
    );

    // Smooth easeInOutCubic curve for natural motion
    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    // Single param t in [0,1] used to compute an arcing path
    _tAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation);

    _sizeAnimation = Tween<double>(
      begin: widget.startSize.width,
      end: widget.endSize.width,
    ).animate(curvedAnimation);

    _borderRadiusAnimation = Tween<double>(
      begin: 24.0,
      end: 10.0,
    ).animate(curvedAnimation);

    _fontSizeAnimation = Tween<double>(
      begin: 64.0,
      end: 18.0,
    ).animate(curvedAnimation);

    // Start animation immediately
    _controller.forward().then((_) {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>();
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Compute arcing position
        final Offset start = widget.startPosition;
        final Offset end = widget.endPosition;
        final double t = _tAnimation.value;
        final Offset linear = Offset.lerp(start, end, t)!;
        final Offset delta = end - start;
        final double distance = delta.distance;
        final double arcHeight = math.min(distance * _arcHeightFactor, _arcHeightMax);
        // Perpendicular (normalized)
        final Offset normal = distance == 0
            ? Offset.zero
            : Offset(-delta.dy / distance, delta.dx / distance);
        // Smooth "bump" using sin(pi * t)
        final double bump = math.sin(math.pi * t);
        final Offset arced = linear + normal * arcHeight * bump;

        return Positioned(
          left: arced.dx.roundToDouble(),
          top: arced.dy.roundToDouble(),
          child: IgnorePointer(
            child: Material(
              elevation: 0,
              color: appColors?.pop ?? Theme.of(context).colorScheme.error,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_borderRadiusAnimation.value),
              ),
              child: SizedBox(
                width: _sizeAnimation.value,
                height: _sizeAnimation.value,
                child: Center(
                  child: Text(
                    'UP',
                    style: TextStyle(
                      color: appColors?.onPop ?? Theme.of(context).colorScheme.onError,
                      fontSize: _fontSizeAnimation.value,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
