import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_config.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/preferences/model/settings_key.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_gate_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_module_interpreter_registry.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';

/// Interprets a typed [ScreenSpec] into a reactive stream of [ScreenSpecData].
///
/// Unlike the legacy JSON-driven screen pipeline, this path avoids string
/// template IDs and JSON params at the screen level. Modules carry typed params
/// and are routed directly to typed interpreters.
class ScreenSpecDataInterpreter {
  ScreenSpecDataInterpreter({
    required SettingsRepositoryContract settingsRepository,
    required ValueRepositoryContract valueRepository,
    required ScreenModuleInterpreterRegistry moduleInterpreterRegistry,
  }) : _settingsRepository = settingsRepository,
       _valueRepository = valueRepository,
       _moduleInterpreterRegistry = moduleInterpreterRegistry;

  final SettingsRepositoryContract _settingsRepository;
  final ValueRepositoryContract _valueRepository;

  final ScreenModuleInterpreterRegistry _moduleInterpreterRegistry;

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
          return _moduleInterpreterRegistry
              .watch(
                index: index,
                module: moduleEntry.module,
              )
              // Defensive guard: even if a module stream throws, keep the
              // screen stream alive and surface the failure as a section-level
              // error VM.
              .onErrorReturnWith((error, _) {
                return SectionVm.unknown(
                  index: index,
                  params: moduleEntry.module,
                  title: moduleEntry.module.title,
                  error: error.toString(),
                );
              });
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
}

class _ModuleEntry {
  const _ModuleEntry(this.slotId, this.module);

  final SlotId slotId;
  final ScreenModuleSpec module;
}
