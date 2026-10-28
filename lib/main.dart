import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'data/expense_repository.dart';
import 'state/expense_controller.dart';
import 'ui/app_theme.dart';
import 'ui/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) databaseFactory = databaseFactoryFfiWeb;
  final repository = ExpenseRepository();
  await repository.open();
  final controller = ExpenseController(repository);
  await controller.initialise();
  runApp(EmberLedgerApp(controller: controller));
}

class EmberLedgerApp extends StatelessWidget {
  const EmberLedgerApp({super.key, required this.controller});

  final ExpenseController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Ember Ledger',
        debugShowCheckedModeBanner: false,
        theme: appTheme(),
        home: HomeScreen(controller: controller),
      );
}
