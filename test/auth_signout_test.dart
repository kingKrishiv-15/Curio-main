import 'dart:convert';
import 'dart:io';

import 'package:curio/core/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final pending in [true, false]) {
    test('sign-out preserves pending=$pending progress correctly', () async {
      final previousHttpOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      const user = 'c1220000-0000-0000-0000-000000000001';
      SharedPreferences.setMockInitialValues({
        'curio_progress_$user': 'saved-progress',
        'curio_pending_$user': pending,
      });
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.headers.contentType = ContentType.json;
        request.response.write('{}');
        await request.response.close();
      });
      final client = SupabaseClient(
        'http://127.0.0.1:${server.port}',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );
      try {
        await client.auth.setInitialSession(
          jsonEncode({
            'access_token': 'test-access-token',
            'refresh_token': 'test-refresh-token',
            'expires_in': 3600,
            'expires_at': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
            'token_type': 'bearer',
            'user': {
              'id': user,
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': 'parent@example.com',
              'app_metadata': {},
              'user_metadata': {},
              'created_at': '2026-10-22T00:00:00Z',
            },
          }),
        );
        await AuthService(client: client).signOut();
        expect(client.auth.currentUser, isNull);
        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('curio_progress_$user'),
          pending ? 'saved-progress' : null,
        );
        expect(prefs.getBool('curio_pending_$user'), pending ? true : null);
      } finally {
        await client.dispose();
        await server.close(force: true);
        HttpOverrides.global = previousHttpOverrides;
      }
    });
  }
}
