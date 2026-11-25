import 'package:flutter/material.dart';

import '../../../core/widgets/curio_clay.dart';
import '../../../core/widgets/curio_kit.dart';
import '../../../theme/curio_tokens.dart';
import '../../games/common/daily_schedule.dart';
import '../../games/game_catalog.dart';
import '../../games/presentation/game_emblem.dart';

/// Home's own pieces. The shared ones (chips, round buttons, the grid,
/// game cards) live in core/widgets/curio_kit.dart and
/// games/presentation/game_cards.dart.

/// Today at a glance, shaped like Airbnb's search bar: the date and how
/// many games are done (the streak lives in the calendar below), with a round coral button that opens
/// the next unfinished game. This is Home's one raised element.
class TodayPill extends StatelessWidget {
  const TodayPill({
    required this.dateLabel,
    required this.done,
    required this.total,
    required this.next,
    required this.onPlay,
    super.key,
  });

  final int done, total;
  final String dateLabel;

  /// The next unfinished game today, or null once they are all done.
  final GameEntry? next;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final next = this.next;
    return CurioClay(
      radius: CurioTokens.radiusPill,
      raised: true,
      padding: const EdgeInsets.all(CurioTokens.s8),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: CurioTokens.wash(CurioTokens.accent, .14),
              shape: BoxShape.circle,
            ),
            child: const SizedBox.square(
              dimension: 44,
              child: Icon(
                Icons.today_rounded,
                color: CurioTokens.accent,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: CurioTokens.s12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: CurioType.strong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  next == null
                      ? 'All $total games done, well played'
                      : '$done of $total games done',
                  style: CurioTokens.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: CurioTokens.s8),
          if (next == null)
            Semantics(
              label: 'All of today’s games are done',
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: CurioTokens.wash(CurioTokens.correct, .14),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox.square(
                  dimension: 48,
                  child: Icon(Icons.check_rounded, color: CurioTokens.correct),
                ),
              ),
            )
          else
            Tooltip(
              message: 'Play ${next.title}',
              child: Semantics(
                button: true,
                label: 'Play ${next.title}',
                excludeSemantics: true,
                onTap: onPlay,
                child: Material(
                  key: const Key('home_play_next'),
                  color: CurioTokens.accent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onPlay,
                    child: const SizedBox.square(
                      dimension: 48,
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: CurioTokens.onAccent,
                        size: 28,
                      ),
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

/// Airbnb's category bar: a row of small 3D icons with a label each, the
/// chosen one underlined. Scrolls sideways when the labels don't all fit.
class CategoryStrip extends StatelessWidget {
  const CategoryStrip({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// The chosen section, or null for "All".
  final LearningSection? selected;
  final ValueChanged<LearningSection?> onSelected;

  static const _emblem = 36.0;
  static const _underline = 2.0;

  /// The strip's height at [scaler], plus its hairline, for a pinned
  /// header that needs to know its size up front.
  static double extentFor(TextScaler scaler) =>
      CurioTokens.s12 +
      _emblem +
      CurioTokens.s4 +
      scaler.scale(CurioTokens.label.fontSize!) * CurioTokens.label.height! +
      CurioTokens.s8 +
      _underline +
      1 +
      CurioTokens.s4;

  @override
  Widget build(BuildContext context) {
    final options = <LearningSection?>[null, ...LearningSection.values];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Never negative: the very first frame can lay out at zero width.
        final share =
            ((constraints.maxWidth - CurioTokens.s16 * 2) / options.length)
                .clamp(0.0, double.infinity);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: CurioTokens.s16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final option in options)
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: share),
                  child: _CategoryTab(
                    key: Key('home_category_${option?.name ?? 'all'}'),
                    section: option,
                    selected: option == selected,
                    onTap: () => onSelected(option),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.section,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final LearningSection? section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final section = this.section;
    final label = section?.title ?? 'All';
    final motion = CurioTokens.motion(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: CurioTokens.cardShape,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CurioTokens.s8,
            CurioTokens.s12,
            CurioTokens.s8,
            0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedOpacity(
                opacity: selected ? 1 : .8,
                duration: motion,
                curve: CurioTokens.curve,
                child: GameEmblem(
                  icon: section == null
                      ? Icons.apps_rounded
                      : sectionIcon(section),
                  color: section == null
                      ? CurioTokens.textSecondary
                      : sectionColor(context, section),
                  size: CategoryStrip._emblem,
                ),
              ),
              const SizedBox(height: CurioTokens.s4),
              IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: CurioTokens.label.copyWith(
                        color: selected
                            ? CurioTokens.textPrimary
                            : CurioTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: CurioTokens.s8),
                    AnimatedContainer(
                      duration: motion,
                      curve: CurioTokens.curve,
                      height: CategoryStrip._underline,
                      color: selected
                          ? CurioTokens.textPrimary
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
