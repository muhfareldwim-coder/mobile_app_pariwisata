import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_pariwisata/data/services/api_service.dart';
import 'package:mobile_pariwisata/data/services/auth_service.dart';

void main() {
  setUp(AuthService.logout);

  test('reads the public Google server client ID from the API', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/auth/google/config');
      return http.Response(
        jsonEncode({
          'data': {'server_client_id': 'public-client-id'},
        }),
        200,
      );
    });
    final service = AuthService(
      api: ApiService(baseUrl: 'https://jembergo.test/api/v1', client: client),
    );

    expect(await service.googleSignInServerClientId(), 'public-client-id');
  });

  test('reports incomplete Google client configuration from the API', () {
    final service = AuthService(
      api: ApiService(
        baseUrl: 'https://jembergo.test/api/v1',
        client: MockClient(
          (_) async => http.Response(jsonEncode({'data': {}}), 200),
        ),
      ),
    );

    expect(
      service.googleSignInServerClientId(),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'profile edits update the server and the signed-in account cache',
    () async {
      final storage = _MemoryAuthSessionStorage();
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/v1/auth/login') {
          return http.Response(
            jsonEncode({
              'data': {
                'token': 'profile-token',
                'user': {
                  'id': 42,
                  'nama': 'Siti Aminah',
                  'email': 'siti@gmail.com',
                  'no_hp': '081234567890',
                  'role': 'CUSTOMER',
                },
              },
            }),
            200,
          );
        }
        if (request.url.path == '/api/v1/customer/profil' &&
            request.method == 'PUT') {
          expect(request.headers['Authorization'], isNotEmpty);
          expect(jsonDecode(request.body), {
            'nama': 'Siti Rahma',
            'email': 'siti.rahma@gmail.com',
            'no_hp': '081234567891',
            'password': 'newPassword123',
            'password_confirmation': 'newPassword123',
          });
          return http.Response(
            jsonEncode({
              'data': {
                'id': 42,
                'nama': 'Siti Rahma',
                'email': 'siti.rahma@gmail.com',
                'no_hp': '081234567891',
              },
            }),
            200,
          );
        }
        if (request.url.path == '/api/v1/customer/profil' &&
            request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'data': {
                'id': 42,
                'nama': 'Siti Website',
                'email': 'siti.website@gmail.com',
                'no_hp': '081234567892',
              },
            }),
            200,
          );
        }
        fail('Unexpected request: ${request.method} ${request.url}');
      });
      final service = AuthService(
        api: ApiService(
          baseUrl: 'https://jembergo.test/api/v1',
          client: client,
        ),
        sessionStorage: storage,
      );

      await service.login('siti@gmail.com', 'oldPassword123');
      final updatedUser = await service.updateProfile(
        name: 'Siti Rahma',
        email: 'siti.rahma@gmail.com',
        phone: '081234567891',
        password: 'newPassword123',
        passwordConfirmation: 'newPassword123',
      );

      expect(updatedUser.name, 'Siti Rahma');
      expect(AuthService.currentUser, updatedUser);
      final savedUser = jsonDecode(storage.values['jembergo_user']!);
      expect(savedUser['nama'], 'Siti Rahma');
      expect(savedUser['email'], 'siti.rahma@gmail.com');
      expect(requests.last.method, 'PUT');

      final refreshedUser = await service.refreshProfile();
      expect(refreshedUser.name, 'Siti Website');
      expect(AuthService.currentUser?.email, 'siti.website@gmail.com');
      final refreshedCache = jsonDecode(storage.values['jembergo_user']!);
      expect(refreshedCache['nama'], 'Siti Website');
    },
  );
}

class _MemoryAuthSessionStorage implements AuthSessionStorage {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
