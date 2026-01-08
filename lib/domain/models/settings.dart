/// Settings models for the application.
///
/// This file serves as the main barrel export for all settings-related models.
/// Import this file to access all settings types.
library;

export 'settings/alert_severity.dart';
export 'settings/allocation_alert_config.dart';
export 'settings/allocation_alert_rule.dart';
export 'settings/allocation_alert_templates.dart';
export 'settings/allocation_alert_type.dart';
export 'settings/allocation_config.dart';
export 'settings/app_theme_mode.dart';
export 'settings/date_format_patterns.dart';
export 'settings/evaluated_alert.dart';
export 'settings/global_settings.dart';
export 'settings/next_actions_settings.dart';
export 'settings/page_display_settings.dart';
export 'settings/screen_preferences.dart';
export 'settings/settings_page_key.dart';
export 'settings/soft_gates_settings.dart';

import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/domain/models/settings/global_settings.dart';
import 'package:taskly_bloc/domain/models/settings/next_actions_settings.dart';
import 'package:taskly_bloc/domain/models/settings/page_display_settings.dart';
import 'package:taskly_bloc/domain/models/settings/soft_gates_settings.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';

/// Main application settings container.
///
/// Aggregates all settings groups into a single serializable object.
///
/// Note: screenPreferences and valueRanking have been removed as part of
/// the attention system migration. Screen preferences are now stored directly
/// in the screen_definitions table (isActive, sortOrder columns).
class AppSettings {
  const AppSettings({
    this.global = const GlobalSettings(),
    this.pageSortPreferences = const <String, SortPreferences>{},
    this.pageDisplaySettings = const <String, PageDisplaySettings>{},
    this.allocation = const AllocationConfig(),
    SoftGatesSettings? softGates,
    NextActionsSettings? nextActions,
  }) : softGates = softGates ?? const SoftGatesSettings(),
       nextActions = nextActions ?? const NextActionsSettings();

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final globalJson = json['global'] as Map<String, dynamic>?;
    final global = globalJson != null
        ? GlobalSettings.fromJson(globalJson)
        : const GlobalSettings();

    final rawSorts = json['pageSortPreferences'] as Map<String, dynamic>?;
    final sorts = <String, SortPreferences>{};
    rawSorts?.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        sorts[key] = SortPreferences.fromJson(value);
      }
    });

    final rawDisplaySettings =
        json['pageDisplaySettings'] as Map<String, dynamic>?;
    final displaySettings = <String, PageDisplaySettings>{};
    rawDisplaySettings?.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        displaySettings[key] = PageDisplaySettings.fromJson(value);
      }
    });

    final allocationJson = json['allocation'] as Map<String, dynamic>?;
    final allocation = allocationJson != null
        ? AllocationConfig.fromJson(allocationJson)
        : const AllocationConfig();

    final nextActionsJson = json['nextActions'] as Map<String, dynamic>?;
    final nextActions = nextActionsJson == null
        ? const NextActionsSettings()
        : NextActionsSettings.fromJson(nextActionsJson);

    final softGatesJson = json['softGates'] as Map<String, dynamic>?;
    final softGates = softGatesJson == null
        ? const SoftGatesSettings()
        : SoftGatesSettings.fromJson(softGatesJson);
    return AppSettings(
      global: global,
      pageSortPreferences: sorts,
      pageDisplaySettings: displaySettings,
      allocation: allocation,
      softGates: softGates,
      nextActions: nextActions,
    );
  }

  final GlobalSettings global;
  final Map<String, SortPreferences> pageSortPreferences;
  final Map<String, PageDisplaySettings> pageDisplaySettings;

  /// Allocation strategy settings (replaces allocation_preferences table).
  final AllocationConfig allocation;

  final SoftGatesSettings softGates;
  final NextActionsSettings nextActions;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'global': global.toJson(),
    'pageSortPreferences': pageSortPreferences.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'pageDisplaySettings': pageDisplaySettings.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
    'allocation': allocation.toJson(),
    'softGates': softGates.toJson(),
    'nextActions': nextActions.toJson(),
  };

  AppSettings copyWith({
    GlobalSettings? global,
    Map<String, SortPreferences>? pageSortPreferences,
    Map<String, PageDisplaySettings>? pageDisplaySettings,
    AllocationConfig? allocation,
    SoftGatesSettings? softGates,
    NextActionsSettings? nextActions,
  }) {
    return AppSettings(
      global: global ?? this.global,
      pageSortPreferences: pageSortPreferences ?? this.pageSortPreferences,
      pageDisplaySettings: pageDisplaySettings ?? this.pageDisplaySettings,
      allocation: allocation ?? this.allocation,
      softGates: softGates ?? this.softGates,
      nextActions: nextActions ?? this.nextActions,
    );
  }

  AppSettings updateGlobal(GlobalSettings value) {
    return copyWith(global: value);
  }

  AppSettings updateSoftGates(SoftGatesSettings value) {
    return copyWith(softGates: value);
  }

  SortPreferences? sortFor(String pageKey) => pageSortPreferences[pageKey];

  PageDisplaySettings displaySettingsFor(String pageKey) =>
      pageDisplaySettings[pageKey] ?? const PageDisplaySettings();

  AppSettings upsertPageSort({
    required String pageKey,
    required SortPreferences preferences,
  }) {
    final updated = Map<String, SortPreferences>.from(pageSortPreferences)
      ..[pageKey] = preferences;
    return copyWith(pageSortPreferences: updated);
  }

  AppSettings upsertPageDisplaySettings({
    required String pageKey,
    required PageDisplaySettings settings,
  }) {
    final updated = Map<String, PageDisplaySettings>.from(pageDisplaySettings)
      ..[pageKey] = settings;
    return copyWith(pageDisplaySettings: updated);
  }

  AppSettings updateNextActions(NextActionsSettings value) {
    return copyWith(nextActions: value);
  }

  /// Update allocation settings.
  AppSettings updateAllocation(AllocationConfig value) {
    return copyWith(allocation: value);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AppSettings) return false;
    if (other.pageSortPreferences.length != pageSortPreferences.length) {
      return false;
    }
    for (final entry in pageSortPreferences.entries) {
      final otherValue = other.pageSortPreferences[entry.key];
      if (otherValue != entry.value) return false;
    }
    if (other.pageDisplaySettings.length != pageDisplaySettings.length) {
      return false;
    }
    for (final entry in pageDisplaySettings.entries) {
      final otherValue = other.pageDisplaySettings[entry.key];
      if (otherValue != entry.value) return false;
    }
    return other.global == global &&
        other.allocation == allocation &&
        other.softGates == softGates &&
        other.nextActions == nextActions;
  }

  @override
  int get hashCode => Object.hash(
    global,
    pageSortPreferences.entries
        .map((e) => Object.hash(e.key, e.value))
        .fold<int>(0, (prev, element) => prev ^ element.hashCode),
    pageDisplaySettings.entries
        .map((e) => Object.hash(e.key, e.value))
        .fold<int>(0, (prev, element) => prev ^ element.hashCode),
    allocation,
    softGates,
    nextActions,
  );
}
