import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_chrome.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_gate_config.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_banner_section_params_v1.dart';
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

  /// Placeholder screen for attention/review overflow.
  const factory ScreenTemplateSpec.reviewInbox() = ScreenTemplateReviewInbox;

  // Full-screen, self-contained templates (feature UIs)
  const factory ScreenTemplateSpec.settingsMenu() = ScreenTemplateSettingsMenu;
  const factory ScreenTemplateSpec.trackerManagement() =
      ScreenTemplateTrackerManagement;
  const factory ScreenTemplateSpec.statisticsDashboard() =
      ScreenTemplateStatisticsDashboard;
  const factory ScreenTemplateSpec.journalHub() = ScreenTemplateJournalHub;
  const factory ScreenTemplateSpec.journalTimeline() =
      ScreenTemplateJournalTimeline;
  const factory ScreenTemplateSpec.allocationSettings() =
      ScreenTemplateAllocationSettings;
  const factory ScreenTemplateSpec.attentionRules() =
      ScreenTemplateAttentionRules;
  const factory ScreenTemplateSpec.focusSetupWizard() =
      ScreenTemplateFocusSetupWizard;
  const factory ScreenTemplateSpec.browseHub() = ScreenTemplateBrowseHub;
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

  const factory ScreenModuleSpec.projectListV2({
    required ListSectionParamsV2 params,
    String? title,
  }) = ScreenModuleProjectListV2;

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

  const factory ScreenModuleSpec.attentionBannerV1({
    required AttentionBannerSectionParamsV1 params,
    String? title,
  }) = ScreenModuleAttentionBannerV1;

  const factory ScreenModuleSpec.entityHeader({
    required EntityHeaderSectionParams params,
    String? title,
  }) = ScreenModuleEntityHeader;
}
