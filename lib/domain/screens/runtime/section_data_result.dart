import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/screens/language/models/agenda_data.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/attention/model/attention_item.dart';

part 'section_data_result.freezed.dart';

/// Result of fetching data for a section.
///
/// Each variant contains the data appropriate for that section type.
/// Used by the screen data interpreter to populate section UIs with data.
@freezed
sealed class SectionDataResult with _$SectionDataResult {
  /// Data section result - generic entity list with optional enrichment.
  const factory SectionDataResult.data({
    required List<ScreenItem> items,

    /// Computed enrichment data (e.g., value statistics).
    /// Present when the section requested enrichment via an enrichment plan.
    EnrichmentResultV2? enrichment,
  }) = DataSectionResult;

  /// V2 data section result - generic entity list with typed V2 enrichment.
  ///
  /// Unlike the `data` variant, this carries no related-entities sidecar.
  const factory SectionDataResult.dataV2({
    required List<ScreenItem> items,
    EnrichmentResultV2? enrichment,
  }) = DataV2SectionResult;

  /// Agenda section result - timeline with tasks and projects grouped by date
  const factory SectionDataResult.agenda({
    required AgendaData agendaData,
    EnrichmentResultV2? enrichment,
  }) = AgendaSectionResult;

  /// Unified attention banner (bucket-aware cutover v1).
  const factory SectionDataResult.attentionBannerV1({
    required int actionCount,
    required int reviewCount,
    required int criticalCount,
    required int warningCount,
    required int infoCount,
    required String overflowScreenKey,
    @Default(<AttentionItem>[]) List<AttentionItem> previewItems,
  }) = AttentionBannerV1SectionResult;

  /// Entity header for project detail screens.
  const factory SectionDataResult.entityHeaderProject({
    required Project project,
    @Default(true) bool showCheckbox,
    @Default(true) bool showMetadata,
  }) = EntityHeaderProjectSectionResult;

  /// Entity header for value detail screens.
  const factory SectionDataResult.entityHeaderValue({
    required Value value,
    int? taskCount,
    @Default(true) bool showMetadata,
  }) = EntityHeaderValueSectionResult;

  /// Missing entity header result (entity not found or unsupported type).
  const factory SectionDataResult.entityHeaderMissing({
    required String entityType,
    required String entityId,
  }) = EntityHeaderMissingSectionResult;

  const SectionDataResult._();

  /// Get all tasks from any result type
  List<Task> get allTasks => switch (this) {
    DataSectionResult(:final items) =>
      items
          .whereType<ScreenItemTask>()
          .map((i) => i.task)
          .whereType<Task>()
          .toList(),
    DataV2SectionResult(:final items) =>
      items
          .whereType<ScreenItemTask>()
          .map((i) => i.task)
          .whereType<Task>()
          .toList(),
    AgendaSectionResult(:final agendaData) =>
      agendaData.groups
          .expand((g) => g.items)
          .where((i) => i.isTask)
          .map((i) => i.task)
          .whereType<Task>()
          .toList(),
    _ => [],
  };

  /// Get all projects from any result type
  List<Project> get allProjects => switch (this) {
    DataSectionResult(:final items) =>
      items
          .whereType<ScreenItemProject>()
          .map((i) => i.project)
          .whereType<Project>()
          .toList(),
    DataV2SectionResult(:final items) =>
      items
          .whereType<ScreenItemProject>()
          .map((i) => i.project)
          .whereType<Project>()
          .toList(),
    AgendaSectionResult(:final agendaData) =>
      agendaData.groups
          .expand((g) => g.items)
          .where((i) => i.isProject)
          .map((i) => i.project)
          .whereType<Project>()
          .toList(),
    EntityHeaderProjectSectionResult(:final project) => [project],
    _ => [],
  };

  /// Get all values from any result type
  List<Value> get allValues => switch (this) {
    DataSectionResult(:final items) =>
      items.whereType<ScreenItemValue>().map((i) => i.value).toList(),
    DataV2SectionResult(:final items) =>
      items.whereType<ScreenItemValue>().map((i) => i.value).toList(),
    EntityHeaderValueSectionResult(:final value) => [value],
    _ => [],
  };

  /// Count of primary entities for logging
  int get primaryCount => switch (this) {
    DataSectionResult(:final items) => items.length,
    DataV2SectionResult(:final items) => items.length,
    AgendaSectionResult(:final agendaData) =>
      agendaData.groups.fold(0, (sum, g) => sum + g.items.length) +
          agendaData.overdueItems.length,
    _ => 0,
  };
}
