import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/services/system_label_seeder.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/user_data_seeder_contract.dart';

/// Service that seeds required user data after authentication.
///
/// This ensures system labels are created with proper user context.
/// Runs idempotently - safe to call multiple times.
///
/// NOTE: System screens are no longer seeded here. They are generated
/// from code by [SystemScreenProvider] to avoid PowerSync sync conflicts.
class UserDataSeeder implements UserDataSeederContract {
  UserDataSeeder({
    required LabelRepositoryContract labelRepository,
  }) : _labelRepository = labelRepository;

  final LabelRepositoryContract _labelRepository;

  /// Seeds all required user data.
  ///
  /// This method is idempotent and safe to call multiple times.
  /// It will only create missing data.
  ///
  /// Must be called after user authentication. PowerSync/Supabase
  /// automatically set user_id on created records based on the session.
  ///
  /// [userId] is required for screen seeding (used for deterministic UUID
  /// generation).
  @override
  Future<void> seedAll(String userId) async {
    talker.serviceLog('UserDataSeeder', 'seedAll() START for user $userId');

    try {
      // Seed system labels
      // Note: user_id is set automatically by Supabase/PowerSync
      talker.serviceLog(
        'UserDataSeeder',
        'Calling SystemLabelSeeder.seedAll()...',
      );
      await SystemLabelSeeder(
        labelRepository: _labelRepository,
      ).seedAll();
      talker.serviceLog('UserDataSeeder', 'System labels seeded successfully');

      // NOTE: System screens are now generated from code by SystemScreenProvider.
      // No seeding needed - this avoids PowerSync V5 CONFLICT errors.

      talker.serviceLog('UserDataSeeder', 'seedAll() completed successfully');
    } catch (error, stackTrace) {
      talker.handle(
        error,
        stackTrace,
        '[UserDataSeeder] Failed to seed user data',
      );
      // Don't rethrow - seeding failures shouldn't crash the app
    }
  }
}
