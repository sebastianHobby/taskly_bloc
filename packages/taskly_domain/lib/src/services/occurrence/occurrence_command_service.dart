import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';

/// Domain-level commands for recurrence/occurrence mutations.
///
/// This service exists to keep recurrence semantics consistent across screens:
/// - Screens that *already have* occurrence keys may pass them through.
/// - Screens that *do not have* occurrence keys (e.g. Projects) can call
///   "complete next occurrence" without guessing dates.
///
/// Storage + sync invariants are still enforced by the repositories/write-helper.
class OccurrenceCommandService {
  OccurrenceCommandService({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required HomeDayKeyService dayKeyService,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _dayKeyService = dayKeyService;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final HomeDayKeyService _dayKeyService;

  /// Completes a task occurrence.
  ///
  /// If [occurrenceDate] is null:
  /// - non-repeating tasks complete as a single entity
  /// - repeating tasks complete the next uncompleted occurrence relative to the
  ///   home-day key.
  Future<void> completeTask({
    required String taskId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
    OperationContext? context,
  }) async {
    if (occurrenceDate != null) {
      await _taskRepository.completeOccurrence(
        taskId: taskId,
        occurrenceDate: occurrenceDate,
        originalOccurrenceDate: originalOccurrenceDate,
        notes: notes,
        context: context,
      );
      return;
    }

    final task = await _taskRepository.getById(taskId);
    if (task == null) {
      throw StateError('Task not found: $taskId');
    }

    if (!task.isRepeating || task.seriesEnded) {
      await _taskRepository.completeOccurrence(
        taskId: taskId,
        occurrenceDate: null,
        originalOccurrenceDate: null,
        notes: notes,
        context: context,
      );
      return;
    }

    final asOfDay = _dayKeyService.todayDayKeyUtc();
    final occurrence = await _resolveNextUncompletedTaskOccurrence(
      taskId: taskId,
      asOfDay: asOfDay,
    );

    await _taskRepository.completeOccurrence(
      taskId: taskId,
      occurrenceDate: occurrence.date,
      originalOccurrenceDate: occurrence.originalDate ?? occurrence.date,
      notes: notes,
      context: context,
    );
  }

  /// Uncompletes a task occurrence.
  ///
  /// If [occurrenceDate] is null:
  /// - non-repeating tasks uncomplete as a single entity
  /// - repeating tasks uncomplete the most recently completed occurrence
  ///   relative to the home-day key.
  Future<void> uncompleteTask({
    required String taskId,
    DateTime? occurrenceDate,
    OperationContext? context,
  }) async {
    if (occurrenceDate != null) {
      await _taskRepository.uncompleteOccurrence(
        taskId: taskId,
        occurrenceDate: occurrenceDate,
        context: context,
      );
      return;
    }

    final task = await _taskRepository.getById(taskId);
    if (task == null) {
      throw StateError('Task not found: $taskId');
    }

    if (!task.isRepeating) {
      await _taskRepository.uncompleteOccurrence(
        taskId: taskId,
        occurrenceDate: null,
        context: context,
      );
      return;
    }

    final asOfDay = _dayKeyService.todayDayKeyUtc();
    final occurrence = await _resolveMostRecentCompletedTaskOccurrence(
      taskId: taskId,
      asOfDay: asOfDay,
    );

    await _taskRepository.uncompleteOccurrence(
      taskId: taskId,
      occurrenceDate: occurrence.date,
      context: context,
    );
  }

  /// Completes a task series (ends recurrence).
  ///
  /// This is the explicit "complete series" pathway, distinct from completing
  /// the next occurrence.
  Future<void> completeTaskSeries({
    required String taskId,
    OperationContext? context,
  }) async {
    final task = await _taskRepository.getById(taskId);
    if (task == null) {
      throw StateError('Task not found: $taskId');
    }

    await _taskRepository.update(
      id: task.id,
      name: task.name,
      completed: true,
      description: task.description,
      startDate: task.startDate,
      deadlineDate: task.deadlineDate,
      projectId: task.projectId,
      priority: task.priority,
      repeatIcalRrule: task.repeatIcalRrule,
      repeatFromCompletion: task.repeatFromCompletion,
      seriesEnded: true,
      isPinned: task.isPinned,
      context: context,
    );
  }

  /// Completes a project occurrence.
  ///
  /// If [occurrenceDate] is null:
  /// - non-repeating projects complete as a single entity
  /// - repeating projects complete the next uncompleted occurrence relative to
  ///   the home-day key.
  Future<void> completeProject({
    required String projectId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
    OperationContext? context,
  }) async {
    if (occurrenceDate != null) {
      await _projectRepository.completeOccurrence(
        projectId: projectId,
        occurrenceDate: occurrenceDate,
        originalOccurrenceDate: originalOccurrenceDate,
        notes: notes,
        context: context,
      );
      return;
    }

    final project = await _projectRepository.getById(projectId);
    if (project == null) {
      throw StateError('Project not found: $projectId');
    }

    if (!project.isRepeating || project.seriesEnded) {
      await _projectRepository.completeOccurrence(
        projectId: projectId,
        occurrenceDate: null,
        originalOccurrenceDate: null,
        notes: notes,
        context: context,
      );
      return;
    }

    final asOfDay = _dayKeyService.todayDayKeyUtc();
    final occurrence = await _resolveNextUncompletedProjectOccurrence(
      projectId: projectId,
      asOfDay: asOfDay,
    );

    await _projectRepository.completeOccurrence(
      projectId: projectId,
      occurrenceDate: occurrence.date,
      originalOccurrenceDate: occurrence.originalDate ?? occurrence.date,
      notes: notes,
      context: context,
    );
  }

  /// Uncompletes a project occurrence.
  ///
  /// If [occurrenceDate] is null:
  /// - non-repeating projects uncomplete as a single entity
  /// - repeating projects uncomplete the most recently completed occurrence
  ///   relative to the home-day key.
  Future<void> uncompleteProject({
    required String projectId,
    DateTime? occurrenceDate,
    OperationContext? context,
  }) async {
    if (occurrenceDate != null) {
      await _projectRepository.uncompleteOccurrence(
        projectId: projectId,
        occurrenceDate: occurrenceDate,
        context: context,
      );
      return;
    }

    final project = await _projectRepository.getById(projectId);
    if (project == null) {
      throw StateError('Project not found: $projectId');
    }

    if (!project.isRepeating) {
      await _projectRepository.uncompleteOccurrence(
        projectId: projectId,
        occurrenceDate: null,
        context: context,
      );
      return;
    }

    final asOfDay = _dayKeyService.todayDayKeyUtc();
    final occurrence = await _resolveMostRecentCompletedProjectOccurrence(
      projectId: projectId,
      asOfDay: asOfDay,
    );

    await _projectRepository.uncompleteOccurrence(
      projectId: projectId,
      occurrenceDate: occurrence.date,
      context: context,
    );
  }

  /// Completes a project series (ends recurrence).
  Future<void> completeProjectSeries({
    required String projectId,
    OperationContext? context,
  }) async {
    final project = await _projectRepository.getById(projectId);
    if (project == null) {
      throw StateError('Project not found: $projectId');
    }

    await _projectRepository.update(
      id: project.id,
      name: project.name,
      completed: true,
      description: project.description,
      startDate: project.startDate,
      deadlineDate: project.deadlineDate,
      repeatIcalRrule: project.repeatIcalRrule,
      repeatFromCompletion: project.repeatFromCompletion,
      seriesEnded: true,
      valueIds: project.values.map((v) => v.id).toList(growable: false),
      priority: project.priority,
      isPinned: project.isPinned,
      context: context,
    );
  }

  Future<OccurrenceData> _resolveNextUncompletedTaskOccurrence({
    required String taskId,
    required DateTime asOfDay,
  }) async {
    final range = OccurrencePolicy.commandResolutionRange(asOfDayKey: asOfDay);
    final expanded = await _taskRepository.getOccurrencesForTask(
      taskId: taskId,
      rangeStart: range.rangeStart,
      rangeEnd: range.rangeEnd,
    );

    final nextById =
        NextOccurrenceSelector.nextUncompletedTaskOccurrenceByTaskId(
          expandedTasks: expanded,
          asOfDay: asOfDay,
        );

    final next = nextById[taskId];
    if (next == null) {
      throw StateError('No next uncompleted task occurrence found: $taskId');
    }

    return next;
  }

  Future<OccurrenceData> _resolveMostRecentCompletedTaskOccurrence({
    required String taskId,
    required DateTime asOfDay,
  }) async {
    final range = OccurrencePolicy.commandResolutionRange(asOfDayKey: asOfDay);
    final expanded = await _taskRepository.getOccurrencesForTask(
      taskId: taskId,
      rangeStart: range.rangeStart,
      rangeEnd: range.rangeEnd,
    );

    final candidates = <OccurrenceData>[];

    for (final t in expanded) {
      final o = t.occurrence;
      if (o == null) continue;
      if (!o.isCompleted) continue;
      candidates.add(o);
    }

    if (candidates.isEmpty) {
      throw StateError(
        'No completed task occurrence found to uncomplete: $taskId',
      );
    }

    candidates.sort((a, b) => a.date.compareTo(b.date));

    // Prefer the most recent completed occurrence on/before the asOf day.
    for (final o in candidates.reversed) {
      if (!o.date.isAfter(asOfDay)) return o;
    }

    // Fallback: latest completed occurrence in the window.
    return candidates.last;
  }

  Future<OccurrenceData> _resolveNextUncompletedProjectOccurrence({
    required String projectId,
    required DateTime asOfDay,
  }) async {
    final range = OccurrencePolicy.commandResolutionRange(asOfDayKey: asOfDay);
    final expanded = await _projectRepository.getOccurrencesForProject(
      projectId: projectId,
      rangeStart: range.rangeStart,
      rangeEnd: range.rangeEnd,
    );

    final nextById =
        NextOccurrenceSelector.nextUncompletedProjectOccurrenceByProjectId(
          expandedProjects: expanded,
          asOfDay: asOfDay,
        );

    final next = nextById[projectId];
    if (next == null) {
      throw StateError(
        'No next uncompleted project occurrence found: $projectId',
      );
    }

    return next;
  }

  Future<OccurrenceData> _resolveMostRecentCompletedProjectOccurrence({
    required String projectId,
    required DateTime asOfDay,
  }) async {
    final range = OccurrencePolicy.commandResolutionRange(asOfDayKey: asOfDay);
    final expanded = await _projectRepository.getOccurrencesForProject(
      projectId: projectId,
      rangeStart: range.rangeStart,
      rangeEnd: range.rangeEnd,
    );

    final candidates = <OccurrenceData>[];

    for (final p in expanded) {
      final o = p.occurrence;
      if (o == null) continue;
      if (!o.isCompleted) continue;
      candidates.add(o);
    }

    if (candidates.isEmpty) {
      throw StateError(
        'No completed project occurrence found to uncomplete: $projectId',
      );
    }

    candidates.sort((a, b) => a.date.compareTo(b.date));

    for (final o in candidates.reversed) {
      if (!o.date.isAfter(asOfDay)) return o;
    }

    return candidates.last;
  }
}
