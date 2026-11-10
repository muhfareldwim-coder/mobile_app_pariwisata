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
        if (firstError != null) return _friendlyValidationMessage(firstError);
      }
      return _friendlyValidationMessage(message);
    }
    return 'Permintaan gagal. Silakan coba lagi.';
  }

  String _friendlyValidationMessage(String message) {
    if (message == 'The given data was invalid.') {
      return 'Periksa kembali data yang Anda masukkan.';
    }

    final required = RegExp(
      r'^The (.+) field is required\.$',
      caseSensitive: false,
    ).firstMatch(message);
    if (required != null) {
      final label = _validationFieldLabel(required.group(1)!);
      if (label != null) return '$label wajib diisi.';
    }

    final validEmail = RegExp(
      r'^The (.+) field must be a valid email address\.$',
      caseSensitive: false,
    ).firstMatch(message);
    if (validEmail != null &&
        _validationFieldLabel(validEmail.group(1)!) == 'Email') {
      return 'Masukkan email yang valid.';
    }

    final taken = RegExp(
      r'^The (.+) has already been taken\.$',
      caseSensitive: false,
    ).firstMatch(message);
    if (taken != null) {
      return switch (_validationFieldLabel(taken.group(1)!)) {
        'Email' => 'Alamat email tersebut sudah terdaftar.',
        'Nomor telepon' => 'Nomor telepon tersebut sudah terdaftar.',
        _ => message,
      };
    }

    final invalidFormat = RegExp(
      r'^The (.+) field format is invalid\.$',
      caseSensitive: false,
    ).firstMatch(message);
    if (invalidFormat != null &&
        _validationFieldLabel(invalidFormat.group(1)!) == 'Nomor telepon') {
      return 'Masukkan nomor telepon dengan format yang valid.';
    }

    final minLength = RegExp(
      r'^The (.+) field must be at least (\d+) characters\.$',
      caseSensitive: false,
    ).firstMatch(message);
    if (minLength != null &&
        _validationFieldLabel(minLength.group(1)!) == 'Kata sandi' &&
        minLength.group(2) == '8') {
      return 'Password minimal 8 karakter.';
    }

    final digits = RegExp(
      r'^The (.+) field must be (\d+) digits\.$',
      caseSensitive: false,
    ).firstMatch(message);
    if (digits != null &&
        _validationFieldLabel(digits.group(1)!) == 'Kode OTP' &&
        digits.group(2) == '6') {
      return 'Masukkan kode OTP 6 digit.';
    }

    return message;
  }

  String? _validationFieldLabel(String attribute) {
    return switch (attribute.toLowerCase().replaceAll('_', ' ').trim()) {
      'nama' || 'name' => 'Nama lengkap',
      'email' => 'Email',
      'no hp' || 'phone' || 'phone number' => 'Nomor telepon',
      'password' => 'Kata sandi',
      'otp' => 'Kode OTP',
      _ => null,
    };
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
