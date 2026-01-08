import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
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
///
/// ## Sync Bounce Protection
/// This repository uses debouncing to protect against PowerSync CDC "sync bounce".
/// When a save occurs, CDC may rapidly deliver: local echo → stale bounce → fresh.
/// A 250ms debounce ensures we emit only the last (fresh) value after the
/// burst settles. The BLoC's optimistic update provides instant UI feedback,
/// so the debounce delay is invisible to users.
class SettingsRepository implements SettingsRepositoryContract {
  SettingsRepository({required this.driftDb});

  final AppDatabase driftDb;

  /// Debounce duration for sync bounce protection.
  ///
  /// 250ms is sufficient to catch the typical bounce pattern:
  /// - T+0ms: Local echo
  /// - T+50-100ms: CDC bounce (stale)
  /// - T+100-200ms: CDC fresh
  ///
  /// After 250ms of quiet, we emit the last (fresh) value.
  static const _syncBounceDebounce = Duration(milliseconds: 250);

  /// Debug method to dump raw SQL data - helps identify PowerSync sync issues
  Future<void> debugDumpRawProfileData() async {
    talker.repositoryLog(
      'Settings',
      '=== DEBUG: Raw SQL user_profiles dump ===',
    );
    try {
      // Query using raw SQL to bypass Drift mapping
      final results = await driftDb
          .customSelect(
            'SELECT * FROM user_profiles LIMIT 10',
          )
          .get();

      talker.repositoryLog(
        'Settings',
        'Raw SQL returned ${results.length} rows',
      );
      for (var i = 0; i < results.length; i++) {
        final row = results[i].data;
        talker.repositoryLog(
          'Settings',
          'RAW SQL row[$i]: ${row.entries.map((e) => '${e.key}=${e.value ?? "NULL"}').join(', ')}',
        );
      }

      // Also check PowerSync's internal ps_crud table for pending uploads.
      // This table won't exist in unit tests (in-memory DB), so guard it.
      try {
        final psCrudExists = await driftDb
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='ps_crud' LIMIT 1",
            )
            .get();

        if (psCrudExists.isNotEmpty) {
          final crudResults = await driftDb
              .customSelect(
                "SELECT * FROM ps_crud WHERE data LIKE '%user_profiles%' LIMIT 5",
              )
              .get();
          if (crudResults.isNotEmpty) {
            talker.repositoryLog(
              'Settings',
              'ps_crud has ${crudResults.length} pending user_profiles uploads:',
            );
            for (final row in crudResults) {
              talker.repositoryLog(
                'Settings',
                '  PENDING UPLOAD: ${row.data}',
              );
            }
          }
        }
      } catch (_) {
        // Best-effort debug helper; ignore ps_crud issues.
      }
    } catch (e, st) {
      talker.databaseError('[Settings] debugDumpRawProfileData FAILED', e, st);
    }
    talker.repositoryLog('Settings', '=== END DEBUG dump ===');
  }

  // =========================================================================
  // Public API (SettingsRepositoryContract)
  // =========================================================================

  @override
  Stream<T> watch<T>(SettingsKey<T> key) {
    // Debounce protects against CDC sync bounce:
    // After a save, CDC may emit: local echo → stale bounce → fresh value
    // Debouncing ensures we wait for the burst to settle and emit only the
    // final (fresh) value. BLoC optimistic updates provide instant UI feedback.
    return _profileStream.debounceTime(_syncBounceDebounce).map((rows) {
      final row = _latestRow(rows);
      final value = _extractValue(key, row);
      talker.repositoryLog(
        'Settings',
        'watch<$T>: emitting value for key=$key, '
            'rows.length=${rows.length}, '
            'selectedRow.updatedAt=${row?.updatedAt}',
      );
      return value;
    }).distinct();
  }

  @override
  Future<T> load<T>(SettingsKey<T> key) async {
    talker.repositoryLog('Settings', 'load<$T>: key=$key');
    try {
      final row = await _selectProfile();
      talker.repositoryLog(
        'Settings',
        'load<$T>: _selectProfile returned ${row == null ? "null" : "row(id=${row.id})"}',
      );
      final value = _extractValue(key, row);
      talker.repositoryLog(
        'Settings',
        'load<$T>: extracted value successfully',
      );
      return value;
    } catch (e, st) {
      talker.databaseError('[Settings] load<$T> FAILED for key=$key', e, st);
      rethrow;
    }
  }

  @override
  Future<void> save<T>(SettingsKey<T> key, T value) async {
    final saveStartTime = DateTime.now();
    talker.repositoryLog(
      'Settings',
      '[SEQUENCE 1/3] save<$T> START at $saveStartTime\n'
          '  key=$key\n'
          '  value=$value',
    );

    final profile = await _ensureProfile();
    final companion = _buildCompanion(key, value, profile);
    talker.repositoryLog(
      'Settings',
      '[SEQUENCE 2/3] save<$T>: about to write to Drift/SQLite\n'
          '  profile.id=${profile.id}\n'
          '  profile.updatedAt=${profile.updatedAt}\n'
          '  companion will set updatedAt=${DateTime.now().toUtc()}',
    );

    // DRIFT WRITE - this updates local SQLite (owned by PowerSync)
    await (driftDb.update(
      driftDb.userProfileTable,
    )..where((row) => row.id.equals(profile.id))).write(companion);

    final driftWriteTime = DateTime.now();
    talker.repositoryLog(
      'Settings',
      '[SEQUENCE 3/3] save<$T> COMPLETE at $driftWriteTime\n'
          '  Duration: ${driftWriteTime.difference(saveStartTime).inMilliseconds}ms\n'
          '  PowerSync will detect change and trigger upload\n'
          '  Stream debounce will filter any CDC bounce',
    );
  }

  // =========================================================================
  // Key dispatch: extract value from row
  // =========================================================================

  T _extractValue<T>(SettingsKey<T> key, UserProfileTableData? row) {
    return switch (key) {
      SettingsKey.global => _globalFromRow(row) as T,
      SettingsKey.allocation => _allocationFromRow(row) as T,
      SettingsKey.all => _rowToAppSettings(row) as T,
      _ => _extractKeyedValue(key, row),
    };
  }

  T _extractKeyedValue<T>(SettingsKey<T> key, UserProfileTableData? row) {
    // Handle keyed keys (pageSort, pageDisplay)
    final keyedKey = key as dynamic;
    final name = keyedKey.name as String;
    final subKey = keyedKey.subKey as String;

    return switch (name) {
      'pageSort' => _pageSortFromRow(row, subKey) as T,
      'pageDisplay' => _pageDisplayFromRow(row, subKey) as T,
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
    // Use UTC to match Supabase server timestamps and avoid timezone comparison issues
    final now = Value(DateTime.now().toUtc());
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

  AppSettings _rowToAppSettings(UserProfileTableData? row) {
    if (row == null) return const AppSettings();
    return AppSettings(
      global: GlobalSettings.fromJson(_parseJson(row.globalSettings)),
      allocation: AllocationConfig.fromJson(
        _parseJson(row.allocationSettings),
      ),
      pageSortPreferences: _parsePageSortPreferences(row.pageSortPreferences),
      pageDisplaySettings: _parsePageDisplaySettings(row.pageDisplaySettings),
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

  // =========================================================================
  // Private helpers
  // =========================================================================

  /// Stream of user profile rows, filtering out ghost rows (all NULL values).
  ///
  /// Ghost rows can occur when PowerSync syncs orphaned rows from the server.
  /// We filter them out at the SQL level to prevent Drift's mapper from
  /// crashing on NULL values in non-nullable columns.
  Stream<List<UserProfileTableData>> get _profileStream {
    final query = driftDb.select(driftDb.userProfileTable)
      ..where(
        (row) =>
            row.globalSettings.isNotNull() &
            row.allocationSettings.isNotNull() &
            row.pageSortPreferences.isNotNull() &
            row.pageDisplaySettings.isNotNull(),
      );

    return query.watch().map((rows) {
      final emitTime = DateTime.now();
      talker.repositoryLog(
        'Settings',
        '[STREAM EMIT] _profileStream emitted at $emitTime\n'
            '  rows.length=${rows.length} (ghost rows filtered)',
      );
      for (final row in rows) {
        final updatedAt = row.updatedAt;
        final age = emitTime.difference(updatedAt);

        talker.repositoryLog(
          'Settings',
          '[STREAM EMIT] Row details:\n'
              '  id=${row.id}\n'
              '  updatedAt=$updatedAt\n'
              '  age=${age.inMilliseconds}ms (${age.inSeconds}s)\n'
              '  globalSettings first 80 chars: ${(row.globalSettings ?? "").substring(0, (row.globalSettings?.length ?? 0) > 80 ? 80 : (row.globalSettings?.length ?? 0))}',
        );

        // Detect potential sync bounce - stale data coming back
        if (age.inMinutes > 1) {
          talker.warning(
            '[SYNC BOUNCE?] STALE DATA DETECTED!\n'
            '  Row updatedAt=$updatedAt is ${age.inMinutes} minutes old\n'
            '  Current time=$emitTime\n'
            '  This may be a PowerSync sync bounce (old server data overwriting local).',
          );
        } else if (age.inSeconds < 2) {
          talker.repositoryLog(
            'Settings',
            '[STREAM EMIT] FRESH data - likely our own save echoing back',
          );
        }
      }
      return rows;
    });
  }

  Future<UserProfileTableData?> _selectProfile() async {
    talker.repositoryLog('Settings', '_selectProfile: querying user_profiles');

    // First dump raw SQL to see what PowerSync actually has
    await debugDumpRawProfileData();

    // Filter out ghost rows (all NULL values) to prevent Drift mapper crash
    final query = driftDb.select(driftDb.userProfileTable)
      ..where(
        (row) =>
            row.globalSettings.isNotNull() &
            row.allocationSettings.isNotNull() &
            row.pageSortPreferences.isNotNull() &
            row.pageDisplaySettings.isNotNull(),
      )
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
      ..limit(1);

    try {
      final result = await query.getSingleOrNull();
      if (result == null) {
        talker.repositoryLog(
          'Settings',
          '_selectProfile: no valid rows found (ghost rows filtered)',
        );
      } else {
        _logRawProfileData('_selectProfile', result);
      }
      return result;
    } catch (e, st) {
      talker.databaseError(
        '[Settings] _selectProfile FAILED during getSingleOrNull',
        e,
        st,
      );
      rethrow;
    }
  }

  void _logRawProfileData(String source, UserProfileTableData row) {
    talker.repositoryLog(
      'Settings',
      '[$source] RAW user_profile data: '
          'id=${row.id}, '
          'globalSettings="${row.globalSettings?.length ?? 0} chars", '
          'allocationSettings="${row.allocationSettings?.length ?? 0} chars", '
          'pageSortPreferences="${row.pageSortPreferences?.length ?? 0} chars", '
          'pageDisplaySettings="${row.pageDisplaySettings?.length ?? 0} chars", '
          'createdAt=${row.createdAt}, '
          'updatedAt=${row.updatedAt}',
    );
  }

  UserProfileTableData? _latestRow(List<UserProfileTableData> rows) {
    if (rows.isEmpty) return null;
    return rows.reduce(
      (a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b,
    );
  }

  Map<String, dynamic> _parseJson(String? json) {
    if (json == null || json.isEmpty) return {};
    try {
      final parsed = jsonDecode(json);
      return parsed is Map<String, dynamic> ? parsed : {};
    } catch (e) {
      talker.repositoryLog('Settings', '_parseJson error: $e');
      return {};
    }
  }

  Future<UserProfileTableData> _ensureProfile() async {
    talker.repositoryLog(
      'Settings',
      '_ensureProfile: checking for existing profile',
    );
    final existing = await _selectProfile();
    if (existing != null) {
      talker.repositoryLog(
        'Settings',
        '_ensureProfile: found existing profile id=${existing.id}',
      );
      return existing;
    }

    talker.repositoryLog(
      'Settings',
      '_ensureProfile: NO existing profile - creating new one',
    );
    final now = DateTime.now();
    // IMPORTANT: Must explicitly provide ALL columns because PowerSync stores
    // data as JSON blobs - any missing keys will be NULL when read back via
    // the SQLite VIEW, regardless of Drift's withDefault() settings.
    await driftDb
        .into(driftDb.userProfileTable)
        .insert(
          UserProfileTableCompanion.insert(
            globalSettings: const Value('{}'),
            allocationSettings: const Value('{}'),
            pageSortPreferences: const Value('{}'),
            pageDisplaySettings: const Value('{}'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    talker.repositoryLog(
      'Settings',
      '_ensureProfile: inserted new profile, reading back',
    );
    final newProfile = await _selectProfile();
    if (newProfile == null) {
      talker.databaseError(
        '[Settings] _ensureProfile: CRITICAL - inserted profile but read-back returned NULL',
        Exception('Profile insert succeeded but read-back failed'),
        StackTrace.current,
      );
      throw StateError('Failed to read back newly created profile');
    }

    talker.repositoryLog(
      'Settings',
      '_ensureProfile: created new profile id=${newProfile.id}',
    );
    return newProfile;
  }

  Map<String, SortPreferences> _parsePageSortPreferences(String? json) {
    final map = _parseJson(json);
    return map.map(
      (key, value) => MapEntry(
        key,
        SortPreferences.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  Map<String, PageDisplaySettings> _parsePageDisplaySettings(String? json) {
    final map = _parseJson(json);
    return map.map(
      (key, value) => MapEntry(
        key,
        PageDisplaySettings.fromJson(value as Map<String, dynamic>),
      ),
    );
  }
}
