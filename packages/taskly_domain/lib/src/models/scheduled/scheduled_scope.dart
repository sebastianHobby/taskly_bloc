/// Optional scope filter for scheduled occurrences.
sealed class ScheduledScope {
  const ScheduledScope();
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
