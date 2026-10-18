import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/constants/app_constants.dart';

class ApiService {
  ApiService({String? baseUrl, http.Client? client})
    : baseUrl = (baseUrl ?? AppConstants.apiBaseUrl).replaceFirst(
        RegExp(r'/$'),
        '',
      ),
      _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  String resolveUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.hasScheme) return url;

    final apiUri = Uri.parse(baseUrl);
    final serverRoot = apiUri.replace(path: '/', query: null, fragment: null);
    return serverRoot.resolveUri(uri).toString();
  }

  Future<Map<String, dynamic>> get(
    String path, {
    String? token,
    Map<String, String>? queryParameters,
  }) {
    final uri = Uri.parse('$baseUrl$path')
        .replace(queryParameters: queryParameters);
    return _send(_client.get(uri, headers: _headers(token)));
  }

  Future<Uint8List> getBytes(
    String path, {
    String? token,
    String accept = 'application/octet-stream',
    String? expectedContentType,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client
          .get(uri, headers: {..._headers(token), 'Accept': accept})
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final Object? decoded;
        try {
          decoded = jsonDecode(response.body);
        } on FormatException {
          throw ApiException(
            'Unduhan gagal dengan status ${response.statusCode}.',
            statusCode: response.statusCode,
          );
        }
        if (decoded is! Map<String, dynamic>) {
          throw ApiException(
            'Server mengirim respons unduhan yang tidak valid.',
            statusCode: response.statusCode,
          );
        }
        throw ApiException(
          _errorMessage(decoded),
          statusCode: response.statusCode,
        );
      }
      final contentType = response.headers['content-type'];
      if (expectedContentType != null &&
          (contentType == null ||
              !contentType.startsWith(expectedContentType))) {
        throw const ApiException('Server tidak mengirim file PDF.');
      }
      return response.bodyBytes;
    } on TimeoutException {
      throw const ApiException(
        'Server terlalu lama merespons. Periksa koneksi lalu coba lagi.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa alamat API dan koneksi jaringan.',
      );
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, Object?> body = const {},
    String? token,
  }) {
    return _send(
      _client.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers(token, hasBody: true),
        body: jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, Object?> body = const {},
    String? token,
  }) {
    return _send(
      _client.put(
        Uri.parse('$baseUrl$path'),
        headers: _headers(token, hasBody: true),
        body: jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> delete(String path, {String? token}) {
    return _send(
      _client.delete(Uri.parse('$baseUrl$path'), headers: _headers(token)),
    );
  }

  Map<String, String> _headers(String? token, {bool hasBody = false}) {
    return {
      'Accept': 'application/json',
      if (hasBody) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _send(Future<http.Response> request) async {
    try {
      final response = await request.timeout(const Duration(seconds: 20));
      final Object? decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw ApiException(
          'Server mengirim respons yang tidak dapat dibaca.',
          statusCode: response.statusCode,
        );
      }
      if (decoded is! Map<String, dynamic>) {
        throw ApiException(
          'Format respons server tidak sesuai.',
          statusCode: response.statusCode,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _errorMessage(decoded),
          statusCode: response.statusCode,
        );
      }
      return decoded;
    } on TimeoutException {
      throw const ApiException(
        'Server terlalu lama merespons. Periksa koneksi lalu coba lagi.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa alamat API dan koneksi jaringan.',
      );
    }
  }

  String _errorMessage(Map<String, dynamic> response) {
    final message = response['message'];
    if (message is String && message.isNotEmpty) {
      final errors = response['errors'];
      if (errors is Map<String, dynamic>) {
        final firstError = errors.values
            .whereType<List<dynamic>>()
            .expand((messages) => messages)
            .whereType<String>()
            .firstOrNull;
        if (firstError != null) return firstError;
      }
      return message;
    }
    return 'Permintaan gagal. Silakan coba lagi.';
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
