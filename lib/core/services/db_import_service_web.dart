import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:drift/drift.dart';
import '../database/app_database.dart';

class DbImportService {
  /// Opens a browser file picker, parses the JSON backup, and restores the
  /// database. Returns null on success, or an Arabic error string on failure.
  static Future<String?> importFromFile(AppDatabase db) async {
    // Trigger file picker
    final input = html.FileUploadInputElement()
      ..accept = '.json,application/json'
      ..style.display = 'none';
    html.document.body!.append(input);
    input.click();
    await input.onChange.first;
    input.remove();

    final file = input.files?.firstOrNull;
    if (file == null) return 'لم يتم اختيار ملف';

    final reader = html.FileReader();
    reader.readAsText(file);
    await reader.onLoad.first;

    Map<String, dynamic> data;
    try {
      data = jsonDecode(reader.result as String) as Map<String, dynamic>;
    } catch (_) {
      return 'صيغة الملف غير صحيحة';
    }

    try {
      await db.transaction(() async {
        // Delete in reverse FK order
        await db.delete(db.orderItems).go();
        await db.delete(db.orders).go();
        await db.delete(db.items).go();
        await db.delete(db.categories).go();
        await db.delete(db.users).go();
        await db.delete(db.appLicenses).go();

        // Users
        for (final u in (data['users'] as List? ?? [])) {
          await db.into(db.users).insert(UsersCompanion(
            id: Value((u['id'] as num).toInt()),
            username: Value(u['username'] as String),
            passwordHash: Value(u['password_hash'] as String),
            isAdmin: Value(u['is_admin'] as bool),
          ));
        }

        // Categories
        for (final c in (data['categories'] as List? ?? [])) {
          await db.into(db.categories).insert(CategoriesCompanion(
            id: Value((c['id'] as num).toInt()),
            name: Value(c['name'] as String),
          ));
        }

        // Items
        for (final i in (data['items'] as List? ?? [])) {
          await db.into(db.items).insert(ItemsCompanion(
            id: Value((i['id'] as num).toInt()),
            categoryId: Value((i['category_id'] as num).toInt()),
            name: Value(i['name'] as String),
            price: Value((i['price'] as num).toDouble()),
          ));
        }

        // Orders
        for (final o in (data['orders'] as List? ?? [])) {
          await db.into(db.orders).insert(OrdersCompanion(
            id: Value((o['id'] as num).toInt()),
            cashierId: Value((o['cashier_id'] as num).toInt()),
            createdAt: Value(DateTime.parse(o['created_at'] as String)),
            status: Value(o['status'] as String),
            total: Value((o['total'] as num).toDouble()),
            notes: Value(o['notes'] as String?),
          ));
        }

        // Order items
        for (final oi in (data['order_items'] as List? ?? [])) {
          await db.into(db.orderItems).insert(OrderItemsCompanion(
            id: Value((oi['id'] as num).toInt()),
            orderId: Value((oi['order_id'] as num).toInt()),
            itemId: Value((oi['item_id'] as num).toInt()),
            itemNameSnapshot: Value(oi['item_name_snapshot'] as String),
            unitPriceSnapshot:
                Value((oi['unit_price_snapshot'] as num).toDouble()),
            quantity: Value((oi['quantity'] as num).toInt()),
            note: Value(oi['note'] as String?),
          ));
        }
      });

      // Re-create license with a fresh valid signature (outside the transaction
      // so LicenseDao can use its own delete + insert logic).
      final licenseList = data['license'] as List? ?? [];
      if (licenseList.isNotEmpty) {
        final l = licenseList.first as Map<String, dynamic>;
        final mode = l['mode'] as String?;
        if (mode == 'infinite') {
          await db.licenseDao.setInfinite();
        } else if (mode == 'trial') {
          final expiresStr = l['trial_expires_at'] as String?;
          if (expiresStr != null) {
            await db.licenseDao
                .setTrialWithExpiry(DateTime.parse(expiresStr));
          }
        }
      }

      return null; // success
    } catch (e) {
      return 'خطأ أثناء الاستيراد: $e';
    }
  }
}
