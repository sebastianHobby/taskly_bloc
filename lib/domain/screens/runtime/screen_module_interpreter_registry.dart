import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_style_resolver.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/agenda_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/attention_banner_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/attention_inbox_section_interpreter_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/data_list_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/entity_header_section_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/hierarchy_value_project_task_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/interleaved_list_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/journal_history_list_module_interpreter_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/journal_manage_trackers_module_interpreter_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/journal_today_composer_module_interpreter_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/journal_today_entries_module_interpreter_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/my_day_hero_v1_module_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/my_day_ranked_tasks_v1_module_interpreter.dart';
import 'package:rxdart/rxdart.dart';

/// Registry that routes typed [ScreenModuleSpec] variants to their interpreters.
///
/// This centralizes the module -> interpreter mapping so [ScreenSpecDataInterpreter]
/// stays focused on orchestration (gates, combining streams, slotting).
abstract interface class ScreenModuleInterpreterRegistry {
  /// Interprets [module] into a reactive [SectionVm] stream.
  ///
  /// The returned stream should be resilient: errors should be mapped to a
  /// section-level error VM where possible.
  Stream<SectionVm> watch({
    required int index,
    required ScreenTemplateSpec screenTemplate,
    required ScreenModuleSpec module,
  });
}

/// Default registry implementation used by the typed unified screen pipeline.
final class DefaultScreenModuleInterpreterRegistry
    implements ScreenModuleInterpreterRegistry {
  DefaultScreenModuleInterpreterRegistry({
    required EntityStyleResolver entityStyleResolver,
    required DataListSectionInterpreterV2 taskListInterpreter,
    required DataListSectionInterpreterV2 valueListInterpreter,
    required InterleavedListSectionInterpreterV2 interleavedListInterpreter,
    required HierarchyValueProjectTaskSectionInterpreterV2
    hierarchyValueProjectTaskInterpreter,
    required AgendaSectionInterpreterV2 agendaInterpreter,
    required AttentionBannerSectionInterpreterV2 attentionBannerV2Interpreter,
    required AttentionInboxSectionInterpreterV1 attentionInboxInterpreter,
    required EntityHeaderSectionInterpreter entityHeaderInterpreter,
    required MyDayHeroV1ModuleInterpreter myDayHeroV1Interpreter,
    required MyDayRankedTasksV1ModuleInterpreter myDayRankedTasksV1Interpreter,
    required JournalTodayComposerModuleInterpreterV1
    journalTodayComposerV1Interpreter,
    required JournalTodayEntriesModuleInterpreterV1
    journalTodayEntriesV1Interpreter,
    required JournalHistoryListModuleInterpreterV1
    journalHistoryListV1Interpreter,
    required JournalManageTrackersModuleInterpreterV1
    journalManageTrackersV1Interpreter,
  }) : _entityStyleResolver = entityStyleResolver,
       _taskListInterpreter = taskListInterpreter,
       _valueListInterpreter = valueListInterpreter,
       _interleavedListInterpreter = interleavedListInterpreter,
       _hierarchyValueProjectTaskInterpreter =
           hierarchyValueProjectTaskInterpreter,
       _agendaInterpreter = agendaInterpreter,
       _attentionBannerV2Interpreter = attentionBannerV2Interpreter,
       _attentionInboxInterpreter = attentionInboxInterpreter,
       _entityHeaderInterpreter = entityHeaderInterpreter,
       _myDayHeroV1Interpreter = myDayHeroV1Interpreter,
       _myDayRankedTasksV1Interpreter = myDayRankedTasksV1Interpreter,
       _journalTodayComposerV1Interpreter = journalTodayComposerV1Interpreter,
       _journalTodayEntriesV1Interpreter = journalTodayEntriesV1Interpreter,
       _journalHistoryListV1Interpreter = journalHistoryListV1Interpreter,
       _journalManageTrackersV1Interpreter = journalManageTrackersV1Interpreter;

  final EntityStyleResolver _entityStyleResolver;

  final DataListSectionInterpreterV2 _taskListInterpreter;
  final DataListSectionInterpreterV2 _valueListInterpreter;
  final InterleavedListSectionInterpreterV2 _interleavedListInterpreter;
  final HierarchyValueProjectTaskSectionInterpreterV2
  _hierarchyValueProjectTaskInterpreter;
  final AgendaSectionInterpreterV2 _agendaInterpreter;
  final AttentionBannerSectionInterpreterV2 _attentionBannerV2Interpreter;
  final AttentionInboxSectionInterpreterV1 _attentionInboxInterpreter;
  final EntityHeaderSectionInterpreter _entityHeaderInterpreter;
  final MyDayHeroV1ModuleInterpreter _myDayHeroV1Interpreter;
  final MyDayRankedTasksV1ModuleInterpreter _myDayRankedTasksV1Interpreter;
  final JournalTodayComposerModuleInterpreterV1
  _journalTodayComposerV1Interpreter;
  final JournalTodayEntriesModuleInterpreterV1
  _journalTodayEntriesV1Interpreter;
  final JournalHistoryListModuleInterpreterV1 _journalHistoryListV1Interpreter;
  final JournalManageTrackersModuleInterpreterV1
  _journalManageTrackersV1Interpreter;

  SectionDataResult? _coerceSectionDataResult(Object? data) {
    if (data == null) return null;
    if (data is SectionDataResult) return data;
    throw StateError(
      'Interpreter returned unsupported data type: ${data.runtimeType}',
    );
  }

  @override
  Stream<SectionVm> watch({
    required int index,
    required ScreenTemplateSpec screenTemplate,
    required ScreenModuleSpec module,
  }) {
    try {
      return module.map(
        taskListV2: (m) => _taskListInterpreter
            .watch(m.params)
            .map(
              (data) {
                final entityStyle = _entityStyleResolver.resolve(
                  template: screenTemplate,
                  sectionTemplateId: SectionTemplateId.taskListV2,
                  override: m.params.entityStyleOverride,
                );
                return SectionVm.taskListV2(
                  index: index,
                  params: m.params,
                  entityStyle: entityStyle,
                  title: m.title,
                  data: _coerceSectionDataResult(data),
                );
              },
            )
            .onErrorReturnWith((error, _) {
              final entityStyle = _entityStyleResolver.resolve(
                template: screenTemplate,
                sectionTemplateId: SectionTemplateId.taskListV2,
                override: m.params.entityStyleOverride,
              );
              return SectionVm.taskListV2(
                index: index,
                params: m.params,
                entityStyle: entityStyle,
                title: m.title,
                error: error.toString(),
              );
            }),
        valueListV2: (m) => _valueListInterpreter
            .watch(m.params)
            .map(
              (data) {
                final entityStyle = _entityStyleResolver.resolve(
                  template: screenTemplate,
                  sectionTemplateId: SectionTemplateId.valueListV2,
                  override: m.params.entityStyleOverride,
                );
                return SectionVm.valueListV2(
                  index: index,
                  params: m.params,
                  entityStyle: entityStyle,
                  title: m.title,
                  data: _coerceSectionDataResult(data),
                );
              },
            )
            .onErrorReturnWith((error, _) {
              final entityStyle = _entityStyleResolver.resolve(
                template: screenTemplate,
                sectionTemplateId: SectionTemplateId.valueListV2,
                override: m.params.entityStyleOverride,
              );
              return SectionVm.valueListV2(
                index: index,
                params: m.params,
                entityStyle: entityStyle,
                title: m.title,
                error: error.toString(),
              );
            }),
        interleavedListV2: (m) => _interleavedListInterpreter
            .watch(m.params)
            .map(
              (data) {
                final entityStyle = _entityStyleResolver.resolve(
                  template: screenTemplate,
                  sectionTemplateId: SectionTemplateId.interleavedListV2,
                  override: m.params.entityStyleOverride,
                );
                return SectionVm.interleavedListV2(
                  index: index,
                  params: m.params,
                  entityStyle: entityStyle,
                  title: m.title,
                  data: _coerceSectionDataResult(data),
                );
              },
            )
            .onErrorReturnWith((error, _) {
              final entityStyle = _entityStyleResolver.resolve(
                template: screenTemplate,
                sectionTemplateId: SectionTemplateId.interleavedListV2,
                override: m.params.entityStyleOverride,
              );
              return SectionVm.interleavedListV2(
                index: index,
                params: m.params,
                entityStyle: entityStyle,
                title: m.title,
                error: error.toString(),
              );
            }),
        hierarchyValueProjectTaskV2: (m) =>
            _hierarchyValueProjectTaskInterpreter
                .watch(m.params)
                .map(
                  (data) {
                    final entityStyle = _entityStyleResolver.resolve(
                      template: screenTemplate,
                      sectionTemplateId:
                          SectionTemplateId.hierarchyValueProjectTaskV2,
                      override: m.params.entityStyleOverride,
                    );
                    return SectionVm.hierarchyValueProjectTaskV2(
                      index: index,
                      params: m.params,
                      entityStyle: entityStyle,
                      title: m.title,
                      data: _coerceSectionDataResult(data),
                    );
                  },
                )
                .onErrorReturnWith((error, _) {
                  final entityStyle = _entityStyleResolver.resolve(
                    template: screenTemplate,
                    sectionTemplateId:
                        SectionTemplateId.hierarchyValueProjectTaskV2,
                    override: m.params.entityStyleOverride,
                  );
                  return SectionVm.hierarchyValueProjectTaskV2(
                    index: index,
                    params: m.params,
                    entityStyle: entityStyle,
                    title: m.title,
                    error: error.toString(),
                  );
                }),
        agendaV2: (m) => _agendaInterpreter
            .watch(m.params)
            .map(
              (data) {
                final entityStyle = _entityStyleResolver.resolve(
                  template: screenTemplate,
                  sectionTemplateId: SectionTemplateId.agendaV2,
                  override: m.params.entityStyleOverride,
                );
                return SectionVm.agendaV2(
                  index: index,
                  params: m.params,
                  entityStyle: entityStyle,
                  title: m.title,
                  data: _coerceSectionDataResult(data),
                );
              },
            )
            .onErrorReturnWith((error, _) {
              final entityStyle = _entityStyleResolver.resolve(
                template: screenTemplate,
                sectionTemplateId: SectionTemplateId.agendaV2,
                override: m.params.entityStyleOverride,
              );
              return SectionVm.agendaV2(
                index: index,
                params: m.params,
                entityStyle: entityStyle,
                title: m.title,
                error: error.toString(),
              );
            }),
        attentionBannerV2: (m) => _attentionBannerV2Interpreter
            .watch(m.params)
            .map(
              (data) {
                return SectionVm.attentionBannerV2(
                  index: index,
                  params: m.params,
                  title: m.title,
                  data: _coerceSectionDataResult(data),
                );
              },
            )
            .onErrorReturnWith((error, _) {
              return SectionVm.attentionBannerV2(
                index: index,
                params: m.params,
                title: m.title,
                error: error.toString(),
              );
            }),
        attentionInboxV1: (m) => _attentionInboxInterpreter
            .watch(m.params)
            .map(
              (data) {
                return SectionVm.attentionInboxV1(
                  index: index,
                  params: m.params,
                  title: m.title,
                  data: _coerceSectionDataResult(data),
                );
              },
            )
            .onErrorReturnWith((error, _) {
              return SectionVm.attentionInboxV1(
                index: index,
                params: m.params,
                title: m.title,
                error: error.toString(),
              );
            }),
        entityHeader: (m) => _entityHeaderInterpreter
            .watch(m.params)
            .map(
              (data) {
                return SectionVm.entityHeader(
                  index: index,
                  params: m.params,
                  title: m.title,
                  data: _coerceSectionDataResult(data),
                );
              },
            )
            .onErrorReturnWith((error, _) {
              return SectionVm.entityHeader(
                index: index,
                params: m.params,
                title: m.title,
                error: error.toString(),
              );
            }),
        myDayHeroV1: (m) => _myDayHeroV1Interpreter
            .watch()
            .map(
              (data) {
                return SectionVm.myDayHeroV1(
                  index: index,
                  title: m.title,
                  data: _coerceSectionDataResult(data),
                );
              },
            )
            .onErrorReturnWith((error, _) {
              return SectionVm.myDayHeroV1(
                index: index,
                title: m.title,
                error: error.toString(),
              );
            }),
        myDayRankedTasksV1: (m) => _myDayRankedTasksV1Interpreter
            .watch()
            .map(
              (data) {
                return SectionVm.myDayRankedTasksV1(
                  index: index,
                  entityStyle: _entityStyleResolver.resolve(
                    template: screenTemplate,
                    sectionTemplateId: SectionTemplateId.myDayRankedTasksV1,
                  ),
                  title: m.title,
                  data: _coerceSectionDataResult(data),
                );
              },
            )
            .onErrorReturnWith((error, _) {
              return SectionVm.myDayRankedTasksV1(
                index: index,
                entityStyle: _entityStyleResolver.resolve(
                  template: screenTemplate,
                  sectionTemplateId: SectionTemplateId.myDayRankedTasksV1,
                ),
                title: m.title,
                error: error.toString(),
              );
            }),

        createValueCtaV1: (m) => Stream.value(
          SectionVm.createValueCtaV1(
            index: index,
            title: m.title,
          ),
        ),

        journalTodayComposerV1: (m) => _journalTodayComposerV1Interpreter
            .watch()
            .map(
              (data) => SectionVm.journalTodayComposerV1(
                index: index,
                title: m.title,
                data: _coerceSectionDataResult(data),
              ),
            )
            .onErrorReturnWith((error, _) {
              return SectionVm.journalTodayComposerV1(
                index: index,
                title: m.title,
                error: error.toString(),
              );
            }),
        journalTodayEntriesV1: (m) => _journalTodayEntriesV1Interpreter
            .watch()
            .map(
              (data) => SectionVm.journalTodayEntriesV1(
                index: index,
                title: m.title,
                data: _coerceSectionDataResult(data),
              ),
            )
            .onErrorReturnWith((error, _) {
              return SectionVm.journalTodayEntriesV1(
                index: index,
                title: m.title,
                error: error.toString(),
              );
            }),
        journalHistoryTeaserV1: (m) => Stream.value(
          SectionVm.journalHistoryTeaserV1(
            index: index,
            title: m.title,
          ),
        ),
        journalHistoryListV1: (m) => _journalHistoryListV1Interpreter
            .watch()
            .map(
              (data) => SectionVm.journalHistoryListV1(
                index: index,
                title: m.title,
                data: _coerceSectionDataResult(data),
              ),
            )
            .onErrorReturnWith((error, _) {
              return SectionVm.journalHistoryListV1(
                index: index,
                title: m.title,
                error: error.toString(),
              );
            }),
        journalManageTrackersV1: (m) => _journalManageTrackersV1Interpreter
            .watch()
            .map(
              (data) => SectionVm.journalManageTrackersV1(
                index: index,
                title: m.title,
                data: _coerceSectionDataResult(data),
              ),
            )
            .onErrorReturnWith((error, _) {
              return SectionVm.journalManageTrackersV1(
                index: index,
                title: m.title,
                error: error.toString(),
              );
            }),
      );
    } catch (e) {
      return Stream.value(
        SectionVm.unknown(
          index: index,
          params: module,
          error: e.toString(),
        ),
      );
    }
  }
}
