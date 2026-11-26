import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_constants.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'auth_user_cache.dart';

class AuthService {
  AuthService({
    ApiService? api,
    FlutterSecureStorage? storage,
    AuthSessionStorage? sessionStorage,
    AuthUserCache? userCache,
  }) : _api = api ?? ApiService(),
       _storage =
           sessionStorage ??
           _FlutterSecureStorageSessionStorage(
             storage ?? const FlutterSecureStorage(),
           ),
       _userCache = userCache ?? const SqliteAuthUserCache();

  static const _tokenKey = 'jembergo_access_token';
  static const _legacyUserKey = 'jembergo_user';
  static final ValueNotifier<User?> _currentUser = ValueNotifier(null);
  static User? get currentUser => _currentUser.value;
  static set currentUser(User? user) => _currentUser.value = user;
  static ValueListenable<User?> get currentUserListenable => _currentUser;
  static String? _accessToken;
  static String? get accessToken => _accessToken;
  static bool _rememberSession = false;

  final ApiService _api;
  final AuthSessionStorage _storage;
  final AuthUserCache _userCache;

  static Future<void> restoreSession({
    AuthSessionStorage? sessionStorage,
    AuthUserCache? userCache,
  }) async {
    final storage =
        sessionStorage ??
        _FlutterSecureStorageSessionStorage(const FlutterSecureStorage());
    final profileCache = userCache ?? const SqliteAuthUserCache();
    final token = await storage.read(_tokenKey);
    if (token == null) {
      await _clearStoredSession(storage, profileCache);
      _accessToken = null;
      _rememberSession = false;
      currentUser = null;
      return;
    }

    var user = await profileCache.read();
    final legacyEncodedUser = await storage.read(_legacyUserKey);
    if (user == null && legacyEncodedUser != null) {
      final decodedUser = jsonDecode(legacyEncodedUser);
      if (decodedUser is! Map<String, dynamic>) {
        throw const FormatException('Data akun tersimpan tidak valid.');
      }
      user = User.fromJson(decodedUser);
      await profileCache.write(user);
    }

    if (user == null) {
      await _clearStoredSession(storage, profileCache);
      _accessToken = null;
      _rememberSession = false;
      currentUser = null;
      return;
    }

    await storage.delete(_legacyUserKey);
    currentUser = user;
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

  Future<GoogleLoginResult> loginWithGoogleIdToken(
    String idToken, {
    bool rememberMe = true,
  }) async {
    final response = await _api.post(
      '/auth/google',
      body: {'id_token': idToken, 'device_name': AppConstants.appName},
    );
    final data = response['data'];
    if (data is Map<String, dynamic> && data['purpose'] == 'google') {
      final email = data['email'];
      if (email is! String || email.isEmpty) {
        throw const FormatException(
          'Email untuk verifikasi Google tidak tersedia.',
        );
      }
      return GoogleLoginOtpRequired(email);
    }
    return GoogleLoginSucceeded(
      await _setSession(response, rememberMe: rememberMe),
    );
  }

  Future<void> register(
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
    _requireOtpChallenge(response, 'registration');
  }

  Future<void> verifyRegistrationOtp(String email, String otp) async {
    await _api.post(
      '/auth/register/verify',
      body: {'email': email.trim().toLowerCase(), 'otp': otp.trim()},
    );
  }

  Future<User> verifyGoogleOtp(
    String email,
    String otp, {
    bool rememberMe = true,
  }) async {
    final response = await _api.post(
      '/auth/google/verify',
      body: {
        'email': email.trim().toLowerCase(),
        'otp': otp.trim(),
        'device_name': AppConstants.appName,
      },
    );
    return _setSession(response, rememberMe: rememberMe);
  }

  Future<void> resendOtp(String email, String purpose) async {
    await _api.post(
      '/auth/otp/resend',
      body: {'email': email.trim().toLowerCase(), 'purpose': purpose},
    );
  }

  Future<void> requestPasswordResetOtp(String email) async {
    await _api.post(
      '/auth/password/otp',
      body: {'email': email.trim().toLowerCase()},
    );
  }

  Future<String> verifyPasswordResetOtp(String email, String otp) async {
    final response = await _api.post(
      '/auth/password/otp/verify',
      body: {'email': email.trim().toLowerCase(), 'otp': otp.trim()},
    );
    final data = response['data'];
    if (data is! Map<String, dynamic> || data['reset_token'] is! String) {
      throw const FormatException('Respons verifikasi OTP tidak lengkap.');
    }
    return data['reset_token'] as String;
  }

  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _api.post(
      '/auth/password/reset',
      body: {
        'email': email.trim().toLowerCase(),
        'reset_token': resetToken,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
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
    await _clearStoredSession(_storage, _userCache);
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
      throw const ApiException(
        'Silakan login sebagai customer untuk memuat profil.',
      );
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
      throw const ApiException(
        'Sesi login customer tidak tersedia. Silakan login kembali.',
      );
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
      try {
        await _userCache.write(user);
        await _storage.delete(_legacyUserKey);
      } on Exception {
        await _storage.delete(_tokenKey);
        rethrow;
      }
    } else {
      await _clearStoredSession(_storage, _userCache);
    }
    _rememberSession = rememberMe;
    _accessToken = token;
    currentUser = user;
    return user;
  }

  void _requireOtpChallenge(
    Map<String, dynamic> response,
    String expectedPurpose,
  ) {
    final data = response['data'];
    if (data is! Map<String, dynamic> ||
        data['purpose'] != expectedPurpose ||
        data['email'] is! String) {
      throw const FormatException(
        'Respons verifikasi OTP dari server tidak lengkap.',
      );
    }
  }

  User _profileUserFromResponse(Map<String, dynamic> response, String role) {
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
      await _userCache.write(user);
    } on Exception catch (error) {
      throw ApiException(
        'Profil berhasil disimpan di server, tetapi cache lokal gagal diperbarui: $error',
      );
    }
  }

  static Future<void> _clearStoredSession(
    AuthSessionStorage storage,
    AuthUserCache userCache,
  ) async {
    await storage.delete(_tokenKey);
    await storage.delete(_legacyUserKey);
    await userCache.clear();
  }
}

sealed class GoogleLoginResult {
  const GoogleLoginResult();
}

class GoogleLoginSucceeded extends GoogleLoginResult {
  const GoogleLoginSucceeded(this.user);

  final User user;
}

class GoogleLoginOtpRequired extends GoogleLoginResult {
  const GoogleLoginOtpRequired(this.email);

  final String email;
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
