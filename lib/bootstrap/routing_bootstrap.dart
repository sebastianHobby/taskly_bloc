import 'package:taskly_bloc/presentation/features/projects/view/project_detail_unified_page.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/values/view/value_detail_unified_page.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

/// Registers entity builders with [Routing].
///
/// System screens are resolved by [Routing.buildScreen] via `SystemScreenSpecs`.
/// Entity detail routes are resolved via registered builders.
void registerRoutingBuilders() {
  Routing.registerEntityBuilders(
    taskBuilder: (id) => TaskEditorRoutePage(taskId: id),
    valueBuilder: (id) => ValueDetailUnifiedPage(valueId: id),
    projectBuilder: (id) => ProjectDetailUnifiedPage(projectId: id),
  );
}
