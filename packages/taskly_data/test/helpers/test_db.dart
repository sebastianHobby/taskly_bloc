import 'package:drift/native.dart';
import 'package:taskly_data/db.dart';

import 'test_imports.dart';

AppDatabase createInMemoryDb() => AppDatabase(NativeDatabase.memory());

AppDatabase createAutoClosingDb() {
  return autoTearDown(createInMemoryDb(), (db) async => db.close());
}
