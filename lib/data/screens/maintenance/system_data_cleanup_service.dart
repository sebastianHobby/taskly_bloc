import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart'
    as db;

/// Post-auth maintenance for system-owned data.
///
/// The app historically had DB-backed screen definitions and other system rows
/// that could become orphaned after template changes.
///
/// The current hard-cutover uses typed system screens from code, so screen
/// definition cleanup is intentionally a no-op.
class SystemDataCleanupService {
  SystemDataCleanupService({
    required db.AppDatabase db,
    required IdGenerator idGenerator,
  }) : _db = db,
       _idGenerator = idGenerator;

  // Kept for API compatibility; may be used for future cleanup semantics.
  // ignore: unused_field
  final db.AppDatabase _db;
  // Kept for API compatibility; may be used for future cleanup semantics.
  // ignore: unused_field
  final IdGenerator _idGenerator;

  Future<void> cleanOrphanedScreenDefinitions() async {
    talker.debug(
      '[SystemDataCleanupService] cleanOrphanedScreenDefinitions: skipped '
      '(system screens are code-based)',
    );
  }

  Future<void> cleanOrphanedAttentionRules() async {
    // Currently handled by AttentionSeeder migrations and server sync rules.
    // Keep as best-effort hook to avoid breaking the post-auth maintenance flow.
    talker.debug(
      '[SystemDataCleanupService] cleanOrphanedAttentionRules: skipped',
    );
  }
}
