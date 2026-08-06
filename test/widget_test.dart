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

  testWidgets('CurioApp starts signed-out users on the sign-in screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [supabaseClientProvider.overrideWithValue(supabaseClient)],
        child: const CurioApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
