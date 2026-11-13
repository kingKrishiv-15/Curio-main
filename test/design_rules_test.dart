import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The design budget in DESIGN.md, enforced. Each test names the files
/// that break a rule so the fix is obvious.
void main() {
  const tokens = 'lib/theme/curio_tokens.dart';

  // The signed-out and onboarding screens were restored to their original
  // look on request. They and the pieces only they use keep their own
  // colours, corners, shadows and gradients, so the visual rules below do
  // not apply to them. The writing rule (no dashes) still applies to all.
  bool original(String path) =>
      path.startsWith('lib/features/auth/') ||
      path.startsWith('lib/core/theme/curio_colors') ||
      path == 'lib/core/widgets/curio_clay.dart' ||
      path == 'lib/core/widgets/curio_ui.dart' ||
      path == 'lib/core/widgets/curio_logo.dart' ||
      path == 'lib/features/games/presentation/game_banner.dart' ||
      path == 'lib/features/games/presentation/game_emblem.dart';
  final sources = <String, String>{
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart')))
      file.path.replaceAll(r'\', '/'): file.readAsStringSync(),
  };

  List<String> offenders(bool Function(String path, String source) breaks) => [
    for (final entry in sources.entries)
      if (breaks(entry.key, entry.value)) entry.key,
  ];

  test('colours come only from curio_tokens.dart', () {
    expect(
      offenders(
        (path, s) =>
            path != tokens && !original(path) && s.contains('Color(0x'),
      ),
      isEmpty,
    );
  });

  test('corners are radiusCard or radiusPill, nothing else', () {
    final call = RegExp(r'BorderRadius\.circular\(\s*([^)]*?),?\s*\)');
    const allowed = {'CurioTokens.radiusCard', 'CurioTokens.radiusPill'};
    expect(
      offenders(
        (path, s) =>
            !original(path) &&
            call.allMatches(s).any((m) => !allowed.contains(m.group(1))),
      ),
      isEmpty,
    );
  });

  test('no em dashes or en dashes anywhere in lib', () {
    final dash = RegExp('[–—]', unicode: true);
    expect(offenders((path, s) => dash.hasMatch(s)), isEmpty);
  });

  test('shadows come only from curio_tokens.dart', () {
    expect(
      offenders(
        (path, s) =>
            path != tokens && !original(path) && s.contains('BoxShadow('),
      ),
      isEmpty,
    );
  });

  test('gradients appear only in progress and timer fills', () {
    const allowed = {'lib/core/widgets/curio_ui.dart'};
    expect(
      offenders(
        (path, s) =>
            !allowed.contains(path) &&
            !original(path) &&
            s.contains('Gradient('),
      ),
      isEmpty,
    );
  });
}
