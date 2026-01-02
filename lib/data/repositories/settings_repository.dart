import 'package:drift/drift.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/page_key.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';

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

  /// Convert a profile row to AppSettings.
  /// The TypeConverter already handles JSON deserialization.
  AppSettings _fromRow(UserProfileTableData row) {
    talker.repositoryLog(
      'Settings',
      '_fromRow: settings type=${row.settings.runtimeType}',
    );
    try {
      // TypeConverter.json2 already deserializes to AppSettings
      final result = row.settings;
      talker.repositoryLog('Settings', '_fromRow: success');
      return result;
    } catch (e, st) {
      talker.databaseError('Settings._fromRow', e, st);
      rethrow;
    }
  }

  /// Watch database for settings changes.
  /// Pattern aligned with other repositories - direct stream mapping.
  Stream<AppSettings> _watchDatabase() {
    talker.repositoryLog('Settings', '_watchDatabase called');
    return _profileStream.map((rows) {
      talker.repositoryLog(
        'Settings',
        '_watchDatabase stream emission: ${rows.length} rows',
      );
      if (rows.isEmpty) {
        talker.repositoryLog(
          'Settings',
          '_watchDatabase: no rows, returning defaults',
        );
        return _defaultSettings;
      }
      // Find the latest row by updatedAt
      final latest = rows.reduce(
        (a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b,
      );
      talker.repositoryLog(
        'Settings',
        '_watchDatabase: found latest row id=${latest.id}',
      );
      return _fromRow(latest);
    });
  }

  /// Save settings to database.
  /// TypeConverter.json2 handles JSON serialization automatically.
  Future<void> _saveToDatabase(AppSettings settings) async {
    final now = DateTime.now();
    final existing = await _selectProfile();

    if (existing == null) {
      await driftDb
          .into(driftDb.userProfileTable)
          .insert(
            UserProfileTableCompanion.insert(
              settings: settings,
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
        settings: Value(settings),
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

  // Screen Preferences (for system screen sortOrder/isActive)
  @override
  Stream<ScreenPreferences> watchScreenPreferences(String screenKey) {
    return _watchDatabase()
        .map((appSettings) => appSettings.screenPreferencesFor(screenKey))
        .distinct();
  }

  @override
  Future<ScreenPreferences> loadScreenPreferences(String screenKey) async {
    final settings = await loadAll();
    return settings.screenPreferencesFor(screenKey);
  }

  @override
  Future<void> saveScreenPreferences(
    String screenKey,
    ScreenPreferences preferences,
  ) async {
    final current = await loadAll();
    final updated = current.upsertScreenPreferences(
      screenKey: screenKey,
      preferences: preferences,
    );
    await _saveToDatabase(updated);
  }

  @override
  Stream<Map<String, ScreenPreferences>> watchAllScreenPreferences() {
    return _watchDatabase().map((appSettings) => appSettings.screenPreferences);
  }

  // Allocation Settings
  @override
  Stream<AllocationSettings> watchAllocationSettings() {
    return _watchDatabase()
        .map((appSettings) => appSettings.allocation)
        .distinct();
  }

  @override
  Future<AllocationSettings> loadAllocationSettings() async {
    final settings = await loadAll();
    return settings.allocation;
  }

  @override
  Future<void> saveAllocationSettings(AllocationSettings settings) async {
    final current = await loadAll();
    final updated = current.updateAllocation(settings);
    await _saveToDatabase(updated);
  }

  // Value Ranking
  @override
  Stream<ValueRanking> watchValueRanking() {
    return _watchDatabase()
        .map((appSettings) => appSettings.valueRanking)
        .distinct();
  }

  @override
  Future<ValueRanking> loadValueRanking() async {
    final settings = await loadAll();
    return settings.valueRanking;
  }

  @override
  Future<void> saveValueRanking(ValueRanking ranking) async {
    final current = await loadAll();
    final updated = current.updateValueRanking(ranking);
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
