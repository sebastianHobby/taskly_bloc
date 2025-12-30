import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/core/utils/app_logger.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/page_key.dart';

/// Repository for managing feature-specific application settings.
///
/// Provides granular access to settings by feature, while managing
/// persistence of the full settings document internally.
///
/// ## Stream Pattern
/// Uses the standard repository pattern aligned with TaskRepository,
/// ProjectRepository, and LabelRepository:
/// - Direct stream mapping (not async* generators)
/// - Automatic initial value emission from Drift's .watch()
/// - Synchronous transformation of database rows to domain objects
class SettingsRepository implements SettingsRepositoryContract {
  SettingsRepository({required this.driftDb});

  final AppDatabase driftDb;

  static const AppSettings _defaultSettings = AppSettings();

  /// Watch all profile rows ordered by updatedAt desc.
  /// Returns a stream that automatically emits when the table changes.
  Stream<List<UserProfileTableData>> get _profileStream =>
      driftDb.select(driftDb.userProfileTable).watch();

  /// Get the latest profile row by updatedAt, or null if none exists.
  Future<UserProfileTableData?> _selectProfile() {
    final query = driftDb.select(driftDb.userProfileTable)
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  /// Convert a profile row to AppSettings, with fallback on parse errors.
  AppSettings _fromRow(UserProfileTableData row) {
    try {
      final decoded = jsonDecode(row.settings) as Map<String, dynamic>;
      return AppSettings.fromJson(decoded);
    } catch (e, stackTrace) {
      AppLogger.forRepository('Settings').warning(
        'Failed to parse settings JSON, using defaults',
        e,
        stackTrace,
      );
      return _defaultSettings;
    }
  }

  /// Watch database for settings changes.
  /// Pattern aligned with other repositories - direct stream mapping.
  Stream<AppSettings> _watchDatabase() {
    return _profileStream.map((rows) {
      if (rows.isEmpty) {
        return _defaultSettings;
      }
      // Find the latest row by updatedAt
      final latest = rows.reduce(
        (a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b,
      );
      return _fromRow(latest);
    });
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

  // Global Settings
  @override
  Stream<GlobalSettings> watchGlobalSettings() {
    return _watchDatabase().map((appSettings) => appSettings.global).distinct();
  }

  @override
  Future<GlobalSettings> loadGlobalSettings() async {
    final settings = await loadAll();
    return settings.global;
  }

  @override
  Future<void> saveGlobalSettings(GlobalSettings settings) async {
    final current = await loadAll();
    final updated = current.updateGlobal(settings);
    await _saveToDatabase(updated);
  }

  // Soft Gates Settings
  @override
  Stream<SoftGatesSettings> watchSoftGatesSettings() {
    return _watchDatabase()
        .map((appSettings) => appSettings.softGates)
        .distinct();
  }

  @override
  Future<SoftGatesSettings> loadSoftGatesSettings() async {
    final settings = await loadAll();
    return settings.softGates;
  }

  @override
  Future<void> saveSoftGatesSettings(SoftGatesSettings settings) async {
    final current = await loadAll();
    final updated = current.updateSoftGates(settings);
    await _saveToDatabase(updated);
  }

  // Next Actions Settings
  @override
  Stream<NextActionsSettings> watchNextActionsSettings() {
    // Note: Removed .distinct() - equality issues with complex nested objects
    // (TaskPriorityBucketRule, TaskRuleSet, etc.) caused legitimate updates
    // to be filtered out, preventing settings changes from propagating.
    return _watchDatabase().map((appSettings) => appSettings.nextActions);
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
  Stream<SortPreferences?> watchPageSort(PageKey pageKey) {
    return _watchDatabase()
        .map((appSettings) => appSettings.sortFor(pageKey.key))
        .distinct();
  }

  @override
  Future<SortPreferences?> loadPageSort(PageKey pageKey) async {
    final settings = await loadAll();
    return settings.sortFor(pageKey.key);
  }

  @override
  Future<void> savePageSort(
    PageKey pageKey,
    SortPreferences preferences,
  ) async {
    final current = await loadAll();
    final updated = current.upsertPageSort(
      pageKey: pageKey.key,
      preferences: preferences,
    );
    await _saveToDatabase(updated);
  }

  // Page Display Settings
  @override
  Stream<PageDisplaySettings> watchPageDisplaySettings(PageKey pageKey) {
    return _watchDatabase()
        .map((appSettings) => appSettings.displaySettingsFor(pageKey.key))
        .distinct();
  }

  @override
  Future<PageDisplaySettings> loadPageDisplaySettings(PageKey pageKey) async {
    final settings = await loadAll();
    return settings.displaySettingsFor(pageKey.key);
  }

  @override
  Future<void> savePageDisplaySettings(
    PageKey pageKey,
    PageDisplaySettings settings,
  ) async {
    final current = await loadAll();
    final updated = current.upsertPageDisplaySettings(
      pageKey: pageKey.key,
      settings: settings,
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
