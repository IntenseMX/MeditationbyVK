import 'package:flutter/material.dart';

/// Reusable widget displaying meditation title, subtitle, category, duration,
/// and premium badge in a cohesive block
class TitleMetadataBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? categoryId;
  final int durationSec;
  final bool isPremium;
  final Map<String, String> categoryIdToName;
  final VoidCallback? onCategoryTap;
  final VoidCallback? onSleepTimerTap;
  final VoidCallback? onShareTap;

  const TitleMetadataBlock({
    required this.title,
    required this.subtitle,
    required this.durationSec,
    required this.isPremium,
    required this.categoryIdToName,
    this.categoryId,
    this.onCategoryTap,
    this.onSleepTimerTap,
    this.onShareTap,
    super.key,
  });

  String _resolveCategoryName(String? id) {
    if (id == null || id.trim().isEmpty) return 'General';
    final byName = categoryIdToName[id];
    if (byName != null && byName.trim().isNotEmpty) return byName;
    return _prettyCategory(id);
  }

  String _prettyCategory(String input) {
    final s = input.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    return s.split(' ').map((w) => w.isEmpty ? '' : (w[0].toUpperCase() + w.substring(1))).join(' ');
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString();
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 8),
        
        // Subtitle with fade effect if too long
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        
        const SizedBox(height: 12),
        
        // Metadata row (category, duration, premium badge)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category chip
            if (categoryId != null && categoryId!.isNotEmpty)
              GestureDetector(
                onTap: onCategoryTap,
                child: Chip(
                  label: Text(_resolveCategoryName(categoryId)),
                  backgroundColor: colorScheme.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 12,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            
            if (categoryId != null && categoryId!.isNotEmpty) ...[
              const SizedBox(width: 12),
              _DotSeparator(colorScheme: colorScheme),
              const SizedBox(width: 12),
            ],
            
            // Duration
            Icon(Icons.timer_outlined, size: 16, color: colorScheme.onSurface.withOpacity(0.6)),
            const SizedBox(width: 4),
            Text(
              _formatDuration(durationSec),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),

            // Sleep timer button
            if (onSleepTimerTap != null) ...[
              const SizedBox(width: 12),
              _DotSeparator(colorScheme: colorScheme),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onSleepTimerTap,
                child: Icon(Icons.bedtime_outlined, size: 18, color: colorScheme.onSurface.withOpacity(0.7)),
              ),
            ],

            // Share button
            if (onShareTap != null) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onShareTap,
                child: Icon(Icons.share_outlined, size: 18, color: colorScheme.onSurface.withOpacity(0.7)),
              ),
            ],

            if (isPremium) ...[
              const SizedBox(width: 12),
              _DotSeparator(colorScheme: colorScheme),
              const SizedBox(width: 12),
              
              // Premium badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber, Colors.amber.shade700],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'PREMIUM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Simple dot separator widget
class _DotSeparator extends StatelessWidget {
  final ColorScheme colorScheme;

  const _DotSeparator({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.onSurface.withOpacity(0.4),
      ),
    );
  }
}

/// Compact version for use in lists or cards
class MiniTitleBlock extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int durationSec;
  final bool isPremium;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const MiniTitleBlock({
    required this.title,
    this.subtitle,
    required this.durationSec,
    required this.isPremium,
    this.titleStyle,
    this.subtitleStyle,
    super.key,
  });

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString();
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: titleStyle ?? Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isPremium) ...[
              const SizedBox(width: 8),
              Icon(Icons.star, size: 16, color: Colors.amber),
            ],
          ],
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: subtitleStyle ?? Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.timer_outlined, size: 14, color: colorScheme.onSurface.withOpacity(0.6)),
            const SizedBox(width: 4),
            Text(
              _formatDuration(durationSec),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
