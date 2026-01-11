import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/screens/repositories/screen_definitions_repository_impl.dart'
    show ScreenDefinitionsRepositoryImpl;
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/system_screen_provider.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/models/settings/screen_preferences.dart';

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
  Stream<List<ScreenDefinition>> watchCustomScreens() {
    talker.repositoryLog('Screens', 'watchCustomScreens');
    return _dbRepo.watchCustomScreens();
  }

  @override
  Stream<ScreenWithPreferences?> watchScreen(String screenKey) {
    talker.repositoryLog('Screens', 'watchScreen: screenKey="$screenKey"');
    return _dbRepo.watchScreen(screenKey);
  }

  @override
  Future<bool> screenKeyExists(String screenKey) {
    talker.repositoryLog('Screens', 'screenKeyExists: screenKey="$screenKey"');
    return _dbRepo.screenKeyExists(screenKey);
  }

  @override
  Future<String> createCustomScreen(ScreenDefinition screen) {
    talker.repositoryLog('Screens', 'createCustomScreen: ${screen.screenKey}');
    return _dbRepo.createCustomScreen(screen);
  }

  @override
  Future<void> updateCustomScreen(ScreenDefinition screen) {
    talker.repositoryLog('Screens', 'updateCustomScreen: ${screen.screenKey}');
    return _dbRepo.updateCustomScreen(screen);
  }

  @override
  Future<void> deleteCustomScreen(String screenKey) {
    talker.repositoryLog(
      'Screens',
      'deleteCustomScreen: screenKey="$screenKey"',
    );
    return _dbRepo.deleteCustomScreen(screenKey);
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
