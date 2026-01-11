import 'package:taskly_bloc/domain/preferences/model/settings_key.dart';

/// Repository contract for managing application settings.
///
/// Uses type-safe [SettingsKey] to access individual settings. Each setting
/// type is stored in its own database column for granular sync support.
///
/// ## Usage
/// ```dart
/// // Watch global settings
/// repo.watch(SettingsKey.global).listen((settings) => ...);
///
/// // Load/save page sort preferences
/// final sort = await repo.load(SettingsKey.pageSort(PageKey.inbox));
/// await repo.save(SettingsKey.pageSort(PageKey.inbox), newSort);
/// ```
abstract class SettingsRepositoryContract {
  /// Watch a setting for changes.
  Stream<T> watch<T>(SettingsKey<T> key);

  /// Load the current value of a setting.
  Future<T> load<T>(SettingsKey<T> key);

  /// Save a new value for a setting.
  Future<void> save<T>(SettingsKey<T> key, T value);
}
