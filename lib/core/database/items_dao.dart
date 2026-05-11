import 'package:drift/drift.dart';
import 'app_database.dart';
import 'tables.dart';

part 'items_dao.g.dart';

@DriftAccessor(tables: [Items, Categories])
class ItemsDao extends DatabaseAccessor<AppDatabase> with _$ItemsDaoMixin {
  ItemsDao(super.db);

  Future<List<Item>> allItems() => select(items).get();

  Stream<List<Item>> watchItems() => select(items).watch();

  Future<List<Item>> itemsByCategory(int categoryId) =>
      (select(items)..where((i) => i.categoryId.equals(categoryId))).get();

  Stream<List<Item>> watchItemsByCategory(int categoryId) =>
      (select(items)..where((i) => i.categoryId.equals(categoryId))).watch();

  Future<int> addItem(int categoryId, String name, double price) =>
      into(items).insert(ItemsCompanion.insert(
        categoryId: categoryId,
        name: name,
        price: price,
      ));

  Future<bool> updateItem(int id, int categoryId, String name, double price) =>
      (update(items)..where((i) => i.id.equals(id)))
          .write(ItemsCompanion(
            categoryId: Value(categoryId),
            name: Value(name),
            price: Value(price),
          ))
          .then((rows) => rows > 0);

  Future<int> deleteItem(int id) =>
      (delete(items)..where((i) => i.id.equals(id))).go();
}
