import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/services/system_label_seeder.dart';
import 'package:taskly_bloc/data/services/system_screen_seeder.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/user_data_seeder_contract.dart';

/// Service that seeds required user data after authentication.
///
/// This ensures system labels and screens are created with proper user context.
/// Runs idempotently - safe to call multiple times.
class UserDataSeeder implements UserDataSeederContract {
  UserDataSeeder({
    required LabelRepositoryContract labelRepository,
    required ScreenDefinitionsRepositoryContract screenRepository,
  }) : _labelRepository = labelRepository,
       _screenRepository = screenRepository;

  final LabelRepositoryContract _labelRepository;
  final ScreenDefinitionsRepositoryContract _screenRepository;

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

      // Seed system screens
      talker.serviceLog(
        'UserDataSeeder',
        'Calling SystemScreenSeeder.seedAll()...',
      );
      await SystemScreenSeeder(_screenRepository).seedAll(userId);
      talker.serviceLog('UserDataSeeder', 'System screens seeded successfully');

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
