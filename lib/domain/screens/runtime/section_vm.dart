import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/language/models/display_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_banner_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_inbox_section_params_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_header_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/hierarchy_value_project_task_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/interleaved_list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';

part 'section_vm.freezed.dart';

/// View model for a resolved screen section.
///
/// This is a sealed model to keep section rendering type-safe and to avoid
/// template-id and param casting throughout presentation.
@freezed
sealed class SectionVm with _$SectionVm {
  const factory SectionVm.taskListV2({
    required int index,
    required ListSectionParamsV2 params,
    String? title,
    SectionDataResult? data,
    DisplayConfig? displayConfig,
    @Default(false) bool isLoading,
    String? error,
  }) = TaskListV2SectionVm;

  const factory SectionVm.valueListV2({
    required int index,
    required ListSectionParamsV2 params,
    String? title,
    SectionDataResult? data,
    DisplayConfig? displayConfig,
    @Default(false) bool isLoading,
    String? error,
  }) = ValueListV2SectionVm;

  const factory SectionVm.interleavedListV2({
    required int index,
    required InterleavedListSectionParamsV2 params,
    String? title,
    SectionDataResult? data,
    DisplayConfig? displayConfig,
    @Default(false) bool isLoading,
    String? error,
  }) = InterleavedListV2SectionVm;

  const factory SectionVm.hierarchyValueProjectTaskV2({
    required int index,
    required HierarchyValueProjectTaskSectionParamsV2 params,
    String? title,
    SectionDataResult? data,
    DisplayConfig? displayConfig,
    @Default(false) bool isLoading,
    String? error,
  }) = HierarchyValueProjectTaskV2SectionVm;

  const factory SectionVm.agendaV2({
    required int index,
    required AgendaSectionParamsV2 params,
    String? title,
    SectionDataResult? data,
    DisplayConfig? displayConfig,
    @Default(false) bool isLoading,
    String? error,
  }) = AgendaV2SectionVm;

  const factory SectionVm.attentionBannerV2({
    required int index,
    required AttentionBannerSectionParamsV2 params,
    String? title,
    SectionDataResult? data,
    DisplayConfig? displayConfig,
    @Default(false) bool isLoading,
    String? error,
  }) = AttentionBannerV2SectionVm;

  const factory SectionVm.attentionInboxV1({
    required int index,
    required AttentionInboxSectionParamsV1 params,
    String? title,
    SectionDataResult? data,
    DisplayConfig? displayConfig,
    @Default(false) bool isLoading,
    String? error,
  }) = AttentionInboxV1SectionVm;

  const factory SectionVm.entityHeader({
    required int index,
    required EntityHeaderSectionParams params,
    String? title,
    SectionDataResult? data,
    DisplayConfig? displayConfig,
    @Default(false) bool isLoading,
    String? error,
  }) = EntityHeaderSectionVm;

  const factory SectionVm.myDayRankedTasksV1({
    required int index,
    String? title,
    SectionDataResult? data,
    DisplayConfig? displayConfig,
    @Default(false) bool isLoading,
    String? error,
  }) = MyDayRankedTasksV1SectionVm;

  const factory SectionVm.myDayHeroV1({
    required int index,
    String? title,
    SectionDataResult? data,
    DisplayConfig? displayConfig,
    @Default(false) bool isLoading,
    String? error,
  }) = MyDayHeroV1SectionVm;

  const factory SectionVm.createValueCtaV1({
    required int index,
    String? title,
    SectionDataResult? data,
    DisplayConfig? displayConfig,
    @Default(false) bool isLoading,
    String? error,
  }) = CreateValueCtaV1SectionVm;

  // === Journal (Today-first) ===

  const factory SectionVm.journalTodayComposerV1({
    required int index,
    String? title,
    SectionDataResult? data,
    DisplayConfig? displayConfig,
    @Default(false) bool isLoading,
    String? error,
  }) = JournalTodayComposerV1SectionVm;

  const factory SectionVm.journalTodayEntriesV1({
    required int index,
    String? title,
    SectionDataResult? data,
    DisplayConfig? displayConfig,
    @Default(false) bool isLoading,
    String? error,
  }) = JournalTodayEntriesV1SectionVm;

  const factory SectionVm.journalHistoryTeaserV1({
    required int index,
    String? title,
    SectionDataResult? data,
    DisplayConfig? displayConfig,
    @Default(false) bool isLoading,
    String? error,
  }) = JournalHistoryTeaserV1SectionVm;

  const factory SectionVm.journalHistoryListV1({
    required int index,
    String? title,
    SectionDataResult? data,
    DisplayConfig? displayConfig,
    @Default(false) bool isLoading,
    String? error,
  }) = JournalHistoryListV1SectionVm;

  const factory SectionVm.journalManageTrackersV1({
    required int index,
    String? title,
    SectionDataResult? data,
    DisplayConfig? displayConfig,
    @Default(false) bool isLoading,
    String? error,
  }) = JournalManageTrackersV1SectionVm;

  const factory SectionVm.unknown({
    required int index,
    required Object params,
    String? title,
    SectionDataResult? data,
    DisplayConfig? displayConfig,
    @Default(false) bool isLoading,
    String? error,
  }) = UnknownSectionVm;

  const SectionVm._();

  String get templateId => map(
    taskListV2: (_) => SectionTemplateId.taskListV2,
    valueListV2: (_) => SectionTemplateId.valueListV2,
    interleavedListV2: (_) => SectionTemplateId.interleavedListV2,
    hierarchyValueProjectTaskV2: (_) =>
        SectionTemplateId.hierarchyValueProjectTaskV2,
    agendaV2: (_) => SectionTemplateId.agendaV2,
    attentionBannerV2: (_) => SectionTemplateId.attentionBannerV2,
    attentionInboxV1: (_) => SectionTemplateId.attentionInboxV1,
    entityHeader: (_) => SectionTemplateId.entityHeader,
    myDayRankedTasksV1: (_) => SectionTemplateId.myDayRankedTasksV1,
    myDayHeroV1: (_) => SectionTemplateId.myDayHeroV1,
    createValueCtaV1: (_) => SectionTemplateId.createValueCtaV1,
    journalTodayComposerV1: (_) => SectionTemplateId.journalTodayComposerV1,
    journalTodayEntriesV1: (_) => SectionTemplateId.journalTodayEntriesV1,
    journalHistoryTeaserV1: (_) => SectionTemplateId.journalHistoryTeaserV1,
    journalHistoryListV1: (_) => SectionTemplateId.journalHistoryListV1,
    journalManageTrackersV1: (_) => SectionTemplateId.journalManageTrackersV1,
    unknown: (_) => 'unknown',
  );
}
