import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../../core/database/app_database.dart';

class DbExportService {
  /// Serialises all database tables to JSON and triggers a browser download.
  static Future<void> exportToFile(AppDatabase db) async {
    final categories = await db.select(db.categories).get();
    final items = await db.select(db.items).get();
    final users = await db.select(db.users).get();
    final orders = await db.select(db.orders).get();
    final orderItems = await db.select(db.orderItems).get();
    final licenses = await db.select(db.appLicenses).get();

    final payload = {
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'categories': categories
          .map((c) => {'id': c.id, 'name': c.name})
          .toList(),
      'items': items
          .map((i) => {
                'id': i.id,
                'category_id': i.categoryId,
                'name': i.name,
                'price': i.price,
              })
          .toList(),
      'users': users
          .map((u) => {
                'id': u.id,
                'username': u.username,
                'password_hash': u.passwordHash,
                'is_admin': u.isAdmin,
              })
          .toList(),
      'orders': orders
          .map((o) => {
                'id': o.id,
                'cashier_id': o.cashierId,
                'created_at': o.createdAt.toIso8601String(),
                'status': o.status,
                'total': o.total,
                'notes': o.notes,
              })
          .toList(),
      'order_items': orderItems
          .map((oi) => {
                'id': oi.id,
                'order_id': oi.orderId,
                'item_id': oi.itemId,
                'item_name_snapshot': oi.itemNameSnapshot,
                'unit_price_snapshot': oi.unitPriceSnapshot,
                'quantity': oi.quantity,
                'note': oi.note,
              })
          .toList(),
      'license': licenses
          .map((l) => {
                'mode': l.mode,
                'trial_expires_at': l.trialExpiresAt?.toIso8601String(),
                'updated_at': l.updatedAt.toIso8601String(),
              })
          .toList(),
    };

    final jsonBytes = utf8.encode(jsonEncode(payload));
    final blob = html.Blob([jsonBytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-')
        .substring(0, 19);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'cashier_backup_$timestamp.json')
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
