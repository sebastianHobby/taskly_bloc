import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/data/screens/repositories/screen_definitions_repository_impl.dart'
    show ScreenDefinitionsRepositoryImpl;
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/presentation/shared/models/screen_preferences.dart';

/// Repository wrapper that delegates to the database implementation.
///
/// This wrapper provides logging and potential future cross-cutting concerns.
///
/// For the database implementation, see [ScreenDefinitionsRepositoryImpl].
class ScreenDefinitionsRepository
    implements ScreenDefinitionsRepositoryContract {
  ScreenDefinitionsRepository({
    required ScreenDefinitionsRepositoryContract databaseRepository,
  }) : _dbRepo = databaseRepository;

  final ScreenDefinitionsRepositoryContract _dbRepo;

  @override
  Stream<List<ScreenWithPreferences>> watchAllScreens() {
    talker.repositoryLog('Screens', 'watchAllScreens');
    return _dbRepo.watchAllScreens();
  }

  @override
  Stream<List<ScreenWithPreferences>> watchSystemScreens() {
    talker.repositoryLog('Screens', 'watchSystemScreens');
    return _dbRepo.watchSystemScreens();
  }

  @override
  Stream<ScreenWithPreferences?> watchScreen(String screenKey) {
    talker.repositoryLog('Screens', 'watchScreen: screenKey="$screenKey"');
    return _dbRepo.watchScreen(screenKey);
  }

  @override
  Future<void> updateScreenPreferences(
    String screenKey,
    ScreenPreferences preferences,
  ) {
    talker.repositoryLog(
      'Screens',
      'updateScreenPreferences: screenKey="$screenKey", '
          'sortOrder=${preferences.sortOrder}, isActive=${preferences.isActive}',
    );
    return _dbRepo.updateScreenPreferences(screenKey, preferences);
  }

  @override
  Future<void> reorderScreens(List<String> orderedScreenKeys) {
    talker.repositoryLog(
      'Screens',
      'reorderScreens: ${orderedScreenKeys.length} screens',
    );
    return _dbRepo.reorderScreens(orderedScreenKeys);
  }
}
