class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    required this.phone,
    this.role = 'CUSTOMER',
  });

  final String id;
  final String name;
  final String email;
  final String username;
  final String phone;
  final String role;

  factory User.fromJson(Map<String, dynamic> json) {
    final name = json['nama'];
    final email = json['email'];
    final id = json['id'];
    if (name is! String || email is! String || id == null) {
      throw const FormatException('Data pengguna dari server tidak lengkap.');
    }
    return User(
      id: id.toString(),
      name: name,
      email: email,
      username: email.split('@').first.replaceAll('.', ''),
      phone: json['no_hp'] is String ? json['no_hp'] as String : '',
      role: json['role'] is String ? json['role'] as String : 'CUSTOMER',
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'nama': name,
    'email': email,
    'no_hp': phone,
    'role': role,
  };

  User copyWith({
    String? name,
    String? email,
    String? username,
    String? phone,
    String? role,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      role: role ?? this.role,
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
