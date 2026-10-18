import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  AuthService({
    ApiService? api,
    FlutterSecureStorage? storage,
    AuthSessionStorage? sessionStorage,
  })
    : _api = api ?? ApiService(),
      _storage =
          sessionStorage ??
          _FlutterSecureStorageSessionStorage(
            storage ?? const FlutterSecureStorage(),
          );

  static const _tokenKey = 'jembergo_access_token';
  static const _userKey = 'jembergo_user';
  static final ValueNotifier<User?> _currentUser = ValueNotifier(null);
  static User? get currentUser => _currentUser.value;
  static set currentUser(User? user) => _currentUser.value = user;
  static ValueListenable<User?> get currentUserListenable => _currentUser;
  static String? _accessToken;
  static String? get accessToken => _accessToken;
  static bool _rememberSession = false;

  final ApiService _api;
  final AuthSessionStorage _storage;

  static Future<void> restoreSession() async {
    const storage = FlutterSecureStorage();
    final values = await Future.wait([
      storage.read(key: _tokenKey),
      storage.read(key: _userKey),
    ]);
    final token = values[0];
    final encodedUser = values[1];
    if (token == null || encodedUser == null) {
      await _clearStoredSession(
        _FlutterSecureStorageSessionStorage(storage),
      );
      return;
    }

    final decodedUser = jsonDecode(encodedUser);
    if (decodedUser is! Map<String, dynamic>) {
      throw const FormatException('Data akun tersimpan tidak valid.');
    }
    currentUser = User.fromJson(decodedUser);
    _accessToken = token;
    _rememberSession = true;
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
    _rememberSession = false;
    currentUser = null;
  }

  static void logout() {
    _accessToken = null;
    _rememberSession = false;
    currentUser = null;
  }

  Future<User> refreshProfile() async {
    final token = _accessToken;
    final current = currentUser;
    if (token == null || current == null || current.role != 'CUSTOMER') {
      throw const ApiException('Silakan login sebagai customer untuk memuat profil.');
    }

    final response = await _api.get('/customer/profil', token: token);
    final updatedUser = _profileUserFromResponse(response, current.role);
    await _updateCurrentProfile(updatedUser);
    return updatedUser;
  }

  Future<User> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? password,
    String? passwordConfirmation,
  }) async {
    final token = _accessToken;
    final current = currentUser;
    if (token == null || current == null || current.role != 'CUSTOMER') {
      throw const ApiException('Sesi login customer tidak tersedia. Silakan login kembali.');
    }

    final body = <String, Object?>{
      'nama': name.trim(),
      'email': email.trim().toLowerCase(),
      'no_hp': phone.trim().isEmpty ? null : phone.trim(),
      if (password != null && password.isNotEmpty) ...{
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    };
    final response = await _api.put(
      '/customer/profil',
      body: body,
      token: token,
    );
    final updatedUser = _profileUserFromResponse(response, current.role);
    await _updateCurrentProfile(updatedUser);
    return updatedUser;
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
      await _storage.write(_tokenKey, token);
      await _storage.write(_userKey, jsonEncode(user.toJson()));
    } else {
      await _clearStoredSession(_storage);
    }
    _rememberSession = rememberMe;
    _accessToken = token;
    currentUser = user;
    return user;
  }

  User _profileUserFromResponse(
    Map<String, dynamic> response,
    String role,
  ) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Respons profil dari server tidak lengkap.');
    }
    return User.fromJson(data).copyWith(role: role);
  }

  Future<void> _updateCurrentProfile(User user) async {
    currentUser = user;
    if (!_rememberSession) return;
    try {
      await _storage.write(_userKey, jsonEncode(user.toJson()));
    } on Exception catch (error) {
      throw ApiException(
        'Profil berhasil disimpan di server, tetapi sesi lokal gagal diperbarui: $error',
      );
    }
  }

  static Future<void> _clearStoredSession(AuthSessionStorage storage) async {
    await storage.delete(_tokenKey);
    await storage.delete(_userKey);
  }
}

abstract interface class AuthSessionStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class _FlutterSecureStorageSessionStorage implements AuthSessionStorage {
  const _FlutterSecureStorageSessionStorage(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
}
