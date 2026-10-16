import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_pariwisata/data/services/api_service.dart';
import 'package:mobile_pariwisata/data/services/auth_service.dart';

void main() {
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
}
