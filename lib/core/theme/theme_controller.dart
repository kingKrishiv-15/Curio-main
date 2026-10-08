import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app's current [ThemeMode] and persists the user's choice.
/// Defaults to dark — Curio's current baseline look — until the person
/// explicitly switches to light.
class ThemeController extends ChangeNotifier {
  ThemeController() {
    _load();
  }

  static const _prefsKey = 'curio_theme_mode';

  bool reduceMotion = false;
  double readingScale = 1;
  Future<void> setReading({bool? motion, double? scale}) async {
    if (motion != null) reduceMotion = motion;
    if (scale != null) readingScale = scale.clamp(1, 1.5);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('curio_reduce_motion', reduceMotion);
    await prefs.setDouble('curio_reading_scale', readingScale);
  }

  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      reduceMotion = prefs.getBool('curio_reduce_motion') ?? false;
      readingScale = (prefs.getDouble('curio_reading_scale') ?? 1).clamp(
        1,
        1.5,
      );
      notifyListeners();
      final saved = prefs.getString(_prefsKey);
      if (saved == 'light') {
        _mode = ThemeMode.light;
        notifyListeners();
      }
    } catch (_) {
      // No local storage available (e.g. some web/test contexts) — keep
      // the in-memory default and simply don't persist.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        mode == ThemeMode.light ? 'light' : 'dark',
      );
    } catch (_) {
      // Best-effort persistence only.
    }
  }

  Future<void> toggle() => setMode(isDark ? ThemeMode.light : ThemeMode.dark);
}

/// Exposes the app-wide [ThemeController] to any descendant via
/// `CurioThemeScope.of(context)`.
class CurioThemeScope extends InheritedNotifier<ThemeController> {
  const CurioThemeScope({
    required ThemeController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CurioThemeScope>();
    assert(scope != null, 'CurioThemeScope was not found in this context');
    return scope!.notifier!;
  }
}
