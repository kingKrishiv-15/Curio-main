import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:curio/app/curio_app.dart';
import 'package:curio/app/providers.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient supabaseClient;
  late MockGoTrueClient authClient;

  setUp(() {
    supabaseClient = MockSupabaseClient();
    authClient = MockGoTrueClient();

    when(() => supabaseClient.auth).thenReturn(authClient);
    when(() => authClient.currentSession).thenReturn(null);
    when(() => authClient.onAuthStateChange).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('CurioApp renders Home on launch', (tester) async {
    // TODO(ui-sprint): router.dart currently starts at /home unconditionally
    // (see its TODO) for this sprint's fake-data screens - once that's
    // reverted to gate on real auth, this test should go back to asserting
    // the signed-out redirect to /sign-in instead.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [supabaseClientProvider.overrideWithValue(supabaseClient)],
        child: const CurioApp(),
      ),
    );
    // Not pumpAndSettle(): Home has a deliberately-continuous idle
    // animation (see IdleFloat), which by design never "settles" -
    // pumpAndSettle would just time out waiting for it to stop.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Ways to learn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
