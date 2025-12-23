import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/settings.dart';

/// Repository for managing feature-specific application settings.
///
/// Provides granular access to settings by feature, while managing
/// persistence of the full settings document internally.
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

  /// Watch database for settings changes
  Stream<AppSettings> _watchDatabase() async* {
    // First emit current state from database
    final profile = await _selectProfile();
    if (profile != null) {
      yield _fromRow(profile);
    } else {
      yield _defaultSettings;
    }

    // Then watch for changes
    await for (final profile
        in driftDb.select(driftDb.userProfileTable).watch()) {
      if (profile.isEmpty) {
        yield _defaultSettings;
      } else {
        final latest = profile.reduce(
          (a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b,
        );
        yield _fromRow(latest);
      }
    }
  }

  /// Save settings to database
  Future<void> _saveToDatabase(AppSettings settings) async {
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

  // Next Actions Settings
  @override
  Stream<NextActionsSettings> watchNextActionsSettings() {
    return _watchDatabase()
        .map((appSettings) => appSettings.nextActions)
        .distinct();
  }

  @override
  Future<NextActionsSettings> loadNextActionsSettings() async {
    final settings = await loadAll();
    return settings.nextActions;
  }

  @override
  Future<void> saveNextActionsSettings(NextActionsSettings settings) async {
    final current = await loadAll();
    final updated = current.updateNextActions(settings);
    await _saveToDatabase(updated);
  }

  // Page Sort Preferences
  @override
  Stream<SortPreferences?> watchPageSort(String pageKey) {
    return _watchDatabase()
        .map((appSettings) => appSettings.sortFor(pageKey))
        .distinct();
  }

  @override
  Future<SortPreferences?> loadPageSort(String pageKey) async {
    final settings = await loadAll();
    return settings.sortFor(pageKey);
  }

  @override
  Future<void> savePageSort(
    String pageKey,
    SortPreferences preferences,
  ) async {
    final current = await loadAll();
    final updated = current.upsertPageSort(
      pageKey: pageKey,
      preferences: preferences,
    );
    await _saveToDatabase(updated);
  }

  // Full settings access (for migration/debugging)
  @override
  Stream<AppSettings> watchAll() => _watchDatabase();

  @override
  Future<AppSettings> loadAll() async {
    final profile = await _selectProfile();
    return profile != null ? _fromRow(profile) : _defaultSettings;
  }
}
