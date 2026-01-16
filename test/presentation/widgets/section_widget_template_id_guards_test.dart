import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_vm.dart';
import 'package:taskly_bloc/domain/screens/templates/params/attention_banner_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_header_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_style_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/presentation/widgets/section_widget.dart';
import '../../helpers/pump_app.dart';

Widget _wrapSliver(Widget sliver) {
  return Scaffold(body: CustomScrollView(slivers: [sliver]));
}

void main() {
  testWidgets('attentionBannerV2 uses section.title override', (tester) async {
    const section = SectionVm.attentionBannerV2(
      index: 0,
      title: 'My Issues',
      params: AttentionBannerSectionParamsV2(),
      data: SectionDataResult.attentionBannerV2(
        reviewCount: 0,
        alertsCount: 0,
        criticalCount: 0,
        warningCount: 0,
        overflowScreenKey: 'review_inbox',
        doneCount: 0,
        totalCount: 0,
      ),
    );

    await pumpLocalizedApp(
      tester,
      home: _wrapSliver(SectionWidget(section: section)),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Issues'), findsOneWidget);
    expect(find.text('Open inbox'), findsOneWidget);
  });

  testWidgets('templateId guards prevent mismatched rendering', (tester) async {
    final section = SectionVm.taskListV2(
      index: 0,
      entityStyle: const EntityStyleV1(),
      params: ListSectionParamsV2(
        config: DataConfig.task(query: TaskQuery.all()),
      ),
      data: SectionDataResult.attentionBannerV2(
        reviewCount: 0,
        alertsCount: 0,
        criticalCount: 0,
        warningCount: 0,
        overflowScreenKey: 'review_inbox',
        doneCount: 0,
        totalCount: 0,
      ),
    );

    await pumpLocalizedApp(
      tester,
      home: _wrapSliver(SectionWidget(section: section)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Unsupported section data: ${SectionTemplateId.taskListV2}'),
      findsOneWidget,
    );
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

    final section = SectionVm.entityHeader(
      index: 0,
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
