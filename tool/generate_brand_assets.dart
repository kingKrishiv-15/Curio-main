// Regenerates every launcher icon, favicon and the SVG logo from the one
// source of truth: CurioMarkPainter / CurioMarkGeometry in
// lib/core/widgets/curio_logo.dart.
//
//   flutter test tool/generate_brand_assets.dart
//
// It runs under `flutter test` only because that's the simplest way to get
// dart:ui painting without a device. Commit the files it writes.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:curio/core/theme/curio_colors.dart';
import 'package:curio/core/widgets/curio_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate brand assets', () async {
    // Android: legacy icons (rounded tile) + adaptive layers (108dp, the
    // glyph kept inside the 66dp safe zone).
    const android = {
      'mdpi': 1.0,
      'hdpi': 1.5,
      'xhdpi': 2.0,
      'xxhdpi': 3.0,
      'xxxhdpi': 4.0,
    };
    for (final MapEntry(key: density, value: scale) in android.entries) {
      final dir = 'android/app/src/main/res/mipmap-$density';
      await _png(
        '$dir/ic_launcher.png',
        (48 * scale).round(),
        const CurioMarkPainter(cornerRadius: .26),
      );
      await _png(
        '$dir/ic_launcher_foreground.png',
        (108 * scale).round(),
        const CurioMarkPainter(drawTile: false, glyphScale: .6),
      );
      await _png(
        '$dir/ic_launcher_background.png',
        (108 * scale).round(),
        const _TileOnly(),
      );
    }
    _write('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml', '''
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
''');

    // iOS masks the corners itself and rejects alpha on the store icon, so
    // these are full-bleed and written as opaque RGB.
    const ios = {
      'Icon-App-20x20@1x.png': 20,
      'Icon-App-20x20@2x.png': 40,
      'Icon-App-20x20@3x.png': 60,
      'Icon-App-29x29@1x.png': 29,
      'Icon-App-29x29@2x.png': 58,
      'Icon-App-29x29@3x.png': 87,
      'Icon-App-40x40@1x.png': 40,
      'Icon-App-40x40@2x.png': 80,
      'Icon-App-40x40@3x.png': 120,
      'Icon-App-60x60@2x.png': 120,
      'Icon-App-60x60@3x.png': 180,
      'Icon-App-76x76@1x.png': 76,
      'Icon-App-76x76@2x.png': 152,
      'Icon-App-83.5x83.5@2x.png': 167,
      'Icon-App-1024x1024@1x.png': 1024,
    };
    for (final MapEntry(key: name, value: size) in ios.entries) {
      await _png(
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/$name',
        size,
        const CurioMarkPainter(cornerRadius: 0),
        opaque: true,
      );
    }

    // macOS: Big Sur-style inset tile with its own soft shadow.
    for (final size in [16, 32, 64, 128, 256, 512, 1024]) {
      await _png(
        'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$size.png',
        size,
        const _MacIcon(),
      );
    }

    // Web: favicon, PWA icons, and maskable variants (80% safe zone).
    await _png(
      'web/favicon.png',
      32,
      const CurioMarkPainter(cornerRadius: .26),
    );
    for (final size in [192, 512]) {
      await _png(
        'web/icons/Icon-$size.png',
        size,
        const CurioMarkPainter(cornerRadius: .26),
      );
      await _png(
        'web/icons/Icon-maskable-$size.png',
        size,
        const CurioMarkPainter(cornerRadius: 0, glyphScale: .8),
      );
    }

    // Launch screens: the mark on the evergreen canvas, so the app opens
    // without a white flash.
    for (final MapEntry(key: density, value: scale) in android.entries) {
      await _png(
        'android/app/src/main/res/drawable-$density/splash_logo.png',
        (96 * scale).round(),
        const CurioMarkPainter(cornerRadius: .26),
      );
    }
    for (final (suffix, scale) in [('', 1), ('@2x', 2), ('@3x', 3)]) {
      await _png(
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage$suffix.png',
        96 * scale,
        const CurioMarkPainter(cornerRadius: .26),
      );
    }

    _write('assets/brand/curio-mark.svg', _svg());
  });
}

class _TileOnly extends CustomPainter {
  const _TileOnly();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..shader = CurioColors.markGradient.createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_TileOnly oldDelegate) => false;
}

class _MacIcon extends CustomPainter {
  const _MacIcon();
  @override
  void paint(Canvas canvas, Size size) {
    // Apple's template: an 824pt body centred in 1024 with a soft shadow.
    final inset = size.width * 100 / 1024;
    final body = Rect.fromLTWH(
      inset,
      inset * .8,
      size.width - inset * 2,
      size.width - inset * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        body.shift(Offset(0, size.width * .012)),
        Radius.circular(body.width * .225),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: .28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * .018),
    );
    canvas.save();
    canvas.translate(body.left, body.top);
    const CurioMarkPainter(cornerRadius: .225).paint(canvas, body.size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MacIcon oldDelegate) => false;
}

Future<void> _png(
  String path,
  int size,
  CustomPainter painter, {
  bool opaque = false,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, Size.square(size.toDouble()));
  final image = await recorder.endRecording().toImage(size, size);
  final Uint8List bytes;
  if (opaque) {
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    bytes = _encodeRgbPng(size, size, rgba.buffer.asUint8List());
  } else {
    bytes = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes);
  // ignore: avoid_print
  print('wrote $path');
}

void _write(String path, String contents) {
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(contents.trimLeft());
  // ignore: avoid_print
  print('wrote $path');
}

/// A tiny PNG writer for 8-bit RGB (colour type 2): no alpha channel, as the
/// App Store requires for the marketing icon.
Uint8List _encodeRgbPng(int width, int height, Uint8List rgba) {
  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.addByte(0); // filter: none
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      raw.add([rgba[i], rgba[i + 1], rgba[i + 2]]);
    }
  }
  final out = BytesBuilder()
    ..add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  void chunk(String type, List<int> data) {
    final typed = [...type.codeUnits, ...data];
    out
      ..add(_u32(data.length))
      ..add(typed)
      ..add(_u32(_crc32(typed)));
  }

  chunk('IHDR', [..._u32(width), ..._u32(height), 8, 2, 0, 0, 0]);
  chunk('IDAT', ZLibCodec(level: 9).encode(raw.toBytes()));
  chunk('IEND', const []);
  return out.toBytes();
}

List<int> _u32(int v) => [v >> 24 & 255, v >> 16 & 255, v >> 8 & 255, v & 255];

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = c & 1 == 1 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 255] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

String _svg() {
  const s = 1024.0;
  String n(double v) => (v * s).toStringAsFixed(1);
  String hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  const g = CurioMarkGeometry.lensCenter;

  final shape = CurioMarkGeometry.cOutline();
  final c = StringBuffer(
    'M${n(shape.outer.first.dx)} ${n(shape.outer.first.dy)}',
  );
  for (final p in shape.outer.skip(1)) {
    c.write(' L${n(p.dx)} ${n(p.dy)}');
  }
  c.write(
    ' A${n(shape.cap)} ${n(shape.cap)} 0 0 1 '
    '${n(shape.inner.last.dx)} ${n(shape.inner.last.dy)}',
  );
  for (final p in shape.inner.reversed.skip(1)) {
    c.write(' L${n(p.dx)} ${n(p.dy)}');
  }
  c.write(
    ' A${n(shape.cap)} ${n(shape.cap)} 0 0 1 '
    '${n(shape.outer.first.dx)} ${n(shape.outer.first.dy)} Z',
  );

  // The glint: a short arc inside the lens, upper left.
  final glintRadius = CurioMarkGeometry.lensRadius * .55;
  Offset onGlint(double degrees) =>
      g +
      Offset(
            math.cos(degrees * math.pi / 180),
            math.sin(degrees * math.pi / 180),
          ) *
          glintRadius;
  final glintFrom = onGlint(200), glintTo = onGlint(262);

  final tile = CurioColors.markGradient.colors;
  final stops = CurioColors.markGradient.stops!;
  final mint = CurioColors.markGlyph;
  final gold = CurioColors.spark;
  String mix(Color color, Color other, double amount) =>
      hex(Color.lerp(color, other, amount)!);
  return '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" role="img" aria-label="Curio">
  <!-- Generated by tool/generate_brand_assets.dart — edit curio_logo.dart, not this file. -->
  <defs>
    <linearGradient id="tile" x1="0" y1="0" x2="1" y2="1">
${[for (var i = 0; i < tile.length; i++) '      <stop offset="${stops[i]}" stop-color="${hex(tile[i])}"/>'].join('\n')}
    </linearGradient>
    <linearGradient id="mint" x2="1" y2="1">
      <stop stop-color="${mix(mint, Colors.white, .5)}"/>
      <stop offset=".5" stop-color="${hex(mint)}"/>
      <stop offset="1" stop-color="${mix(mint, Colors.black, .1)}"/>
    </linearGradient>
    <linearGradient id="gold" x2="1" y2="1">
      <stop stop-color="${mix(gold, Colors.white, .55)}"/>
      <stop offset=".5" stop-color="${hex(gold)}"/>
      <stop offset="1" stop-color="${mix(gold, Colors.black, .2)}"/>
    </linearGradient>
    <linearGradient id="glass" x2="1" y2="1">
      <stop stop-color="#fff" stop-opacity=".3"/>
      <stop offset="1" stop-color="${hex(mint)}" stop-opacity=".05"/>
    </linearGradient>
    <linearGradient id="rim" x2="1" y2="1">
      <stop stop-color="#fff" stop-opacity=".25"/>
      <stop offset="1" stop-color="#fff" stop-opacity=".02"/>
    </linearGradient>
    <clipPath id="tileClip"><rect width="1024" height="1024" rx="${n(.3)}"/></clipPath>
    <mask id="cut" maskUnits="userSpaceOnUse" x="0" y="0" width="1024" height="1024">
      <rect width="1024" height="1024" fill="#fff"/>
      <circle cx="${n(g.dx)}" cy="${n(g.dy)}" r="${n(CurioMarkGeometry.cutRadius)}" fill="#000"/>
    </mask>
  </defs>
  <rect width="1024" height="1024" rx="${n(.3)}" fill="url(#tile)"/>
  <ellipse cx="${n(.4)}" cy="0" rx="${n(.65)}" ry="${n(.5)}" fill="#fff" fill-opacity=".06" clip-path="url(#tileClip)"/>
  <rect x="${n(.008)}" y="${n(.008)}" width="${n(.984)}" height="${n(.984)}" rx="${n(.292)}" fill="none" stroke="url(#rim)" stroke-width="${n(.009)}"/>
  ${[for (var i = 5; i > 0; i--) '<path d="$c" fill="${mix(mint, Colors.black, .42)}" mask="url(#cut)" transform="translate(0 ${n(.005 * i)})"/>'].join('\n  ')}
  <path d="$c" fill="url(#mint)" mask="url(#cut)"/>
  <circle cx="${n(g.dx)}" cy="${n(g.dy)}" r="${n(CurioMarkGeometry.lensRadius)}" fill="url(#glass)"/>
  <circle cx="${n(g.dx)}" cy="${n(g.dy + .014)}" r="${n(CurioMarkGeometry.lensRadius)}" fill="none" stroke="${mix(gold, Colors.black, .45)}" stroke-width="${n(CurioMarkGeometry.lensWeight)}"/>
  <circle cx="${n(g.dx)}" cy="${n(g.dy)}" r="${n(CurioMarkGeometry.lensRadius)}" fill="none" stroke="url(#gold)" stroke-width="${n(CurioMarkGeometry.lensWeight)}"/>
  <path d="M${n(glintFrom.dx)} ${n(glintFrom.dy)} A${n(glintRadius)} ${n(glintRadius)} 0 0 1 ${n(glintTo.dx)} ${n(glintTo.dy)}" fill="none" stroke="#ffffff" stroke-opacity=".6" stroke-width="${n(CurioMarkGeometry.lensWeight * .42)}" stroke-linecap="round"/>
  <line x1="${n(CurioMarkGeometry.handleStart.dx)}" y1="${n(CurioMarkGeometry.handleStart.dy)}" x2="${n(CurioMarkGeometry.handleEnd.dx)}" y2="${n(CurioMarkGeometry.handleEnd.dy)}" stroke="${hex(CurioColors.spark)}" stroke-width="${n(CurioMarkGeometry.handleWeight)}" stroke-linecap="round"/>
</svg>
''';
}
