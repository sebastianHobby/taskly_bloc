import 'package:taskly_bloc/domain/models/page_key.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';

/// Type-safe key for accessing settings.
///
/// Each key specifies the return type [T] for type-safe load/watch/save
/// operations. Keys are either singletons (one value per user) or keyed
/// (parameterized by page/screen identifier).
sealed class SettingsKey<T> {
  const SettingsKey._();

  // ─────────────────────────────────────────────────────────────────────────
  // Singleton keys (one value per user)
  // ─────────────────────────────────────────────────────────────────────────

  /// Global app settings (theme, locale, etc.)
  static const global = _SingletonKey<GlobalSettings>('global');

  /// Allocation algorithm settings.
  static const allocation = _SingletonKey<AllocationConfig>('allocation');

  /// Allocation alert configuration.
  static const allocationAlerts = _SingletonKey<AllocationAlertSettings>(
    'allocationAlerts',
  );

  /// Soft gates threshold settings.
  static const softGates = _SingletonKey<SoftGatesSettings>('softGates');

  /// Next actions display settings.
  static const nextActions = _SingletonKey<NextActionsSettings>('nextActions');

  /// Value ranking weights for allocation.
  static const valueRanking = _SingletonKey<ValueRanking>('valueRanking');

  // ─────────────────────────────────────────────────────────────────────────
  // Keyed keys (parameterized by identifier)
  // ─────────────────────────────────────────────────────────────────────────

  /// Sort preferences for a specific page.
  static SettingsKey<SortPreferences?> pageSort(PageKey page) =>
      _KeyedKey<SortPreferences?>('pageSort', page.key);

  /// Display settings for a specific page.
  static SettingsKey<PageDisplaySettings> pageDisplay(PageKey page) =>
      _KeyedKey<PageDisplaySettings>('pageDisplay', page.key);

  /// Screen preferences (sortOrder, isActive) for a system screen.
  static SettingsKey<ScreenPreferences> screenPrefs(String screenKey) =>
      _KeyedKey<ScreenPreferences>('screenPrefs', screenKey);

  // ─────────────────────────────────────────────────────────────────────────
  // Aggregate keys
  // ─────────────────────────────────────────────────────────────────────────

  /// All screen preferences as a map.
  static const allScreenPrefs = _SingletonKey<Map<String, ScreenPreferences>>(
    'allScreenPrefs',
  );

  /// Full AppSettings (for migration/debugging).
  static const all = _SingletonKey<AppSettings>('all');
}

/// A singleton key with no sub-identifier.
final class _SingletonKey<T> extends SettingsKey<T> {
  const _SingletonKey(this.name) : super._();

  /// Debug name for logging.
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _SingletonKey<T> && other.name == name;

  @override
  int get hashCode => Object.hash(_SingletonKey, name, T);

  @override
  String toString() => 'SettingsKey.$name';
}

/// A key parameterized by a sub-identifier (e.g., page key or screen key).
final class _KeyedKey<T> extends SettingsKey<T> {
  const _KeyedKey(this.name, this.subKey) : super._();

  /// Debug name for logging.
  final String name;

  /// The sub-identifier (page key, screen key, etc.)
  final String subKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _KeyedKey<T> && other.name == name && other.subKey == subKey;

  @override
  int get hashCode => Object.hash(_KeyedKey, name, subKey, T);

  @override
  String toString() => 'SettingsKey.$name($subKey)';
}
