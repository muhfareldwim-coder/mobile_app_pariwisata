import 'package:sqflite/sqflite.dart';

import '../models/user.dart';

abstract interface class AuthUserCache {
  Future<User?> read();
  Future<void> write(User user);
  Future<void> clear();
}

class SqliteAuthUserCache implements AuthUserCache {
  const SqliteAuthUserCache();

  static const _tableName = 'cached_auth_user';
  static Future<Database>? _databaseFuture;

  Future<Database> get _database => _databaseFuture ??= _openDatabase();

  Future<Database> _openDatabase() async {
    final databasesPath = await getDatabasesPath();
    return openDatabase(
      '$databasesPath/jembergo_auth.db',
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            nama TEXT NOT NULL,
            email TEXT NOT NULL,
            no_hp TEXT NOT NULL,
            role TEXT NOT NULL
          )
        ''');
      },
    );
  }

  @override
  Future<User?> read() async {
    final database = await _database;
    final rows = await database.query(_tableName, limit: 1);
    if (rows.isEmpty) return null;
    return User.fromJson(Map<String, dynamic>.from(rows.first));
  }

  @override
  Future<void> write(User user) async {
    final database = await _database;
    await database.transaction((transaction) async {
      await transaction.delete(_tableName);
      await transaction.insert(_tableName, user.toJson());
    });
  }

  @override
  Future<void> clear() async {
    final database = await _database;
    await database.delete(_tableName);
  }
}
