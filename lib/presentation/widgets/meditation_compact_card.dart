import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/meditation_service.dart';

/// Compact meditation card used in related/recommended sections.
class MeditationCompactCard extends StatelessWidget {
  const MeditationCompactCard({
    super.key,
    required this.meditation,
    required this.onTap,
  });

  final MeditationListItem meditation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final String title = (meditation.title).trim().isEmpty
        ? 'Untitled'
        : (meditation.title).trim();
    final String imageUrl = meditation.imageUrl ?? '';
    final int? durationSec = meditation.durationSec;
    final bool isPremium = meditation.isPremium ?? false;

    String formatMinutes(int? seconds) {
      if (seconds == null || seconds <= 0) return '5 min';
      final minutes = (seconds / 60).ceil();
      return '$minutes min';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: colors.surface.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outline.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: imageUrl.isEmpty
                  ? Container(
                      height: 80,
                      color: colors.surfaceVariant,
                      child: Icon(Icons.spa, size: 40, color: colors.onSurfaceVariant),
                    )
                  : Image.network(
                      imageUrl,
                      height: 80,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatMinutes(durationSec),
                          style: textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (isPremium)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.workspace_premium,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Plus',
                                style: GoogleFonts.norican(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


