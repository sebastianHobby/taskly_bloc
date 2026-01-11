import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/interleaved_list_section_params.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_service.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter.dart';

class InterleavedListSectionInterpreter
    implements SectionTemplateInterpreter<InterleavedListSectionParams> {
  InterleavedListSectionInterpreter({
    required SectionDataService sectionDataService,
  }) : _sectionDataService = sectionDataService;

  final SectionDataService _sectionDataService;

  @override
  String get templateId => SectionTemplateId.interleavedList;

  @override
  Stream<SectionDataResult> watch(InterleavedListSectionParams params) {
    if (params.sources.isEmpty) {
      return Stream.value(const SectionDataResult.data(items: []));
    }

    final streams = params.sources
        .map((s) => _sectionDataService.watchDataList(s.params))
        .toList(growable: false);

    return Rx.combineLatestList(streams).map(
      (results) => _mergeAndSort(params, results),
    );
  }

  @override
  Future<SectionDataResult> fetch(InterleavedListSectionParams params) async {
    if (params.sources.isEmpty) {
      return const SectionDataResult.data(items: []);
    }

    final results = await Future.wait(
      params.sources.map((s) => _sectionDataService.fetchDataList(s.params)),
    );

    return _mergeAndSort(params, results);
  }

  SectionDataResult _mergeAndSort(
    InterleavedListSectionParams params,
    List<SectionDataResult> results,
  ) {
    final dataResults = results.whereType<DataSectionResult>().toList();

    final entityItems = <ScreenItem>[];
    final structuralItems = <ScreenItem>[];

    for (final d in dataResults) {
      for (final item in d.items) {
        switch (item) {
          case ScreenItemTask() || ScreenItemProject() || ScreenItemValue():
            entityItems.add(item);
          default:
            structuralItems.add(item);
        }
      }
    }

    entityItems.sort((a, b) {
      final aKey = _sortKeyFor(params.orderStrategy, a);
      final bKey = _sortKeyFor(params.orderStrategy, b);

      var byKey = aKey.compareTo(bKey);
      if (params.orderStrategy == InterleavedOrderStrategy.updatedAtDesc ||
          params.orderStrategy == InterleavedOrderStrategy.createdAtDesc) {
        byKey = -byKey;
      }
      if (byKey != 0) return byKey;

      final aId = _stableId(a);
      final bId = _stableId(b);
      return aId.compareTo(bId);
    });

    final items = <ScreenItem>[...entityItems, ...structuralItems];
    return SectionDataResult.data(items: items);
  }

  DateTime _sortKeyFor(InterleavedOrderStrategy strategy, ScreenItem item) {
    DateTime keyForTask(Task task) {
      return switch (strategy) {
        InterleavedOrderStrategy.updatedAtDesc => task.updatedAt,
        InterleavedOrderStrategy.createdAtDesc => task.createdAt,
        InterleavedOrderStrategy.deadlineDateAsc =>
          task.deadlineDate ?? DateTime.utc(9999),
        InterleavedOrderStrategy.startDateAsc =>
          task.startDate ?? DateTime.utc(9999),
      };
    }

    DateTime keyForProject(Project project) {
      return switch (strategy) {
        InterleavedOrderStrategy.updatedAtDesc => project.updatedAt,
        InterleavedOrderStrategy.createdAtDesc => project.createdAt,
        InterleavedOrderStrategy.deadlineDateAsc =>
          project.deadlineDate ?? DateTime.utc(9999),
        InterleavedOrderStrategy.startDateAsc =>
          project.startDate ?? DateTime.utc(9999),
      };
    }

    final raw = switch (item) {
      ScreenItemTask(:final task) => keyForTask(task),
      ScreenItemProject(:final project) => keyForProject(project),
      ScreenItemValue(:final value) => value.updatedAt,
      _ => DateTime.utc(0),
    };

    return raw;
  }

  String _stableId(ScreenItem item) {
    return switch (item) {
      ScreenItemTask(:final task) => 't:${task.id}',
      ScreenItemProject(:final project) => 'p:${project.id}',
      ScreenItemValue(:final value) => 'v:${value.id}',
      ScreenItemHeader(:final title) => 'h:$title',
      ScreenItemDivider() => 'd',
    };
  }
}
