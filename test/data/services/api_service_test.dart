import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_pariwisata/data/services/api_service.dart';

void main() {
  group('ApiService', () {
    test('sends bearer credentials and decodes JSON', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v1/customer/me');
        expect(request.headers['Authorization'], 'Bearer access-token');
        expect(request.headers['Accept'], 'application/json');
        return http.Response(
          jsonEncode({
            'data': {'nama': 'Dewi'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = ApiService(
        baseUrl: 'http://localhost/api/v1/',
        client: client,
      );

      final response = await api.get('/customer/me', token: 'access-token');

      expect(response['data'], {'nama': 'Dewi'});
    });

    test('reports the first Laravel validation message', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'message': 'The given data was invalid.',
            'errors': {
              'email': ['Alamat email sudah digunakan.'],
            },
          }),
          422,
        ),
      );
      final api = ApiService(
        baseUrl: 'http://localhost/api/v1',
        client: client,
      );

      await expectLater(
        api.post('/auth/register'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 422)
              .having(
                (error) => error.message,
                'message',
                'Alamat email sudah digunakan.',
              ),
        ),
      );
    });
  });
}
