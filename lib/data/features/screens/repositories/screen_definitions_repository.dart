import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/features/screens/repositories/screen_definitions_repository_impl.dart'
    show ScreenDefinitionsRepositoryImpl;
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';

/// Repository wrapper that delegates to the database implementation.
///
/// After the UUID5 migration, system screens are seeded directly to the
/// database, eliminating the need for template merging. This wrapper is
/// kept as a thin layer for logging and potential future cross-cutting
/// concerns.
///
/// For the database implementation, see [ScreenDefinitionsRepositoryImpl].
class ScreenDefinitionsRepository
    implements ScreenDefinitionsRepositoryContract {
  ScreenDefinitionsRepository({
    required ScreenDefinitionsRepositoryContract databaseRepository,
  }) : _dbRepo = databaseRepository;

  final ScreenDefinitionsRepositoryContract _dbRepo;

  @override
  Stream<List<ScreenDefinition>> watchAllScreens() {
    talker.repositoryLog('Screens', 'watchAllScreens');
    return _dbRepo.watchAllScreens();
  }

  @override
  Stream<List<ScreenDefinition>> watchSystemScreens() {
    talker.repositoryLog('Screens', 'watchSystemScreens');
    return _dbRepo.watchSystemScreens();
  }

  @override
  Stream<List<ScreenDefinition>> watchUserScreens() {
    talker.repositoryLog('Screens', 'watchUserScreens');
    return _dbRepo.watchUserScreens();
  }

  @override
  Future<void> seedSystemScreens(List<ScreenDefinition> screens) {
    talker.repositoryLog(
      'Screens',
      'seedSystemScreens: ${screens.length} screens',
    );
    return _dbRepo.seedSystemScreens(screens);
  }

  @override
  Stream<ScreenDefinition?> watchScreen(String id) {
    talker.repositoryLog('Screens', 'watchScreen: id="$id"');
    return _dbRepo.watchScreen(id);
  }

  @override
  Stream<ScreenDefinition?> watchScreenByScreenKey(String screenKey) {
    talker.repositoryLog(
      'Screens',
      'watchScreenByScreenKey: screenKey="$screenKey"',
    );
    return _dbRepo.watchScreenByScreenKey(screenKey);
  }

  @override
  Future<String> createScreen(ScreenDefinition screen) {
    talker.repositoryLog('Screens', 'createScreen: ${screen.screenKey}');
    return _dbRepo.createScreen(screen);
  }

  @override
  Future<void> updateScreen(ScreenDefinition screen) {
    talker.repositoryLog('Screens', 'updateScreen: ${screen.screenKey}');
    return _dbRepo.updateScreen(screen);
  }

  @override
  Future<void> deleteScreen(String id) {
    talker.repositoryLog('Screens', 'deleteScreen: id="$id"');
    return _dbRepo.deleteScreen(id);
  }

  @override
  Future<void> setScreenActive(String screenKey, bool isActive) {
    talker.repositoryLog(
      'Screens',
      'setScreenActive: screenKey="$screenKey", isActive=$isActive',
    );
    return _dbRepo.setScreenActive(screenKey, isActive);
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
