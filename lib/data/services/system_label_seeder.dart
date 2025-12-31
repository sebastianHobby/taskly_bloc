import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/models/label.dart';

/// Service to seed system labels and migrate legacy data
class SystemLabelSeeder {
  SystemLabelSeeder({
    required LabelRepositoryContract labelRepository,
  }) : _labelRepository = labelRepository;

  final LabelRepositoryContract _labelRepository;

  /// Ensures the Pinned system label exists for the current user.
  ///
  /// Must be called after authentication. PowerSync/Supabase automatically
  /// set user_id on created records based on the current session.
  Future<Label> ensurePinnedLabelExists() async {
    return _labelRepository.getOrCreateSystemLabel(SystemLabelType.pinned);
  }

  /// Migrates tasks with isNextAction=true to use the Pinned label
  /// This is a one-time migration for existing users
  /// NOTE: Migration disabled - isNextAction field deprecated
  /// Users will manually pin tasks they want to keep in focus
  Future<void> migrateNextActionTasks() async {
    // Migration not needed - handled at UI level
    await ensurePinnedLabelExists();
  }

  /// Runs all seeding and migration operations.
  ///
  /// Must be called after authentication. PowerSync/Supabase automatically
  /// set user_id on created records based on the current session.
  Future<void> seedAll() async {
    await ensurePinnedLabelExists();
    await migrateNextActionTasks();
  }
}
