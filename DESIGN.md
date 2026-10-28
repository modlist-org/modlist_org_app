# Design: modlist.org app

The app shares the locked system of the website: `modlist-org/DESIGN.md` is the rule, and this file only maps it to Flutter. Change the system there first, then here.

## Where the tokens live
- `lib/src/ui/theme.dart`: `AppColors`, `AppRadius`, `buildAppTheme()`.
- Palette: Overlayer V5, same values as the site's `tokens.css` (hex here, OKLCH there).
- Face: SUIT, fallback NotoSansSC.

## Rules carried over
- Text on accent and status fills uses `AppColors.onAccent` (dark ink); white fails contrast on `#6C78FF`.
- Faint text is `AppColors.textTertiary` (`#8D8BA6`), never darker.
- Text fields draw a 1px `AppColors.fieldEdge`; focus is a 2px accent outline.
- Mod lists are index rows parted by `Divider()` (logo 72, name 20/w700, one-line summary, tags; downloads large and version beneath on the right), never a card grid.
- Fallback logo tiles are one flat hue (`fallbackLogoGradient`), never a two-hue gradient.
- No emoji or text glyphs as icons; Material icons or SVG.
- overlayer_ui_flutter controls (`OlButton`, `OlSwitch`…) are kept as the library draws them.
- Motion: 120ms hover and press, no overshoot.
