import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/features/screens/services/screen_system_seeder.dart';
import 'package:taskly_bloc/data/services/allocation_data_seeder.dart';
import 'package:taskly_bloc/data/services/system_label_seeder.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/allocation_preferences_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/priority_rankings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';

/// Service that seeds required user data after authentication.
///
/// This ensures all system labels, screens, and allocation defaults
/// are created with proper user context. Runs idempotently - safe to
/// call multiple times.
class UserDataSeeder {
  UserDataSeeder({
    required LabelRepositoryContract labelRepository,
    required ScreenDefinitionsRepositoryContract screenRepository,
    required AllocationPreferencesRepositoryContract preferencesRepository,
    required PriorityRankingsRepositoryContract rankingsRepository,
  }) : _labelRepository = labelRepository,
       _screenRepository = screenRepository,
       _preferencesRepository = preferencesRepository,
       _rankingsRepository = rankingsRepository;

  final LabelRepositoryContract _labelRepository;
  final ScreenDefinitionsRepositoryContract _screenRepository;
  final AllocationPreferencesRepositoryContract _preferencesRepository;
  final PriorityRankingsRepositoryContract _rankingsRepository;

  /// Seeds all required user data.
  ///
  /// This method is idempotent and safe to call multiple times.
  /// It will only create missing data.
  ///
  /// Must be called after user authentication. PowerSync/Supabase
  /// automatically set user_id on created records based on the session.
  Future<void> seedAll() async {
    talker.serviceLog('UserDataSeeder', 'seedAll() START');

    try {
      // Seed system screens
      // Note: user_id is set automatically by Supabase/PowerSync
      talker.serviceLog(
        'UserDataSeeder',
        'Calling ScreenSystemSeeder.seedDefaults()...',
      );
      await ScreenSystemSeeder(
        screensRepository: _screenRepository,
      ).seedDefaults();
      talker.serviceLog('UserDataSeeder', 'System screens seeded successfully');

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

      // Seed allocation defaults (preferences + value ranking if values exist)
      // Note: Must run after system labels since it may use value labels
      talker.serviceLog(
        'UserDataSeeder',
        'Calling AllocationDataSeeder.seedDefaults()...',
      );
      await AllocationDataSeeder(
        preferencesRepository: _preferencesRepository,
        rankingsRepository: _rankingsRepository,
        labelRepository: _labelRepository,
      ).seedDefaults();
      talker.serviceLog(
        'UserDataSeeder',
        'Allocation defaults seeded successfully',
      );

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
