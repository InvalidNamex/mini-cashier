import 'package:drift/drift.dart';
import 'app_database.dart';
import 'tables.dart';

part 'periods_dao.g.dart';

@DriftAccessor(tables: [Periods, Orders, OrderItems, Items, Categories])
class PeriodsDao extends DatabaseAccessor<AppDatabase>
    with _$PeriodsDaoMixin {
  PeriodsDao(super.db);

  /// Returns the currently open period (no end_timestamp), or null.
  Future<Period?> getOpenPeriod() =>
      (select(periods)..where((p) => p.endTimestamp.isNull()))
          .getSingleOrNull();

  /// Starts a new period and returns its id.
  Future<int> createPeriod() =>
      into(periods).insert(const PeriodsCompanion());

  /// Sets the end timestamp on a period, closing it.
  Future<bool> closePeriod(int id) =>
      (update(periods)..where((p) => p.id.equals(id)))
          .write(PeriodsCompanion(endTimestamp: Value(DateTime.now())))
          .then((r) => r > 0);

  /// Returns the closed period row.
  Future<Period?> getPeriod(int id) =>
      (select(periods)..where((p) => p.id.equals(id))).getSingleOrNull();

  /// Revenue grouped by category for all paid orders in the given period.
  Future<List<Map<String, dynamic>>> revenueByCategoryForPeriod(
      int periodId) async {
    final periodOrders = await (select(orders)
          ..where((o) =>
              o.periodId.equals(periodId) & o.status.equals('paid')))
        .get();

    final Map<int, Map<String, dynamic>> byCategory = {};

    for (final order in periodOrders) {
      final ois = await (select(orderItems)
            ..where((oi) => oi.orderId.equals(order.id)))
          .get();
      for (final oi in ois) {
        final item = await (select(items)
              ..where((i) => i.id.equals(oi.itemId)))
            .getSingleOrNull();
        if (item == null) continue;
        final cat = await (select(categories)
              ..where((c) => c.id.equals(item.categoryId)))
            .getSingleOrNull();
        if (cat == null) continue;
        final revenue = oi.unitPriceSnapshot * oi.quantity;
        byCategory.update(
          cat.id,
          (v) {
            v['revenue'] = (v['revenue'] as double) + revenue;
            return v;
          },
          ifAbsent: () =>
              {'categoryName': cat.name, 'revenue': revenue, 'catId': cat.id},
        );
      }
    }
    return byCategory.values.toList()
      ..sort((a, b) =>
          (b['revenue'] as double).compareTo(a['revenue'] as double));
  }
}
