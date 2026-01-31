import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';

import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';

sealed class ProjectOverviewEvent {
  const ProjectOverviewEvent();
}

final class ProjectOverviewStarted extends ProjectOverviewEvent {
  const ProjectOverviewStarted();
}

sealed class ProjectOverviewState {
  const ProjectOverviewState();
}

final class ProjectOverviewLoading extends ProjectOverviewState {
  const ProjectOverviewLoading();
}

final class ProjectOverviewLoaded extends ProjectOverviewState {
  const ProjectOverviewLoaded({
    required this.project,
    required this.tasks,
    required this.todayDayKeyUtc,
  });

  final Project project;
  final List<Task> tasks;
  final DateTime todayDayKeyUtc;
}

final class ProjectOverviewError extends ProjectOverviewState {
  const ProjectOverviewError({required this.message});

  final String message;
}

class ProjectOverviewBloc
    extends Bloc<ProjectOverviewEvent, ProjectOverviewState> {
  ProjectOverviewBloc({
    required String projectId,
    required ProjectRepositoryContract projectRepository,
    required OccurrenceReadService occurrenceReadService,
    required SessionDayKeyService sessionDayKeyService,
  }) : _projectId = projectId,
       _projectRepository = projectRepository,
       _occurrenceReadService = occurrenceReadService,
       _sessionDayKeyService = sessionDayKeyService,
       super(const ProjectOverviewLoading()) {
    on<ProjectOverviewStarted>(_onStarted, transformer: restartable());
    add(const ProjectOverviewStarted());
  }

  final String _projectId;
  final ProjectRepositoryContract _projectRepository;
  final OccurrenceReadService _occurrenceReadService;
  final SessionDayKeyService _sessionDayKeyService;
  final String _inboxProjectKey = ProjectGroupingRef.inbox().stableKey;

  bool get _isInbox => _projectId == _inboxProjectKey;

  Future<void> _onStarted(
    ProjectOverviewStarted event,
    Emitter<ProjectOverviewState> emit,
  ) async {
    await emit.onEach<_OverviewSnapshot>(
      _watchOverview(),
      onData: (snapshot) {
        final project = snapshot.project;
        if (project == null) {
          emit(const ProjectOverviewError(message: 'Project not found'));
          return;
        }
        emit(
          ProjectOverviewLoaded(
            project: project,
            tasks: snapshot.tasks,
            todayDayKeyUtc: snapshot.todayDayKeyUtc,
          ),
        );
      },
      onError: (error, __) {
        emit(ProjectOverviewError(message: error.toString()));
      },
    );
  }

  Stream<_OverviewSnapshot> _watchOverview() {
    final dayKey$ = _sessionDayKeyService.todayDayKeyUtc;
    final project$ = _isInbox
        ? dayKey$.map(_buildInboxProject)
        : _projectRepository.watchById(_projectId);

    final tasks$ = dayKey$.switchMap((dayKey) {
      final preview = OccurrencePolicy.projectsPreview(asOfDayKey: dayKey);
      final query = _isInbox
          ? TaskQuery.all().withAdditionalPredicates(
              const [
                TaskProjectPredicate(operator: ProjectOperator.isNull),
              ],
            )
          : TaskQuery.byProject(_projectId);
      return _occurrenceReadService.watchTasksWithOccurrencePreview(
        query: query,
        preview: preview,
      );
    });

    return Rx.combineLatest3<DateTime, Project?, List<Task>, _OverviewSnapshot>(
      dayKey$,
      project$,
      tasks$,
      (dayKey, project, tasks) => _OverviewSnapshot(
        todayDayKeyUtc: dayKey,
        project: project,
        tasks: tasks,
      ),
    );
  }

  Project _buildInboxProject(DateTime todayDayKeyUtc) {
    return Project(
      id: _inboxProjectKey,
      createdAt: todayDayKeyUtc,
      updatedAt: todayDayKeyUtc,
      name: 'Inbox',
      completed: false,
    );
  }
}

final class _OverviewSnapshot {
  const _OverviewSnapshot({
    required this.todayDayKeyUtc,
    required this.project,
    required this.tasks,
  });

  final DateTime todayDayKeyUtc;
  final Project? project;
  final List<Task> tasks;
}
