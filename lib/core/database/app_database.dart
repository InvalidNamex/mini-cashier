import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';
import 'users_dao.dart';
import 'categories_dao.dart';
import 'items_dao.dart';
import 'orders_dao.dart';
import 'license_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Users, Categories, Items, Orders, OrderItems, AppLicenses],
  daos: [UsersDao, CategoriesDao, ItemsDao, OrdersDao, LicenseDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

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
          if (from < 3) {
            await m.createTable(appLicenses);
          }
          if (from < 4) {
            await m.addColumn(appLicenses, appLicenses.signature);
          }
        },
      );

  Future<void> _seedAdmin() async {
    // SHA-256 of 'Pass123'
    const hash =
        '08fa299aecc0c034e037033e3b0bbfaef26b78c742f16cf88ac3194502d6c394';
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
