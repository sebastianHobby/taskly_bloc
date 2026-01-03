import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/settings_key.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';

/// Repository for managing application settings via [SettingsKey].
///
/// Uses individual database columns for each settings type to enable
/// PowerSync field-level sync (prevents cross-device conflicts).
///
/// ## Architecture
/// Each settings type is stored in its own column:
/// - globalSettings, allocationSettings, softGatesSettings, etc.
/// - Each column syncs independently via PowerSync
/// - Changing one setting type doesn't conflict with others
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

  // =========================================================================
  // Public API (SettingsRepositoryContract)
  // =========================================================================

  @override
  Stream<T> watch<T>(SettingsKey<T> key) {
    return _profileStream.map((rows) {
      final row = _latestRow(rows);
      return _extractValue(key, row);
    }).distinct();
  }

  @override
  Future<T> load<T>(SettingsKey<T> key) async {
    final row = await _selectProfile();
    return _extractValue(key, row);
  }

  @override
  Future<void> save<T>(SettingsKey<T> key, T value) async {
    final profile = await _ensureProfile();
    final companion = _buildCompanion(key, value, profile);
    await (driftDb.update(
      driftDb.userProfileTable,
    )..where((row) => row.id.equals(profile.id))).write(companion);
  }

  // =========================================================================
  // Key dispatch: extract value from row
  // =========================================================================

  T _extractValue<T>(SettingsKey<T> key, UserProfileTableData? row) {
    return switch (key) {
      SettingsKey.global => _globalFromRow(row) as T,
      SettingsKey.allocation => _allocationFromRow(row) as T,
      SettingsKey.softGates => _softGatesFromRow(row) as T,
      SettingsKey.nextActions => _nextActionsFromRow(row) as T,
      SettingsKey.valueRanking => _valueRankingFromRow(row) as T,
      SettingsKey.allScreenPrefs => _allScreenPrefsFromRow(row) as T,
      SettingsKey.all => _rowToAppSettings(row) as T,
      _ => _extractKeyedValue(key, row),
    };
  }

  T _extractKeyedValue<T>(SettingsKey<T> key, UserProfileTableData? row) {
    // Handle keyed keys (pageSort, pageDisplay, screenPrefs)
    final keyedKey = key as dynamic;
    final name = keyedKey.name as String;
    final subKey = keyedKey.subKey as String;

    return switch (name) {
      'pageSort' => _pageSortFromRow(row, subKey) as T,
      'pageDisplay' => _pageDisplayFromRow(row, subKey) as T,
      'screenPrefs' => _screenPrefsFromRow(row, subKey) as T,
      _ => throw ArgumentError('Unknown keyed key: $name'),
    };
  }

  // =========================================================================
  // Key dispatch: build companion for save
  // =========================================================================

  UserProfileTableCompanion _buildCompanion<T>(
    SettingsKey<T> key,
    T value,
    UserProfileTableData profile,
  ) {
    final now = Value(DateTime.now());
    return switch (key) {
      SettingsKey.global => UserProfileTableCompanion(
        globalSettings: Value(jsonEncode((value as GlobalSettings).toJson())),
        updatedAt: now,
      ),
      SettingsKey.allocation => UserProfileTableCompanion(
        allocationSettings: Value(
          jsonEncode((value as AllocationConfig).toJson()),
        ),
        updatedAt: now,
      ),
      SettingsKey.softGates => UserProfileTableCompanion(
        softGatesSettings: Value(
          jsonEncode((value as SoftGatesSettings).toJson()),
        ),
        updatedAt: now,
      ),
      SettingsKey.nextActions => UserProfileTableCompanion(
        nextActionsSettings: Value(
          jsonEncode((value as NextActionsSettings).toJson()),
        ),
        updatedAt: now,
      ),
      SettingsKey.valueRanking => UserProfileTableCompanion(
        valueRanking: Value(jsonEncode((value as ValueRanking).toJson())),
        updatedAt: now,
      ),
      SettingsKey.allScreenPrefs => _buildAllScreenPrefsCompanion(
        value as Map<String, ScreenPreferences>,
        now,
      ),
      SettingsKey.all => throw UnsupportedError(
        'Cannot save full AppSettings; save individual keys instead',
      ),
      _ => _buildKeyedCompanion(key, value, profile, now),
    };
  }

  UserProfileTableCompanion _buildKeyedCompanion<T>(
    SettingsKey<T> key,
    T value,
    UserProfileTableData profile,
    Value<DateTime> now,
  ) {
    final keyedKey = key as dynamic;
    final name = keyedKey.name as String;
    final subKey = keyedKey.subKey as String;

    return switch (name) {
      'pageSort' => _buildPageSortCompanion(
        subKey,
        value as SortPreferences?,
        profile,
        now,
      ),
      'pageDisplay' => _buildPageDisplayCompanion(
        subKey,
        value as PageDisplaySettings,
        profile,
        now,
      ),
      'screenPrefs' => _buildScreenPrefsCompanion(
        subKey,
        value as ScreenPreferences,
        profile,
        now,
      ),
      _ => throw ArgumentError('Unknown keyed key: $name'),
    };
  }

  // =========================================================================
  // Value extractors
  // =========================================================================

  GlobalSettings _globalFromRow(UserProfileTableData? row) {
    if (row == null) return const GlobalSettings();
    return GlobalSettings.fromJson(_parseJson(row.globalSettings));
  }

  AllocationConfig _allocationFromRow(UserProfileTableData? row) {
    if (row == null) return const AllocationConfig();
    return AllocationConfig.fromJson(_parseJson(row.allocationSettings));
  }

  SoftGatesSettings _softGatesFromRow(UserProfileTableData? row) {
    if (row == null) return const SoftGatesSettings();
    return SoftGatesSettings.fromJson(_parseJson(row.softGatesSettings));
  }

  NextActionsSettings _nextActionsFromRow(UserProfileTableData? row) {
    if (row == null) return const NextActionsSettings();
    return NextActionsSettings.fromJson(_parseJson(row.nextActionsSettings));
  }

  ValueRanking _valueRankingFromRow(UserProfileTableData? row) {
    if (row == null) return const ValueRanking();
    return ValueRanking.fromJson(_parseJson(row.valueRanking));
  }

  Map<String, ScreenPreferences> _allScreenPrefsFromRow(
    UserProfileTableData? row,
  ) {
    if (row == null) return {};
    return _parseScreenPreferences(row.screenPreferences);
  }

  SortPreferences? _pageSortFromRow(UserProfileTableData? row, String subKey) {
    if (row == null) return null;
    final prefs = _parsePageSortPreferences(row.pageSortPreferences);
    return prefs[subKey];
  }

  PageDisplaySettings _pageDisplayFromRow(
    UserProfileTableData? row,
    String subKey,
  ) {
    if (row == null) return const PageDisplaySettings();
    final settings = _parsePageDisplaySettings(row.pageDisplaySettings);
    return settings[subKey] ?? const PageDisplaySettings();
  }

  ScreenPreferences _screenPrefsFromRow(
    UserProfileTableData? row,
    String subKey,
  ) {
    if (row == null) return const ScreenPreferences();
    final prefs = _parseScreenPreferences(row.screenPreferences);
    return prefs[subKey] ?? const ScreenPreferences();
  }

  AppSettings _rowToAppSettings(UserProfileTableData? row) {
    if (row == null) return const AppSettings();
    return AppSettings(
      global: GlobalSettings.fromJson(_parseJson(row.globalSettings)),
      allocation: AllocationConfig.fromJson(
        _parseJson(row.allocationSettings),
      ),
      softGates: SoftGatesSettings.fromJson(_parseJson(row.softGatesSettings)),
      nextActions: NextActionsSettings.fromJson(
        _parseJson(row.nextActionsSettings),
      ),
      valueRanking: ValueRanking.fromJson(_parseJson(row.valueRanking)),
      pageSortPreferences: _parsePageSortPreferences(row.pageSortPreferences),
      pageDisplaySettings: _parsePageDisplaySettings(row.pageDisplaySettings),
      screenPreferences: _parseScreenPreferences(row.screenPreferences),
    );
  }

  // =========================================================================
  // Companion builders for keyed settings
  // =========================================================================

  UserProfileTableCompanion _buildPageSortCompanion(
    String subKey,
    SortPreferences? value,
    UserProfileTableData profile,
    Value<DateTime> now,
  ) {
    final current = _parsePageSortPreferences(profile.pageSortPreferences);
    if (value == null) {
      current.remove(subKey);
    } else {
      current[subKey] = value;
    }
    final json = jsonEncode(
      current.map((key, v) => MapEntry(key, v.toJson())),
    );
    return UserProfileTableCompanion(
      pageSortPreferences: Value(json),
      updatedAt: now,
    );
  }

  UserProfileTableCompanion _buildPageDisplayCompanion(
    String subKey,
    PageDisplaySettings value,
    UserProfileTableData profile,
    Value<DateTime> now,
  ) {
    final current = _parsePageDisplaySettings(profile.pageDisplaySettings);
    current[subKey] = value;
    final json = jsonEncode(
      current.map((key, v) => MapEntry(key, v.toJson())),
    );
    return UserProfileTableCompanion(
      pageDisplaySettings: Value(json),
      updatedAt: now,
    );
  }

  UserProfileTableCompanion _buildScreenPrefsCompanion(
    String subKey,
    ScreenPreferences value,
    UserProfileTableData profile,
    Value<DateTime> now,
  ) {
    final current = _parseScreenPreferences(profile.screenPreferences);
    current[subKey] = value;
    final json = jsonEncode(
      current.map((key, v) => MapEntry(key, v.toJson())),
    );
    return UserProfileTableCompanion(
      screenPreferences: Value(json),
      updatedAt: now,
    );
  }

  UserProfileTableCompanion _buildAllScreenPrefsCompanion(
    Map<String, ScreenPreferences> value,
    Value<DateTime> now,
  ) {
    final json = jsonEncode(
      value.map((key, v) => MapEntry(key, v.toJson())),
    );
    return UserProfileTableCompanion(
      screenPreferences: Value(json),
      updatedAt: now,
    );
  }

  // =========================================================================
  // Private helpers
  // =========================================================================

  Stream<List<UserProfileTableData>> get _profileStream =>
      driftDb.select(driftDb.userProfileTable).watch();

  Future<UserProfileTableData?> _selectProfile() {
    final query = driftDb.select(driftDb.userProfileTable)
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  UserProfileTableData? _latestRow(List<UserProfileTableData> rows) {
    if (rows.isEmpty) return null;
    return rows.reduce((a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b);
  }

  Map<String, dynamic> _parseJson(String json) {
    try {
      final parsed = jsonDecode(json);
      return parsed is Map<String, dynamic> ? parsed : {};
    } catch (e) {
      talker.repositoryLog('Settings', '_parseJson error: $e');
      return {};
    }
  }

  Future<UserProfileTableData> _ensureProfile() async {
    final existing = await _selectProfile();
    if (existing != null) return existing;

    final now = DateTime.now();
    await driftDb
        .into(driftDb.userProfileTable)
        .insert(
          UserProfileTableCompanion.insert(
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return (await _selectProfile())!;
  }

  Map<String, SortPreferences> _parsePageSortPreferences(String json) {
    final map = _parseJson(json);
    return map.map(
      (key, value) => MapEntry(
        key,
        SortPreferences.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  Map<String, PageDisplaySettings> _parsePageDisplaySettings(String json) {
    final map = _parseJson(json);
    return map.map(
      (key, value) => MapEntry(
        key,
        PageDisplaySettings.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  Map<String, ScreenPreferences> _parseScreenPreferences(String json) {
    final map = _parseJson(json);
    return map.map(
      (key, value) => MapEntry(
        key,
        ScreenPreferences.fromJson(value as Map<String, dynamic>),
      ),
    );
  }
}
