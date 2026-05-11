import 'package:drift/drift.dart';
import 'app_database.dart';
import 'tables.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  Future<List<Category>> allCategories() => select(categories).get();

  Stream<List<Category>> watchCategories() => select(categories).watch();

  Future<int> addCategory(String name) =>
      into(categories).insert(CategoriesCompanion.insert(name: name));

  Future<bool> updateCategory(int id, String name) =>
      (update(categories)..where((c) => c.id.equals(id)))
          .write(CategoriesCompanion(name: Value(name)))
          .then((rows) => rows > 0);

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();
}
