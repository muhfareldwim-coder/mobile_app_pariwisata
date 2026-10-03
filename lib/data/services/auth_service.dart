import '../models/user.dart';

class AuthService {
  static User? currentUser;

  Future<User?> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) return null;
    final normalizedEmail = email.trim().toLowerCase();
    currentUser = User(
      id: 'local-user',
      name: _nameFromEmail(normalizedEmail),
      email: normalizedEmail,
      username: normalizedEmail.split('@').first.replaceAll('.', ''),
      phone: User.sample.phone,
    );
    return currentUser;
  }

  Future<User> register(String name, String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final user = User(
      id: 'local-user',
      name: name.trim(),
      email: normalizedEmail,
      username: name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ''),
      phone: User.sample.phone,
    );
    currentUser = user;
    return user;
  }

  static void logout() {
    currentUser = null;
  }

  static String _nameFromEmail(String email) {
    final localPart = email.split('@').first;
    final words = localPart
        .split(RegExp(r'[._-]+'))
        .where((word) => word.isNotEmpty);
    return words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
