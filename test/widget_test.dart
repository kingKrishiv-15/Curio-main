import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:curio/app/curio_app.dart';

void main() {
  testWidgets('CurioApp renders the blank shell without error', (
    tester,
  ) async {
    await tester.pumpWidget(const CurioApp());

    expect(find.text('Curio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
