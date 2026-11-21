import 'package:curio/app/curio_app.dart';
import 'package:curio/core/widgets/curio_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in [const Size(390, 844), const Size(1280, 900)]) {
    testWidgets('Four branded tabs work at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const CurioApp());
      await tester.pump(const Duration(seconds: 1));
      for (final tab in ['Home', 'Games', 'Discover', 'Profile']) {
        expect(find.byKey(Key('nav_$tab')), findsOneWidget);
      }
      expect(find.byType(CurioLogo), findsOneWidget);

      await tester.tap(find.byKey(const Key('nav_Games')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Today’s games'), findsOneWidget);
      expect(find.byType(CurioLogo), findsOneWidget);

      await tester.tap(find.byKey(const Key('nav_Discover')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('discover_summary')), findsOneWidget);
      expect(find.byType(CurioLogo), findsOneWidget);
      expect(find.textContaining('Nothing here yet'), findsOneWidget);
      expect(find.text('Keep exploring'), findsNothing);

      await tester.tap(find.byKey(const Key('nav_Profile')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(CurioLogo), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav_Home')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Today’s games'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
