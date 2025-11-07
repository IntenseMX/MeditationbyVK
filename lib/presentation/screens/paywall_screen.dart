import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../providers/subscription_provider.dart';
import '../../config/subscription_config.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);
    final appColors = Theme.of(context).extension<AppColors>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeaderCard(),
              const SizedBox(height: 24),
              _BenefitRow(icon: Icons.lock_open_rounded, text: 'Unlock all premium meditations'),
              const SizedBox(height: 12),
              _BenefitRow(icon: Icons.stars_rounded, text: 'Curated collections and new releases'),
              const SizedBox(height: 12),
              _BenefitRow(icon: Icons.favorite_rounded, text: 'Support ongoing content and features'),
              const Spacer(),
              if (sub.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    sub.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: sub.isLoading || sub.isPremium
                      ? null
                      : () => ref.read(subscriptionProvider.notifier).purchaseMonthly(),
                  child: sub.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Continue — ${sub.priceText ?? SubscriptionConfig.monthlyDisplayPriceFallback}'),
                ),
              ),
              const SizedBox(height: 12),
              if (SubscriptionConfig.enableRestore)
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: sub.isLoading ? null : () => ref.read(subscriptionProvider.notifier).restore(),
                    child: const Text('Restore Purchases'),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Auto-renewing monthly subscription. Cancel anytime in your account settings.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                children: [
                  TextButton(
                    onPressed: () => _launchUrl(context, 'https://meditation-by-vk-89927.web.app/legal/terms.html'),
                    child: Text(
                      'Terms of Service',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _launchUrl(context, 'https://meditation-by-vk-89927.web.app/legal/privacy.html'),
                    child: Text(
                      'Privacy Policy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final ext = Theme.of(context).extension<AppColors>();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colors.tertiary, colors.secondary]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Go Premium',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ext?.textOnGradient ?? colors.onInverseSurface,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Instant access to all premium sessions',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: (ext?.textOnGradient ?? colors.onInverseSurface).withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.onSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}


