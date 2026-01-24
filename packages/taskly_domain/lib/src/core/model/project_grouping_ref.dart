import 'package:flutter/foundation.dart';

/// Identifies how tasks are grouped by project in feeds.
///
/// This is a domain type so the UI does not need to implement its own
/// "inbox vs project" grouping logic.
@immutable
sealed class ProjectGroupingRef {
  const ProjectGroupingRef();

  const factory ProjectGroupingRef.inbox() = InboxProjectGroupingRef;
  const factory ProjectGroupingRef.project({required String projectId}) =
      ProjectProjectGroupingRef;

  factory ProjectGroupingRef.fromProjectId(String? projectId) {
    final trimmed = projectId?.trim() ?? '';
    if (trimmed.isEmpty) return const ProjectGroupingRef.inbox();
    return ProjectGroupingRef.project(projectId: trimmed);
  }

  bool get isInbox => switch (this) {
    InboxProjectGroupingRef() => true,
    ProjectProjectGroupingRef() => false,
  };

  String? get projectId => switch (this) {
    InboxProjectGroupingRef() => null,
    ProjectProjectGroupingRef(:final projectId) => projectId,
  };

  /// A stable key for row identity and logging.
  String get stableKey => switch (this) {
    InboxProjectGroupingRef() => 'inbox',
    ProjectProjectGroupingRef(:final projectId) => projectId,
  };

  @override
  bool operator ==(Object other) => switch ((this, other)) {
    (InboxProjectGroupingRef(), InboxProjectGroupingRef()) => true,
    (
      ProjectProjectGroupingRef(:final projectId),
      ProjectProjectGroupingRef(projectId: final otherProjectId),
    ) =>
      projectId == otherProjectId,
    _ => false,
  };

  @override
  int get hashCode => switch (this) {
    InboxProjectGroupingRef() => Object.hash(ProjectGroupingRef, 'inbox'),
    ProjectProjectGroupingRef(:final projectId) => Object.hash(
      ProjectGroupingRef,
      projectId,
    ),
  };
}

final class InboxProjectGroupingRef extends ProjectGroupingRef {
  const InboxProjectGroupingRef();
}

final class ProjectProjectGroupingRef extends ProjectGroupingRef {
  const ProjectProjectGroupingRef({required this.projectId});

  @override
  final String projectId;
}
