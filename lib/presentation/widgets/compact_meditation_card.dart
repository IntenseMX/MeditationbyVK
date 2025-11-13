import 'package:flutter/material.dart';

class CompactMeditationCard extends StatelessWidget {
  const CompactMeditationCard({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.durationSec,
    this.categoryName,
    this.isPremium = false,
    required this.onPlay,
  });

  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final int? durationSec;
  final String? categoryName;
  final bool isPremium;
  final VoidCallback onPlay;

  static const double _thumbnailSize = 96.0;
  static const double _cornerRadius = 16.0;
  static const double _spacing = 12.0;

  String _formatMinutes(int? seconds) {
    if (seconds == null || seconds <= 0) return '1 min';
    if (seconds < 300) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      final mm = m.toString();
      final ss = s.toString().padLeft(2, '0');
      return '$mm:$ss';
    }
    final minutes = (seconds / 60).ceil();
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final heroTag = 'meditation_$id';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(_cornerRadius),
        border: Border.all(color: colors.outline.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onPlay,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_cornerRadius),
              child: Hero(
                tag: heroTag,
                child: Container(
                  width: _thumbnailSize,
                  height: _thumbnailSize,
                  color: colors.surface,
                  child: imageUrl.isEmpty
                      ? Icon(Icons.spa, color: colors.onSurfaceVariant)
                      : Image.network(imageUrl, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
          const SizedBox(width: _spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPremium)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.workspace_premium, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.surface.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.outline.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 16, color: colors.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text(
                            _formatMinutes(durationSec),
                            style: textTheme.labelMedium?.copyWith(color: colors.onSurface),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (categoryName != null && categoryName!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.surface.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.outline.withOpacity(0.2)),
                        ),
                        child: Text(
                          categoryName!,
                          style: textTheme.labelMedium?.copyWith(color: colors.onSurface),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const Spacer(),
                    SizedBox(
                      height: 40,
                      width: 40,
                      child: Material(
                        color: colors.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onPlay,
                          child: Icon(Icons.play_arrow, color: colors.onPrimary, size: 22),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


