import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';

/// Service that repairs corrupted database rows before normal access.
///
/// This handles cases where PowerSync syncs rows with NULL values in
/// non-nullable columns, which would crash Drift's mapping layer.
///
/// Runs automatically at the start of [seedAll] in [UserDataSeeder].
class DataRepairService {
  DataRepairService(this._db);

  final AppDatabase _db;

  /// Repairs all known corruption patterns in the database.
  ///
  /// This is idempotent - safe to call multiple times.
  /// Returns the total number of rows repaired.
  Future<int> repairAll() async {
    talker.serviceLog('DataRepairService', 'repairAll() START');

    var totalRepaired = 0;

    try {
      totalRepaired += await _repairUserProfiles();
      totalRepaired += await _repairScreenDefinitions();

      if (totalRepaired > 0) {
        talker.warning(
          '[DataRepairService] Repaired $totalRepaired corrupted row(s)',
        );
      } else {
        talker.serviceLog('DataRepairService', 'No corrupted rows found');
      }
    } catch (e, st) {
      talker.databaseError('[DataRepairService] repairAll FAILED', e, st);
      // Don't rethrow - repair failures shouldn't block the app
    }

    talker.serviceLog('DataRepairService', 'repairAll() COMPLETE');
    return totalRepaired;
  }

  /// Repairs user_profiles rows with NULL in required JSON columns.
  ///
  /// PowerSync stores data as JSON blobs, so Drift's withDefault() doesn't
  /// apply to synced rows. This fixes rows that were created before explicit
  /// column values were provided during insert.
  Future<int> _repairUserProfiles() async {
    talker.serviceLog('DataRepairService', 'Checking user_profiles...');

    // Query for rows with any NULL in required columns using raw SQL
    // (Drift would crash trying to map these rows)
    final corruptedRows = await _db.customSelect(
      '''
      SELECT id FROM user_profiles
      WHERE global_settings IS NULL
         OR allocation_settings IS NULL
         OR soft_gates_settings IS NULL
         OR next_actions_settings IS NULL
         OR value_ranking IS NULL
         OR page_sort_preferences IS NULL
         OR page_display_settings IS NULL
         OR screen_preferences IS NULL
      ''',
    ).get();

    if (corruptedRows.isEmpty) {
      talker.serviceLog('DataRepairService', 'user_profiles: OK (0 corrupted)');
      return 0;
    }

    talker.warning(
      '[DataRepairService] user_profiles: Found ${corruptedRows.length} '
      'corrupted row(s) with NULL values',
    );

    // Repair each row
    for (final row in corruptedRows) {
      final id = row.read<String>('id');
      talker.serviceLog('DataRepairService', 'Repairing user_profile id=$id');

      await _db.customStatement(
        '''
        UPDATE user_profiles SET
          global_settings = COALESCE(global_settings, '{}'),
          allocation_settings = COALESCE(allocation_settings, '{}'),
          soft_gates_settings = COALESCE(soft_gates_settings, '{}'),
          next_actions_settings = COALESCE(next_actions_settings, '{}'),
          value_ranking = COALESCE(value_ranking, '{}'),
          page_sort_preferences = COALESCE(page_sort_preferences, '{}'),
          page_display_settings = COALESCE(page_display_settings, '{}'),
          screen_preferences = COALESCE(screen_preferences, '{}'),
          updated_at = ?
        WHERE id = ?
        ''',
        [DateTime.now().toIso8601String(), id],
      );
    }

    talker.serviceLog(
      'DataRepairService',
      'user_profiles: Repaired ${corruptedRows.length} row(s)',
    );
    return corruptedRows.length;
  }

  /// Repairs screen_definitions rows with NULL in required columns.
  ///
  /// The screen_definitions table has several columns that shouldn't be NULL
  /// for system screens. This repairs rows that may have been partially synced
  /// or corrupted.
  Future<int> _repairScreenDefinitions() async {
    talker.serviceLog('DataRepairService', 'Checking screen_definitions...');

    // Check for system screens with NULL in critical fields
    // screen_type and category are enums that will crash if NULL
    final corruptedRows = await _db.customSelect(
      '''
      SELECT id, screen_key, name, screen_type, category, is_system, is_active,
             sort_order, icon_name, sections_config, support_blocks_config
      FROM screen_definitions
      WHERE screen_type IS NULL
         OR category IS NULL
         OR name IS NULL
         OR name = ''
         OR screen_key IS NULL
         OR screen_key = ''
      ''',
    ).get();

    if (corruptedRows.isEmpty) {
      talker.serviceLog(
        'DataRepairService',
        'screen_definitions: OK (0 corrupted)',
      );
      return 0;
    }

    talker.warning(
      '[DataRepairService] screen_definitions: Found ${corruptedRows.length} '
      'corrupted row(s)',
    );

    // Repair each row with sensible defaults
    for (final row in corruptedRows) {
      final id = row.read<String>('id');
      final screenKey = row.readNullable<String>('screen_key') ?? 'unknown';
      final name = row.readNullable<String>('name');

      talker.serviceLog(
        'DataRepairService',
        'Repairing screen_definition id=$id, screenKey=$screenKey',
      );

      // Use COALESCE to only fill in NULL values, preserving existing data
      await _db.customStatement(
        '''
        UPDATE screen_definitions SET
          screen_type = COALESCE(screen_type, 'list'),
          category = COALESCE(category, 'workspace'),
          name = COALESCE(NULLIF(name, ''), ?),
          screen_key = COALESCE(NULLIF(screen_key, ''), ?),
          is_system = COALESCE(is_system, 0),
          is_active = COALESCE(is_active, 1),
          sort_order = COALESCE(sort_order, 999),
          updated_at = ?
        WHERE id = ?
        ''',
        [
          if (name?.isNotEmpty ?? false) name else _titleCase(screenKey),
          if (screenKey.isNotEmpty) screenKey else 'unknown_$id',
          DateTime.now().toIso8601String(),
          id,
        ],
      );
    }

    talker.serviceLog(
      'DataRepairService',
      'screen_definitions: Repaired ${corruptedRows.length} row(s)',
    );
    return corruptedRows.length;
  }

  /// Converts snake_case or lowercase to Title Case.
  String _titleCase(String input) {
    return input
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
