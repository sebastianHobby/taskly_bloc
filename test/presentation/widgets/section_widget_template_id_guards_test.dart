import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/domain/screens/templates/params/allocation_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_tile_variants.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_header_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/issues_summary_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/screen_item_tile_variants.dart';
import 'package:taskly_bloc/presentation/widgets/section_widget.dart';
import '../../helpers/pump_app.dart';

Widget _wrapSliver(Widget sliver) {
  return Scaffold(body: CustomScrollView(slivers: [sliver]));
}

void main() {
  testWidgets('issues_summary uses section.title override', (tester) async {
    const section = SectionVm(
      index: 0,
      templateId: SectionTemplateId.issuesSummary,
      title: 'My Issues',
      params: IssuesSummarySectionParams(
        attentionItemTileVariant: AttentionItemTileVariant.standard,
      ),
      data: SectionDataResult.issuesSummary(
        items: [],
        criticalCount: 0,
        warningCount: 0,
      ),
    );

    await pumpLocalizedApp(
      tester,
      home: _wrapSliver(const SectionWidget(section: section)),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Issues'), findsOneWidget);
    expect(find.text('All clear! No issues to address.'), findsOneWidget);
  });

  testWidgets('templateId guards prevent mismatched rendering', (tester) async {
    const section = SectionVm(
      index: 0,
      templateId: SectionTemplateId.taskListV2,
      params: IssuesSummarySectionParams(
        attentionItemTileVariant: AttentionItemTileVariant.standard,
      ),
      data: SectionDataResult.issuesSummary(
        items: [],
        criticalCount: 0,
        warningCount: 0,
      ),
    );

    await pumpLocalizedApp(
      tester,
      home: _wrapSliver(const SectionWidget(section: section)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Unsupported section data: ${SectionTemplateId.taskListV2}'),
      findsOneWidget,
    );
  });

  testWidgets('allocation requiresValueSetup shows gateway UI', (tester) async {
    const section = SectionVm(
      index: 0,
      templateId: SectionTemplateId.allocation,
      params: AllocationSectionParams(
        taskTileVariant: TaskTileVariant.listTile,
      ),
      data: SectionDataResult.allocation(
        allocatedTasks: [],
        totalAvailable: 0,
        requiresValueSetup: true,
      ),
    );

    await pumpLocalizedApp(
      tester,
      home: _wrapSliver(const SectionWidget(section: section)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set up values to use focus mode'), findsOneWidget);
    expect(find.text('Set up focus'), findsOneWidget);
  });

  testWidgets('entity_header showMetadata=false hides value chips', (
    tester,
  ) async {
    final value = Value(
      id: 'v1',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      name: 'Health',
      color: '#00FF00',
    );

    final project = Project(
      id: 'p1',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
      name: 'Project A',
      completed: false,
      values: [value],
      primaryValueId: value.id,
    );

    final section = SectionVm(
      index: 0,
      templateId: SectionTemplateId.entityHeader,
      params: const EntityHeaderSectionParams(
        entityType: 'project',
        entityId: 'p1',
      ),
      data: SectionDataResult.entityHeaderProject(
        project: project,
        showCheckbox: true,
        showMetadata: false,
      ),
    );

    await pumpLocalizedApp(
      tester,
      home: _wrapSliver(SectionWidget(section: section)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Project A'), findsOneWidget);
    expect(find.text('Health'), findsNothing);
  });
}
