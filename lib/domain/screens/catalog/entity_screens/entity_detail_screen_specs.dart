import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/value.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_header_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/hierarchy_value_project_task_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';

/// Typed ScreenSpecs for entity detail (RD) surfaces.
///
/// These are used by entity detail route widgets after the entity is loaded.
abstract class EntityDetailScreenSpecs {
  EntityDetailScreenSpecs._();

  static ScreenSpec projectDetail({
    required Project project,
    required String tasksTitle,
    StylePackV2 pack = StylePackV2.standard,
  }) {
    return ScreenSpec(
      id: 'project_${project.id}',
      screenKey: 'project_detail',
      name: project.name,
      template: const ScreenTemplateSpec.entityDetailScaffoldV1(),
      modules: SlottedModules(
        header: [
          ScreenModuleSpec.entityHeader(
            params: EntityHeaderSectionParams(
              entityType: 'project',
              entityId: project.id,
              showCheckbox: true,
              showMetadata: true,
            ),
          ),
        ],
        primary: [
          ScreenModuleSpec.taskListV2(
            title: tasksTitle,
            params: ListSectionParamsV2(
              config: DataConfig.task(
                query: TaskQuery.forProject(projectId: project.id),
              ),
              pack: pack,
              separator: ListSeparatorV2.divider,
            ),
          ),
        ],
      ),
    );
  }

  static ScreenSpec valueDetail({
    required Value value,
    required String projectsAndTasksTitle,
    StylePackV2 pack = StylePackV2.standard,
  }) {
    return ScreenSpec(
      id: 'value_${value.id}',
      screenKey: 'value_detail',
      name: value.name,
      template: const ScreenTemplateSpec.entityDetailScaffoldV1(),
      modules: SlottedModules(
        header: [
          ScreenModuleSpec.entityHeader(
            params: EntityHeaderSectionParams(
              entityType: 'value',
              entityId: value.id,
              showCheckbox: false,
              showMetadata: true,
            ),
          ),
        ],
        primary: [
          ScreenModuleSpec.hierarchyValueProjectTaskV2(
            title: projectsAndTasksTitle,
            params: HierarchyValueProjectTaskSectionParamsV2(
              sources: [
                DataConfig.task(query: TaskQuery.forValue(valueId: value.id)),
              ],
              pack: pack,
              pinnedValueHeaders: false,
              pinnedProjectHeaders: true,
              singleInboxGroupForNoProjectTasks: true,
            ),
          ),
        ],
      ),
    );
  }
}
