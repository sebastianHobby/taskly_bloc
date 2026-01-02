import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/features/screens/system_screen_factory.dart';
import 'package:taskly_bloc/data/services/user_data_seeder.dart'
    show UserDataSeeder;
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';

/// Service that seeds system screens for a user after authentication.
///
/// Uses deterministic UUID v5 IDs based on userId + screenKey, so the same
/// screens get the same IDs across devices. Combined with INSERT OR IGNORE,
/// this ensures idempotent seeding without conflicts.
///
/// Called from [UserDataSeeder] after successful authentication.
class SystemScreenSeeder {
  SystemScreenSeeder(this._repository);

  final ScreenDefinitionsRepositoryContract _repository;

  /// Seeds all system screens for a user.
  ///
  /// This is safe to call multiple times - existing screens are skipped
  /// via INSERT OR IGNORE on the (userId, screenKey) unique constraint.
  Future<void> seedAll(String userId) async {
    talker.info('[SystemScreenSeeder] Seeding system screens for user $userId');

    final screens = SystemScreenFactory.createAll(userId);

    await _repository.seedSystemScreens(screens);

    talker.info(
      '[SystemScreenSeeder] Seeded ${screens.length} system screens',
    );
  }
}
