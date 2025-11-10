import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/progress_provider.dart';
import '../widgets/goal_settings_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final effectiveDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);
    // TODO(Section C - 2025-10-27): Replace with real Firestore-backed profile provider
    final userProfile = {
      'name': 'Guest',
      'email': '',
      'isPremium': false,
      'totalSessions': 0,
      'totalMinutes': 0,
      'currentStreak': 0,
      'streak': 0,
    };

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with Profile Info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile Header
                    Row(
                      children: [
                        Builder(
                          builder: (context) {
                            final appColors = Theme.of(context).extension<AppColors>();
                            return CircleAvatar(
                              radius: 40,
                              backgroundColor: appColors?.pop ?? AppTheme.deepCrimson,
                              child: Text(
                                userProfile['name'].toString().substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: appColors?.onPop ?? AppTheme.warmSandBeige,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userProfile['name'] as String,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                (userProfile['email'] as String?) ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Premium Banner
                    if (!((userProfile['isPremium'] as bool?) ?? false))
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.tertiary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Builder(builder: (context) {
                          final gradientText = Theme.of(context).extension<AppColors>()?.textOnGradient
                              ?? Theme.of(context).colorScheme.onInverseSurface;
                          return Column(
                            children: [
                              Icon(
                                Icons.stars,
                                color: gradientText,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Upgrade to Premium',
                                style: TextStyle(
                                  color: gradientText,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Unlock all meditations & features',
                                style: TextStyle(
                                  color: gradientText.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => context.push('/paywall'),
                                child: const Text(
                                  'Learn More',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),

                    const SizedBox(height: 24),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Sessions',
                            userProfile['totalSessions'].toString(),
                            Icons.self_improvement,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Total Time',
                            '${userProfile['totalMinutes']} min',
                            Icons.timer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            'Streak',
                            '${userProfile['currentStreak']} days',
                            Icons.local_fire_department,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Settings List
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Settings Items
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSettingItem(
                    context,
                    icon: Icons.dark_mode,
                    title: 'Dark Mode',
                    trailing: Switch(
                      value: effectiveDark,
                      onChanged: (value) {
                        ref
                            .read(themeModeProvider.notifier)
                            .setTheme(value ? ThemeMode.dark : ThemeMode.light);
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.palette,
                    title: 'Themes',
                    subtitle: 'Choose from 12 luxury presets',
                    onTap: () => context.go('/themes'),
                  ),
                  // TEMP (2025-10-21): Admin button is always visible until login/auth is integrated.
                  // TODO: Re-enable admin gating by checking authProvider.isAdmin here.
                  _buildSettingItem(
                    context,
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Panel',
                    subtitle: 'Manage content and categories',
                    onTap: () => context.go('/admin'),
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Daily reminders & updates',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.flag,
                    title: 'Goals',
                    subtitle: 'Set your meditation goals',
                    onTap: () async {
                      final dto = ref.read(progressDtoProvider);
                      int initial = 10;
                      dto.whenData((m) {
                        try {
                          initial = (m['daily']?['goalMinutes'] as int?) ?? 10;
                        } catch (_) {
                          initial = 10;
                        }
                      });
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (_) => GoalSettingsDialog(initialMinutes: initial),
                      );
                      if (result == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Daily goal updated')),
                        );
                      }
                    },
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.music_note,
                    title: 'Background Sounds',
                    subtitle: 'Customize ambient sounds',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.download,
                    title: 'Downloads',
                    subtitle: 'Manage offline content',
                    onTap: () {},
                  ),
                  // Manage Subscription (visible for premium users)
                  Consumer(
                    builder: (context, ref, _) {
                      final sub = ref.watch(subscriptionProvider);
                      if (!sub.isPremium) return const SizedBox.shrink();

                      return ListTile(
                        leading: const Icon(Icons.manage_accounts),
                        title: const Text('Manage Subscription'),
                        trailing: const Icon(Icons.open_in_new, size: 16),
                        onTap: () => _launchUrl(
                          context,
                          Platform.isIOS
                              ? 'https://apps.apple.com/account/subscriptions'
                              : 'https://play.google.com/store/account/subscriptions',
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.softCharcoal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    context,
                    icon: Icons.help,
                    title: 'Help & Support',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    onTap: () => _launchUrl(context, 'https://meditation-by-vk-89927.web.app/legal/privacy.html'),
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.description,
                    title: 'Terms of Service',
                    onTap: () => _launchUrl(context, 'https://meditation-by-vk-89927.web.app/legal/terms.html'),
                  ),
                  _buildSettingItem(
                    context,
                    icon: Icons.info,
                    title: 'About',
                    subtitle: 'Version 1.0.0',
                    onTap: () {},
                  ),
                  const SizedBox(height: 20),
                  // Sign Out Button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: OutlinedButton(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).signOut();
                        if (context.mounted) {
                          context.go('/splash');
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).colorScheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Sign Out',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.12),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: trailing ??
            (onTap != null
                ? Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
                : null),
        onTap: onTap,
      ),
    );
  }
}

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