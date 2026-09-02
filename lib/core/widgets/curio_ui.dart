import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/curio_colors.dart';

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
    super.key,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final pageColor = backgroundColor ?? CurioColors.canvas;
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
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: CurioColors.pageGradient),
              ),
            ),
            const Positioned.fill(child: _CurioBackdrop()),
          ],
          SafeArea(
            top: title == null,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: CurioColors.ink),
                  child: IconTheme.merge(
                    data: const IconThemeData(color: CurioColors.inkSoft),
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
  const _CurioBackdrop();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(painter: _CurioBackdropPainter(), child: SizedBox.expand()),
    );
  }
}

class _CurioBackdropPainter extends CustomPainter {
  const _CurioBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final warm = Paint()..color = CurioColors.saffron.withValues(alpha: .05);
    final cool = Paint()..color = CurioColors.blue.withValues(alpha: .045);
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

    final grain = Paint()..color = Colors.white.withValues(alpha: .022);
    for (var y = 20.0; y < size.height; y += 30) {
      for (var x = 10.0; x < size.width; x += 30) {
        if ((x + y).round().isEven) continue;
        canvas.drawCircle(Offset(x, y), .9, grain);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Curio's standard "glass" card: a translucent tinted fill, a crisp bright
/// border, a top sheen, and a lift shadow. Deliberately does **not** use a
/// real `BackdropFilter` blur — stacking many independent blurs (one per
/// card in a scrolling list, say) is what caused blur to render in the
/// wrong place on real devices during the home-screen redesign. Reserve an
/// actual blur for a single, well-contained floating element (like the
/// bottom nav) rather than every card that wants a "glass" look.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = CurioRadius.large,
    this.tint = CurioColors.surface,
    this.opacity = .58,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color tint;
  final double opacity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final fill = Color.lerp(tint, Colors.white, .1)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x66020504),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Material(
          color: fill.withValues(alpha: opacity),
          child: InkWell(
            onTap: onTap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(color: Colors.white.withValues(alpha: .2)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: borderRadius,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: .14),
                              Colors.white.withValues(alpha: 0),
                            ],
                            stops: const [0, .6],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(padding: padding, child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CurioCard extends StatelessWidget {
  const CurioCard({
    required this.child,
    this.color = CurioColors.surface,
    this.borderColor = CurioColors.outlineSoft,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.radius = CurioRadius.large,
    this.elevation = false,
    super.key,
  });

  final Widget child;
  final Color color;
  final Color borderColor;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double radius;
  final bool elevation;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor),
        boxShadow: elevation
            ? const [
                BoxShadow(
                  color: Color(0x10291C12),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: CurioColors.forest.withValues(alpha: .08),
          highlightColor: CurioColors.forest.withValues(alpha: .035),
          borderRadius: borderRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class CurioEyebrow extends StatelessWidget {
  const CurioEyebrow(this.label, {this.color = CurioColors.forest, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 2,
          decoration: BoxDecoration(
            color: color,
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
              color: color,
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
                  ).textTheme.bodyMedium?.copyWith(color: CurioColors.inkMuted),
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
                  ).textTheme.bodySmall?.copyWith(color: CurioColors.inkMuted),
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
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Curio',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CurioLogoMark(size: compact ? 29 : 34),
          const SizedBox(width: 10),
          Text(
            'curio',
            style: TextStyle(
              fontFamily: 'Fraunces',
              color: CurioColors.ink,
              fontSize: compact ? 24 : 29,
              fontWeight: FontWeight.w500,
              letterSpacing: -1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurioLogoMark extends StatelessWidget {
  const _CurioLogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: CurioColors.brandGradient,
        borderRadius: BorderRadius.circular(size * .34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x29183E35),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: CurioColors.onDark,
            size: size * .48,
          ),
          Positioned(
            right: size * .17,
            top: size * .16,
            child: Container(
              width: size * .13,
              height: size * .13,
              decoration: const BoxDecoration(
                color: CurioColors.saffron,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MascotBadge extends StatelessWidget {
  const MascotBadge({this.size = 72, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Nova, your Curio companion',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: CurioColors.forestSoft,
          borderRadius: BorderRadius.circular(size * .36),
          border: Border.all(color: CurioColors.surface, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x18291C12),
              blurRadius: 15,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: -.08,
              child: Container(
                width: size * .7,
                height: size * .62,
                decoration: BoxDecoration(
                  color: CurioColors.forest,
                  borderRadius: BorderRadius.circular(size * .28),
                ),
                child: Center(
                  child: Container(
                    width: size * .48,
                    height: size * .28,
                    decoration: BoxDecoration(
                      color: CurioColors.surface,
                      borderRadius: BorderRadius.circular(size * .14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MascotEye(size: size * .065),
                        SizedBox(width: size * .13),
                        _MascotEye(size: size * .065),
                      ],
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
                  color: CurioColors.saffron,
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
  const _MascotEye({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: CurioColors.ink,
        shape: BoxShape.circle,
      ),
    );
  }
}

class StatPill extends StatelessWidget {
  const StatPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.background,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(CurioRadius.medium),
          border: Border.all(color: color.withValues(alpha: .16)),
        ),
        child: Row(
          children: [
            CurioIconTile(
              icon: icon,
              color: color,
              background: color.withValues(alpha: .1),
              size: 30,
              iconSize: 17,
              radius: 10,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CurioColors.inkMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class GameMetaChip extends StatelessWidget {
  const GameMetaChip({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: CurioColors.inkMuted),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: CurioColors.inkMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
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
    return CurioCard(
      onTap: onTap,
      color: CurioColors.surface,
      borderColor: CurioColors.outlineSoft,
      padding: EdgeInsets.zero,
      elevation: true,
      radius: CurioRadius.large,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 5, color: color),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 9, 12),
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
                              color: color.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(6),
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
                      style: const TextStyle(
                        color: CurioColors.inkMuted,
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
    this.color = CurioColors.coral,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

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
        style: FilledButton.styleFrom(backgroundColor: color),
      ),
    );
  }
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.value,
    required this.child,
    this.color = CurioColors.coral,
    this.size = 54,
    super.key,
  });

  final double value;
  final Widget child;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
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
              color: color,
              backgroundColor: color.withValues(alpha: .12),
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
    this.color = CurioColors.forest,
    this.height = 8,
    super.key,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(height),
          ),
          alignment: Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            width: math.max(height, constraints.maxWidth * value.clamp(0, 1)),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        );
      },
    );
  }
}

class CurioStatusStrip extends StatelessWidget {
  const CurioStatusStrip({
    required this.icon,
    required this.title,
    required this.body,
    this.color = CurioColors.forest,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .075),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: .16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CurioIconTile(
            icon: icon,
            color: color,
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
                Text(
                  body,
                  style: const TextStyle(
                    color: CurioColors.inkMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
