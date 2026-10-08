import 'package:curio/app/curio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final light in [true, false]) {
    testWidgets(
      'Compact glass dock animates and preserves tabs, light=$light',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'curio_theme_mode': light ? 'light' : 'dark',
        });
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(const CurioApp());
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        final capsule = find.byKey(const Key('bottom_capsule'));
        final size = tester.getSize(capsule);
        expect(size.width, 304);
        expect(size.height, lessThanOrEqualTo(64));
        expect(
          find.descendant(of: capsule, matching: find.byType(BackdropFilter)),
          findsOneWidget,
        );
        final homeScroll = find.byType(ListView).first;
        await tester.drag(homeScroll, const Offset(0, -340));
        await tester.pump(const Duration(milliseconds: 600));
        final scrollable = find
            .descendant(of: homeScroll, matching: find.byType(Scrollable))
            .first;
        final position = tester.state<ScrollableState>(scrollable).position;
        final oldOffset = position.pixels;
        await tester.tap(find.byKey(const Key('nav_Games')));
        await tester.pump();
        expect(
          tester
              .widget<FadeTransition>(find.byKey(const Key('tab_transition')))
              .opacity
              .value,
          lessThan(1),
        );
        await tester.pump(const Duration(milliseconds: 140));
        expect(
          tester
              .widget<FadeTransition>(find.byKey(const Key('tab_transition')))
              .opacity
              .value,
          lessThan(1),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          tester
              .widget<FadeTransition>(find.byKey(const Key('tab_transition')))
              .opacity
              .value,
          1,
        );
        expect(find.text('Ways to learn'), findsOneWidget);
        await tester.tap(find.byKey(const Key('nav_Home')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        expect(position.pixels, oldOffset);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
