import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_service.dart';
import 'package:taskly_bloc/domain/services/screens/support_block_computer.dart';

/// Interprets a [ScreenDefinition] into a reactive stream of [ScreenData].
///
/// This is the core service for the unified screen model (DR-017).
/// It coordinates [SectionDataService] and [SupportBlockComputer] to
/// produce a single stream that widgets can consume.
class ScreenDataInterpreter {
  ScreenDataInterpreter({
    required SectionDataService sectionDataService,
    required SupportBlockComputer supportBlockComputer,
  }) : _sectionDataService = sectionDataService,
       _supportBlockComputer = supportBlockComputer;

  final SectionDataService _sectionDataService;
  final SupportBlockComputer _supportBlockComputer;

  /// Watch a screen definition and emit [ScreenData] on changes.
  ///
  /// Combines streams from all sections and recomputes support blocks
  /// whenever section data changes.
  Stream<ScreenData> watchScreen(ScreenDefinition definition) {
    talker.serviceLog(
      'ScreenDataInterpreter',
      'watchScreen: ${definition.id} with ${definition.sections.length} sections',
    );

    if (definition.sections.isEmpty) {
      return Stream.value(
        ScreenData(
          definition: definition,
          sections: const [],
          supportBlocks: const [],
        ),
      );
    }

    // Create streams for each section
    final sectionStreams = definition.sections.asMap().entries.map((entry) {
      final index = entry.key;
      final section = entry.value;
      return _watchSection(index, section);
    }).toList();

    // Combine all section streams
    return Rx.combineLatestList(sectionStreams)
        .asyncMap((sectionResults) async {
          // Compute support blocks based on section data
          final supportBlocks = await _computeSupportBlocks(
            definition,
            sectionResults,
          );

          return ScreenData(
            definition: definition,
            sections: sectionResults,
            supportBlocks: supportBlocks,
          );
        })
        .handleError((Object error, StackTrace stackTrace) {
          talker.handle(
            error,
            stackTrace,
            '[ScreenDataInterpreter] watchScreen failed',
          );
          return ScreenData.error(definition, error.toString());
        });
  }

  /// Fetch screen data once (non-reactive).
  Future<ScreenData> fetchScreen(ScreenDefinition definition) async {
    talker.serviceLog(
      'ScreenDataInterpreter',
      'fetchScreen: ${definition.id}',
    );

    try {
      final sections = await Future.wait(
        definition.sections.asMap().entries.map((entry) async {
          final index = entry.key;
          final section = entry.value;
          return _fetchSection(index, section);
        }),
      );

      final supportBlocks = await _computeSupportBlocks(definition, sections);

      return ScreenData(
        definition: definition,
        sections: sections,
        supportBlocks: supportBlocks,
      );
    } catch (e, st) {
      talker.handle(e, st, '[ScreenDataInterpreter] fetchScreen failed');
      return ScreenData.error(definition, e.toString());
    }
  }

  Stream<SectionDataWithMeta> _watchSection(int index, Section section) {
    return _sectionDataService
        .watchSectionData(section)
        .map((result) {
          return SectionDataWithMeta(
            index: index,
            title: _getSectionTitle(section),
            result: result,
            displayConfig: _getSectionDisplayConfig(section),
          );
        })
        .handleError((Object error, StackTrace stackTrace) {
          talker.handle(
            error,
            stackTrace,
            '[ScreenDataInterpreter] Section $index failed',
          );
          // Return error state for this section
          return SectionDataWithMeta(
            index: index,
            title: _getSectionTitle(section),
            result: const SectionDataResult.data(
              primaryEntities: [],
              primaryEntityType: 'unknown',
            ),
            error: error.toString(),
            displayConfig: _getSectionDisplayConfig(section),
          );
        });
  }

  Future<SectionDataWithMeta> _fetchSection(int index, Section section) async {
    try {
      final result = await _sectionDataService.fetchSectionData(section);
      return SectionDataWithMeta(
        index: index,
        title: _getSectionTitle(section),
        result: result,
        displayConfig: _getSectionDisplayConfig(section),
      );
    } catch (e) {
      return SectionDataWithMeta(
        index: index,
        title: _getSectionTitle(section),
        result: const SectionDataResult.data(
          primaryEntities: [],
          primaryEntityType: 'unknown',
        ),
        error: e.toString(),
        displayConfig: _getSectionDisplayConfig(section),
      );
    }
  }

  String? _getSectionTitle(Section section) {
    return switch (section) {
      DataSection(:final title) => title,
      AllocationSection(:final title) => title,
      AgendaSection(:final title) => title,
    };
  }

  DisplayConfig? _getSectionDisplayConfig(Section section) {
    return switch (section) {
      DataSection(:final display) => display,
      AllocationSection() => null,
      AgendaSection() => null,
    };
  }

  Future<List<SupportBlockWithMeta>> _computeSupportBlocks(
    ScreenDefinition definition,
    List<SectionDataWithMeta> sections,
  ) async {
    if (definition.supportBlocks.isEmpty) {
      return [];
    }

    // Extract tasks and projects from section results using the built-in getters
    final allTasks = sections.expand((s) => s.result.allTasks).toList();
    final allProjects = sections.expand((s) => s.result.allProjects).toList();

    // Extract displayConfig from sections if available, otherwise use default
    final displayConfig = _extractDisplayConfig(definition.sections);

    final results = <SupportBlockWithMeta>[];

    for (var i = 0; i < definition.supportBlocks.length; i++) {
      final block = definition.supportBlocks[i];
      try {
        final result = await _supportBlockComputer.compute(
          block,
          tasks: allTasks,
          projects: allProjects,
          displayConfig: displayConfig,
        );
        results.add(SupportBlockWithMeta(index: i, result: result));
      } catch (e) {
        talker.warning('[ScreenDataInterpreter] Support block $i failed: $e');
      }
    }

    return results;
  }

  /// Extract DisplayConfig from sections (if any DataSection has one).
  DisplayConfig _extractDisplayConfig(List<Section> sections) {
    for (final section in sections) {
      if (section is DataSection && section.display != null) {
        return section.display!;
      }
    }
    return const DisplayConfig();
  }
}
