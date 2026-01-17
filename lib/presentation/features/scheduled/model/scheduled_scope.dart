sealed class ScheduledScope {
  const ScheduledScope();

  const factory ScheduledScope.global() = GlobalScheduledScope;
  const factory ScheduledScope.project({required String projectId}) =
      ProjectScheduledScope;
  const factory ScheduledScope.value({required String valueId}) =
      ValueScheduledScope;
}

final class GlobalScheduledScope extends ScheduledScope {
  const GlobalScheduledScope();
}

final class ProjectScheduledScope extends ScheduledScope {
  const ProjectScheduledScope({required this.projectId});

  final String projectId;
}

final class ValueScheduledScope extends ScheduledScope {
  const ValueScheduledScope({required this.valueId});

  final String valueId;
}
