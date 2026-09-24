import '../models/user.dart';

class AuthService {
  Future<User?> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) return null;
    return User(id: 'local-user', name: 'Pengguna JemberGo', email: email);
  }

  Future<User> register(String name, String email, String password) async {
    return User(id: 'local-user', name: name, email: email);
  }
}