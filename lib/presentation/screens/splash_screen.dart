import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:meditation_by_vk/core/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meditation_by_vk/providers/auth_provider.dart';
import '../../core/constants.dart';
import 'package:meditation_by_vk/core/animation_constants.dart';
import 'package:meditation_by_vk/presentation/widgets/zen_background.dart';
import 'package:meditation_by_vk/presentation/widgets/breathing_glow.dart';
import 'package:meditation_by_vk/services/auth_service.dart';
import 'package:meditation_by_vk/presentation/widgets/auth/auth_dialog.dart';

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
  int _ctaStage = 0;
  // Exit timeline
  late AnimationController _exitController;
  late Animation<double> _logoExitScale;
  late Animation<double> _logoExitLift;
  late Animation<double> _glowExitScale;
  late Animation<double> _glowExitOpacity;
  late Animation<double> _titleExitOpacity;
  late Animation<double> _subtitleExitOpacity;
  bool _isExiting = false;

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

    // Reveal CTAs after brief brand animation (no auto-navigation)
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showCtas = true);
      // Stagger CTA items
      Future.delayed(SplashAnimationConfig.ctaStagger, () {
        if (!mounted) return;
        setState(() => _ctaStage = 1);
      });
      Future.delayed(Duration(milliseconds: SplashAnimationConfig.ctaStagger.inMilliseconds * 2), () {
        if (!mounted) return;
        setState(() => _ctaStage = 2);
      });
      // Ensure auth state checked (no side effects)
      ref.read(authProvider.notifier).checkAuthState();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shimmerController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _playExitAndNavigate(BuildContext context) async {
    if (_isExiting) return;
    setState(() {
      _isExiting = true;
      _showCtas = false; // let CTAs fade away via AnimatedSwitcher
    });
    await _exitController.forward();
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final hasUser = authState.user != null;
    final isGuest = hasUser && authState.status == AuthStatus.guest;

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
                          child: Hero(
                            tag: 'brand',
                            child: Container(
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
                      ],
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _subtitleExitOpacity,
                      child: Text(
                        'by VK',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 24),
                    // App name with subtle shimmer overlay
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
                                  // Shift the gradient window across the text bounds
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
                    const SizedBox(height: 48),
                    AnimatedSwitcher(
                      duration: AnimationDurations.ctaReveal,
                      switchInCurve: AnimationCurves.standardEasing,
                      switchOutCurve: AnimationCurves.standardEasing,
                      transitionBuilder: (child, animation) {
                        final slide = Tween<Offset>(
                          begin: const Offset(0, 0.04),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(parent: animation, curve: AnimationCurves.standardEasing));
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: _showCtas
                          ? Padding(
                              key: const ValueKey('ctas'),
                              padding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // If user is authenticated (not anonymous), show Continue + Sign Out
                                  if (hasUser && !isGuest) ...[
                                    AnimatedOpacity(
                                      duration: SplashAnimationConfig.ctaItemDuration,
                                      opacity: _ctaStage >= 1 ? 1 : 0,
                                      curve: AnimationCurves.standardEasing,
                                      child: AnimatedSlide(
                                        duration: SplashAnimationConfig.ctaItemDuration,
                                        offset: _ctaStage >= 1 ? Offset.zero : const Offset(0, 0.02),
                                        curve: AnimationCurves.standardEasing,
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () async => await _playExitAndNavigate(context),
                                            child: const Text('Continue'),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    AnimatedOpacity(
                                      duration: SplashAnimationConfig.ctaItemDuration,
                                      opacity: _ctaStage >= 2 ? 1 : 0,
                                      curve: AnimationCurves.standardEasing,
                                      child: AnimatedSlide(
                                        duration: SplashAnimationConfig.ctaItemDuration,
                                        offset: _ctaStage >= 2 ? Offset.zero : const Offset(0, 0.02),
                                        curve: AnimationCurves.standardEasing,
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
                                  ]
                                  // If not authenticated or guest, show Continue as Guest + Sign In + Sign Up
                                  else ...[
                                    AnimatedOpacity(
                                      duration: SplashAnimationConfig.ctaItemDuration,
                                      opacity: _ctaStage >= 1 ? 1 : 0,
                                      curve: AnimationCurves.standardEasing,
                                      child: AnimatedSlide(
                                        duration: SplashAnimationConfig.ctaItemDuration,
                                        offset: _ctaStage >= 1 ? Offset.zero : const Offset(0, 0.02),
                                        curve: AnimationCurves.standardEasing,
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () async {
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
                                      duration: SplashAnimationConfig.ctaItemDuration,
                                      opacity: _ctaStage >= 2 ? 1 : 0,
                                      curve: AnimationCurves.standardEasing,
                                      child: AnimatedSlide(
                                        duration: SplashAnimationConfig.ctaItemDuration,
                                        offset: _ctaStage >= 2 ? Offset.zero : const Offset(0, 0.02),
                                        curve: AnimationCurves.standardEasing,
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
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
                            )
                          : SizedBox(
                              key: const ValueKey('spinner'),
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                ),
                              ),
                            ),
                    ),
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

class _SignInDialog extends ConsumerStatefulWidget {
  const _SignInDialog();

  @override
  ConsumerState<_SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends ConsumerState<_SignInDialog> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = 'Please enter email and password.';
        _isLoading = false;
      });
      return;
    }
    try {
      await ref.read(authProvider.notifier).signInWithEmail(email, password);
      if (!mounted) return;
      Navigator.of(context).pop();
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Sign-in failed';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sign In'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleSignIn,
          child: _isLoading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Continue'),
        ),
      ],
    );
  }
}

class _SignUpDialog extends ConsumerStatefulWidget {
  const _SignUpDialog();

  @override
  ConsumerState<_SignUpDialog> createState() => _SignUpDialogState();
}

class _SignUpDialogState extends ConsumerState<_SignUpDialog> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSignUp() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = 'Please enter email and password.';
        _isLoading = false;
      });
      return;
    }
    try {
      await ref.read(authProvider.notifier).signUpWithEmail(email, password);
      if (!mounted) return;
      Navigator.of(context).pop();
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'Sign-up failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogle() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await AuthService().signInWithGoogle();
      if (!mounted) return;
      Navigator.of(context).pop();
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'Google sign-in failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleApple() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await AuthService().signInWithApple();
      if (!mounted) return;
      Navigator.of(context).pop();
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = 'Apple sign-in failed');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sign Up'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isLoading ? null : _handleEmailSignUp,
              child: _isLoading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Sign Up'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _handleGoogle,
              icon: const Icon(Icons.login),
              label: const Text('Continue with Google'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _handleApple,
              icon: const Icon(Icons.apple),
              label: const Text('Continue with Apple'),
            ),
          ),
          if (_errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}