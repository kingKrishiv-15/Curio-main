import 'curio_clay.dart';
import 'curio_logo.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/curio_colors.dart';
import '../theme/curio_colors_light.dart';

/// Resolves a colour to its dark/light counterpart based on the current
/// `Theme.of(context).brightness`. Used throughout this file so every
/// shared widget adapts to both modes automatically — callers that just
/// use the defaults never need to think about which mode is active.
/// [CurioColors] and [CurioColorsLight] share field names by design
/// specifically so this is always a direct 1:1 swap.
Color curioColor(BuildContext context, Color darkColor, Color lightColor) {
  return Theme.of(context).brightness == Brightness.dark
      ? darkColor
      : lightColor;
}

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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pageColor =
        backgroundColor ??
        curioColor(context, CurioColors.canvas, CurioColorsLight.canvas);
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
          if (backgroundColor == null) ...[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: dark
                      ? CurioColors.pageGradient
                      : CurioColorsLight.pageGradient,
                ),
              ),
            ),
            Positioned.fill(child: _CurioBackdrop(dark: dark)),
          ],
          SafeArea(
            top: title == null,
            bottom: !extendBehindBottom,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: curioColor(
                      context,
                      CurioColors.ink,
                      CurioColorsLight.ink,
                    ),
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      color: curioColor(
                        context,
                        CurioColors.inkSoft,
                        CurioColorsLight.inkSoft,
                      ),
                    ),
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

class _CurioBackdrop extends StatelessWidget {
  const _CurioBackdrop({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CurioBackdropPainter(dark: dark),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CurioBackdropPainter extends CustomPainter {
  const _CurioBackdropPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final warmColor = dark ? CurioColors.saffron : CurioColorsLight.saffron;
    final coolColor = dark ? CurioColors.blue : CurioColorsLight.blue;
    final warm = Paint()..color = warmColor.withValues(alpha: dark ? .05 : .07);
    final cool = Paint()
      ..color = coolColor.withValues(alpha: dark ? .045 : .06);
    canvas.drawCircle(
      Offset(size.width * .86, size.height * .05),
      size.width * .5,
      warm,
    );
    canvas.drawCircle(
      Offset(size.width * .04, size.height * .82),
      size.width * .46,
      cool,
    );

    final grainColor = dark ? Colors.white : const Color(0xFF2E2417);
    final grain = Paint()
      ..color = grainColor.withValues(alpha: dark ? .022 : .014);
    for (var y = 20.0; y < size.height; y += 30) {
      for (var x = 10.0; x < size.width; x += 30) {
        if ((x + y).round().isEven) continue;
        canvas.drawCircle(Offset(x, y), .9, grain);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CurioBackdropPainter oldDelegate) =>
      oldDelegate.dark != dark;
}

/// Curio's standard card: a [CurioClay] body, optionally tinted, with an
/// ink ripple when tappable. (Named from Curio's earlier glass look.)
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = CurioRadius.large,
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
          borderRadius: BorderRadius.circular(radius),
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
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.radius = CurioRadius.large,
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
    final surface = curioColor(
      context,
      CurioColors.surface,
      CurioColorsLight.surface,
    );
    final forest = curioColor(
      context,
      CurioColors.forest,
      CurioColorsLight.forest,
    );
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
          borderRadius: BorderRadius.circular(radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
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

class PageIntro extends StatelessWidget {
  const PageIntro({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
    super.key,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final inkMuted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CurioEyebrow(eyebrow),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 7),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: inkMuted),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 16), trailing!],
      ],
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
    final inkMuted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
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
    final inkMuted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: inkMuted),
        const SizedBox(width: 5),
        // Wraps rather than overflowing a narrow row at large text sizes.
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: inkMuted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class ModeTile extends StatelessWidget {
  const ModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
    this.duration,
    this.skill,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  final String? duration;
  final String? skill;

  @override
  Widget build(BuildContext context) {
    final inkMuted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    return CurioCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      elevation: true,
      radius: CurioRadius.large,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: CurioIconTile(icon: icon, color: color),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                color: color,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: .55,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: inkMuted,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                    if (duration != null || skill != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 5,
                        children: [
                          if (duration != null)
                            GameMetaChip(
                              icon: Icons.schedule_rounded,
                              label: duration!,
                            ),
                          if (skill != null)
                            GameMetaChip(
                              icon: Icons.psychology_alt_rounded,
                              label: skill!,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.arrow_forward_rounded, size: 19, color: color),
            ),
          ],
        ),
      ),
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
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Text(label),
        ),
        style: color == null
            ? null
            : FilledButton.styleFrom(backgroundColor: color),
      ),
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
    final resolved =
        color ??
        curioColor(context, CurioColors.forest, CurioColorsLight.forest);
    // Painted rather than laid out with a LayoutBuilder, so the bar can sit
    // inside IntrinsicHeight rows (equal-height card grids).
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 1).toDouble()),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
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
    final resolved =
        color ??
        curioColor(context, CurioColors.forest, CurioColorsLight.forest);
    final inkMuted = curioColor(
      context,
      CurioColors.inkMuted,
      CurioColorsLight.inkMuted,
    );
    return CurioClay(
      radius: 18,
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
            radius: 11,
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
                const SizedBox(height: 3),
                Text(body, style: TextStyle(color: inkMuted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The colour families a [CurioStatTile] comes in.
enum StatTone { gold, plum, forest, coral }

/// A pastel stat tile: a big number over a short label. Home's weekly
/// growth and Profile's totals share it, so numbers look the same app-wide.
class CurioStatTile extends StatelessWidget {
  const CurioStatTile({
    required this.value,
    required this.label,
    required this.tone,
    this.semanticLabel,
    super.key,
  });

  final String value, label;
  final StatTone tone;

  /// Read instead of "value label" when that alone would be unclear.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final (color, fill, valueColor) = switch (tone) {
      StatTone.gold => (
        curioColor(context, CurioColors.saffron, CurioColorsLight.saffron),
        CurioColorsLight.saffronSoft,
        curioColor(
          context,
          CurioColors.saffron,
          CurioColorsLight.saffronStrong,
        ),
      ),
      StatTone.plum => (
        curioColor(context, CurioColors.plum, CurioColorsLight.plum),
        CurioColorsLight.plumSoft,
        curioColor(context, CurioColors.plum, const Color(0xFF6448C4)),
      ),
      StatTone.forest => (
        curioColor(context, CurioColors.forest, CurioColorsLight.forest),
        CurioColorsLight.forestSoft,
        curioColor(context, CurioColors.forest, CurioColorsLight.forestStrong),
      ),
      StatTone.coral => (
        curioColor(context, CurioColors.coral, CurioColorsLight.coral),
        CurioColorsLight.coralSoft,
        curioColor(context, CurioColors.coral, CurioColorsLight.coralStrong),
      ),
    };
    return Semantics(
      label: semanticLabel ?? '$value $label',
      excludeSemantics: true,
      child: CurioClay(
        radius: 24,
        // Dark mode tints the clay slate rather than the page, so gold stays
        // gold instead of turning olive on green.
        color: curioColor(context, color.withValues(alpha: .16), fill),
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  color: valueColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: curioColor(
                  context,
                  CurioColors.inkSoft,
                  CurioColorsLight.inkSoft,
                ),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [CurioStatTile]s side by side, equal heights; at large text sizes one
/// full-width row each, so labels never break mid-word in a narrow tile.
class CurioStatRow extends StatelessWidget {
  const CurioStatRow({required this.tiles, super.key});
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(10) > 13) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            tiles[i],
          ],
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: tiles[i]),
          ],
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
            ? Color.lerp(CurioColors.forestStrong, CurioColors.forest, .5)
            : CurioColorsLight.coral,
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
