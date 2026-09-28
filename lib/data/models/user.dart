class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.username = '',
    this.phone = '',
  });

  final String id;
  final String name;
  final String email;
  final String username;
  final String phone;
}