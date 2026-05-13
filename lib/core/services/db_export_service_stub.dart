import '../../core/database/app_database.dart';

/// Non-web stub — export is only supported on the web build.
class DbExportService {
  static Future<void> exportToFile(AppDatabase db) async {
    // No-op on non-web platforms.
  }
}
