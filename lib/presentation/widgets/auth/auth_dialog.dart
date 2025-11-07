import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meditation_by_vk/core/constants.dart';
import 'package:meditation_by_vk/providers/auth_provider.dart';

class AuthDialog extends ConsumerStatefulWidget {
  const AuthDialog({super.key});

  @override
  ConsumerState<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends ConsumerState<AuthDialog> {
  bool isSignInMode = true; // true = Sign In, false = Sign Up
  bool isLoading = false;
  String? errorText;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handlePrimaryAction() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });
    try {
      final email = emailController.text.trim();
      final password = passwordController.text;
      if (email.isEmpty || password.isEmpty) {
        setState(() {
          errorText = 'Please enter email and password.';
        });
        return;
      }
      if (isSignInMode) {
        await ref.read(authProvider.notifier).signInWithEmail(email, password);
      } else {
        // Name is optional at this stage; can be captured later
        await ref.read(authProvider.notifier).signUpWithEmail(email, password);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorText = isSignInMode ? 'Sign-in failed' : 'Sign-up failed';
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _handleGoogle() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      if (!mounted) return;
      Navigator.of(context).pop();
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() => errorText = 'Google sign-in failed');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleApple() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });
    try {
      await ref.read(authProvider.notifier).signInWithApple();
      if (!mounted) return;
      Navigator.of(context).pop();
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      setState(() => errorText = 'Apple sign-in failed');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _promptPasswordReset() async {
    final TextEditingController resetEmailController = TextEditingController(text: emailController.text.trim());
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset password'),
          content: TextField(
            controller: resetEmailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(resetEmailController.text.trim()), child: const Text('Send')),
          ],
        );
      },
    );
    if (result == null || result.isEmpty) return;
    setState(() {
      isLoading = true;
      errorText = null;
    });
    try {
      await ref.read(authProvider.notifier).sendPasswordResetEmail(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => errorText = 'Password reset failed');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = isSignInMode ? 'Sign In' : 'Sign Up';
    final dividerText = isSignInMode ? 'Or sign in with email' : 'Or sign up with email';
    final primaryCta = isSignInMode ? 'Sign in' : 'Create account';

    return AlertDialog(
      title: Text(titleText),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top: SSO buttons
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : _handleApple,
                icon: const Icon(Icons.apple),
                label: const Text('Continue with Apple'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : _handleGoogle,
                icon: const Icon(Icons.login),
                label: const Text('Continue with Google'),
              ),
            ),
            const SizedBox(height: 16),
            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: Theme.of(context).dividerColor.withOpacity(0.7))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(dividerText, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                ),
                Expanded(child: Divider(color: Theme.of(context).dividerColor.withOpacity(0.7))),
              ],
            ),
            const SizedBox(height: 16),
            if (!isSignInMode) ...[
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.username, AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding, vertical: 12),
      actions: [
        if (isSignInMode)
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onPressed: isLoading ? null : _promptPasswordReset,
            child: const Text('Forgot password?'),
          ),
        const Spacer(),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: isLoading
              ? null
              : () {
                  setState(() {
                    isSignInMode = !isSignInMode;
                    errorText = null;
                  });
                },
          child: Text(isSignInMode ? "Don't have an account? Sign Up" : 'Already have an account? Sign In'),
        ),
        FilledButton(
          onPressed: isLoading ? null : _handlePrimaryAction,
          child: isLoading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(primaryCta),
        ),
      ],
    );
  }
}


