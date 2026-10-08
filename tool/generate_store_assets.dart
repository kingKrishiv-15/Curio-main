// Renders the Google Play listing graphics into store/:
//   flutter test tool/generate_store_assets.dart
//
// • store/play-icon-512.png       — 512×512 app icon (full-bleed; Play rounds it)
// • store/feature-graphic.png     — 1024×500 feature graphic

import 'dart:io';
import 'dart:ui' as ui;

import 'package:curio/core/theme/curio_colors.dart';
import 'package:curio/core/theme/curio_theme.dart';
import 'package:curio/core/widgets/curio_logo.dart';
import 'package:curio/features/auth/presentation/widgets/welcome_art.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadFonts() async {
  final material = File(
    '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/share/flutter'}'
    '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  for (final (family, file) in [
    ('Fraunces', File('assets/fonts/Fraunces.ttf')),
    ('DM Sans', File('assets/fonts/DMSans.ttf')),
    ('MaterialIcons', material),
  ]) {
    final bytes = file.readAsBytesSync();
    await (FontLoader(
      family,
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
}

Future<void> _save(GlobalKey key, String path) async {
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('wrote $path (${image.width}×${image.height})');
}

void main() {
  testWidgets('store assets', (tester) async {
    await tester.runAsync(_loadFonts);
    tester.view.devicePixelRatio = 1;

    // 512 icon
    tester.view.physicalSize = const Size(512, 512);
    final iconKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: iconKey,
        child: const CustomPaint(
          size: Size(512, 512),
          painter: CurioMarkPainter(cornerRadius: 0),
        ),
      ),
    );
    await tester.runAsync(() => _save(iconKey, 'store/play-icon-512.png'));

    // 1024×500 feature graphic
    tester.view.physicalSize = const Size(1024, 500);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: CurioTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: RepaintBoundary(
          key: key,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: 1024,
              height: 500,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0E211B),
                    Color(0xFF0A1A15),
                    Color(0xFF05100D),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -120,
                    top: -140,
                    child: Container(
                      width: 560,
                      height: 560,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            CurioColors.forest.withValues(alpha: .22),
                            CurioColors.forest.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 70,
                    top: 40,
                    child: OrbitHero(size: 420),
                  ),
                  Positioned(
                    left: 64,
                    top: 0,
                    bottom: 0,
                    width: 500,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CurioLogo(markSize: 52),
                        const SizedBox(height: 34),
                        Text.rich(
                          const TextSpan(
                            children: [
                              TextSpan(text: 'Turn '),
                              TextSpan(
                                text: '“why?”',
                                style: TextStyle(color: CurioColors.coral),
                              ),
                              TextSpan(text: '\ninto a daily adventure.'),
                            ],
                          ),
                          style: const TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 50,
                            height: 1.05,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -2,
                            color: CurioColors.ink,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Five-minute brain games for curious kids.',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 21,
                            fontWeight: FontWeight.w500,
                            color: CurioColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.runAsync(() => _save(key, 'store/feature-graphic.png'));
  });
}
