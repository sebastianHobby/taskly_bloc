import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_config.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/preferences/model/settings_key.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_gate_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/attention_banner_section_interpreter_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/agenda_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/data_list_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/entity_header_section_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/hierarchy_value_project_task_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/interleaved_list_section_interpreter_v2.dart';

/// Interprets a typed [ScreenSpec] into a reactive stream of [ScreenSpecData].
///
/// Unlike [ScreenDataInterpreter], this path avoids JSON params + templateId
/// registries at the screen-definition level. Modules carry typed params and are
/// routed directly to their typed interpreters.
class ScreenSpecDataInterpreter {
  ScreenSpecDataInterpreter({
    required SettingsRepositoryContract settingsRepository,
    required ValueRepositoryContract valueRepository,
    required DataListSectionInterpreterV2 taskListInterpreter,
    required DataListSectionInterpreterV2 projectListInterpreter,
    required DataListSectionInterpreterV2 valueListInterpreter,
    required InterleavedListSectionInterpreterV2 interleavedListInterpreter,
    required HierarchyValueProjectTaskSectionInterpreterV2
    hierarchyValueProjectTaskInterpreter,
    required AgendaSectionInterpreterV2 agendaInterpreter,
    required AttentionBannerSectionInterpreterV1 attentionBannerInterpreter,
    required EntityHeaderSectionInterpreter entityHeaderInterpreter,
  }) : _settingsRepository = settingsRepository,
       _valueRepository = valueRepository,
       _taskListInterpreter = taskListInterpreter,
       _projectListInterpreter = projectListInterpreter,
       _valueListInterpreter = valueListInterpreter,
       _interleavedListInterpreter = interleavedListInterpreter,
       _hierarchyValueProjectTaskInterpreter =
           hierarchyValueProjectTaskInterpreter,
       _agendaInterpreter = agendaInterpreter,
       _attentionBannerInterpreter = attentionBannerInterpreter,
       _entityHeaderInterpreter = entityHeaderInterpreter;

  final SettingsRepositoryContract _settingsRepository;
  final ValueRepositoryContract _valueRepository;

  final DataListSectionInterpreterV2 _taskListInterpreter;
  final DataListSectionInterpreterV2 _projectListInterpreter;
  final DataListSectionInterpreterV2 _valueListInterpreter;
  final InterleavedListSectionInterpreterV2 _interleavedListInterpreter;
  final HierarchyValueProjectTaskSectionInterpreterV2
  _hierarchyValueProjectTaskInterpreter;
  final AgendaSectionInterpreterV2 _agendaInterpreter;
  final AttentionBannerSectionInterpreterV1 _attentionBannerInterpreter;
  final EntityHeaderSectionInterpreter _entityHeaderInterpreter;

  Stream<ScreenSpecData> watchScreen(ScreenSpec spec) {
    final gate = spec.gate;
    if (gate == null) {
      return _watchUngated(spec);
    }

    return _watchGateActive(gate.criteria).distinct().switchMap((isActive) {
      if (isActive) {
        return Stream.value(
          ScreenSpecData(
            spec: spec,
            template: gate.template,
            sections: const SlottedSectionVms(),
          ),
        );
      }

      return _watchUngated(spec);
    });
  }

  Stream<bool> _watchGateActive(ScreenGateCriteria criteria) {
    return switch (criteria) {
      AllocationFocusModeNotSelectedGateCriteria() =>
        _settingsRepository
            .watch<AllocationConfig>(SettingsKey.allocation)
            .map((c) => !c.hasSelectedFocusMode),
      MyDayPrereqsMissingGateCriteria() => Rx.combineLatest2(
        _settingsRepository
            .watch<AllocationConfig>(SettingsKey.allocation)
            .map((c) => !c.hasSelectedFocusMode)
            .distinct(),
        _valueRepository.watchAll().map((values) => values.isEmpty).distinct(),
        (needsFocusModeSetup, needsValuesSetup) =>
            needsFocusModeSetup || needsValuesSetup,
      ),
    };
  }

  Stream<ScreenSpecData> _watchUngated(ScreenSpec spec) {
    if (spec.modules.isEmpty) {
      return Stream.value(
        ScreenSpecData(
          spec: spec,
          template: spec.template,
          sections: const SlottedSectionVms(),
        ),
      );
    }

    final moduleEntries = <_ModuleEntry>[
      ...spec.modules.header.map((m) => _ModuleEntry(SlotId.header, m)),
      ...spec.modules.primary.map((m) => _ModuleEntry(SlotId.primary, m)),
    ];

    if (moduleEntries.isEmpty) {
      return Stream.value(
        ScreenSpecData(
          spec: spec,
          template: spec.template,
          sections: const SlottedSectionVms(),
        ),
      );
    }

    final sectionStreams = moduleEntries
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final moduleEntry = entry.value;
          return _watchModule(index: index, entry: moduleEntry);
        })
        .toList(growable: false);

    return Rx.combineLatestList(sectionStreams)
        .map((sections) {
          final header = <SectionVm>[];
          final primary = <SectionVm>[];

          for (final (i, vm) in sections.indexed) {
            final slot = moduleEntries[i].slotId;
            switch (slot) {
              case SlotId.header:
                header.add(vm);
              case SlotId.primary:
                primary.add(vm);
            }
          }

          return ScreenSpecData(
            spec: spec,
            template: spec.template,
            sections: SlottedSectionVms(
              header: header,
              primary: primary,
            ),
          );
        })
        .onErrorReturnWith((error, _) {
          return ScreenSpecData(
            spec: spec,
            template: spec.template,
            sections: const SlottedSectionVms(),
            error: error.toString(),
          );
        });
  }

  Stream<SectionVm> _watchModule({
    required int index,
    required _ModuleEntry entry,
  }) {
    try {
      return entry.module.map(
        taskListV2: (m) => _taskListInterpreter
            .watch(m.params)
            .map(
              (data) => SectionVm(
                index: index,
                templateId: SectionTemplateId.taskListV2,
                params: m.params,
                title: m.title,
                data: data,
              ),
            ),
        projectListV2: (m) => _projectListInterpreter
            .watch(m.params)
            .map(
              (data) => SectionVm(
                index: index,
                templateId: SectionTemplateId.projectListV2,
                params: m.params,
                title: m.title,
                data: data,
              ),
            ),
        valueListV2: (m) => _valueListInterpreter
            .watch(m.params)
            .map(
              (data) => SectionVm(
                index: index,
                templateId: SectionTemplateId.valueListV2,
                params: m.params,
                title: m.title,
                data: data,
              ),
            ),
        interleavedListV2: (m) => _interleavedListInterpreter
            .watch(m.params)
            .map(
              (data) => SectionVm(
                index: index,
                templateId: SectionTemplateId.interleavedListV2,
                params: m.params,
                title: m.title,
                data: data,
              ),
            ),
        hierarchyValueProjectTaskV2: (m) =>
            _hierarchyValueProjectTaskInterpreter
                .watch(m.params)
                .map(
                  (data) => SectionVm(
                    index: index,
                    templateId: SectionTemplateId.hierarchyValueProjectTaskV2,
                    params: m.params,
                    title: m.title,
                    data: data,
                  ),
                ),
        agendaV2: (m) => _agendaInterpreter
            .watch(m.params)
            .map(
              (data) => SectionVm(
                index: index,
                templateId: SectionTemplateId.agendaV2,
                params: m.params,
                title: m.title,
                data: data,
              ),
            ),
        attentionBannerV1: (m) => _attentionBannerInterpreter
            .watch(m.params)
            .map(
              (data) => SectionVm(
                index: index,
                templateId: SectionTemplateId.attentionBannerV1,
                params: m.params,
                title: m.title,
                data: data,
              ),
            ),
        entityHeader: (m) => _entityHeaderInterpreter
            .watch(m.params)
            .map(
              (data) => SectionVm(
                index: index,
                templateId: SectionTemplateId.entityHeader,
                params: m.params,
                title: m.title,
                data: data,
              ),
            ),
      );
    } catch (e) {
      return Stream.value(
        SectionVm(
          index: index,
          templateId: 'unknown',
          params: entry.module,
          data: null,
          error: e.toString(),
        ),
      );
    }
  }
}

class _ModuleEntry {
  const _ModuleEntry(this.slotId, this.module);

  final SlotId slotId;
  final ScreenModuleSpec module;
}
