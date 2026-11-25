import 'package:flutter/material.dart';

import '../../theme/curio_tokens.dart';
import 'curio_clay.dart';

/// The small building blocks of Curio's Airbnb-style screens: a soft
/// blush page, white panels with a hairline, one sans face with weight
/// doing the work, round grey buttons, white pills on pictures, and cards
/// that scale a touch when pressed instead of splashing ink. Every value
/// comes from CurioTokens. Section titles are [SectionHeading] in
/// curio_ui.dart.

/// Type roles beyond the five tokens, all built from them.
abstract final class CurioType {
  /// A card's or a row's name.
  static final cardTitle = CurioTokens.body.copyWith(
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  /// The quiet line under a name.
  static const meta = CurioTokens.bodySmall;

  /// A short line that should read first in its group.
  static final strong = CurioTokens.bodySmall.copyWith(
    color: CurioTokens.textPrimary,
    fontWeight: FontWeight.w700,
  );

  /// Text inside a chip or pill.
  static final chip = CurioTokens.label.copyWith(
    color: CurioTokens.textPrimary,
    fontWeight: FontWeight.w700,
  );
}

/// Scales down a touch while pressed instead of splashing ink over a
/// picture, the way Airbnb's cards respond.
class CurioPressable extends StatefulWidget {
  const CurioPressable({
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  State<CurioPressable> createState() => _CurioPressableState();
}

class _CurioPressableState extends State<CurioPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.semanticLabel,
    onTap: widget.onTap,
    excludeSemantics: true,
    child: InkWell(
      onTap: widget.onTap,
      onHighlightChanged: (value) => setState(() => _pressed = value),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      borderRadius: CurioTokens.cardShape,
      child: AnimatedScale(
        scale: _pressed ? .97 : 1,
        duration: CurioTokens.motion(context),
        curve: CurioTokens.curve,
        child: widget.child,
      ),
    ),
  );
}

/// A round grey icon button, like the ones in Airbnb's top bar.
class CurioIconButton extends StatelessWidget {
  const CurioIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 44,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Semantics(
      button: true,
      label: tooltip,
      excludeSemantics: true,
      onTap: onPressed,
      child: Material(
        color: CurioTokens.surfaceRaised,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: size,
            child: Icon(icon, size: 20, color: CurioTokens.textPrimary),
          ),
        ),
      ),
    ),
  );
}

/// A small pill: white on a picture (Airbnb's "Guest favourite"), or
/// washed in [tint] on a page.
class CurioChip extends StatelessWidget {
  const CurioChip(
    this.label, {
    this.icon,
    this.iconColor,
    this.tint,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color? iconColor;

  /// When set, the pill is this colour washed over white instead of white.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final tint = this.tint;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tint == null ? CurioTokens.surface : CurioTokens.wash(tint, .14),
        borderRadius: CurioTokens.pillShape,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CurioTokens.s12,
          vertical: CurioTokens.s4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: iconColor ?? tint ?? CurioTokens.textPrimary,
              ),
              const SizedBox(width: CurioTokens.s4),
            ],
            Flexible(
              child: Text(
                label,
                style: CurioType.chip,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A soft coral pill for the reward a game is worth.
class XpChip extends StatelessWidget {
  const XpChip(this.xp, {super.key});

  final int xp;

  @override
  Widget build(BuildContext context) => CurioChip(
    '+$xp XP',
    icon: Icons.bolt_rounded,
    iconColor: CurioTokens.accent,
    tint: CurioTokens.accent,
  );
}

/// The white tick in a picture's corner once today's round is done.
class DoneBadge extends StatelessWidget {
  const DoneBadge({super.key});

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      color: CurioTokens.surface,
      shape: BoxShape.circle,
    ),
    child: SizedBox.square(
      dimension: 32,
      child: Icon(
        Icons.check_rounded,
        size: 18,
        color: CurioTokens.correct,
        semanticLabel: 'Done today',
      ),
    ),
  );
}

/// Cards two to a row on a phone and three on anything wider, each row as
/// tall as its tallest card, with Airbnb's generous gaps.
class CurioGrid extends StatelessWidget {
  const CurioGrid({required this.children, this.wideColumns = 3, super.key});

  final List<Widget> children;

  /// Columns once there is room (560 wide or more); phones get two.
  final int wideColumns;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 560 ? wideColumns : 2;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i += columns) ...[
            if (i > 0) const SizedBox(height: CurioTokens.s24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var j = 0; j < columns; j++) ...[
                  if (j > 0) const SizedBox(width: CurioTokens.s16),
                  Expanded(
                    child: i + j < children.length
                        ? children[i + j]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ],
        ],
      );
    },
  );
}

/// A settings row as Airbnb lists them: a line icon, a name with an
/// optional quiet line, and a chevron (or [trailing]).
class CurioListRow extends StatelessWidget {
  const CurioListRow({
    required this.title,
    this.onTap,
    this.icon,
    this.subtitle,
    this.trailing,
    this.color,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// The icon's and title's colour, for a destructive row.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? CurioTokens.textPrimary;
    final row = Padding(
      padding: const EdgeInsets.all(CurioTokens.s16),
      child: Row(
        children: [
          if (icon != null) ...[
            ExcludeSemantics(child: Icon(icon, size: 24, color: ink)),
            const SizedBox(width: CurioTokens.s24),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CurioTokens.body.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) Text(subtitle!, style: CurioType.meta),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: CurioTokens.s12),
            trailing!,
          ] else if (onTap != null) ...[
            const SizedBox(width: CurioTokens.s12),
            const ExcludeSemantics(
              child: Icon(
                Icons.chevron_right_rounded,
                color: CurioTokens.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

/// Rows grouped in one white card with a hairline between them, the way
/// Airbnb lists account settings.
class CurioListGroup extends StatelessWidget {
  const CurioListGroup({
    required this.children,
    this.indent = CurioTokens.s48 + CurioTokens.s16,
    super.key,
  });

  final List<Widget> children;

  /// Where each hairline starts: under the text, past the row's icon.
  final double indent;

  @override
  Widget build(BuildContext context) => CurioClay(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(height: 1, indent: indent),
          children[i],
        ],
      ],
    ),
  );
}

/// An icon in a white circle with a hairline: the back, close, help and
/// pause buttons in top bars, drawn the way Airbnb draws them. Put it in
/// an IconButton for the tap target.
class CurioRoundIcon extends StatelessWidget {
  const CurioRoundIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: CurioTokens.surface,
      shape: BoxShape.circle,
      border: Border.all(color: CurioTokens.border),
    ),
    child: SizedBox.square(
      dimension: 36,
      child: Icon(icon, size: 16, color: CurioTokens.textPrimary),
    ),
  );
}
