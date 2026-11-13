import 'curio_clay.dart';
import '../theme/curio_colors_light.dart';
import '../theme/curio_colors.dart';
import 'package:curio/theme/curio_tokens.dart';
import 'curio_logo.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class CurioSpace {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class CurioRadius {
  static const small = 10.0;
  static const medium = 14.0;
  static const large = 20.0;
  static const hero = 26.0;
}

class CurioPage extends StatelessWidget {
  const CurioPage({
    required this.child,
    this.title,
    this.actions,
    this.backgroundColor,
    this.maxWidth = 720,
    this.extendBehindBottom = false,
    super.key,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final double maxWidth;
  final bool extendBehindBottom;

  @override
  Widget build(BuildContext context) {
    final pageColor = backgroundColor ?? CurioTokens.base;
    return Scaffold(
      backgroundColor: pageColor,
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!),
              actions: actions,
              backgroundColor: pageColor,
            ),
      body: Stack(
        children: [
          if (backgroundColor == null)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: CurioColorsLight.pageGradient,
                ),
              ),
            ),
          SafeArea(
            top: title == null,
            bottom: !extendBehindBottom,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: CurioTokens.textPrimary),
                  child: IconTheme.merge(
                    data: IconThemeData(color: CurioTokens.textSecondary),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Curio's standard card: a [CurioClay] body, optionally tinted, with an
/// ink ripple when tappable. (Named from Curio's earlier glass look.)
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = CurioTokens.radiusCard,
    this.tint,
    this.opacity,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? tint;
  final double? opacity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CurioClay(
      radius: radius,
      color: tint,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CurioTokens.radiusCard),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class CurioCard extends StatelessWidget {
  const CurioCard({
    required this.child,
    this.color,
    this.borderColor,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = CurioTokens.radiusCard,
    this.elevation = false,
    super.key,
  });

  final Widget child;
  final Color? color;
  final Color? borderColor;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double radius;
  final bool elevation;

  @override
  Widget build(BuildContext context) {
    final surface = CurioTokens.surface;
    final forest = CurioTokens.accent;
    return CurioClay(
      radius: radius,
      color: color == surface ? null : color,
      // A faint border is how glass kept a tinted card off the page; clay's
      // shadows already do that, so only a strong one (selected, solved)
      // still draws.
      outline: borderColor != null && borderColor!.a > .5 ? borderColor : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: forest.withValues(alpha: .08),
          highlightColor: forest.withValues(alpha: .035),
          borderRadius: BorderRadius.circular(CurioTokens.radiusCard),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {this.trailing, this.subtitle, super.key});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final inkMuted = CurioTokens.textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: inkMuted),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class CurioBrand extends StatelessWidget {
  const CurioBrand({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) => CurioLogo(markSize: compact ? 29 : 34);
}

class CurioIconTile extends StatelessWidget {
  const CurioIconTile({
    required this.icon,
    required this.color,
    this.background,
    this.size = 44,
    this.iconSize = 22,
    this.radius = 15,
    super.key,
  });

  final IconData icon;
  final Color color;
  final Color? background;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CurioClay(
        radius: radius,
        color: background ?? color.withValues(alpha: .11),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }
}

class GameMetaChip extends StatelessWidget {
  const GameMetaChip({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final inkMuted = CurioTokens.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: inkMuted),
        const SizedBox(width: 4),
        // Wraps rather than overflowing a narrow row at large text sizes.
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: inkMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label),
        style: color == null
            ? null
            : FilledButton.styleFrom(backgroundColor: color),
      ),
    );
  }
}

class CurioProgressBar extends StatelessWidget {
  const CurioProgressBar({
    required this.value,
    this.color,
    this.height = 8,
    super.key,
  });

  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? CurioTokens.accent;
    // Painted rather than laid out with a LayoutBuilder, so the bar can sit
    // inside IntrinsicHeight rows (equal-height card grids).
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 1).toDouble()),
      duration: CurioTokens.slow,
      curve: CurioTokens.curve,
      // A groove pressed into the card, a little deeper than [height] asks
      // so the clay reads, filled with a puffy strip.
      builder: (context, animated, _) => SizedBox(
        height: height + 4,
        width: double.infinity,
        child: CustomPaint(
          painter: _BarPainter(
            animated,
            resolved,
            clayBase(context),
            Theme.of(context).brightness == Brightness.dark,
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter(this.value, this.color, this.base, this.dark);
  final double value;
  final Color color, base;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height);
    final track = RRect.fromRectAndRadius(Offset.zero & size, radius);
    // Never thinner than a dot, so an empty bar still shows where it starts.
    final filled = math.max(size.height, size.width * value);
    final bar = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, filled, size.height),
      radius,
    );
    paintClay(
      canvas,
      track,
      Color.alphaBlend(color.withValues(alpha: .12), base),
      dark: dark,
      pressed: true,
    );
    paintClay(canvas, bar, color, dark: dark);
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.value != value ||
      old.color != color ||
      old.base != base ||
      old.dark != dark;
}

class CurioStatusStrip extends StatelessWidget {
  const CurioStatusStrip({
    required this.icon,
    required this.title,
    required this.body,
    this.color,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? CurioTokens.accent;
    final inkMuted = CurioTokens.textSecondary;
    return CurioClay(
      radius: CurioTokens.radiusCard,
      color: resolved.withValues(alpha: .1),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurioIconTile(
            icon: icon,
            color: resolved,
            size: 38,
            iconSize: 20,
            radius: CurioTokens.radiusCard,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(color: inkMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The explorer's round letter avatar: evergreen in dark mode, coral in
/// light. Home's header (where it opens Profile) and Profile's own header.
class ExplorerAvatar extends StatelessWidget {
  const ExplorerAvatar({
    required this.name,
    this.size = 52,
    this.onTap,
    super.key,
  });

  final String name;
  final double size;

  /// When set, the avatar is a "Your profile" button.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final trimmed = name.trim();
    final letter = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    final initial = Text(
      letter,
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        fontFamily: 'Fraunces',
        color: Colors.white,
        fontSize: size * .4,
        fontWeight: FontWeight.w600,
      ),
    );
    final avatar = SizedBox(
      width: size,
      height: size,
      child: CurioClay(
        radius: size / 2,
        color: dark
            ? Color.lerp(CurioTokens.accent, CurioTokens.accent, .5)
            : CurioTokens.wrong,
        child: Center(child: initial),
      ),
    );
    if (onTap == null) return ExcludeSemantics(child: avatar);
    return Semantics(
      button: true,
      label: 'Your profile',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(onTap: onTap, child: avatar),
    );
  }
}

/// A plain list row: a title, at most one supporting line, an optional
/// 3px section tint on the left edge, and a 1px rule underneath. Rows are
/// how Curio shows everything that is not the screen's one primary block.
class CurioRow extends StatelessWidget {
  const CurioRow({
    required this.title,
    this.subtitle,
    this.tint,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Color? tint;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CurioTokens.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (tint != null) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: CurioTokens.pillShape,
                  ),
                  child: const SizedBox(width: 3),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: CurioTokens.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: CurioTokens.bodySmall),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                Center(child: trailing),
              ] else if (onTap != null) ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: CurioTokens.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

/// Resolves a colour to its dark/light counterpart based on the current
/// `Theme.of(context).brightness`. Used throughout this file so every
/// shared widget adapts to both modes automatically, callers that just
/// use the defaults never need to think about which mode is active.
/// [CurioColors] and [CurioColorsLight] share field names by design
/// specifically so this is always a direct 1:1 swap.
Color curioColor(BuildContext context, Color darkColor, Color lightColor) {
  return Theme.of(context).brightness == Brightness.dark
      ? darkColor
      : lightColor;
}

class CurioEyebrow extends StatelessWidget {
  const CurioEyebrow(this.label, {this.color, super.key});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ??
        curioColor(context, CurioColors.forest, CurioColorsLight.forest);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 2,
          decoration: BoxDecoration(
            color: resolved,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: resolved,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class MascotBadge extends StatelessWidget {
  const MascotBadge({this.size = 72, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final forestSoft = dark
        ? CurioColors.forestSoft
        : CurioColorsLight.forestSoft;
    final surface = dark ? CurioColors.surface : CurioColorsLight.surface;
    final forest = dark ? CurioColors.forest : CurioColorsLight.forest;
    final saffron = dark ? CurioColors.saffron : CurioColorsLight.saffron;
    final ink = dark ? CurioColors.ink : CurioColorsLight.ink;
    return Semantics(
      label: 'Nova, your Curio companion',
      child: SizedBox.square(
        dimension: size,
        // The sparkle pokes past the badge's rounded corner, so the clay
        // body sits behind the face instead of clipping it.
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CurioClay(
                radius: size * .36,
                color: forestSoft,
                child: const SizedBox.expand(),
              ),
            ),
            Transform.rotate(
              angle: -.08,
              child: SizedBox(
                width: size * .7,
                height: size * .62,
                child: CurioClay(
                  radius: size * .28,
                  color: forest,
                  child: Center(
                    child: Container(
                      width: size * .48,
                      height: size * .28,
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(size * .14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _MascotEye(size: size * .065, color: ink),
                          SizedBox(width: size * .13),
                          _MascotEye(size: size * .065, color: ink),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: size * .015,
              top: size * .01,
              child: Transform.rotate(
                angle: .18,
                child: Icon(
                  Icons.auto_awesome,
                  color: saffron,
                  size: size * .27,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MascotEye extends StatelessWidget {
  const _MascotEye({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.value,
    required this.child,
    this.color,
    this.size = 54,
    super.key,
  });

  final double value;
  final Widget child;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: value.clamp(0, 1),
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              color: resolved,
              backgroundColor: resolved.withValues(alpha: .12),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
