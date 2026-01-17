sealed class AgendaScope {
  const AgendaScope();

  const factory AgendaScope.project({required String projectId}) =
      ProjectAgendaScope;
  const factory AgendaScope.value({required String valueId}) = ValueAgendaScope;
}

final class ProjectAgendaScope extends AgendaScope {
  const ProjectAgendaScope({required this.projectId});

  final String projectId;
}

final class ValueAgendaScope extends AgendaScope {
  const ValueAgendaScope({required this.valueId});

  final String valueId;
}
