// Web implementation — used only when compiled for the browser.
// sqflite_common_ffi_web requires us to set the global factory
// before any openDatabase / getDatabasesPath call.

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> setupDatabase() async {
  databaseFactory = databaseFactoryFfiWeb;
}
