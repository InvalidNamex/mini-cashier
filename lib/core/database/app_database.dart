import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'tables.dart';
import 'users_dao.dart';
import 'categories_dao.dart';
import 'items_dao.dart';
import 'orders_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Users, Categories, Items, Orders, OrderItems],
  daos: [UsersDao, CategoriesDao, ItemsDao, OrdersDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedAdmin();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(orders, orders.notes);
            await m.addColumn(orderItems, orderItems.note);
          }
        },
      );

  Future<void> _seedAdmin() async {
    final hash = sha256.convert(utf8.encode('Pass123')).toString();
    await into(users).insert(UsersCompanion.insert(
      username: 'admin',
      passwordHash: hash,
      isAdmin: const Value(true),
    ));
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'cashier_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  }
}
