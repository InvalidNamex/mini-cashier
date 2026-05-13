import 'package:drift/drift.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'app_database.dart';
import 'tables.dart';

part 'users_dao.g.dart';

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(super.db);

  Future<User?> findByUsername(String username) {
    return (select(users)..where((u) => u.username.equals(username)))
        .getSingleOrNull();
  }

  Future<User?> authenticate(String username, String password) async {
    final hash = sha256.convert(utf8.encode(password)).toString();
    return (select(users)
          ..where((u) => u.username.equals(username) & u.passwordHash.equals(hash)))
        .getSingleOrNull();
  }

  Future<List<User>> allCashiers() {
    return (select(users)..where((u) => u.isAdmin.equals(false))).get();
  }

  Future<int> createCashier(String username, String password) {
    final hash = sha256.convert(utf8.encode(password)).toString();
    return into(users).insert(UsersCompanion.insert(
      username: username,
      passwordHash: hash,
    ));
  }

  Future<void> updateCashier(int id,
      {required String newUsername, String? newPassword}) {
    final hash = newPassword != null && newPassword.isNotEmpty
        ? sha256.convert(utf8.encode(newPassword)).toString()
        : null;
    return (update(users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(
        username: Value(newUsername.trim()),
        passwordHash: hash != null ? Value(hash) : const Value.absent(),
      ),
    );
  }

  Future<int> deleteCashier(int id) {
    return (delete(users)..where((u) => u.id.equals(id))).go();
  }
}
