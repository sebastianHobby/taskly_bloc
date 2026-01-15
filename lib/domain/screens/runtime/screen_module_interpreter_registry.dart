import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/agenda_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/attention_banner_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/attention_inbox_section_interpreter_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/data_list_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/entity_header_section_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/hierarchy_value_project_task_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/interleaved_list_section_interpreter_v2.dart';
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
    required ScreenModuleSpec module,
  });
}

/// Default registry implementation used by the typed unified screen pipeline.
final class DefaultScreenModuleInterpreterRegistry
    implements ScreenModuleInterpreterRegistry {
  DefaultScreenModuleInterpreterRegistry({
    required DataListSectionInterpreterV2 taskListInterpreter,
    required DataListSectionInterpreterV2 valueListInterpreter,
    required InterleavedListSectionInterpreterV2 interleavedListInterpreter,
    required HierarchyValueProjectTaskSectionInterpreterV2
    hierarchyValueProjectTaskInterpreter,
    required AgendaSectionInterpreterV2 agendaInterpreter,
    required AttentionBannerSectionInterpreterV2 attentionBannerV2Interpreter,
    required AttentionInboxSectionInterpreterV1 attentionInboxInterpreter,
    required EntityHeaderSectionInterpreter entityHeaderInterpreter,
  }) : _taskListInterpreter = taskListInterpreter,
       _valueListInterpreter = valueListInterpreter,
       _interleavedListInterpreter = interleavedListInterpreter,
       _hierarchyValueProjectTaskInterpreter =
           hierarchyValueProjectTaskInterpreter,
       _agendaInterpreter = agendaInterpreter,
       _attentionBannerV2Interpreter = attentionBannerV2Interpreter,
       _attentionInboxInterpreter = attentionInboxInterpreter,
       _entityHeaderInterpreter = entityHeaderInterpreter;

  final DataListSectionInterpreterV2 _taskListInterpreter;
  final DataListSectionInterpreterV2 _valueListInterpreter;
  final InterleavedListSectionInterpreterV2 _interleavedListInterpreter;
  final HierarchyValueProjectTaskSectionInterpreterV2
  _hierarchyValueProjectTaskInterpreter;
  final AgendaSectionInterpreterV2 _agendaInterpreter;
  final AttentionBannerSectionInterpreterV2 _attentionBannerV2Interpreter;
  final AttentionInboxSectionInterpreterV1 _attentionInboxInterpreter;
  final EntityHeaderSectionInterpreter _entityHeaderInterpreter;

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
    required ScreenModuleSpec module,
  }) {
    try {
      return module.map(
        taskListV2: (m) => _taskListInterpreter
            .watch(m.params)
            .map(
              (data) {
                return SectionVm.taskListV2(
                  index: index,
                  params: m.params,
                  title: m.title,
                  data: _coerceSectionDataResult(data),
                );
              },
            )
            .onErrorReturnWith((error, _) {
              return SectionVm.taskListV2(
                index: index,
                params: m.params,
                title: m.title,
                error: error.toString(),
              );
            }),
        valueListV2: (m) => _valueListInterpreter
            .watch(m.params)
            .map(
              (data) {
                return SectionVm.valueListV2(
                  index: index,
                  params: m.params,
                  title: m.title,
                  data: _coerceSectionDataResult(data),
                );
              },
            )
            .onErrorReturnWith((error, _) {
              return SectionVm.valueListV2(
                index: index,
                params: m.params,
                title: m.title,
                error: error.toString(),
              );
            }),
        interleavedListV2: (m) => _interleavedListInterpreter
            .watch(m.params)
            .map(
              (data) {
                return SectionVm.interleavedListV2(
                  index: index,
                  params: m.params,
                  title: m.title,
                  data: _coerceSectionDataResult(data),
                );
              },
            )
            .onErrorReturnWith((error, _) {
              return SectionVm.interleavedListV2(
                index: index,
                params: m.params,
                title: m.title,
                error: error.toString(),
              );
            }),
        hierarchyValueProjectTaskV2: (m) =>
            _hierarchyValueProjectTaskInterpreter
                .watch(m.params)
                .map(
                  (data) {
                    return SectionVm.hierarchyValueProjectTaskV2(
                      index: index,
                      params: m.params,
                      title: m.title,
                      data: _coerceSectionDataResult(data),
                    );
                  },
                )
                .onErrorReturnWith((error, _) {
                  return SectionVm.hierarchyValueProjectTaskV2(
                    index: index,
                    params: m.params,
                    title: m.title,
                    error: error.toString(),
                  );
                }),
        agendaV2: (m) => _agendaInterpreter
            .watch(m.params)
            .map(
              (data) {
                return SectionVm.agendaV2(
                  index: index,
                  params: m.params,
                  title: m.title,
                  data: _coerceSectionDataResult(data),
                );
              },
            )
            .onErrorReturnWith((error, _) {
              return SectionVm.agendaV2(
                index: index,
                params: m.params,
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
