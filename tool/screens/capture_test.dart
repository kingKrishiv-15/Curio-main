// ignore_for_file: invalid_use_of_visible_for_testing_member
// Renders every screen at a phone viewport (390 x 844) in demo mode and
// writes the PNGs for docs/ui/update_1.
//
// Run: flutter test tool/screens/capture_test.dart --update-goldens
//
// These are the real widgets drawn by the Flutter engine with the app's
// own fonts. They are not browser screenshots of the web build.
import 'dart:io';

import 'package:curio/app/curio_app.dart';
import 'package:curio/core/services/auth_service.dart';
import 'package:curio/core/state/curio_state.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/features/auth/presentation/intro_page.dart';
import 'package:curio/features/auth/presentation/landing_page.dart';
import 'package:curio/features/auth/presentation/onboarding_page.dart';
import 'package:curio/features/games/cascade/presentation/cascade_page.dart';
import 'package:curio/features/games/common/game_kit.dart';
import 'package:curio/features/games/link_lab/domain/link_lab.dart';
import 'package:curio/features/games/link_lab/presentation/link_lab_page.dart';
import 'package:curio/features/games/scale/presentation/scale_page.dart';
import 'package:curio/features/games/second_opinion/data/second_opinion_gateways.dart';
import 'package:curio/features/games/second_opinion/domain/second_opinion.dart';
import 'package:curio/features/games/second_opinion/presentation/second_opinion_page.dart';
import 'package:curio/features/games/verdict/presentation/verdict_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _out = '../../docs/ui/update_1';
final _day = DateTime(2026, 11, 13);

Future<void> _font(String family, String path) async {
  final file = File(path);
  if (!file.existsSync()) return;
  final bytes = file.readAsBytesSync();
  await (FontLoader(
    family,
  )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
}

Future<void> _phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

Widget _page(Widget page, CurioState state) => CurioScope(
  notifier: state,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: CurioTheme.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: page,
  ),
);

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pump(const Duration(milliseconds: 400));
  // Tests paint shadows as flat blocks unless told otherwise. Turn real
  // shadows on just for the capture, then restore the test default.
  debugDisableShadows = false;
  tester.binding.renderViews.first.markNeedsPaint();
  for (final element in find.byType(MaterialApp).evaluate()) {
    element.markNeedsBuild();
  }
  await tester.pump();
  await expectLater(
    find.byType(MaterialApp).first,
    matchesGoldenFile('$_out/$name.png'),
  );
  debugDisableShadows = true;
  await tester.pump();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  final list = find.byType(Scrollable).first;
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 200, scrollable: list);
  }
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _top(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
  await tester.pump();
}

AuthService _auth() => AuthService(
  client: SupabaseClient(
    'https://example.supabase.co',
    'demo-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  ),
);

void main() {
  setUpAll(() async {
    await _font('Fraunces', 'assets/fonts/Fraunces.ttf');
    await _font('DM Sans', 'assets/fonts/DMSans.ttf');
    await _font(
      'MaterialIcons',
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    );
    await _font('Segoe UI Emoji', r'C:\Windows\Fonts\seguiemj.ttf');
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DemoSecondOpinionGateway.reset();
  });

  testWidgets('welcome, intro and onboarding', (tester) async {
    await _phone(tester);
    Widget signedOut(Widget home) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: CurioTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: home,
    );
    await tester.pumpWidget(signedOut(LandingPage(authService: _auth())));
    await _shot(tester, '02_welcome');
    await tester.pumpWidget(signedOut(IntroPage(authService: _auth())));
    await _shot(tester, '02b_intro');
    await tester.pumpWidget(
      signedOut(OnboardingPage(authService: _auth(), onComplete: () {})),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.enterText(find.byType(TextFormField), 'Alex');
    await tester.tap(find.byKey(const Key('age_12')));
    await _shot(tester, '01_onboarding');
    await tester.tap(find.byKey(const Key('onboarding_continue')));
    await tester.pump(const Duration(milliseconds: 600));
    await _shot(tester, '01b_onboarding_goal');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('home, discover (empty state) and profile', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(const CurioApp());
    await tester.pump(const Duration(seconds: 1));
    await _shot(tester, '03_home');
    await tester.tap(find.byKey(const Key('nav_Discover')));
    await _shot(tester, '12_discover_empty');
    await tester.tap(find.byKey(const Key('nav_Profile')));
    await _shot(tester, '13_profile');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('second opinion, all four states', (tester) async {
    await _phone(tester);
    final state = CurioState();
    await tester.pumpWidget(
      _page(SecondOpinionPage(gateway: DemoSecondOpinionGateway()), state),
    );
    await tester.pump();
    await _shot(tester, '04_second_opinion_brief');
    for (final probe in [Probe.source, Probe.current, Probe.example]) {
      await _tap(tester, find.byKey(Key('so_probe_${probe.id}')));
    }
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const Key('so_reply_source'))),
      alignment: .1,
    );
    await _shot(tester, '05_second_opinion_probes');
    await _tap(tester, find.byKey(const Key('so_to_verdict')));
    for (final id in ['c3', 'c5']) {
      await _tap(tester, find.byKey(Key('so_claim_$id')));
    }
    await _top(tester);
    await _shot(tester, '06_second_opinion_verdict');
    await _tap(tester, find.byKey(const Key('so_claim_c1')));
    await _tap(tester, find.byKey(const Key('so_submit')));
    await _shot(tester, '07_second_opinion_debrief');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -520));
    await _shot(tester, '08_second_opinion_debrief_lessons');
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });

  testWidgets('second opinion error state', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(
      _page(SecondOpinionPage(gateway: _Unpublished()), CurioState()),
    );
    await tester.pump();
    await _shot(tester, '14_error_state');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('games mid-play', (tester) async {
    await _phone(tester);

    var state = CurioState();
    await tester.pumpWidget(_page(ScalePage(date: _day), state));
    await tester.pump();
    await _tap(tester, find.byKey(const Key('scale_left')));
    await tester.pump(const Duration(seconds: 3));
    await _top(tester);
    await _shot(tester, '09_maths_tip_the_scale');
    await tester.pumpWidget(const SizedBox());
    state.dispose();

    state = CurioState();
    await tester.pumpWidget(_page(LinkLabPage(date: _day), state));
    await tester.pump();
    final game = LinkLabGame.forDay(linkLabDay(DailyPick.dayNumber(_day)));
    for (final word in game.puzzle.groups.first.words) {
      await _tap(tester, find.byKey(Key('link_$word')));
    }
    await _tap(tester, find.byKey(const Key('link_submit')));
    for (final word in game.puzzle.groups[1].words.take(2)) {
      await _tap(tester, find.byKey(Key('link_$word')));
    }
    await _top(tester);
    await _shot(tester, '10_logic_link_lab');
    await tester.pumpWidget(const SizedBox());
    state.dispose();

    state = CurioState();
    await tester.pumpWidget(_page(VerdictPage(date: _day), state));
    await tester.pump();
    await _tap(tester, find.byKey(const Key('verdict_supports')));
    await _top(tester);
    await _shot(tester, '11a_verdict');
    await tester.pumpWidget(const SizedBox());
    state.dispose();

    state = CurioState();
    await tester.pumpWidget(_page(CascadePage(date: _day), state));
    await tester.pump();
    for (final start in ['Rain soaks', 'Leaves shade']) {
      final tile = find.textContaining(start);
      if (tile.evaluate().isNotEmpty) await _tap(tester, tile.first);
    }
    await _top(tester);
    await _shot(tester, '11b_cascade');
    await tester.pumpWidget(const SizedBox());
    state.dispose();
  });
}

class _Unpublished implements SecondOpinionGateway {
  @override
  Future<SecondOpinionSession> open() async =>
      throw const SecondOpinionUnavailable(
        'Today\'s Second Opinion has not been published yet.',
      );

  @override
  Future<String> ask(Probe probe) async => '';

  @override
  Future<SecondOpinionVerdict> submit(Set<String> claimIds) =>
      throw UnimplementedError();
}
