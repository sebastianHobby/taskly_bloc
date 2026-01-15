import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/hierarchy_value_project_task_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/hierarchy_value_project_task_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';

final class MyDayRankedTasksV1ModuleInterpreter {
  MyDayRankedTasksV1ModuleInterpreter({
    required HierarchyValueProjectTaskSectionInterpreterV2
    hierarchyValueProjectTaskInterpreter,
  }) : _hierarchyValueProjectTaskInterpreter =
           hierarchyValueProjectTaskInterpreter;

  final HierarchyValueProjectTaskSectionInterpreterV2
  _hierarchyValueProjectTaskInterpreter;

  static const _params = HierarchyValueProjectTaskSectionParamsV2(
    sources: [DataConfig.allocationSnapshotTasksToday()],
    pack: StylePackV2.standard,
    pinnedValueHeaders: false,
    pinnedProjectHeaders: false,
    singleInboxGroupForNoProjectTasks: false,
    enrichment: EnrichmentPlanV2(
      items: [EnrichmentPlanItemV2.allocationMembership()],
    ),
  );

  Stream<SectionDataResult> watch() {
    return _hierarchyValueProjectTaskInterpreter.watch(_params);
  }
}
