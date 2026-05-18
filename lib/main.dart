import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'core/database/app_database.dart';
import 'app.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    windowManager.waitUntilReadyToShow(
      const WindowOptions(titleBarStyle: TitleBarStyle.normal),
      () async {
        await windowManager.setPreventClose(true);
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  final db = AppDatabase();
  runApp(CashierApp(db: db));
}
