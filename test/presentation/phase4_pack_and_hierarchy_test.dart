import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/value_query.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/domain/screens/templates/params/interleaved_list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';
import 'package:taskly_bloc/presentation/entity_views/value_view.dart';
import 'package:taskly_bloc/presentation/screens/templates/renderers/interleaved_list_renderer_v2.dart';
import 'package:taskly_bloc/presentation/widgets/section_widget.dart';

import '../fixtures/test_data.dart';

void main() {
  group('Phase 4: StylePackV2 (pack-only)', () {
    testWidgets('TaskListV2 compactTiles derives from params.pack', (
      tester,
    ) async {
      Widget build({required StylePackV2 pack}) {
        final task = TestData.task();
        final data =
            SectionDataResult.dataV2(items: [ScreenItem.task(task)])
                as DataV2SectionResult;

        final params = ListSectionParamsV2(
          config: DataConfig.task(query: TaskQuery.all()),
          pack: pack,
          layout: const SectionLayoutSpecV2.flatList(),
        );

        final section = SectionVm(
          index: 0,
          templateId: SectionTemplateId.taskListV2,
          params: params,
          data: data,
        );

        return MaterialApp(
          home: Scaffold(
            body: CustomScrollView(slivers: [SectionWidget(section: section)]),
          ),
        );
      }

      await tester.pumpWidget(build(pack: StylePackV2.compact));
      await tester.pumpAndSettle();

      final taskView = tester.widget<TaskView>(find.byType(TaskView));
      expect(taskView.compact, isTrue);

      await tester.pumpWidget(build(pack: StylePackV2.standard));
      await tester.pumpAndSettle();

      final taskView2 = tester.widget<TaskView>(find.byType(TaskView));
      expect(taskView2.compact, isFalse);
    });

    testWidgets('ValueListV2 compactTiles derives from params.pack', (
      tester,
    ) async {
      Widget build({required StylePackV2 pack}) {
        final value = TestData.value();
        final data =
            SectionDataResult.dataV2(items: [ScreenItem.value(value)])
                as DataV2SectionResult;

        final params = ListSectionParamsV2(
          config: DataConfig.value(query: ValueQuery.all()),
          pack: pack,
          layout: const SectionLayoutSpecV2.flatList(),
        );

        final section = SectionVm(
          index: 0,
          templateId: SectionTemplateId.valueListV2,
          params: params,
          data: data,
        );

        return MaterialApp(
          home: Scaffold(
            body: CustomScrollView(slivers: [SectionWidget(section: section)]),
          ),
        );
      }

      await tester.pumpWidget(build(pack: StylePackV2.compact));
      await tester.pumpAndSettle();

      final valueView = tester.widget<ValueView>(find.byType(ValueView));
      expect(valueView.compact, isTrue);

      await tester.pumpWidget(build(pack: StylePackV2.standard));
      await tester.pumpAndSettle();

      final valueView2 = tester.widget<ValueView>(find.byType(ValueView));
      expect(valueView2.compact, isFalse);
    });

    test('ListSectionParamsV2 requires pack during JSON decoding', () {
      final original = ListSectionParamsV2(
        config: DataConfig.task(query: TaskQuery.all()),
        pack: StylePackV2.standard,
        layout: const SectionLayoutSpecV2.flatList(),
      );

      final json = Map<String, dynamic>.from(original.toJson())..remove('pack');

      expect(
        () => ListSectionParamsV2.fromJson(json),
        throwsA(isA<CheckedFromJsonException>()),
      );
    });
  });

  group('Phase 4: hierarchy affordance', () {
    testWidgets('Pinned orphan project headers show expand/collapse control', (
      tester,
    ) async {
      final task = TestData.task(projectId: 'project-orphan');
      final data =
          SectionDataResult.dataV2(items: [ScreenItem.task(task)])
              as DataV2SectionResult;

      final params = InterleavedListSectionParamsV2(
        sources: [DataConfig.task(query: TaskQuery.all())],
        pack: StylePackV2.standard,
        layout: const SectionLayoutSpecV2.hierarchyValueProjectTask(
          pinnedProjectHeaders: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [InterleavedListRendererV2(data: data, params: params)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Collapse project'), findsOneWidget);
    });
  });
}
