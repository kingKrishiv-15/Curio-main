import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The design budget in DESIGN.md, enforced. Each test names the files
/// that break a rule so the fix is obvious.
void main() {
  const tokens = 'lib/theme/curio_tokens.dart';
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
      offenders((path, s) => path != tokens && s.contains('Color(0x')),
      isEmpty,
    );
  });

  test('corners are radiusCard or radiusPill, nothing else', () {
    final call = RegExp(r'BorderRadius\.circular\(\s*([^)]*?),?\s*\)');
    const allowed = {'CurioTokens.radiusCard', 'CurioTokens.radiusPill'};
    expect(
      offenders(
        (path, s) =>
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
      offenders((path, s) => path != tokens && s.contains('BoxShadow(')),
      isEmpty,
    );
  });

  test('gradients appear only in progress and timer fills', () {
    const allowed = {'lib/core/widgets/curio_ui.dart'};
    expect(
      offenders(
        (path, s) => !allowed.contains(path) && s.contains('Gradient('),
      ),
      isEmpty,
    );
  });
}
