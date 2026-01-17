/// Deprecated stub.
///
/// USM screen types (ScreenSpec/ScreenPreferences/etc) remain in the app for
/// now, so this contract is app-owned.
///
/// Use `package:taskly_bloc/domain/interfaces/screen_catalog_repository_contract.dart`.
@Deprecated(
  'USM screen catalog is app-owned during extraction; '
  'use package:taskly_bloc/domain/interfaces/screen_catalog_repository_contract.dart',
)
library;

@Deprecated(
  'Use ScreenWithPreferences from taskly_bloc screen catalog contract.',
)
class ScreenWithPreferences {
  @Deprecated(
    'Use ScreenWithPreferences from taskly_bloc screen catalog contract.',
  )
  const ScreenWithPreferences({
    required this.screen,
    this.preferences,
  });

  final Object screen;
  final Object? preferences;

  int get effectiveSortOrder => 0;

  bool get isActive => true;
}

@Deprecated(
  'Use ScreenCatalogRepositoryContract from taskly_bloc screen catalog contract.',
)
abstract class ScreenCatalogRepositoryContract {
  Stream<List<ScreenWithPreferences>> watchAllScreens();

  Stream<List<ScreenWithPreferences>> watchSystemScreens();

  Stream<ScreenWithPreferences?> watchScreen(String screenKey);

  Future<void> updateScreenPreferences(
    String screenKey,
    Object preferences,
  );

  Future<void> reorderScreens(List<String> orderedScreenKeys);
}
