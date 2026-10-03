class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.phone,
  });

  final String id;
  final String name;
  final String email;
  final String username;
  final String phone;

  User copyWith({
    String? name,
    String? email,
    String? username,
    String? phone,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      phone: phone ?? this.phone,
    );
  }

  static const sample = User(
    id: 'sample-customer',
    name: 'Ahmad Pratama',
    email: 'ahmad.pratama@email.com',
    username: 'ahmadpratama',
    phone: '+62 812-3456-7890',
  );
}
