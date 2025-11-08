# Theming System (2025-11-03)

Last Updated: 2025-11-03

## Overview
This document explains how the app's theming works, where theme data flows, and how to add or modify themes safely. The goals are:
- One place to adjust visual identity across the whole app
- 15 data-driven presets that fully change the look (backgrounds, text, components)
- Mobile-first tinting tuned for Android/iOS rendering

## Key Files
- lib/config/theme_presets.dart
  - Source of truth for the 15 presets and all tinting constants
  - Builds ColorScheme via `_cs(...)` helper with background/surface tinting
- lib/core/theme.dart
  - Base Material 3 theme wiring and ThemeExtension `AppColors`
  - Holds cross-app constants like `AppTheme.thumbnailBottomFadeOpacity`
- lib/providers/theme_provider.dart
  - Persists selected preset key and ThemeMode (light/dark)
  - Exposes providers used by `MaterialApp.router` in `main.dart`
- lib/presentation/screens/themes_screen.dart
  - UI to preview/apply presets; navigates to `/splash` to ensure full theme refresh
- lib/presentation/screens/* and widgets/*
  - All UI reads `Theme.of(context).colorScheme` and `AppColors`

## Data Flow
1) User selects a preset on `ThemesScreen`
2) `themeSelectionProvider` saves the preset key (SharedPreferences)
3) App rebuilds with the selected `ThemePreset`
4) `buildThemeFromPreset` constructs `ThemeData` using `ColorScheme` from `_cs(...)`
5) UI reads colors from `colorScheme` and `AppColors`

## ColorScheme Construction (_cs)
`_cs(...)` centralizes theme math:
- Background tinting for whole app surface
  - Light: `background = alphaBlend(primary @ kLightBackgroundTint, surface)`
  - Dark:  `background = alphaBlend(primary @ kDarkBackgroundTint, surface)`
- Surface tinting for cards/sheets
  - `surface = alphaBlend(primary @ kLightSurfaceTint|kDarkSurfaceTint, surface)`
- Surface variant & outline opacities
  - `surfaceVariant = surface.withOpacity(kSurfaceVariantOpacity)`
  - `outline = onSurface.withOpacity(kOutlineOpacityDefault)`
- Text contrast
  - `onSurface` is explicitly set per preset and now thematically blended with `primary` (see Preset Rules)

## Mobile-First Tinting Constants
Defined at top of `theme_presets.dart`:
- kLightBackgroundTint = 0.50
- kDarkBackgroundTint  = 0.32
- kLightSurfaceTint    = 0.35
- kDarkSurfaceTint     = 0.10
- kSurfaceVariantOpacity = 0.18

These values were tuned for Android/iOS compositor behavior to keep the app visibly themed without muddying text or causing heavy layered opacity.

## ThemeExtension: AppColors
`AppColors` augments Material colors for special cases:
- pop / onPop: strong accent for logos/alerts
- textOnGradient: ensures legibility on gradient content
- statusSuccess / statusWarning: consistent status coloring
Access with:
```dart
final appColors = Theme.of(context).extension<AppColors>();
```

## Preset Rules (Light/Dark)
Each preset specifies `primary/secondary/surface` and related colors. Two important rules drive consistency:
- Background & surface are tinted by `primary` via `_cs(...)`
- onSurface text is contrasted AND lightly themed
  - Light mode: `onSurface = alphaBlend(primary @ 0.30, darkNeutral)`
  - Dark mode:  `onSurface = alphaBlend(primary @ 0.20, lightNeutral)`
This makes headers like “Recently Added” and “Trending Now” subtly reflect the theme while staying readable.

## How to Add a New Theme (Preset)
1) Open `lib/config/theme_presets.dart`
2) Copy an existing `ThemePreset` block and adjust values:
   - `key`: unique snake_case string (e.g., `midnight_sage`)
   - `name`: human readable (e.g., `Midnight Sage`)
   - `primary`, `secondary`, `surface` (light/dark) — pick brand palette
   - `onPrimary`, `onSecondary`, `onTertiary` for contrast
   - `onSurface` base neutrals: choose a dark neutral (light mode) and a light neutral (dark mode)
     - Keep the per-preset onSurface blending pattern intact (already implemented)
   - `tertiary` optional, defaults to `secondary` if not set
   - `previewGradient`: two representative colors for the picker tile
3) Do NOT hardcode widget colors. Ensure affected widgets read from `colorScheme` or `AppColors`.
4) Hot restart or navigate to `/splash` to force full theme refresh.

## Preset Catalog Update (2025-11-03)

- Added three new palettes:
  - `winter_wonderland` (Frosted Mist, Powder Blue, Ice Lake, Arctic Sky)
  - `burgundy_luxe` (Burgundy + soft gold)
  - `racing_green_gold` (Deep racing green + gold)
- Total presets: 15.

## Choosing Colors (Guidelines)
- Primary: the main vibe; should influence background & surface pleasingly
- Secondary/Tertiary: accents for chips, charts, highlights
- Surface (base): very light (light mode) or deep (dark mode) neutral in the same hue family
- onSurface neutrals: pick high-contrast baseline, tinting will add the theme flavor
- Accessibility: keep text contrast WCAG-friendly after blending (ideally AA)

## Where Components Get Colors
- Text, icons, borders, backgrounds: `Theme.of(context).colorScheme.*`
  - Examples: `onSurface`, `onSurfaceVariant`, `primary`, `tertiary`, `outline`, `surfaceVariant`
- Gradient content and special accents: `AppColors.textOnGradient`, `AppColors.pop`
- Overlays on images (thumbnails): use `AppTheme.thumbnailBottomFadeOpacity`

## Do / Don’t
- Do: use `colorScheme` everywhere; keep constants centralized
- Do: update presets only in `theme_presets.dart`
- Don’t: use `Colors.white/black/0xFF...` directly in widgets
- Don’t: add page-level background overlays that hide `scaffoldBackgroundColor`
- Don’t: bypass `ThemeMode` / preset providers

## Persistence & Mode
- Theme preset key and `ThemeMode` are persisted via `SharedPreferences`
- Default mode is `ThemeMode.light`
- Profile screen switch updates theme mode and persists it

## Platform Notes
- Android: stacked opacity can look heavier than web
  - We tuned background/surface tints for mobile and reduced `surfaceVariant` opacity
  - If you add new overlays, keep opacity conservative (≤ 0.30 combined)
- Use Flutter Inspector to verify `colorScheme.background/surface` on device
- Disable Android “Override force-dark” in Developer Options

## Testing Checklist
- Headers (Home/Discover/Progress/Profile) reflect the theme subtly (onSurface)
- Cards/sheets follow theme (surface tint); borders use `outline`
- Gradients remain legible using `AppColors.textOnGradient`
- Dark mode toggle updates correctly after app restart
- No hardcoded `Color(...)` in widgets

## FAQ
- Q: I want stronger theme text.
  - A: Increase onSurface blend opacity (e.g., 0.30 → 0.40) per preset light mode; keep dark ≤ 0.25 for contrast.
- Q: Background looks too white/black.
  - A: Raise `kLightBackgroundTint` / `kDarkBackgroundTint` a bit (small steps: +0.05) and re-test.
- Q: Web vs Android looks different.
  - A: Prioritize mobile values; reduce extra overlays; verify Inspector values match expectations.

## Example Snippets
```dart
// Read primary/onSurface in a widget
final cs = Theme.of(context).colorScheme;
Text('Trending Now', style: TextStyle(color: cs.onSurface));

// Access ThemeExtension
final appColors = Theme.of(context).extension<AppColors>();
Text('On gradient', style: TextStyle(color: appColors?.textOnGradient));
```

## Maintenance
- All theme math and constants live in `theme_presets.dart`
- Update this document after any theming changes (add timestamp above)
- Cross-check `CODE_FLOW.md`, `APP_LOGIC.md`, `TASK.md` for high-level notes/links


