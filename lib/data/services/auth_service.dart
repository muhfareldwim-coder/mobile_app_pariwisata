import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  AuthService({ApiService? api, FlutterSecureStorage? storage})
    : _api = api ?? ApiService(),
      _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'jembergo_access_token';
  static const _userKey = 'jembergo_user';
  static User? currentUser;
  static String? _accessToken;
  static String? get accessToken => _accessToken;

  final ApiService _api;
  final FlutterSecureStorage _storage;

  static Future<void> restoreSession() async {
    const storage = FlutterSecureStorage();
    final values = await Future.wait([
      storage.read(key: _tokenKey),
      storage.read(key: _userKey),
    ]);
    final token = values[0];
    final encodedUser = values[1];
    if (token == null || encodedUser == null) {
      await _clearStoredSession(storage);
      return;
    }

    final decodedUser = jsonDecode(encodedUser);
    if (decodedUser is! Map<String, dynamic>) {
      throw const FormatException('Data akun tersimpan tidak valid.');
    }
    currentUser = User.fromJson(decodedUser);
    _accessToken = token;
  }

  Future<User> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    final response = await _api.post(
      '/auth/login',
      body: {
        'email': email.trim().toLowerCase(),
        'password': password,
        'device_name': AppConstants.appName,
      },
    );
    return _setSession(response, rememberMe: rememberMe);
  }

  Future<String> googleSignInServerClientId() async {
    final response = await _api.get('/auth/google/config');
    final data = response['data'];
    if (data is! Map<String, dynamic> || data['server_client_id'] is! String) {
      throw const FormatException(
        'Konfigurasi login Google dari server tidak lengkap.',
      );
    }
    return data['server_client_id'] as String;
  }

  Future<User> loginWithGoogleIdToken(
    String idToken, {
    bool rememberMe = true,
  }) async {
    final response = await _api.post(
      '/auth/google',
      body: {'id_token': idToken, 'device_name': AppConstants.appName},
    );
    return _setSession(response, rememberMe: rememberMe);
  }

  Future<User> register(
    String name,
    String email,
    String phone,
    String password,
  ) async {
    final response = await _api.post(
      '/auth/register',
      body: {
        'nama': name.trim(),
        'email': email.trim().toLowerCase(),
        'no_hp': phone.trim(),
        'password': password,
        'device_name': AppConstants.appName,
      },
    );
    return _setSession(response, rememberMe: true);
  }

  Future<void> logoutFromServer() async {
    final user = currentUser;
    final token = _accessToken;
    if (user != null && token != null) {
      final route = user.role == 'ADMIN_PARIWISATA'
          ? '/admin/auth/token'
          : '/customer/auth/token';
      try {
        await _api.delete(route, token: token);
      } on ApiException catch (error) {
        if (error.statusCode != 401) rethrow;
      }
    }
    await _clearStoredSession(_storage);
    _accessToken = null;
    currentUser = null;
  }

  static void logout() {
    _accessToken = null;
    currentUser = null;
  }

  Future<User> _setSession(
    Map<String, dynamic> response, {
    required bool rememberMe,
  }) async {
    final data = response['data'];
    if (data is! Map<String, dynamic> ||
        data['token'] is! String ||
        data['user'] is! Map<String, dynamic>) {
      throw const FormatException('Respons autentikasi server tidak lengkap.');
    }

    final token = data['token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);

    if (rememberMe) {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    } else {
      await _clearStoredSession(_storage);
    }
    _accessToken = token;
    currentUser = user;
    return user;
  }

  static Future<void> _clearStoredSession(FlutterSecureStorage storage) async {
    await storage.delete(key: _tokenKey);
    await storage.delete(key: _userKey);
  }
}
