import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_data/data/infrastructure/drift/drift_database.dart';
import 'package:taskly_domain/taskly_domain.dart';

/// Repository for managing application settings via [SettingsKey].
///
/// ## Storage model
/// Settings are stored in a single `user_profiles.settings_overrides` JSON map:
/// - Code provides defaults.
/// - DB stores overrides only; missing/invalid data falls back to defaults.
/// - If an override is invalid (bad JSON / wrong type), we self-heal by writing
///   a repaired override map back to the DB.
///
/// ## Sync bounce protection
/// Debounces the user profile stream to reduce PowerSync CDC "bounce" where an
/// older snapshot may briefly appear after a local save.
class SettingsRepository implements SettingsRepositoryContract {
  SettingsRepository({required this.driftDb});

  final AppDatabase driftDb;

  // Diagnostics for detecting PowerSync CDC "sync bounce".
  //
  // A real bounce looks like: optimistic save -> local echo -> older server row
  // reappears briefly -> newest row returns. "Old" rows by themselves are normal
  // (e.g. settings last changed days ago).
  DateTime? _lastSaveCompletedAtUtc;
  DateTime? _lastEmittedUpdatedAtUtc;
  DateTime? _lastRepairAttemptAtUtc;

  static const _repairsKey = '_repairs';

  // =========================================================================
  // Public API (SettingsRepositoryContract)
  // =========================================================================

  @override
  Stream<T> watch<T>(SettingsKey<T> key) {
    return _profileStream.map((row) => _extractValue(key, row)).distinct();
  }

  @override
  Future<T> load<T>(SettingsKey<T> key) async {
    try {
      final row = await _selectProfile();
      final value = _extractValue(key, row);
      return value;
    } catch (e, st) {
      talker.databaseError('[Settings] load<$T> FAILED for key=$key', e, st);
      rethrow;
    }
  }

  @override
  Future<void> save<T>(SettingsKey<T> key, T value) async {
    final saveStartTime = DateTime.now();
    final profile = await _ensureProfile();
    final overrides = _parseOverrides(
      profile.settingsOverrides,
      source: 'save<$T> key=$key',
      profileId: profile.id,
    );
    final updated = _upsertOverride(key, value, overrides);
    await _writeOverrides(
      profileId: profile.id,
      overrides: updated,
    );

    final driftWriteTime = DateTime.now();
    _lastSaveCompletedAtUtc = driftWriteTime.toUtc();
    talker.repositoryLog(
      'Settings',
      'save<$T>: key=$key complete in '
          '${driftWriteTime.difference(saveStartTime).inMilliseconds}ms',
    );
  }

  // =========================================================================
  // Private helpers
  // =========================================================================

  Stream<UserProfileTableData?> get _profileStream {
    final query = driftDb.select(driftDb.userProfileTable)
      ..where(
        (row) => row.createdAt.isNotNull() & row.updatedAt.isNotNull(),
      )
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
      ..limit(1);

    return query.watchSingleOrNull().map((row) {
      final newestUpdatedAtUtc = row?.updatedAt.toUtc();
      final previousEmittedUtc = _lastEmittedUpdatedAtUtc;
      if (newestUpdatedAtUtc != null && previousEmittedUtc != null) {
        final regressed = newestUpdatedAtUtc.isBefore(
          previousEmittedUtc.subtract(const Duration(seconds: 2)),
        );

        final savedRecently =
            _lastSaveCompletedAtUtc != null &&
            DateTime.now().toUtc().difference(_lastSaveCompletedAtUtc!) <
                const Duration(seconds: 10);

        if (regressed && savedRecently) {
          talker.warning(
            '[SYNC BOUNCE?] updatedAt regressed after recent save\n'
            '  newestUpdatedAt=$newestUpdatedAtUtc\n'
            '  previousEmittedUpdatedAt=$previousEmittedUtc\n'
            '  lastSaveCompletedAt=$_lastSaveCompletedAtUtc',
          );
        }
      }

      _lastEmittedUpdatedAtUtc = newestUpdatedAtUtc;
      return row;
    });
  }

  Future<UserProfileTableData?> _selectProfile() async {
    final query = driftDb.select(driftDb.userProfileTable)
      ..where(
        (row) => row.createdAt.isNotNull() & row.updatedAt.isNotNull(),
      )
      ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
      ..limit(1);

    return query.getSingleOrNull();
  }

  Map<String, dynamic> _parseOverrides(
    String? json, {
    required String source,
    required String profileId,
  }) {
    if (json == null || json.isEmpty) return <String, dynamic>{};
    try {
      final parsed = jsonDecode(json);
      if (parsed is Map<String, dynamic>) return parsed;
      talker.warning(
        '[Settings] Invalid settings_overrides type from $source (expected map)',
      );
      _scheduleRepair(
        profileId: profileId,
        repaired: _withRepairMeta(
          const <String, dynamic>{},
          repairKey: 'settings_overrides',
          repairedFrom: parsed,
          reason: 'settings_overrides_not_a_map',
        ),
      );
      return <String, dynamic>{};
    } catch (e) {
      talker.warning(
        '[Settings] Invalid settings_overrides JSON from $source ($e)',
      );
      _scheduleRepair(
        profileId: profileId,
        repaired: _withRepairMeta(
          const <String, dynamic>{},
          repairKey: 'settings_overrides',
          repairedFrom: json,
          reason: 'settings_overrides_invalid_json',
        ),
      );
      return <String, dynamic>{};
    }
  }

  void _scheduleRepair({
    required String profileId,
    required Map<String, dynamic> repaired,
  }) {
    final nowUtc = DateTime.now().toUtc();
    final last = _lastRepairAttemptAtUtc;
    if (last != null && nowUtc.difference(last) < const Duration(seconds: 2)) {
      return;
    }
    _lastRepairAttemptAtUtc = nowUtc;

    unawaited(
      _writeOverrides(
        profileId: profileId,
        overrides: repaired,
      ).catchError((Object e, StackTrace st) {
        talker.databaseError('[Settings] repair write failed', e, st);
      }),
    );
  }

  Map<String, dynamic> _withRepairMeta(
    Map<String, dynamic> overrides, {
    required String repairKey,
    required Object? repairedFrom,
    required String reason,
  }) {
    final nowUtc = DateTime.now().toUtc();
    final updated = Map<String, dynamic>.from(overrides);
    final existing = updated[_repairsKey];
    final repairs = existing is Map<String, dynamic>
        ? Map<String, dynamic>.from(existing)
        : <String, dynamic>{};

    repairs[repairKey] = <String, dynamic>{
      'repaired_at': nowUtc.toIso8601String(),
      'repaired_from': _previewForStorage(repairedFrom),
      'reason': reason,
    };
    updated[_repairsKey] = repairs;
    return updated;
  }

  String _previewForStorage(Object? value, {int maxChars = 500}) {
    if (value == null) return '<null>';
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.length <= maxChars) return trimmed;
      return '${trimmed.substring(0, maxChars)}…';
    }

    try {
      final encoded = jsonEncode(value);
      if (encoded.length <= maxChars) return encoded;
      return '${encoded.substring(0, maxChars)}…';
    } catch (_) {
      final stringified = value.toString();
      if (stringified.length <= maxChars) return stringified;
      return '${stringified.substring(0, maxChars)}…';
    }
  }

  Future<UserProfileTableData> _ensureProfile() async {
    final existing = await _selectProfile();
    if (existing != null) {
      return existing;
    }

    final nowUtc = DateTime.now().toUtc();
    await driftDb
        .into(driftDb.userProfileTable)
        .insert(
          UserProfileTableCompanion.insert(
            settingsOverrides: const Value('{}'),
            createdAt: Value(nowUtc),
            updatedAt: Value(nowUtc),
          ),
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
    return newProfile;
  }

  Future<void> _writeOverrides({
    required String profileId,
    required Map<String, dynamic> overrides,
  }) async {
    final nowUtc = DateTime.now().toUtc();
    final companion = UserProfileTableCompanion(
      settingsOverrides: Value(jsonEncode(overrides)),
      updatedAt: Value(nowUtc),
    );

    await (driftDb.update(
      driftDb.userProfileTable,
    )..where((row) => row.id.equals(profileId))).write(companion);
  }

  T _extractValue<T>(SettingsKey<T> key, UserProfileTableData? row) {
    if (row == null) {
      return _defaultForKey(key);
    }

    final overrides = _parseOverrides(
      row.settingsOverrides,
      source: 'extract key=$key',
      profileId: row.id,
    );

    if (identical(key, SettingsKey.global)) {
      return _decodeSingleton(
            keyName: 'global',
            overrides: overrides,
            profileId: row.id,
            defaultValue: const GlobalSettings(),
            fromJson: GlobalSettings.fromJson,
          )
          as T;
    }
    if (identical(key, SettingsKey.allocation)) {
      return _decodeSingleton(
            keyName: 'allocation',
            overrides: overrides,
            profileId: row.id,
            defaultValue: const AllocationConfig(),
            fromJson: AllocationConfig.fromJson,
          )
          as T;
    }

    return _extractKeyedValue(key, row.id, overrides);
  }

  T _extractKeyedValue<T>(
    SettingsKey<T> key,
    String profileId,
    Map<String, dynamic> overrides,
  ) {
    final keyedKey = key as dynamic;
    final name = keyedKey.name as String;
    final subKey = keyedKey.subKey as String;

    return switch (name) {
      'pageSort' =>
        _decodePageSort(
              profileId: profileId,
              overrides: overrides,
              pageKey: subKey,
            )
            as T,
      _ => throw ArgumentError('Unknown keyed key: $name'),
    };
  }

  SortPreferences? _decodePageSort({
    required String profileId,
    required Map<String, dynamic> overrides,
    required String pageKey,
  }) {
    final group = overrides['pageSort'];
    if (group == null) return null;
    if (group is! Map<String, dynamic>) {
      final repaired = Map<String, dynamic>.from(overrides)..remove('pageSort');
      _scheduleRepair(
        profileId: profileId,
        repaired: _withRepairMeta(
          repaired,
          repairKey: 'pageSort',
          repairedFrom: group,
          reason: 'pageSort_not_a_map',
        ),
      );
      return null;
    }

    final value = group[pageKey];
    if (value == null) return null;
    if (value is! Map<String, dynamic>) {
      final repairedGroup = Map<String, dynamic>.from(group)..remove(pageKey);
      final repaired = Map<String, dynamic>.from(overrides)
        ..['pageSort'] = repairedGroup;
      _scheduleRepair(
        profileId: profileId,
        repaired: _withRepairMeta(
          repaired,
          repairKey: 'pageSort:$pageKey',
          repairedFrom: value,
          reason: 'pageSort_entry_not_a_map',
        ),
      );
      return null;
    }

    return SortPreferences.fromJson(value);
  }

  T _decodeSingleton<T>({
    required String keyName,
    required Map<String, dynamic> overrides,
    required String profileId,
    required T defaultValue,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    final value = overrides[keyName];
    if (value == null) return defaultValue;
    if (value is! Map<String, dynamic>) {
      final repaired = Map<String, dynamic>.from(overrides)..remove(keyName);
      _scheduleRepair(
        profileId: profileId,
        repaired: _withRepairMeta(
          repaired,
          repairKey: keyName,
          repairedFrom: value,
          reason: '${keyName}_not_a_map',
        ),
      );
      return defaultValue;
    }
    try {
      return fromJson(value);
    } catch (e) {
      final repaired = Map<String, dynamic>.from(overrides)..remove(keyName);
      _scheduleRepair(
        profileId: profileId,
        repaired: _withRepairMeta(
          repaired,
          repairKey: keyName,
          repairedFrom: value,
          reason: '${keyName}_fromJson_failed',
        ),
      );
      return defaultValue;
    }
  }

  Map<String, dynamic> _upsertOverride<T>(
    SettingsKey<T> key,
    T value,
    Map<String, dynamic> overrides,
  ) {
    final updated = Map<String, dynamic>.from(overrides);

    if (identical(key, SettingsKey.global)) {
      updated['global'] = (value as GlobalSettings).toJson();
      return updated;
    }
    if (identical(key, SettingsKey.allocation)) {
      updated['allocation'] = (value as AllocationConfig).toJson();
      return updated;
    }

    final keyedKey = key as dynamic;
    final name = keyedKey.name as String;
    final subKey = keyedKey.subKey as String;
    switch (name) {
      case 'pageSort':
        final group = Map<String, dynamic>.from(
          (updated['pageSort'] as Map<String, dynamic>?) ??
              const <String, dynamic>{},
        );
        final prefs = value as SortPreferences?;
        if (prefs == null) {
          group.remove(subKey);
        } else {
          group[subKey] = prefs.toJson();
        }
        if (group.isEmpty) {
          updated.remove('pageSort');
        } else {
          updated['pageSort'] = group;
        }
        return updated;

      default:
        throw ArgumentError('Unknown keyed key: $name');
    }
  }

  T _defaultForKey<T>(SettingsKey<T> key) {
    if (identical(key, SettingsKey.global)) return const GlobalSettings() as T;
    if (identical(key, SettingsKey.allocation)) {
      return const AllocationConfig() as T;
    }

    final keyedKey = key as dynamic;
    final name = keyedKey.name as String;
    return switch (name) {
      'pageSort' => null as T,
      _ => throw ArgumentError('Unknown SettingsKey default: $key'),
    };
  }
}
