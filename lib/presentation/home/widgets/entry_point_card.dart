import 'package:flutter/material.dart';

import '../../widgets/pressable_scale.dart';

/// A bold, color-blocked navigation entry ("Maths", "Curio Special", "IPM &
/// MAT"). [featured] renders larger with a bigger icon and subtitle, used
/// for the one entry point that should visually anchor the screen instead
/// of every entry point being identically sized.
class EntryPointCard extends StatelessWidget {
  const EntryPointCard({
    super.key,
    required this.label,
    required this.icon,
    required this.tintColor,
    required this.accentColor,
    required this.onTap,
    this.subtitle,
    this.featured = false,
    this.locked = false,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final Color tintColor;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool featured;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PressableScale(
      onTap: locked ? null : onTap,
      child: Container(
        padding: EdgeInsets.all(featured ? 22 : 16),
        decoration: BoxDecoration(
          color: tintColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: featured ? 56 : 44,
              height: featured ? 56 : 44,
              decoration: BoxDecoration(
                color: locked ? accentColor.withValues(alpha: 0.35) : accentColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                locked ? Icons.lock_outline : icon,
                color: Colors.white,
                size: featured ? 30 : 24,
              ),
            ),
            SizedBox(height: featured ? 16 : 12),
            Text(
              label,
              style: (featured ? textTheme.headlineSmall : textTheme.titleLarge)?.copyWith(
                color: const Color(0xFF15121F),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: textTheme.bodySmall?.copyWith(color: const Color(0xFF6E6B7A)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
