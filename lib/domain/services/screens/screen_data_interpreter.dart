import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section_ref.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data.dart';
import 'package:taskly_bloc/domain/services/screens/section_vm.dart';
import 'package:taskly_bloc/domain/services/screens/templates/section_template_interpreter_registry.dart';
import 'package:taskly_bloc/domain/services/screens/templates/section_template_params_codec.dart';

/// Interprets a [ScreenDefinition] into a reactive stream of [ScreenData].
class ScreenDataInterpreter {
  ScreenDataInterpreter({
    required SectionTemplateInterpreterRegistry interpreterRegistry,
    required SectionTemplateParamsCodec paramsCodec,
  }) : _interpreterRegistry = interpreterRegistry,
       _paramsCodec = paramsCodec;

  final SectionTemplateInterpreterRegistry _interpreterRegistry;
  final SectionTemplateParamsCodec _paramsCodec;

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

    try {
      for (final ref in definition.sections) {
        if (ref.overrides?.enabled == false) continue;
        _validateSectionRefOrFail(ref);
      }
    } catch (e, st) {
      talker.handle(e, st, '[ScreenDataInterpreter] invalid screen definition');
      if (!_isReleaseMode) {
        rethrow;
      }
      return Stream.value(ScreenData.error(definition, e.toString()));
    }

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

    final sectionStreams = enabledSections.map((entry) {
      return _watchSection(entry.$1, entry.$2);
    }).toList();

    // Combine all section streams
    return Rx.combineLatestList(sectionStreams)
        .map((sectionResults) {
          return ScreenData(definition: definition, sections: sectionResults);
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

  Stream<SectionVm> _watchSection(int index, SectionRef ref) {
    final interpreter = _interpreterRegistry.get(ref.templateId);
    final params = _paramsCodec.decode(ref.templateId, ref.params);
    final title = ref.overrides?.title;

    final stream = interpreter.watch(params).cast<Object?>();

    return stream.transform(
      StreamTransformer<Object?, SectionVm>.fromHandlers(
        handleData: (data, EventSink<SectionVm> sink) {
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
