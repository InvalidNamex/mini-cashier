import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()();
  TextColumn get passwordHash => text()();
  BoolColumn get isAdmin => boolean().withDefault(const Constant(false))();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class Items extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get name => text()();
  RealColumn get price => real()();
}

class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cashierId => integer().references(Users, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text().withDefault(const Constant('open'))();
  RealColumn get total => real().withDefault(const Constant(0.0))();
  TextColumn get notes => text().nullable()();
}

class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderId => integer().references(Orders, #id)();
  IntColumn get itemId => integer().references(Items, #id)();
  TextColumn get itemNameSnapshot => text()();
  RealColumn get unitPriceSnapshot => real()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get note => text().nullable()();
}

/// Stores the application license / trial status.
/// Only one row should exist at a time.
class AppLicenses extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 'infinite' or 'trial'
  TextColumn get mode => text()();

  /// Non-null when mode == 'trial'; the UTC instant when the trial expires.
  DateTimeColumn get trialExpiresAt => dateTime().nullable()();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// HMAC-SHA256 signature of (mode + trialExpiresAt + updatedAt).
  /// If null or invalid, the record is considered tampered and the app suspends.
  TextColumn get signature => text().nullable()();
}
