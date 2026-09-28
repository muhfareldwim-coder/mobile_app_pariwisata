import '../models/user.dart';

class AuthService {
  static final Map<String, String> _passwordsByEmail = {};

  Future<User?> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) return null;
    final normalizedEmail = email.trim().toLowerCase();
    final savedPassword = _passwordsByEmail[normalizedEmail];
    if (savedPassword != null && savedPassword != password) return null;
    _passwordsByEmail.putIfAbsent(normalizedEmail, () => password);
    final emailName = email
        .split('@')
        .first
        .split(RegExp(r'[._-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
    return User(id: 'local-user', name: emailName, email: email);
  }

  Future<User> register(String name, String email, String password) async {
    _passwordsByEmail[email.trim().toLowerCase()] = password;
    return User(id: 'local-user', name: name, email: email);
  }

  Future<bool> changePassword(
    String email,
    String currentPassword,
    String newPassword,
  ) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (_passwordsByEmail[normalizedEmail] != currentPassword) return false;
    _passwordsByEmail[normalizedEmail] = newPassword;
    return true;
  }
}