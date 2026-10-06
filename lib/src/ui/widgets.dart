import 'package:flutter/material.dart';
import 'package:overlayer_ui_flutter/overlayer_ui_flutter.dart';

import 'theme.dart';

/// Builds [builder] with the current hover state of the pointer.
class HoverBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, bool hovered) builder;
  final MouseCursor cursor;
  final VoidCallback? onTap;

  const HoverBuilder({
    super.key,
    required this.builder,
    this.cursor = SystemMouseCursors.click,
    this.onTap,
  });

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.builder(context, _hovered),
      ),
    );
  }
}

/// overlayer-ui's hover outline: a 2px accent ring faded in over ~100ms,
/// painted on top of [child] without affecting layout.
class HoverOutline extends StatelessWidget {
  final bool visible;
  final Widget child;
  final double radius;
  final Color color;

  const HoverOutline({
    super.key,
    required this.visible,
    required this.child,
    this.radius = AppRadius.sm,
    this.color = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: visible ? 1.0 : 0.0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 2.0),
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum OlButtonTone { primary, danger, neutral }

/// Wraps a text field so it shows overlayer's hover outline.
class HoverOutlineField extends StatelessWidget {
  final Widget child;
  const HoverOutlineField({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return HoverBuilder(
      cursor: SystemMouseCursors.text,
      builder: (context, hovered) =>
          HoverOutline(visible: hovered, child: child),
    );
  }
}

/// Primary/danger/neutral action rendered with overlayer-ui's [UIButton], sized for
/// denser layouts (UIButton is 50px tall by default).
class OlButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onClick;
  final OlButtonTone tone;
  final double height;
  final double fontSize;
  final bool expand;

  const OlButton({
    super.key,
    required this.label,
    required this.onClick,
    this.icon,
    this.tone = OlButtonTone.primary,
    this.height = 40.0,
    this.fontSize = 14.0,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget? child = icon == null
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: fontSize + 2.0, color: Colors.white),
              const SizedBox(width: 8.0),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: appFontFamily,
                    fontFamilyFallback: appFontFamilyFallback,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w400,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          );

    final button = SizedBox(
      height: height,
      child: UIButton(
        label: child == null ? label : null,
        fontSize: fontSize,
        blocked: onClick == null,
        color: switch (tone) {
          OlButtonTone.primary => null,
          OlButtonTone.danger => AppColors.danger,
          OlButtonTone.neutral => AppColors.control,
        },
        hoverColor: switch (tone) {
          OlButtonTone.primary => null,
          OlButtonTone.danger => AppColors.dangerHover,
          OlButtonTone.neutral => AppColors.controlHover,
        },
        pressedColor: switch (tone) {
          OlButtonTone.primary => null,
          OlButtonTone.danger => AppColors.dangerActive,
          OlButtonTone.neutral => AppColors.controlPressed,
        },
        onClick: onClick,
        child: child,
      ),
    );
    return expand ? button : IntrinsicWidth(child: button);
  }
}

enum AppButtonVariant { primary, secondary, ghost, danger, beta }

enum AppButtonSize { sm, md, lg }

/// Button following overlayer-ui's interaction language:
/// filled backgrounds, no border lines, hover = 2px accent outline for
/// neutral controls, colour steps for primary/danger.
class AppButton extends StatefulWidget {
  final String? label;
  final Widget? child;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool expand;

  const AppButton({
    super.key,
    this.label,
    this.child,
    this.icon,
    this.leading,
    required this.onPressed,
    this.variant = AppButtonVariant.secondary,
    this.size = AppButtonSize.md,
    this.expand = false,
  }) : assert(label != null || child != null);

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovered = false;
  bool _pressed = false;

  Color _background(bool enabled) {
    final bool hovered = _hovered && enabled;
    final bool pressed = _pressed && enabled;
    switch (widget.variant) {
      case AppButtonVariant.primary:
        if (pressed) return AppColors.buttonActive;
        if (hovered) return AppColors.buttonHover;
        return AppColors.button;
      case AppButtonVariant.danger:
        if (pressed) return AppColors.dangerActive;
        if (hovered) return AppColors.dangerHover;
        return AppColors.danger;
      case AppButtonVariant.secondary:
        return AppColors.control;
      case AppButtonVariant.ghost:
        return hovered ? AppColors.control : Colors.transparent;
      case AppButtonVariant.beta:
        return AppColors.warningSoft;
    }
  }

  Color _foreground(bool enabled) {
    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
      case AppButtonVariant.secondary:
        return AppColors.text;
      case AppButtonVariant.ghost:
        return _hovered && enabled ? AppColors.text : AppColors.textSecondary;
      case AppButtonVariant.beta:
        return AppColors.warning;
    }
  }

  bool get _usesOutline =>
      widget.variant == AppButtonVariant.secondary ||
      widget.variant == AppButtonVariant.beta;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final double height = switch (widget.size) {
      AppButtonSize.sm => 34.0,
      AppButtonSize.md => 40.0,
      AppButtonSize.lg => 50.0,
    };
    final double fontSize = switch (widget.size) {
      AppButtonSize.sm => 13.0,
      AppButtonSize.md => 14.0,
      AppButtonSize.lg => 16.0,
    };
    final double hPadding = switch (widget.size) {
      AppButtonSize.sm => 12.0,
      AppButtonSize.md => 18.0,
      AppButtonSize.lg => 24.0,
    };
    final Color foreground = _foreground(enabled);

    Widget content = widget.child ??
        Text(
          widget.label!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: foreground,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        );

    final leading = widget.leading ??
        (widget.icon != null
            ? Icon(widget.icon, size: fontSize + 2.0, color: foreground)
            : null);
    content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading, const SizedBox(width: 8.0)],
        Flexible(child: content),
      ],
    );

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1.0 : 0.4,
          child: HoverOutline(
            visible: _usesOutline && _hovered && enabled,
            child: AnimatedContainer(
              duration: _pressed
                  ? Duration.zero
                  : const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              height: height,
              width: widget.expand ? double.infinity : null,
              padding: EdgeInsets.symmetric(horizontal: hPadding),
              decoration: BoxDecoration(
                color: _background(enabled),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: foreground, fontSize: fontSize),
                child: IconTheme.merge(
                  data: IconThemeData(color: foreground, size: fontSize + 2.0),
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact switch using overlayer-ui's UIToggle indicator
/// (filled accent dot when on, hollow muted ring when off).
class OlSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? tooltip;

  const OlSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.tooltip,
  });

  @override
  State<OlSwitch> createState() => _OlSwitchState();
}

class _OlSwitchState extends State<OlSwitch>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _bounce;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_bounce);
  }

  @override
  void didUpdateWidget(covariant OlSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _bounce.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onChanged != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: enabled ? () => widget.onChanged!(!widget.value) : null,
        child: Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: HoverOutline(
            visible: _hovered && enabled,
            child: Container(
              width: 40.0,
              height: 40.0,
              alignment: Alignment.center,
              child: ScaleTransition(
                scale: _scale,
                child: SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: widget.value
                        ? Container(
                            key: const ValueKey('active'),
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          )
                        : Container(
                            key: const ValueKey('inactive'),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.muted,
                                width: 3.2,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grouped section card (web `.card`).
class AppCard extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget? action;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppCard({
    super.key,
    this.title,
    this.description,
    this.action,
    required this.child,
    this.padding = const EdgeInsets.all(20.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 4.0),
                        Text(
                          description!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.0,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: 12.0),
                  action!,
                ],
              ],
            ),
            const SizedBox(height: 16.0),
          ],
          child,
        ],
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 24.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4.0),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14.0,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 16.0), trailing!],
      ],
    );
  }
}

enum BadgeTone { game, category, accent, success, warning, danger }

/// Small sentence-case badge (web `.badge`).
class AppBadge extends StatelessWidget {
  final String label;
  final BadgeTone tone;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    this.tone = BadgeTone.category,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (tone) {
      BadgeTone.game => (AppColors.control, AppColors.text),
      BadgeTone.category => (AppColors.accentSoft, AppColors.accent),
      BadgeTone.accent => (AppColors.accentSoft, AppColors.accent),
      BadgeTone.success => (AppColors.successSoft, AppColors.success),
      BadgeTone.warning => (AppColors.warningSoft, AppColors.warning),
      BadgeTone.danger => (AppColors.dangerSoft, AppColors.danger),
    };

    return Container(
      height: 22.0,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.0, color: fg),
            const SizedBox(width: 4.0),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Round check mark shown next to verified developers.
class VerifiedDot extends StatelessWidget {
  final double size;
  const VerifiedDot({super.key, this.size = 15.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.successSoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(Icons.check_rounded, size: size * 0.7, color: AppColors.success),
    );
  }
}

enum BannerTone { info, warning, danger }

/// Inline notice box with a soft tinted background.
class StatusBanner extends StatelessWidget {
  final String message;
  final BannerTone tone;
  final IconData? icon;
  final TextAlign textAlign;

  const StatusBanner({
    super.key,
    required this.message,
    this.tone = BannerTone.info,
    this.icon,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (tone) {
      BannerTone.info => (AppColors.accentSoft, AppColors.accent),
      BannerTone.warning => (AppColors.warningSoft, AppColors.warning),
      BannerTone.danger => (AppColors.dangerSoft, AppColors.danger),
    };
    final resolvedIcon = icon ??
        switch (tone) {
          BannerTone.info => Icons.info_outline_rounded,
          BannerTone.warning => Icons.warning_amber_rounded,
          BannerTone.danger => Icons.error_outline_rounded,
        };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1.0),
            child: Icon(resolvedIcon, size: 18.0, color: fg),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              message,
              textAlign: textAlign,
              style: TextStyle(
                color: fg == AppColors.accent ? AppColors.text : fg,
                fontSize: 13.0,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hue-based gradient used for logo tiles when a mod has no logo
/// (same hashing as the website's getFallbackGradientStyle).
LinearGradient fallbackLogoGradient(String name) {
  int hash = 0;
  for (int i = 0; i < name.length; i++) {
    hash = name.codeUnitAt(i) + ((hash << 5) - hash);
  }
  final double h1 = (hash.abs() % 360).toDouble();
  final double h2 = ((h1 + 40) % 360).toDouble();
  return LinearGradient(
    colors: [
      HSLColor.fromAHSL(1.0, h1, 0.7, 0.5).toColor(),
      HSLColor.fromAHSL(1.0, h2, 0.7, 0.4).toColor(),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
