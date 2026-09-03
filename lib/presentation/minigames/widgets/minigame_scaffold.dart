import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_typography.dart';
import '../../../domain/minigames/entities/minigame_streak.dart';
import '../../../domain/minigames/entities/minigame_type.dart';
import '../../widgets/pressable_scale.dart';

/// The shell every minigame renders inside, so all five read as one suite
/// the way the NYT games do: same header shape, same how-to-play affordance,
/// same archive entry point, same result sheet. A game supplies its board and
/// its rules copy; everything around it comes from here.
class MinigameScaffold extends StatelessWidget {
  const MinigameScaffold({
    super.key,
    required this.type,
    required this.puzzleDate,
    required this.accentColor,
    required this.howToPlay,
    required this.child,
    this.streak,
    this.onOpenArchive,
    this.onBack,
  });

  final MinigameType type;
  final DateTime puzzleDate;
  final Color accentColor;

  /// One line per rule. Kept to a handful of short lines on purpose - if a
  /// game needs more than that to explain, the game is wrong, not the sheet.
  final List<String> howToPlay;

  final Widget child;
  final MinigameStreak? streak;
  final VoidCallback? onOpenArchive;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CurioColors.platformBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              type: type,
              puzzleDate: puzzleDate,
              accentColor: accentColor,
              streak: streak,
              onOpenArchive: onOpenArchive,
              onBack: onBack,
              onHowToPlay: () => showMinigameHowToPlay(
                context,
                type: type,
                accentColor: accentColor,
                lines: howToPlay,
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.type,
    required this.puzzleDate,
    required this.accentColor,
    required this.streak,
    required this.onOpenArchive,
    required this.onBack,
    required this.onHowToPlay,
  });

  final MinigameType type;
  final DateTime puzzleDate;
  final Color accentColor;
  final MinigameStreak? streak;
  final VoidCallback? onOpenArchive;
  final VoidCallback? onBack;
  final VoidCallback onHowToPlay;

  @override
  Widget build(BuildContext context) {
    final currentStreak = streak?.currentCount ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          if (onBack != null)
            _HeaderIconButton(icon: Icons.arrow_back_rounded, onTap: onBack!, semanticLabel: 'Back'),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(type.displayName, style: CurioTypography.platform.headlineSmall),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatDate(puzzleDate),
                      style: CurioTypography.platform.bodySmall?.copyWith(color: CurioColors.inkMuted),
                    ),
                    if (currentStreak > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '🔥 $currentStreak',
                          style: CurioTypography.platform.labelMedium?.copyWith(color: CurioColors.ink),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (onOpenArchive != null)
            _HeaderIconButton(
              icon: Icons.calendar_month_rounded,
              onTap: onOpenArchive!,
              semanticLabel: 'Past puzzles',
            ),
          _HeaderIconButton(
            icon: Icons.help_outline_rounded,
            onTap: onHowToPlay,
            semanticLabel: 'How to play',
          ),
        ],
      ),
    );
  }

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String _formatDate(DateTime date) => '${_months[date.month - 1]} ${date.day}';
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap, required this.semanticLabel});

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: PressableScale(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: Icon(icon, size: 22, color: CurioColors.ink),
        ),
      ),
    );
  }
}

/// The rules sheet. Shown on demand from the header, and by each game on a
/// player's first ever run - never as a wall in front of the puzzle.
Future<void> showMinigameHowToPlay(
  BuildContext context, {
  required MinigameType type,
  required Color accentColor,
  required List<String> lines,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: CurioColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CurioColors.surfaceSunken,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('How to play', style: CurioTypography.platform.headlineMedium),
          const SizedBox(height: 4),
          Text(
            type.displayName,
            style: CurioTypography.platform.labelLarge?.copyWith(color: accentColor),
          ),
          const SizedBox(height: 16),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7, right: 10),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                  ),
                  Expanded(child: Text(line, style: CurioTypography.platform.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

/// The end-of-puzzle screen: outcome, the spoiler-safe share string, and a
/// copy button. Shared so a player learns one result screen, not five.
class MinigameResultSheet extends StatelessWidget {
  const MinigameResultSheet({
    super.key,
    required this.headline,
    required this.accentColor,
    required this.shareText,
    this.detail,
    this.extra,
  });

  final String headline;
  final Color accentColor;
  final String shareText;
  final String? detail;

  /// Optional per-game content - the explanation of why an answer worked,
  /// the correct causal chain, and so on.
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CurioColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline, style: CurioTypography.platform.headlineMedium?.copyWith(color: accentColor)),
          if (detail != null) ...[
            const SizedBox(height: 6),
            Text(detail!, style: CurioTypography.platform.bodyMedium?.copyWith(color: CurioColors.inkMuted)),
          ],
          if (extra != null) ...[const SizedBox(height: 16), extra!],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: CurioColors.platformBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              shareText,
              style: CurioTypography.platform.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          PressableScale(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: shareText));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Result copied'), duration: Duration(seconds: 2)),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CurioColors.ink,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Copy result',
                style: CurioTypography.platform.titleLarge?.copyWith(color: CurioColors.surface),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
