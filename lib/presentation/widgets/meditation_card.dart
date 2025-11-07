import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/subscription_provider.dart';

class MeditationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int duration;
  final String imageUrl;
  final List<int> gradientColors;
  final bool isPremium;
  final VoidCallback? onTap;
  final bool compact;
  final String? category;

  const MeditationCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.imageUrl,
    required this.gradientColors,
    this.isPremium = false,
    this.onTap,
    this.compact = false,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    // Create unique hero tag from title
    final heroTag = 'meditation_$title';
    final appColors = Theme.of(context).extension<AppColors>();
    final gradientText = appColors?.textOnGradient ?? Theme.of(context).colorScheme.onInverseSurface;
    const double _defaultTitleFontSize = 22.0;
    const double _compactTitleFontSize = 18.0;
    const double _defaultCardHeight = 180.0;
    const double _compactCardHeight = 140.0;
    final double cardHeight = compact ? _compactCardHeight : _defaultCardHeight;
    final double titleFontSize = compact ? _compactTitleFontSize : _defaultTitleFontSize;

    return Consumer(
      builder: (context, ref, _) {
        final sub = ref.watch(subscriptionProvider);
        final isLocked = isPremium && !sub.isPremium;
        return GestureDetector(
          onTap: () {
            if (isLocked) {
              context.push('/paywall');
              return;
            }
            onTap?.call();
          },
          child: Hero(
        tag: heroTag,
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: cardHeight,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Color(gradientColors[0]).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: imageUrl.isNotEmpty
                ? [
                    Colors.transparent,
                    Color(gradientColors.last).withOpacity(AppTheme.thumbnailBottomFadeOpacity),
                  ]
                : gradientColors.map((c) => Color(c)).toList(),
          ),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                ),
              ),
            ),
            // Optional lock overlay for non-subscribers
            if (isLocked)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.85),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isPremium)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.agedGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: AppTheme.softCharcoal,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: gradientText,
                              fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: gradientText.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                      if (!compact)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: gradientText.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.timer_outlined,
                                    color: gradientText,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$duration min',
                                    style: TextStyle(
                                      color: gradientText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: gradientText.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow,
                                color: gradientText,
                                size: 24,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (category != null && category!.trim().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: gradientText.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  category!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: gradientText, fontSize: 12),
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            Text(
                              '$duration min',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: gradientText.withOpacity(0.9)),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
          ),
        ),
          ),
        );
      },
    );
  }
}