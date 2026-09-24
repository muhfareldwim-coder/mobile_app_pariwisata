import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Profil')), body: const ListTile(leading: CircleAvatar(child: Icon(Icons.person)), title: Text('Pengguna JemberGo'), subtitle: Text('Kelola akun kamu')));
  }
}