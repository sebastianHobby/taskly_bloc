import 'dart:async';
import 'dart:developer' as developer;

import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_gate_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_config.dart';
import 'package:taskly_bloc/domain/preferences/model/settings_key.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter_registry.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_params_codec.dart';

/// Interprets a [ScreenDefinition] into a reactive stream of [ScreenData].
class ScreenDataInterpreter {
  ScreenDataInterpreter({
    required SectionTemplateInterpreterRegistry interpreterRegistry,
    required SectionTemplateParamsCodec paramsCodec,
    required SettingsRepositoryContract settingsRepository,
  }) : _interpreterRegistry = interpreterRegistry,
       _paramsCodec = paramsCodec,
       _settingsRepository = settingsRepository;

  final SectionTemplateInterpreterRegistry _interpreterRegistry;
  final SectionTemplateParamsCodec _paramsCodec;
  final SettingsRepositoryContract _settingsRepository;

  static const bool _isReleaseMode = bool.fromEnvironment('dart.vm.product');

  Never _failFast(String message) {
    throw StateError(message);
  }

  void _validateSectionRefOrFail(SectionRef ref) {
    try {
      _interpreterRegistry.get(ref.templateId);
    } catch (e) {
      _failFast(
        'Unknown section templateId: ${ref.templateId} (no interpreter)',
      );
    }

    try {
      _paramsCodec.decode(ref.templateId, ref.params);
    } catch (e) {
      _failFast(
        'Invalid params for templateId=${ref.templateId}: $e (params=${ref.params})',
      );
    }
  }

  /// Watch a screen definition and emit [ScreenData] on changes.
  Stream<ScreenData> watchScreen(ScreenDefinition definition) {
    talker.serviceLog(
      'ScreenDataInterpreter',
      'watchScreen: ${definition.id} with ${definition.sections.length} sections',
    );
    developer.log(
      '🔄 Interpreter: Starting watchScreen for "${definition.name}"',
      name: 'perf.interpreter',
    );

    try {
      for (final ref in definition.sections) {
        if (ref.overrides?.enabled == false) continue;
        _validateSectionRefOrFail(ref);
      }
      final gateSection = definition.gate?.section;
      if (gateSection != null) {
        _validateSectionRefOrFail(gateSection);
      }
    } catch (e, st) {
      talker.handle(e, st, '[ScreenDataInterpreter] invalid screen definition');
      if (!_isReleaseMode) {
        rethrow;
      }
      return Stream.value(ScreenData.error(definition, e.toString()));
    }

    final gate = definition.gate;
    if (gate == null) {
      return _watchUngatedScreenWithTiming(definition);
    }

    return _watchGateActive(gate.criteria)
        .distinct()
        .switchMap((isActive) {
          if (isActive) {
            return _watchGateScreen(definition, gate.section);
          }
          return _watchUngatedScreenWithTiming(definition);
        })
        .transform(
          StreamTransformer.fromHandlers(
            handleError:
                (
                  Object error,
                  StackTrace stackTrace,
                  EventSink<ScreenData> sink,
                ) {
                  talker.handle(
                    error,
                    stackTrace,
                    '[ScreenDataInterpreter] watchScreen failed',
                  );
                  sink.add(ScreenData.error(definition, error.toString()));
                },
          ),
        );
  }

  /// Fetch screen data once (non-reactive).
  Future<ScreenData> fetchScreen(ScreenDefinition definition) async {
    talker.serviceLog(
      'ScreenDataInterpreter',
      'fetchScreen: ${definition.id}',
    );

    try {
      for (final ref in definition.sections) {
        if (ref.overrides?.enabled == false) continue;
        _validateSectionRefOrFail(ref);
      }

      final gate = definition.gate;
      if (gate != null) {
        _validateSectionRefOrFail(gate.section);
        final isActive = await _isGateActiveOnce(gate.criteria);
        if (isActive) {
          final sectionVm = await _fetchSection(0, gate.section);
          return ScreenData(definition: definition, sections: [sectionVm]);
        }
      }

      final sections = await Future.wait(
        definition.sections.asMap().entries.map((entry) async {
          final index = entry.key;
          final section = entry.value;
          if (section.overrides?.enabled == false) {
            return null;
          }
          return _fetchSection(index, section);
        }),
      );

      return ScreenData(
        definition: definition,
        sections: sections.whereType<SectionVm>().toList(growable: false),
      );
    } catch (e, st) {
      talker.handle(e, st, '[ScreenDataInterpreter] fetchScreen failed');
      if (!_isReleaseMode) {
        rethrow;
      }
      return ScreenData.error(definition, e.toString());
    }
  }

  Stream<ScreenData> _watchUngatedScreenWithTiming(
    ScreenDefinition definition,
  ) {
    final watchStartTime = DateTime.now();
    return _watchUngatedScreen(definition).transform(
      StreamTransformer.fromHandlers(
        handleData: (ScreenData data, EventSink<ScreenData> sink) {
          if (!data.sections.any((s) => s.data != null)) {
            // Skip timing for empty initial states
            sink.add(data);
            return;
          }

          final interpreterMs = DateTime.now()
              .difference(watchStartTime)
              .inMilliseconds;

          // Only log once per stream
          if (interpreterMs < 100000) {
            // Reasonable cutoff to prevent re-logging
            developer.log(
              '✅ Interpreter: First data for "${definition.name}" - ${interpreterMs}ms',
              name: 'perf.interpreter',
              level: interpreterMs > 1000 ? 900 : 800,
            );
            if (interpreterMs > 1000) {
              talker.warning(
                '[Perf] Interpreter slow for "${definition.name}": ${interpreterMs}ms',
              );
            }
          }
          sink.add(data);
        },
      ),
    );
  }

  Stream<ScreenData> _watchUngatedScreen(ScreenDefinition definition) {
    if (definition.sections.isEmpty) {
      return Stream.value(
        ScreenData(
          definition: definition,
          sections: const [],
        ),
      );
    }

    final enabledSections = <(int index, SectionRef ref)>[];
    for (final entry in definition.sections.asMap().entries) {
      final ref = entry.value;
      if (ref.overrides?.enabled == false) continue;
      enabledSections.add((entry.key, ref));
    }

    if (enabledSections.isEmpty) {
      return Stream.value(
        ScreenData(definition: definition, sections: const []),
      );
    }

    final sectionStreams = enabledSections
        .map((entry) {
          return _watchSection(entry.$1, entry.$2, definition.name);
        })
        .toList(growable: false);

    return Rx.combineLatestList(sectionStreams).map((sectionResults) {
      return ScreenData(definition: definition, sections: sectionResults);
    });
  }

  Stream<ScreenData> _watchGateScreen(
    ScreenDefinition definition,
    SectionRef gateSection,
  ) {
    return _watchSection(
      0,
      gateSection,
    ).map((vm) => ScreenData(definition: definition, sections: [vm]));
  }

  Stream<bool> _watchGateActive(ScreenGateCriteria criteria) {
    return switch (criteria) {
      AllocationFocusModeNotSelectedGateCriteria() =>
        _settingsRepository
            .watch<AllocationConfig>(SettingsKey.allocation)
            .map((c) => !c.hasSelectedFocusMode),
    };
  }

  Future<bool> _isGateActiveOnce(ScreenGateCriteria criteria) async {
    if (criteria is AllocationFocusModeNotSelectedGateCriteria) {
      final config = await _settingsRepository.load<AllocationConfig>(
        SettingsKey.allocation,
      );
      return !config.hasSelectedFocusMode;
    }

    return false;
  }

  Stream<SectionVm> _watchSection(
    int index,
    SectionRef ref, [
    String? screenName,
  ]) {
    final sectionStartTime = DateTime.now();
    developer.log(
      '📦 Section: Starting watch for ${ref.templateId} (screen: $screenName)',
      name: 'perf.section',
    );

    final interpreter = _interpreterRegistry.get(ref.templateId);
    final params = _paramsCodec.decode(ref.templateId, ref.params);
    final title = ref.overrides?.title;

    final stream = interpreter.watch(params).cast<Object?>();

    var firstSectionEmit = true;
    return stream.transform(
      StreamTransformer<Object?, SectionVm>.fromHandlers(
        handleData: (data, EventSink<SectionVm> sink) {
          if (firstSectionEmit) {
            firstSectionEmit = false;
            final sectionMs = DateTime.now()
                .difference(sectionStartTime)
                .inMilliseconds;
            developer.log(
              '✅ Section: First data for ${ref.templateId} - ${sectionMs}ms',
              name: 'perf.section',
              level: sectionMs > 500 ? 900 : 800,
            );
            if (sectionMs > 1000) {
              talker.warning(
                '[Perf] Section ${ref.templateId} slow: ${sectionMs}ms',
              );
            }
          }

          sink.add(
            SectionVm(
              index: index,
              templateId: ref.templateId,
              params: params,
              title: title,
              data: data,
            ),
          );
        },
        handleError:
            (
              Object error,
              StackTrace stackTrace,
              EventSink<SectionVm> sink,
            ) {
              talker.handle(
                error,
                stackTrace,
                '[ScreenDataInterpreter] Section $index failed',
              );
              sink.add(
                SectionVm(
                  index: index,
                  templateId: ref.templateId,
                  params: params,
                  title: title,
                  data: null,
                  error: error.toString(),
                ),
              );
            },
      ),
    );
  }

  Future<SectionVm> _fetchSection(int index, SectionRef ref) async {
    try {
      final interpreter = _interpreterRegistry.get(ref.templateId);
      final params = _paramsCodec.decode(ref.templateId, ref.params);
      final data = await interpreter.fetch(params);
      return SectionVm(
        index: index,
        templateId: ref.templateId,
        params: params,
        title: ref.overrides?.title,
        data: data,
      );
    } catch (e) {
      return SectionVm(
        index: index,
        templateId: ref.templateId,
        params: ref.params,
        title: ref.overrides?.title,
        data: null,
        error: e.toString(),
      );
    }
  }
}
