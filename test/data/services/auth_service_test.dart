import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_pariwisata/data/services/api_service.dart';
import 'package:mobile_pariwisata/data/services/auth_service.dart';

void main() {
  setUp(AuthService.logout);

  test(
    'writes a remembered session to the configured session storage',
    () async {
      final storage = _MemoryAuthSessionStorage();
      final service = AuthService(
        sessionStorage: storage,
        api: ApiService(
          baseUrl: 'https://jembergo.test/api/v1',
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'data': {
                  'token': 'stored-token',
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
            ),
          ),
        ),
      );

      await service.login('siti@gmail.com', 'password');
      expect(storage.values['jembergo_access_token'], 'stored-token');
      expect(storage.values['jembergo_user'], isNotNull);
      expect(AuthService.accessToken, 'stored-token');
      expect(AuthService.currentUser?.id, '42');
      expect(AuthService.currentUser?.name, 'Siti Aminah');
      expect(AuthService.currentUser?.email, 'siti@gmail.com');
      expect(AuthService.currentUser?.phone, '081234567890');
    },
  );

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
    'registration starts email verification without creating a session',
    () async {
      final requests = <http.Request>[];
      final service = AuthService(
        api: ApiService(
          baseUrl: 'https://jembergo.test/api/v1',
          client: MockClient((request) async {
            requests.add(request);
            if (request.url.path == '/api/v1/auth/register') {
              return http.Response(
                jsonEncode({
                  'data': {
                    'email': 'siti@example.com',
                    'purpose': 'registration',
                  },
                }),
                202,
              );
            }
            if (request.url.path == '/api/v1/auth/register/verify') {
              expect(jsonDecode(request.body), {
                'email': 'siti@example.com',
                'otp': '123456',
              });
              return http.Response(
                jsonEncode({'message': 'Email berhasil diverifikasi.'}),
                200,
              );
            }
            fail('Unexpected request: ${request.method} ${request.url}');
          }),
        ),
      );

      await service.register(
        'Siti Aminah',
        'Siti@example.com',
        '081234567890',
        'password123',
      );
      expect(AuthService.currentUser, isNull);
      await service.verifyRegistrationOtp('Siti@example.com', '123456');
      expect(requests.map((request) => request.url.path), [
        '/api/v1/auth/register',
        '/api/v1/auth/register/verify',
      ]);
    },
  );

  test('Google login can finish after the server requires email OTP', () async {
    final storage = _MemoryAuthSessionStorage();
    final service = AuthService(
      api: ApiService(
        baseUrl: 'https://jembergo.test/api/v1',
        client: MockClient((request) async {
          if (request.url.path == '/api/v1/auth/google') {
            return http.Response(
              jsonEncode({
                'data': {'email': 'siti@example.com', 'purpose': 'google'},
              }),
              202,
            );
          }
          if (request.url.path == '/api/v1/auth/google/verify') {
            return http.Response(
              jsonEncode({
                'data': {
                  'token': 'google-token',
                  'user': {
                    'id': 42,
                    'nama': 'Siti Aminah',
                    'email': 'siti@example.com',
                    'no_hp': '081234567890',
                    'role': 'CUSTOMER',
                  },
                },
              }),
              200,
            );
          }
          fail('Unexpected request: ${request.method} ${request.url}');
        }),
      ),
      sessionStorage: storage,
    );

    final result = await service.loginWithGoogleIdToken('google-id-token');
    expect(result, isA<GoogleLoginOtpRequired>());
    expect((result as GoogleLoginOtpRequired).email, 'siti@example.com');
    expect(AuthService.currentUser, isNull);

    final user = await service.verifyGoogleOtp('siti@example.com', '123456');
    expect(user.email, 'siti@example.com');
    expect(AuthService.accessToken, 'google-token');
  });

  test('password recovery verifies OTP and submits the reset token', () async {
    final requests = <http.Request>[];
    final service = AuthService(
      api: ApiService(
        baseUrl: 'https://jembergo.test/api/v1',
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/api/v1/auth/password/otp') {
            return http.Response(jsonEncode({'message': 'OTP dikirim.'}), 202);
          }
          if (request.url.path == '/api/v1/auth/password/otp/verify') {
            return http.Response(
              jsonEncode({
                'data': {'reset_token': 'one-time-reset-token'},
              }),
              200,
            );
          }
          if (request.url.path == '/api/v1/auth/password/reset') {
            expect(jsonDecode(request.body), {
              'email': 'siti@example.com',
              'reset_token': 'one-time-reset-token',
              'password': 'new-password',
              'password_confirmation': 'new-password',
            });
            return http.Response(
              jsonEncode({'message': 'Password berhasil diubah.'}),
              200,
            );
          }
          fail('Unexpected request: ${request.method} ${request.url}');
        }),
      ),
    );

    await service.requestPasswordResetOtp('Siti@example.com');
    final resetToken = await service.verifyPasswordResetOtp(
      'Siti@example.com',
      '123456',
    );
    await service.resetPassword(
      email: 'Siti@example.com',
      resetToken: resetToken,
      password: 'new-password',
      passwordConfirmation: 'new-password',
    );
    expect(requests, hasLength(3));
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
