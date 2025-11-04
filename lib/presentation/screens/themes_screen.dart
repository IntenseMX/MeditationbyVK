import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme_presets.dart';
import '../../providers/theme_provider.dart';

class ThemesScreen extends ConsumerWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(themeSelectionProvider);
    final isDark = ref.watch(isDarkModeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Themes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Preview Mode',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Row(
                  children: [
                    const Text('Light'),
                    Switch(
                      value: isDark,
                      onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
                    ),
                    const Text('Dark'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3 / 4,
              ),
              itemCount: kThemePresets.length,
              itemBuilder: (context, index) {
                final preset = kThemePresets[index];
                final selected = preset.key == sel.selectedKey;
                return _ThemeTile(
                  preset: preset,
                  selected: selected,
                  onTap: () => ref.read(themeSelectionProvider.notifier).select(preset.key),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Theme selection is already persisted on tile tap.
                    // Apply should take user back to Splash with new theme.
                    context.go('/splash');
                  },
                  child: const Text('Apply'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.preset, required this.selected, required this.onTap});
  final ThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = preset.previewGradient;
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? cs.primary : cs.outline.withOpacity(0.4), width: selected ? 2 : 1),
          color: cs.surface,
        ),
        child: Column(
          children: [
            // Preview card
            Container(
              margin: const EdgeInsets.all(12),
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(colors: gradient),
                boxShadow: [
                  BoxShadow(color: gradient.first.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              child: Center(
                child: Text(
                  'Preview',
                  style: TextStyle(
                    color: (preset.lightExtension.textOnGradient),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      preset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle,
                      color: cs.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  _Swatch(color: preset.light.primary),
                  _Swatch(color: preset.light.secondary),
                  _Swatch(color: preset.light.surface),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
    );
  }
}


