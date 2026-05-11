import 'package:drift/drift.dart';
import 'app_database.dart';
import 'tables.dart';

part 'orders_dao.g.dart';

class OrderWithItems {
  final Order order;
  final List<OrderItem> items;
  OrderWithItems(this.order, this.items);
}

@DriftAccessor(tables: [Orders, OrderItems, Users, Items, Categories])
class OrdersDao extends DatabaseAccessor<AppDatabase> with _$OrdersDaoMixin {
  OrdersDao(super.db);

  // --- Orders ---

  Future<int> createOrder(int cashierId) => into(orders).insert(
        OrdersCompanion.insert(cashierId: cashierId),
      );

  Future<List<Order>> openOrders() =>
      (select(orders)..where((o) => o.status.equals('open'))).get();

  Future<bool> updateOrderTotal(int orderId, double total) =>
      (update(orders)..where((o) => o.id.equals(orderId)))
          .write(OrdersCompanion(total: Value(total)))
          .then((r) => r > 0);

  Future<bool> closeOrder(int orderId, double total, {String? notes}) =>
      (update(orders)..where((o) => o.id.equals(orderId)))
          .write(OrdersCompanion(
            status: const Value('paid'),
            total: Value(total),
            notes: Value(notes),
          ))
          .then((r) => r > 0);

  Future<bool> cancelOrder(int orderId) =>
      (update(orders)..where((o) => o.id.equals(orderId)))
          .write(const OrdersCompanion(status: Value('cancelled')))
          .then((r) => r > 0);

  Future<Order?> getOrder(int orderId) =>
      (select(orders)..where((o) => o.id.equals(orderId))).getSingleOrNull();

  // --- Order Items ---

  Future<int> addOrderItem({
    required int orderId,
    required int itemId,
    required String itemNameSnapshot,
    required double unitPriceSnapshot,
    required int quantity,
    String? note,
  }) =>
      into(orderItems).insert(OrderItemsCompanion.insert(
        orderId: orderId,
        itemId: itemId,
        itemNameSnapshot: itemNameSnapshot,
        unitPriceSnapshot: unitPriceSnapshot,
        quantity: Value(quantity),
        note: Value(note),
      ));

  Future<List<OrderItem>> itemsForOrder(int orderId) =>
      (select(orderItems)..where((oi) => oi.orderId.equals(orderId))).get();

  Future<bool> updateOrderItemQty(int orderItemId, int qty) =>
      (update(orderItems)..where((oi) => oi.id.equals(orderItemId)))
          .write(OrderItemsCompanion(quantity: Value(qty)))
          .then((r) => r > 0);

  Future<bool> updateOrderItemNote(int orderItemId, String? note) =>
      (update(orderItems)..where((oi) => oi.id.equals(orderItemId)))
          .write(OrderItemsCompanion(note: Value(note)))
          .then((r) => r > 0);

  Future<int> removeOrderItem(int orderItemId) =>
      (delete(orderItems)..where((oi) => oi.id.equals(orderItemId))).go();

  Future<int> removeAllOrderItems(int orderId) =>
      (delete(orderItems)..where((oi) => oi.orderId.equals(orderId))).go();

  // --- Reports ---

  Future<List<Order>> paidOrdersInRange(DateTime from, DateTime to) {
    final toEnd = DateTime(to.year, to.month, to.day, 23, 59, 59);
    return (select(orders)
          ..where((o) =>
              o.status.equals('paid') &
              o.createdAt.isBiggerOrEqualValue(from) &
              o.createdAt.isSmallerOrEqualValue(toEnd)))
        .get();
  }

  Future<List<OrderWithItems>> paidOrdersWithItemsInRange(
      DateTime from, DateTime to) async {
    final orderList = await paidOrdersInRange(from, to);
    final result = <OrderWithItems>[];
    for (final order in orderList) {
      final ois = await itemsForOrder(order.id);
      result.add(OrderWithItems(order, ois));
    }
    return result;
  }

  // Revenue per category in range
  Future<List<Map<String, dynamic>>> revenueByCategory(
      DateTime from, DateTime to) async {
    final rows = await paidOrdersWithItemsInRange(from, to);
    final Map<int, Map<String, dynamic>> byCategory = {};

    for (final row in rows) {
      for (final oi in row.items) {
        // Get item's category
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
              {'categoryName': cat.name, 'revenue': revenue, 'id': cat.id},
        );
      }
    }
    return byCategory.values.toList();
  }

  // Revenue per item in range
  Future<List<Map<String, dynamic>>> revenueByItem(
      DateTime from, DateTime to) async {
    final rows = await paidOrdersWithItemsInRange(from, to);
    final Map<int, Map<String, dynamic>> byItem = {};

    for (final row in rows) {
      for (final oi in row.items) {
        final revenue = oi.unitPriceSnapshot * oi.quantity;
        byItem.update(
          oi.itemId,
          (v) {
            v['revenue'] = (v['revenue'] as double) + revenue;
            v['quantity'] = (v['quantity'] as int) + oi.quantity;
            return v;
          },
          ifAbsent: () => {
            'itemName': oi.itemNameSnapshot,
            'revenue': revenue,
            'quantity': oi.quantity,
          },
        );
      }
    }
    return byItem.values.toList();
  }

  // Daily totals in range
  Future<List<Map<String, dynamic>>> dailySales(
      DateTime from, DateTime to) async {
    final orders = await paidOrdersInRange(from, to);
    final Map<String, Map<String, dynamic>> byDay = {};
    for (final o in orders) {
      final day =
          '${o.createdAt.year}-${o.createdAt.month.toString().padLeft(2, '0')}-${o.createdAt.day.toString().padLeft(2, '0')}';
      byDay.update(
        day,
        (v) {
          v['total'] = (v['total'] as double) + o.total;
          v['count'] = (v['count'] as int) + 1;
          return v;
        },
        ifAbsent: () => {'day': day, 'total': o.total, 'count': 1},
      );
    }
    final list = byDay.values.toList();
    list.sort((a, b) => (a['day'] as String).compareTo(b['day'] as String));
    return list;
  }
}
