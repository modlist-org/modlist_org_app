import 'package:flutter/material.dart';

/// Design tokens shared with the modlist.org website (Overlayer V5 palette,
/// matching overlayer-ui).
class AppColors {
  AppColors._();

  // Surfaces (darkest -> lightest), purple-tinted
  static const Color bg = Color(0xFF121118);
  static const Color bgElev = Color(0xFF16151D);
  static const Color surface = Color(0xFF1E1C28);
  static const Color surface2 = Color(0xFF2A2836);
  static const Color surface3 = Color(0xFF3C3A4B);
  static const Color surfaceHover = Color(0xFF24222F);

  /// Filled control background used by overlayer-ui (buttons, inputs, toggles).
  static const Color control = surface3;
  static const Color controlHover = Color(0xFF4A4860);
  static const Color controlPressed = Color(0xFF5A5873);

  static const Color border = Color(0x0DFFFFFF);
  static const Color borderStrong = Color(0x17FFFFFF);

  static const Color text = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B2C6);
  static const Color textTertiary = Color(0xFF75738F);

  static const Color accent = Color(0xFF919AFF);
  static const Color button = Color(0xFF6C78FF);
  static const Color buttonHover = Color(0xFF838EFF);
  static const Color buttonActive = Color(0xFFB1B8FF);
  static const Color muted = Color(0xFF626696);
  static const Color iconLight = Color(0xFFF3F4FF);
  static const Color accentSoft = Color(0x24919AFF);
  static const Color accentBorder = Color(0x73919AFF);

  static const Color success = Color(0xFF5FC391);
  static const Color successSoft = Color(0x245FC391);
  static const Color warning = Color(0xFFF0B45A);
  static const Color warningSoft = Color(0x24F0B45A);
  static const Color warningBorder = Color(0x2EF0B45A);
  static const Color danger = Color(0xFFE2676D);
  static const Color dangerHover = Color(0xFFF87D84);
  static const Color dangerActive = Color(0xFFFFA3A8);
  static const Color dangerSoft = Color(0x24E2676D);

  static const Color discord = Color(0xFF5865F2);

  static const Color barrier = Color(0xDE000000);
}

class AppRadius {
  AppRadius._();

  /// Controls and most elements.
  static const double sm = 8.0;

  /// Cards and dialogs.
  static const double lg = 12.0;
}

const String appFontFamily = 'SUIT';
const List<String> appFontFamilyFallback = ['NotoSansSC'];

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.dark(
    primary: AppColors.button,
    onPrimary: Colors.white,
    primaryContainer: AppColors.accentSoft,
    onPrimaryContainer: AppColors.accent,
    secondary: AppColors.accent,
    onSecondary: AppColors.bg,
    tertiary: AppColors.success,
    error: AppColors.danger,
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerLowest: AppColors.bg,
    surfaceContainerLow: AppColors.bgElev,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surface2,
    surfaceContainerHighest: AppColors.surface3,
    outline: AppColors.borderStrong,
    outlineVariant: AppColors.border,
    shadow: Colors.black,
    scrim: AppColors.barrier,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    fontFamily: appFontFamily,
    fontFamilyFallback: appFontFamilyFallback,
  );

  final textTheme = base.textTheme.apply(
    bodyColor: AppColors.text,
    displayColor: AppColors.text,
  );

  final controlRadius = BorderRadius.circular(AppRadius.sm);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 18.0);
  const buttonTextStyle = TextStyle(
    fontFamily: appFontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
  );

  // Overlayer inputs: filled control, no border line; 2px accent outline on
  // focus (hover outline is added by HoverOutline in the widgets).
  final noBorder = OutlineInputBorder(
    borderRadius: controlRadius,
    borderSide: BorderSide.none,
  );
  OutlineInputBorder outline(Color color) => OutlineInputBorder(
    borderRadius: controlRadius,
    borderSide: BorderSide(color: color, width: 2.0),
  );

  final buttonOverlay = WidgetStateProperty.resolveWith<Color?>(
    (states) => Colors.transparent,
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.bg,
    textTheme: textTheme,
    hoverColor: AppColors.surfaceHover,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
    dividerColor: AppColors.border,
    iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 20.0),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1.0,
      space: 1.0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      barrierColor: AppColors.barrier,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: appFontFamily,
        color: AppColors.text,
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: appFontFamily,
        color: AppColors.textSecondary,
        fontSize: 14.0,
        height: 1.5,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.control,
      hoverColor: Colors.transparent,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14.0,
        vertical: 13.0,
      ),
      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14.0),
      prefixIconColor: AppColors.textSecondary,
      suffixIconColor: AppColors.textSecondary,
      border: noBorder,
      enabledBorder: noBorder,
      disabledBorder: noBorder,
      focusedBorder: outline(AppColors.accent),
      errorBorder: outline(AppColors.danger),
      focusedErrorBorder: outline(AppColors.danger),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.accent,
      selectionColor: AppColors.accent.withValues(alpha: 0.35),
      selectionHandleColor: AppColors.accent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.control;
          if (states.contains(WidgetState.pressed)) {
            return AppColors.buttonActive;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.buttonHover;
          }
          return AppColors.button;
        }),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? AppColors.textTertiary
              : Colors.white,
        ),
        overlayColor: buttonOverlay,
        elevation: const WidgetStatePropertyAll(0),
        minimumSize: const WidgetStatePropertyAll(Size(0, 40.0)),
        padding: const WidgetStatePropertyAll(buttonPadding),
        textStyle: const WidgetStatePropertyAll(buttonTextStyle),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: controlRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? AppColors.text
              : AppColors.textSecondary,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? AppColors.control
              : Colors.transparent,
        ),
        overlayColor: buttonOverlay,
        minimumSize: const WidgetStatePropertyAll(Size(0, 40.0)),
        padding: const WidgetStatePropertyAll(buttonPadding),
        textStyle: const WidgetStatePropertyAll(buttonTextStyle),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: controlRadius),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? AppColors.text
              : AppColors.textSecondary,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.hovered)
              ? AppColors.control
              : Colors.transparent,
        ),
        overlayColor: buttonOverlay,
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: controlRadius),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface2,
      contentTextStyle: const TextStyle(
        fontFamily: appFontFamily,
        color: AppColors.text,
        fontSize: 13.5,
      ),
      actionTextColor: AppColors.accent,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      width: 480.0,
      shape: RoundedRectangleBorder(
        borderRadius: controlRadius,
        side: const BorderSide(color: AppColors.borderStrong),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: WidgetStateProperty.all(6.0),
      radius: const Radius.circular(999.0),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.dragged) ||
            states.contains(WidgetState.hovered)) {
          return AppColors.muted;
        }
        return AppColors.control;
      }),
      crossAxisMargin: 2.0,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: const Color(0xFA1E1C28),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      textStyle: const TextStyle(
        fontFamily: appFontFamily,
        color: AppColors.text,
        fontSize: 13.0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      waitDuration: const Duration(milliseconds: 300),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
      linearTrackColor: AppColors.bgElev,
      circularTrackColor: Colors.transparent,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.control,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: controlRadius),
    ),
  );
}
