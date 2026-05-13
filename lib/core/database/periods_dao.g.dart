// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'periods_dao.dart';

// ignore_for_file: type=lint
mixin _$PeriodsDaoMixin on DatabaseAccessor<AppDatabase> {
  $PeriodsTable get periods => attachedDatabase.periods;
  $UsersTable get users => attachedDatabase.users;
  $OrdersTable get orders => attachedDatabase.orders;
  $CategoriesTable get categories => attachedDatabase.categories;
  $ItemsTable get items => attachedDatabase.items;
  $OrderItemsTable get orderItems => attachedDatabase.orderItems;
  PeriodsDaoManager get managers => PeriodsDaoManager(this);
}

class PeriodsDaoManager {
  final _$PeriodsDaoMixin _db;
  PeriodsDaoManager(this._db);
  $$PeriodsTableTableManager get periods =>
      $$PeriodsTableTableManager(_db.attachedDatabase, _db.periods);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db.attachedDatabase, _db.orders);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db.attachedDatabase, _db.items);
  $$OrderItemsTableTableManager get orderItems =>
      $$OrderItemsTableTableManager(_db.attachedDatabase, _db.orderItems);
}
