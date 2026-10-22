import 'package:flutter/material.dart';

import '../../../core/theme/curio_colors.dart';
import '../../../core/theme/curio_colors_light.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/curio_ui.dart';

/// Reading size and motion for this device, on top of the device's own
/// accessibility settings.
class AccessibilityPage extends StatelessWidget {
  const AccessibilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CurioThemeScope.of(context);
    final muted = curioColor(
      context,
      CurioColors.inkSoft,
      CurioColorsLight.inkSoft,
    );
    final forest = curioColor(
      context,
      CurioColors.forest,
      CurioColorsLight.forest,
    );
    final sunken = curioColor(
      context,
      CurioColors.surfaceMuted,
      CurioColorsLight.surfaceMuted,
    );
    final percent = (controller.readingScale * 100).round();
    return CurioPage(
      title: 'Reading and motion',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Make yourself comfortable.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'These work on top of your phone’s own accessibility settings.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 20),
          CurioCard(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
            child: Row(
              children: [
                CurioIconTile(
                  icon: Icons.motion_photos_paused_outlined,
                  color: forest,
                  size: 38,
                  iconSize: 19,
                  radius: 12,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reduce motion',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Keep navigation and decorations still. Your device’s reduced-motion setting is always respected.',
                        style: TextStyle(color: muted, height: 1.45),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: controller.reduceMotion,
                  onChanged: (v) => controller.setReading(motion: v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CurioCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CurioIconTile(
                      icon: Icons.text_fields_rounded,
                      color: forest,
                      size: 38,
                      iconSize: 19,
                      radius: 12,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Reading size',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Slider(
                  value: controller.readingScale,
                  min: 1,
                  max: 1.5,
                  divisions: 5,
                  label: '$percent%',
                  onChanged: (v) => controller.setReading(scale: v),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sunken,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Every little question can lead to a big discovery.',
                    style: TextStyle(height: 1.45),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Adds to your device’s text size. The line above is a preview.',
                  style: TextStyle(color: muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          CurioStatusStrip(
            icon: Icons.record_voice_over_outlined,
            title: 'Screen readers',
            body:
                'Curio follows your device’s TalkBack or VoiceOver settings. Every tab, game card and button has a spoken label.',
            color: forest,
          ),
        ],
      ),
    );
  }
}
