import 'package:drift/drift.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/drift/features/shared_enums.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/models/screens/actions_config.dart';
import 'package:taskly_bloc/domain/models/screens/content_config.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/system_screen_definitions.dart';

/// Seeds system screen definitions to database.
///
/// Pattern matches [AttentionSeeder]:
/// - Uses deterministic UUID v5 for idempotent seeding
/// - insertOrIgnore for safe re-runs
/// - Reads templates from [SystemScreenDefinitions], writes to database
///
/// ## Architecture
///
/// After this change, ALL screens (system + custom) come from the database.
/// System screens are seeded once on first launch, then users can customize
/// them (change sortOrder, isActive) via the database.
///
/// This enables:
/// 1. Unified cleanup service for orphaned system screens
/// 2. PowerSync sync for all screen data
/// 3. Consistent architecture with attention rules
class ScreenSeeder {
  ScreenSeeder({
    required AppDatabase db,
    required IdGenerator idGenerator,
  }) : _db = db,
       _idGenerator = idGenerator;

  final AppDatabase _db;
  final IdGenerator _idGenerator;

  /// Seed all system screen definitions.
  ///
  /// IMPORTANT: This writes to database ONCE on first launch.
  /// After that, users customize via database - templates are not consulted.
  ///
  /// Uses deterministic IDs so re-running is safe (no duplicates).
  /// Uses insertOrIgnore so existing screens are not overwritten.
  Future<void> seedSystemScreens() async {
    talker.info('[ScreenSeeder] Seeding system screen definitions');
    talker.info(
      '[ScreenSeeder] Templates to seed: '
      '${SystemScreenDefinitions.allKeys}',
    );

    try {
      var seededCount = 0;
      await _db.transaction(() async {
        for (final template in SystemScreenDefinitions.all) {
          final didSeed = await _seedScreen(template);
          if (didSeed) seededCount++;
        }
      });

      talker.info(
        '[ScreenSeeder] Successfully seeded $seededCount new screens '
        '(${SystemScreenDefinitions.all.length - seededCount} already existed)',
      );
    } catch (e, stackTrace) {
      talker.operationFailed(
        '[ScreenSeeder] Failed to seed screen definitions',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Seeds a single screen definition. Returns true if inserted, false if skipped.
  Future<bool> _seedScreen(ScreenDefinition template) async {
    // Deterministic ID: namespace='screen_definitions', name=screenKey
    // Same screen key always generates same ID
    final id = _idGenerator.screenDefinitionId(screenKey: template.screenKey);

    // Check if already exists (insertOrIgnore doesn't tell us)
    final existing = await (_db.select(
      _db.screenDefinitions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (existing != null) {
      talker.debug(
        '[ScreenSeeder] Screen "${template.screenKey}" already exists, skipping',
      );
      return false;
    }

    final contentConfig = ContentConfig(sections: template.sections);
    final actionsConfig = ActionsConfig(
      fabOperations: template.chrome.fabOperations,
      appBarActions: template.chrome.appBarActions,
      settingsRoute: template.chrome.settingsRoute,
    );

    final sortOrder = SystemScreenDefinitions.getDefaultSortOrder(
      template.screenKey,
    );

    talker.info(
      '[ScreenSeeder] Seeding screen "${template.screenKey}" '
      '(id=$id, sortOrder=$sortOrder)',
    );

    await _db
        .into(_db.screenDefinitions)
        .insert(
          ScreenDefinitionsCompanion.insert(
            id: id,
            screenKey: template.screenKey,
            name: template.name,
            iconName: Value(template.chrome.iconName),
            source: const Value(EntitySource.system_template),
            isActive: const Value(true),
            sortOrder: Value(sortOrder),
            contentConfig: Value(contentConfig),
            actionsConfig: Value(actionsConfig),
            createdAt: Value(template.createdAt),
            updatedAt: Value(template.updatedAt),
          ),
          mode: InsertMode.insertOrIgnore, // Skip if already exists
        );

    return true;
  }

  /// Check if user has any system screens (determines if seeding needed).
  Future<bool> hasInitializedScreens() async {
    final count = await _db.screenDefinitions
        .count(
          where: (t) => t.source.equals(EntitySource.system_template.name),
        )
        .getSingle();

    talker.info(
      '[ScreenSeeder] hasInitializedScreens: found $count system screens in DB',
    );
    return count > 0;
  }

  /// Check if all required system screens exist in database.
  Future<bool> _hasAllSystemScreens() async {
    final existingScreenKeys =
        await (_db.selectOnly(_db.screenDefinitions)
              ..addColumns([_db.screenDefinitions.screenKey])
              ..where(
                _db.screenDefinitions.source.equals(
                  EntitySource.system_template.name,
                ),
              ))
            .map((row) => row.read(_db.screenDefinitions.screenKey)!)
            .get();

    final requiredKeys = SystemScreenDefinitions.allKeys;
    final missing = requiredKeys
        .where(
          (key) => !existingScreenKeys.contains(key),
        )
        .toList();

    if (missing.isNotEmpty) {
      talker.warning(
        '[ScreenSeeder] Missing ${missing.length} system screens: $missing',
      );
      return false;
    }

    talker.info(
      '[ScreenSeeder] All ${requiredKeys.length} system screens present',
    );
    return true;
  }

  /// Idempotent initialization - safe to call multiple times.
  ///
  /// Seeds missing system screens. This handles:
  /// 1. First launch (no screens) - seeds all
  /// 2. Partial sync (some screens from Supabase) - seeds missing ones
  /// 3. Full sync (all screens present) - no-op
  Future<void> ensureSeeded() async {
    final hasAll = await _hasAllSystemScreens();
    if (!hasAll) {
      talker.info('[ScreenSeeder] Seeding missing system screens...');
      await seedSystemScreens();
    } else {
      talker.info(
        '[ScreenSeeder] All system screens already present, skipping seed',
      );
    }
  }
}
