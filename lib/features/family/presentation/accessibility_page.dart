import 'package:flutter/material.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/curio_ui.dart';

class AccessibilityPage extends StatelessWidget {
  const AccessibilityPage({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = CurioThemeScope.of(context);
    return CurioPage(
      title: 'Reading and motion',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Make yourself comfortable.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reduce motion'),
            subtitle: const Text(
              'Keep navigation and home decorations still. Your device’s reduced-motion preference is always respected.',
            ),
            value: controller.reduceMotion,
            onChanged: (v) => controller.setReading(motion: v),
          ),
          const SizedBox(height: 24),
          Text(
            'Reading size · ${(controller.readingScale * 100).round()}%',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: controller.readingScale,
            min: 1,
            max: 1.5,
            divisions: 5,
            label: '${(controller.readingScale * 100).round()}%',
            onChanged: (v) => controller.setReading(scale: v),
          ),
          const Text(
            'This adds to your device’s text-size preference. Preview: every little question can lead to a big discovery.',
          ),
          const SizedBox(height: 24),
          const Text(
            'Screen readers use your device settings. All four navigation destinations have permanent labels and selected-state announcements.',
          ),
        ],
      ),
    );
  }
}
