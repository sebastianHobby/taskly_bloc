import 'package:flutter/foundation.dart';

@immutable
sealed class ProjectsScope {
  const ProjectsScope();

  const factory ProjectsScope.project({required String projectId}) =
      ProjectsProjectScope;
  const factory ProjectsScope.value({required String valueId}) =
      ProjectsValueScope;

  String get id;
}

@immutable
final class ProjectsProjectScope implements ProjectsScope {
  const ProjectsProjectScope({required this.projectId});

  final String projectId;

  @override
  String get id => projectId;
}

@immutable
final class ProjectsValueScope implements ProjectsScope {
  const ProjectsValueScope({required this.valueId});

  final String valueId;

  @override
  String get id => valueId;
}
