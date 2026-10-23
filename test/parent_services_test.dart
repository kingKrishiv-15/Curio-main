import 'dart:convert';
import 'dart:io';

import 'package:curio/core/services/auth_service.dart';
import 'package:curio/core/services/family_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _id = 'c1220000-0000-0000-0000-000000000001';
Map<String, Object> _session(String token) => {
  'access_token': token,
  'refresh_token': 'test-refresh-token',
  'expires_in': 3600,
  'expires_at': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
  'token_type': 'bearer',
  'user': {
    'id': _id,
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'parent@example.com',
    'app_metadata': {},
    'user_metadata': {},
    'created_at': '2026-10-23T00:00:00Z',
  },
};

Future<void> _withServer(
  Future<void> Function(HttpRequest) handler,
  Future<void> Function(SupabaseClient) check,
) async {
  final previous = HttpOverrides.current;
  HttpOverrides.global = null;
  SharedPreferences.setMockInitialValues({});
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen(handler);
  final client = SupabaseClient(
    'http://127.0.0.1:${server.port}',
    'test',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  try {
    await client.auth.setInitialSession(jsonEncode(_session('original-token')));
    await check(client);
  } finally {
    await client.dispose();
    await server.close(force: true);
    HttpOverrides.global = previous;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Parent password verification checks the current email against auth and rejects incorrect passwords',
    () async {
      var attempts = 0;
      await _withServer(
        (request) async {
          attempts++;
          expect(request.uri.path, '/auth/v1/token');
          final body =
              jsonDecode(await utf8.decoder.bind(request).join()) as Map;
          expect(body['email'], 'parent@example.com');
          request.response.headers.contentType = ContentType.json;
          if (body['password'] != 'correct-password') {
            request.response.statusCode = 400;
            request.response.write(
              jsonEncode({
                'error_code': 'invalid_credentials',
                'msg': 'Invalid login credentials',
              }),
            );
          } else {
            request.response.write(jsonEncode(_session('verified-token')));
          }
          await request.response.close();
        },
        (client) async {
          final auth = AuthService(client: client);
          await expectLater(
            auth.verifyParentPassword('incorrect'),
            throwsA(isA<AuthException>()),
          );
          expect(client.auth.currentSession!.accessToken, 'original-token');
          await auth.verifyParentPassword('correct-password');
          expect(client.auth.currentUser!.id, _id);
          expect(attempts, 2);
        },
      );
    },
  );

  test(
    'Weekly email switch only patches the opt-in and caches the complete server preference',
    () async {
      await _withServer(
        (request) async {
          expect(request.method, 'PATCH');
          expect(request.uri.path, '/rest/v1/family_settings');
          expect(request.uri.queryParameters['parent_id'], 'eq.$_id');
          expect(jsonDecode(await utf8.decoder.bind(request).join()), {
            'weekly_email_enabled': true,
          });
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode({
              'parent_id': _id,
              'daily_goal': 2,
              'timezone': 'Asia/Kolkata',
              'reminders_enabled': true,
              'weekly_email_enabled': true,
              'consent_version': '2026-09',
            }),
          );
          await request.response.close();
        },
        (client) async {
          await FamilyService(client: client).setWeeklyEmailEnabled(true);
          final cached =
              jsonDecode(
                    (await SharedPreferences.getInstance()).getString(
                      'curio_family_$_id',
                    )!,
                  )
                  as Map;
          expect(cached['daily_goal'], 2);
          expect(cached['reminders_enabled'], isTrue);
          expect(cached['weekly_email_enabled'], isTrue);
        },
      );
    },
  );
}
