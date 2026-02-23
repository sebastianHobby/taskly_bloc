import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

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
    required this.routines,
    required this.todayDayKeyUtc,
  });

  final Project project;
  final List<Task> tasks;
  final List<ProjectRoutineItem> routines;
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
    required RoutineRepositoryContract routineRepository,
    RoutineScheduleService scheduleService = const RoutineScheduleService(),
  }) : _projectId = projectId,
       _projectRepository = projectRepository,
       _occurrenceReadService = occurrenceReadService,
       _sessionDayKeyService = sessionDayKeyService,
       _routineRepository = routineRepository,
       _scheduleService = scheduleService,
       super(const ProjectOverviewLoading()) {
    on<ProjectOverviewStarted>(_onStarted, transformer: restartable());
    add(const ProjectOverviewStarted());
  }

  final String _projectId;
  final ProjectRepositoryContract _projectRepository;
  final OccurrenceReadService _occurrenceReadService;
  final SessionDayKeyService _sessionDayKeyService;
  final RoutineRepositoryContract _routineRepository;
  final RoutineScheduleService _scheduleService;
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
            routines: snapshot.routines,
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

    final routines$ = _routineRepository
        .watchAll(includeInactive: true)
        .map(
          (routines) => routines
              .where((routine) => routine.projectId == _projectId)
              .toList(growable: false),
        );
    final completions$ = _routineRepository.watchCompletions();
    final skips$ = _routineRepository.watchSkips();

    return Rx.combineLatest6<
      DateTime,
      Project?,
      List<Task>,
      List<Routine>,
      List<RoutineCompletion>,
      List<RoutineSkip>,
      _OverviewSnapshot
    >(
      dayKey$,
      project$,
      tasks$,
      routines$,
      completions$,
      skips$,
      (dayKey, project, tasks, routines, completions, skips) =>
          _OverviewSnapshot(
            todayDayKeyUtc: dayKey,
            project: project,
            tasks: tasks,
            routines: _buildRoutineItems(
              routines: routines,
              dayKeyUtc: dayKey,
              completions: completions,
              skips: skips,
            ),
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

  List<ProjectRoutineItem> _buildRoutineItems({
    required List<Routine> routines,
    required DateTime dayKeyUtc,
    required List<RoutineCompletion> completions,
    required List<RoutineSkip> skips,
  }) {
    if (routines.isEmpty) return const <ProjectRoutineItem>[];

    final items = <ProjectRoutineItem>[];
    for (final routine in routines) {
      final snapshot = _scheduleService.buildSnapshot(
        routine: routine,
        dayKeyUtc: dayKeyUtc,
        completions: completions,
        skips: skips,
      );
      items.add(
        ProjectRoutineItem(
          routine: routine,
          snapshot: snapshot,
          dayKeyUtc: dayKeyUtc,
          completionsInPeriod: _completionsForPeriod(
            routine: routine,
            snapshot: snapshot,
            completions: completions,
          ),
          skipsInPeriod: _skipsForPeriod(
            routine: routine,
            snapshot: snapshot,
            skips: skips,
          ),
        ),
      );
    }

    items.sort((a, b) => a.routine.name.compareTo(b.routine.name));
    return items;
  }

  List<RoutineCompletion> _completionsForPeriod({
    required Routine routine,
    required RoutineCadenceSnapshot snapshot,
    required List<RoutineCompletion> completions,
  }) {
    final periodStart = dateOnly(snapshot.periodStartUtc);
    final periodEnd = dateOnly(snapshot.periodEndUtc);
    final filtered = <RoutineCompletion>[];

    for (final completion in completions) {
      if (completion.routineId != routine.id) continue;
      final day = dateOnly(
        completion.completedDayLocal ?? completion.completedAtUtc,
      );
      if (day.isBefore(periodStart) || day.isAfter(periodEnd)) continue;
      filtered.add(completion);
    }

    return filtered;
  }

  List<RoutineSkip> _skipsForPeriod({
    required Routine routine,
    required RoutineCadenceSnapshot snapshot,
    required List<RoutineSkip> skips,
  }) {
    if (routine.periodType != RoutinePeriodType.week) {
      return const <RoutineSkip>[];
    }

    final periodStart = dateOnly(snapshot.periodStartUtc);
    return skips
        .where((skip) => skip.routineId == routine.id)
        .where((skip) => skip.periodType == RoutineSkipPeriodType.week)
        .where((skip) => dateOnly(skip.periodKeyUtc).isAtSameMomentAs(periodStart))
        .toList(growable: false);
  }
}

final class _OverviewSnapshot {
  const _OverviewSnapshot({
    required this.todayDayKeyUtc,
    required this.project,
    required this.tasks,
    required this.routines,
  });

  final DateTime todayDayKeyUtc;
  final Project? project;
  final List<Task> tasks;
  final List<ProjectRoutineItem> routines;
}

final class ProjectRoutineItem {
  const ProjectRoutineItem({
    required this.routine,
    required this.snapshot,
    required this.dayKeyUtc,
    required this.completionsInPeriod,
    required this.skipsInPeriod,
  });

  final Routine routine;
  final RoutineCadenceSnapshot snapshot;
  final DateTime dayKeyUtc;
  final List<RoutineCompletion> completionsInPeriod;
  final List<RoutineSkip> skipsInPeriod;
}
