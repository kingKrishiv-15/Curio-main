// Rebuilds reviewable UI images without signing in or sending any email:
// flutter test tool/preview_visual_refresh.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:curio/core/services/auth_service.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/core/theme/theme_controller.dart';
import 'package:curio/features/auth/presentation/landing_page.dart';
import 'package:curio/features/auth/presentation/verify_code_page.dart';
import 'package:curio/features/auth/presentation/about_curio_page.dart';
import 'package:curio/features/auth/presentation/onboarding_page.dart';
import 'package:curio/features/games/game_catalog.dart';
import 'package:curio/features/games/presentation/game_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> _fonts() async {
  for (final (family, path) in [
    ('Fraunces', 'assets/fonts/Fraunces.ttf'),
    ('DM Sans', 'assets/fonts/DMSans.ttf'),
    (
      'MaterialIcons',
      '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ),
  ]) {
    final bytes = File(path).readAsBytesSync();
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
}

void main() {
  testWidgets('render the visual refresh in both themes and at reading sizes', (
    tester,
  ) async {
    // This tool runs under flutter test, with no device preferences to change.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(_fonts);
    // Client setup/disposal uses real asynchronous work, outside the widget
    // test's fake clock. No authentication or network requests are made.
    final client = (await tester.runAsync(
      () async => SupabaseClient(
        'https://example.supabase.co',
        'preview-only',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ),
    ))!;
    final auth = AuthService(client: client);
    final reading = ThemeController();
    final frame = GlobalKey();
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(reading.dispose);

    Future<void> mount(
      Widget page,
      Size size, {
      bool dark = false,
      double scale = 1,
      EdgeInsets insets = EdgeInsets.zero,
    }) async {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        CurioThemeScope(
          controller: reading,
          child: RepaintBoundary(
            key: frame,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: dark ? CurioTheme.dark : CurioTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: true,
                  textScaler: TextScaler.linear(scale),
                  padding: insets,
                ),
                child: child!,
              ),
              home: page,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> save(String name) async {
      final boundary =
          frame.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('build/design-preview/$name.png')
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    for (final dark in [false, true]) {
      await mount(
        LandingPage(authService: auth),
        const Size(402, 874),
        dark: dark,
        insets: const EdgeInsets.only(top: 62, bottom: 34),
      );
      await save('welcome-${dark ? 'dark' : 'light'}');
      await mount(
        const AboutCurioPage(),
        const Size(402, 874),
        dark: dark,
        insets: const EdgeInsets.only(top: 62, bottom: 34),
      );
      await save('about-${dark ? 'dark' : 'light'}');
      await mount(
        LandingPage(authService: auth),
        const Size(1280, 900),
        dark: dark,
        scale: 1.6,
      );
      await save('welcome-large-text-${dark ? 'dark' : 'light'}');
      await mount(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: 1.75,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              children: [
                for (final game in gameCatalog)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GameArt(game: game, height: 136, badges: false),
                      const SizedBox(height: 8),
                      Text(
                        game.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const Size(1080, 1440),
        dark: dark,
      );
      await save('games-${dark ? 'dark' : 'light'}');
    }
    await mount(
      VerifyCodePage(
        authService: auth,
        purpose: CodePurpose.signUp,
        email: 'parent@example.com',
        codeLength: 8,
      ),
      const Size(402, 874),
      insets: const EdgeInsets.only(top: 62, bottom: 34),
    );
    await tester.enterText(find.byKey(const Key('otp_input')), '01234567');
    await tester.pumpAndSettle();
    await save('otp-eight-digits');
    await mount(
      OnboardingPage(authService: auth, onComplete: () {}),
      const Size(390, 844),
    );
    await tester.enterText(find.byType(TextFormField), 'Alex');
    for (var i = 0; i < 2; i++) {
      await tester.ensureVisible(find.byKey(const Key('onboarding_continue')));
      await tester.tap(find.byKey(const Key('onboarding_continue')));
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.text('Make it comfortable.'));
    await tester.pumpAndSettle();
    await save('onboarding-comfort');
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(client.dispose);
  });
}
