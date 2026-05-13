import 'package:flutter/material.dart';
import 'core/database/app_database.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  
  runApp(CashierApp(db: db));
}
