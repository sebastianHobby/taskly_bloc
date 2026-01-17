import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_chrome.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_gate_config.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_banner_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_inbox_section_params_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_header_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/hierarchy_value_project_task_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/interleaved_list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';

part 'screen_spec.freezed.dart';

/// Identifies a layout slot in a screen template.
enum SlotId {
  header,
  primary,
}

/// A group of modules assigned to well-known layout slots.
@freezed
abstract class SlottedModules with _$SlottedModules {
  const factory SlottedModules({
    @Default(<ScreenModuleSpec>[]) List<ScreenModuleSpec> header,
    @Default(<ScreenModuleSpec>[]) List<ScreenModuleSpec> primary,
  }) = _SlottedModules;

  const SlottedModules._();

  List<ScreenModuleSpec> forSlot(SlotId slotId) {
    return switch (slotId) {
      SlotId.header => header,
      SlotId.primary => primary,
    };
  }

  bool get isEmpty => header.isEmpty && primary.isEmpty;
}

/// A typed screen definition used for system screens (hard cutover).
///
/// This intentionally avoids string template IDs and JSON params.
@freezed
abstract class ScreenSpec with _$ScreenSpec {
  const factory ScreenSpec({
    required String id,
    required String screenKey,
    required String name,
    required ScreenTemplateSpec template,
    String? description,
    @Default(ScreenChrome.empty) ScreenChrome chrome,
    ScreenGateSpec? gate,
    @Default(SlottedModules()) SlottedModules modules,
  }) = _ScreenSpec;

  const ScreenSpec._();
}

/// A gate that can temporarily replace a screen with a different template.
@freezed
abstract class ScreenGateSpec with _$ScreenGateSpec {
  const factory ScreenGateSpec({
    required ScreenGateCriteria criteria,
    required ScreenTemplateSpec template,
  }) = _ScreenGateSpec;

  const ScreenGateSpec._();
}

/// Screen-level templates (shell/orchestration).
@freezed
sealed class ScreenTemplateSpec with _$ScreenTemplateSpec {
  /// Default scaffold template with header + primary slots.
  const factory ScreenTemplateSpec.standardScaffoldV1() =
      ScreenTemplateStandardScaffoldV1;

  /// Entity detail scaffold template (projects/values RD surfaces).
  ///
  /// This is used for RD pages where the primary content is driven by unified
  /// modules but the top-level chrome is entity-specific (edit/delete actions,
  /// desktop width constraints, etc.).
  const factory ScreenTemplateSpec.entityDetailScaffoldV1() =
      ScreenTemplateEntityDetailScaffoldV1;

  // Full-screen, self-contained templates (feature UIs)
  const factory ScreenTemplateSpec.settingsMenu() = ScreenTemplateSettingsMenu;
  const factory ScreenTemplateSpec.trackerManagement() =
      ScreenTemplateTrackerManagement;
  const factory ScreenTemplateSpec.statisticsDashboard() =
      ScreenTemplateStatisticsDashboard;
  const factory ScreenTemplateSpec.journalHub() = ScreenTemplateJournalHub;
  const factory ScreenTemplateSpec.myDayFocusModeRequired() =
      ScreenTemplateMyDayFocusModeRequired;
}

/// Screen modules (what used to be section templates + params).
@freezed
sealed class ScreenModuleSpec with _$ScreenModuleSpec {
  const factory ScreenModuleSpec.taskListV2({
    required ListSectionParamsV2 params,
    String? title,
  }) = ScreenModuleTaskListV2;

  const factory ScreenModuleSpec.valueListV2({
    required ListSectionParamsV2 params,
    String? title,
  }) = ScreenModuleValueListV2;

  const factory ScreenModuleSpec.interleavedListV2({
    required InterleavedListSectionParamsV2 params,
    String? title,
  }) = ScreenModuleInterleavedListV2;

  const factory ScreenModuleSpec.hierarchyValueProjectTaskV2({
    required HierarchyValueProjectTaskSectionParamsV2 params,
    String? title,
  }) = ScreenModuleHierarchyValueProjectTaskV2;

  const factory ScreenModuleSpec.agendaV2({
    required AgendaSectionParamsV2 params,
    String? title,
  }) = ScreenModuleAgendaV2;

  const factory ScreenModuleSpec.attentionBannerV2({
    required AttentionBannerSectionParamsV2 params,
    String? title,
  }) = ScreenModuleAttentionBannerV2;

  const factory ScreenModuleSpec.attentionInboxV1({
    required AttentionInboxSectionParamsV1 params,
    String? title,
  }) = ScreenModuleAttentionInboxV1;

  const factory ScreenModuleSpec.entityHeader({
    required EntityHeaderSectionParams params,
    String? title,
  }) = ScreenModuleEntityHeader;

  const factory ScreenModuleSpec.myDayHeroV1({
    String? title,
  }) = ScreenModuleMyDayHeroV1;

  const factory ScreenModuleSpec.myDayRankedTasksV1({
    String? title,
  }) = ScreenModuleMyDayRankedTasksV1;

  /// A lightweight CTA module shown on the Values screen.
  const factory ScreenModuleSpec.createValueCtaV1({
    String? title,
  }) = ScreenModuleCreateValueCtaV1;

  // === Journal (Today-first) ===

  /// Journal Today hero/composer module.
  const factory ScreenModuleSpec.journalTodayComposerV1({
    String? title,
  }) = ScreenModuleJournalTodayComposerV1;

  /// Journal Today entries list module.
  const factory ScreenModuleSpec.journalTodayEntriesV1({
    String? title,
  }) = ScreenModuleJournalTodayEntriesV1;

  /// Journal history teaser / navigation CTA.
  const factory ScreenModuleSpec.journalHistoryTeaserV1({
    String? title,
  }) = ScreenModuleJournalHistoryTeaserV1;

  /// Journal history list module (used by journal_history screen).
  const factory ScreenModuleSpec.journalHistoryListV1({
    String? title,
  }) = ScreenModuleJournalHistoryListV1;

  /// Journal tracker management module (used by journal_manage_trackers).
  const factory ScreenModuleSpec.journalManageTrackersV1({
    String? title,
  }) = ScreenModuleJournalManageTrackersV1;
}
