import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/settings.dart';

class SettingsRepository implements SettingsRepositoryContract {
  SettingsRepository({required this.driftDb});

  final AppDatabase driftDb;

  static const AppSettings _defaultSettings = AppSettings();

  Future<UserProfileTableData?> _selectProfile() {
    final query = driftDb.select(driftDb.userProfileTable)
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  AppSettings _fromRow(UserProfileTableData row) {
    try {
      final decoded = jsonDecode(row.settings) as Map<String, dynamic>;
      return AppSettings.fromJson(decoded);
    } catch (_) {
      return _defaultSettings;
    }
  }

  @override
  Stream<AppSettings> watch() {
    final query = driftDb.select(driftDb.userProfileTable)
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
      ..limit(1);
    return query.watch().map((rows) {
      if (rows.isEmpty) return _defaultSettings;
      return _fromRow(rows.first);
    });
  }

  @override
  Future<AppSettings> load() async {
    final row = await _selectProfile();
    if (row == null) {
      await driftDb
          .into(driftDb.userProfileTable)
          .insert(
            UserProfileTableCompanion.insert(
              settings: jsonEncode(_defaultSettings.toJson()),
            ),
          );
      return _defaultSettings;
    }
    return _fromRow(row);
  }

  @override
  Future<void> save(AppSettings settings) async {
    final now = DateTime.now();
    final settingsJson = jsonEncode(settings.toJson());
    final existing = await _selectProfile();

    if (existing == null) {
      await driftDb
          .into(driftDb.userProfileTable)
          .insert(
            UserProfileTableCompanion.insert(
              settings: settingsJson,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      return;
    }

    await (driftDb.update(
      driftDb.userProfileTable,
    )..where((row) => row.id.equals(existing.id))).write(
      UserProfileTableCompanion(
        settings: Value(settingsJson),
        updatedAt: Value(now),
      ),
    );
  }
}
