import 'package:curio/app/curio_app.dart';
import 'package:curio/core/widgets/curio_clay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final light in [true, false]) {
    testWidgets(
      'Every tab extends behind the dock with iPhone insets; light=$light',
      (tester) async {
        for (final font in ['DMSans', 'Fraunces']) {
          await (FontLoader(
            font == 'DMSans' ? 'DM Sans' : font,
          )..addFont(rootBundle.load('assets/fonts/$font.ttf'))).load();
        }
        SharedPreferences.setMockInitialValues({
          'curio_theme_mode': light ? 'light' : 'dark',
        });
        tester.view.physicalSize = const Size(402, 874);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 62, bottom: 34);
        tester.view.viewPadding = const FakeViewPadding(top: 62, bottom: 34);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(const CurioApp());
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(
          tester.getSize(find.byKey(const Key('daily_goal_banner'))).height,
          lessThan(160),
        );
        for (final tab in ['Home', 'Games', 'Discover', 'Profile']) {
          await tester.tap(find.byKey(Key('nav_$tab')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          // The list's viewport must reach the physical bottom, not stop at 840.
          expect(tester.getBottomRight(find.byType(ListView).first).dy, 874);
          expect(find.byType(CurioClay), findsWidgets);
          expect(
            tester.getBottomRight(find.byKey(const Key('bottom_capsule'))).dy,
            lessThanOrEqualTo(840),
          );
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
