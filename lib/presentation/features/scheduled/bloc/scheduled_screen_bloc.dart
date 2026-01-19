import 'package:bloc/bloc.dart';

import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/contracts.dart';

sealed class ScheduledScreenEffect {
  const ScheduledScreenEffect();
}

final class ScheduledOpenTaskNew extends ScheduledScreenEffect {
  const ScheduledOpenTaskNew({required this.defaultDeadlineDay});

  /// Date-only day (local day semantics) to prefill as a deadline.
  final DateTime defaultDeadlineDay;
}

final class ScheduledOpenProjectNew extends ScheduledScreenEffect {
  const ScheduledOpenProjectNew();
}

final class ScheduledBulkDeadlineRescheduled extends ScheduledScreenEffect {
  const ScheduledBulkDeadlineRescheduled({
    required this.taskCount,
    required this.projectCount,
    required this.newDeadlineDay,
  });

  final int taskCount;
  final int projectCount;
  final DateTime newDeadlineDay;
}

final class ScheduledShowMessage extends ScheduledScreenEffect {
  const ScheduledShowMessage(this.message);

  final String message;
}

sealed class ScheduledScreenEvent {
  const ScheduledScreenEvent();
}

final class ScheduledCreateTaskForDayRequested extends ScheduledScreenEvent {
  const ScheduledCreateTaskForDayRequested({required this.day});

  /// Day key to create the task for (date-only semantics).
  final DateTime day;
}

final class ScheduledCreateProjectRequested extends ScheduledScreenEvent {
  const ScheduledCreateProjectRequested();
}

final class ScheduledEffectHandled extends ScheduledScreenEvent {
  const ScheduledEffectHandled();
}

final class ScheduledRescheduleTasksDeadlineRequested
    extends ScheduledScreenEvent {
  const ScheduledRescheduleTasksDeadlineRequested({
    required this.taskIds,
    required this.newDeadlineDay,
  });

  final List<String> taskIds;

  /// Date-only semantics.
  final DateTime newDeadlineDay;
}

final class ScheduledRescheduleProjectsDeadlineRequested
    extends ScheduledScreenEvent {
  const ScheduledRescheduleProjectsDeadlineRequested({
    required this.projectIds,
    required this.newDeadlineDay,
  });

  final List<String> projectIds;

  /// Date-only semantics.
  final DateTime newDeadlineDay;
}

final class ScheduledRescheduleEntitiesDeadlineRequested
    extends ScheduledScreenEvent {
  const ScheduledRescheduleEntitiesDeadlineRequested({
    required this.taskIds,
    required this.projectIds,
    required this.newDeadlineDay,
  });

  final List<String> taskIds;
  final List<String> projectIds;

  /// Date-only semantics.
  final DateTime newDeadlineDay;
}

sealed class ScheduledScreenState {
  const ScheduledScreenState({this.effect});

  final ScheduledScreenEffect? effect;
}

final class ScheduledScreenReady extends ScheduledScreenState {
  const ScheduledScreenReady({super.effect});
}

class ScheduledScreenBloc
    extends Bloc<ScheduledScreenEvent, ScheduledScreenState> {
  ScheduledScreenBloc({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    OperationContextFactory contextFactory = const OperationContextFactory(),
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _contextFactory = contextFactory,
       super(const ScheduledScreenReady()) {
    on<ScheduledCreateTaskForDayRequested>((event, emit) {
      emit(
        ScheduledScreenReady(
          effect: ScheduledOpenTaskNew(
            defaultDeadlineDay: DateTime(
              event.day.year,
              event.day.month,
              event.day.day,
            ),
          ),
        ),
      );
    });

    on<ScheduledCreateProjectRequested>((event, emit) {
      emit(const ScheduledScreenReady(effect: ScheduledOpenProjectNew()));
    });

    on<ScheduledEffectHandled>((event, emit) {
      if (state.effect == null) return;
      emit(const ScheduledScreenReady());
    });

    on<ScheduledRescheduleTasksDeadlineRequested>(_onRescheduleTasksDeadline);
    on<ScheduledRescheduleProjectsDeadlineRequested>(
      _onRescheduleProjectsDeadline,
    );
    on<ScheduledRescheduleEntitiesDeadlineRequested>(
      _onRescheduleEntitiesDeadline,
    );
  }

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final OperationContextFactory _contextFactory;

  Future<void> _onRescheduleTasksDeadline(
    ScheduledRescheduleTasksDeadlineRequested event,
    Emitter<ScheduledScreenState> emit,
  ) async {
    final uniqueTaskIds = event.taskIds.toSet().toList(growable: false);
    if (uniqueTaskIds.isEmpty) return;

    final newDeadlineDay = DateTime(
      event.newDeadlineDay.year,
      event.newDeadlineDay.month,
      event.newDeadlineDay.day,
    );

    final baseContext = _contextFactory.create(
      feature: 'scheduled',
      screen: 'scheduled',
      intent: 'bulk_reschedule',
      operation: 'task_update_deadline',
      extraFields: <String, Object?>{
        'task_count': uniqueTaskIds.length,
        'new_deadline_day': newDeadlineDay.toIso8601String(),
      },
    );

    var updated = 0;

    try {
      for (final taskId in uniqueTaskIds) {
        final task = await _taskRepository.getById(taskId);
        if (task == null) continue;

        await _taskRepository.update(
          id: task.id,
          name: task.name,
          completed: task.completed,
          description: task.description,
          startDate: task.startDate,
          deadlineDate: newDeadlineDay,
          projectId: task.projectId,
          priority: task.priority,
          repeatIcalRrule: task.repeatIcalRrule,
          repeatFromCompletion: task.repeatFromCompletion,
          seriesEnded: task.seriesEnded,
          valueIds: task.values.map((v) => v.id).toList(growable: false),
          isPinned: task.isPinned,
          context: baseContext.copyWith(entityType: 'task', entityId: task.id),
        );

        updated++;
      }

      emit(
        ScheduledScreenReady(
          effect: ScheduledBulkDeadlineRescheduled(
            taskCount: updated,
            projectCount: 0,
            newDeadlineDay: newDeadlineDay,
          ),
        ),
      );
    } catch (e) {
      emit(ScheduledScreenReady(effect: ScheduledShowMessage(e.toString())));
    }
  }

  Future<void> _onRescheduleProjectsDeadline(
    ScheduledRescheduleProjectsDeadlineRequested event,
    Emitter<ScheduledScreenState> emit,
  ) async {
    final uniqueProjectIds = event.projectIds.toSet().toList(growable: false);
    if (uniqueProjectIds.isEmpty) return;

    final newDeadlineDay = DateTime(
      event.newDeadlineDay.year,
      event.newDeadlineDay.month,
      event.newDeadlineDay.day,
    );

    final baseContext = _contextFactory.create(
      feature: 'scheduled',
      screen: 'scheduled',
      intent: 'bulk_reschedule',
      operation: 'project_update_deadline',
      extraFields: <String, Object?>{
        'project_count': uniqueProjectIds.length,
        'new_deadline_day': newDeadlineDay.toIso8601String(),
      },
    );

    var updated = 0;

    try {
      for (final projectId in uniqueProjectIds) {
        final project = await _projectRepository.getById(projectId);
        if (project == null) continue;

        await _projectRepository.update(
          id: project.id,
          name: project.name,
          completed: project.completed,
          description: project.description,
          startDate: project.startDate,
          deadlineDate: newDeadlineDay,
          priority: project.priority,
          repeatIcalRrule: project.repeatIcalRrule,
          repeatFromCompletion: project.repeatFromCompletion,
          seriesEnded: project.seriesEnded,
          valueIds: project.values.map((v) => v.id).toList(growable: false),
          isPinned: project.isPinned,
          context: baseContext.copyWith(
            entityType: 'project',
            entityId: project.id,
          ),
        );

        updated++;
      }

      emit(
        ScheduledScreenReady(
          effect: ScheduledBulkDeadlineRescheduled(
            taskCount: 0,
            projectCount: updated,
            newDeadlineDay: newDeadlineDay,
          ),
        ),
      );
    } catch (e) {
      emit(ScheduledScreenReady(effect: ScheduledShowMessage(e.toString())));
    }
  }

  Future<void> _onRescheduleEntitiesDeadline(
    ScheduledRescheduleEntitiesDeadlineRequested event,
    Emitter<ScheduledScreenState> emit,
  ) async {
    final uniqueTaskIds = event.taskIds.toSet().toList(growable: false);
    final uniqueProjectIds = event.projectIds.toSet().toList(growable: false);
    if (uniqueTaskIds.isEmpty && uniqueProjectIds.isEmpty) return;

    final newDeadlineDay = DateTime(
      event.newDeadlineDay.year,
      event.newDeadlineDay.month,
      event.newDeadlineDay.day,
    );

    final baseContext = _contextFactory.create(
      feature: 'scheduled',
      screen: 'scheduled',
      intent: 'bulk_reschedule',
      operation: 'bulk_update_deadline',
      extraFields: <String, Object?>{
        'task_count': uniqueTaskIds.length,
        'project_count': uniqueProjectIds.length,
        'new_deadline_day': newDeadlineDay.toIso8601String(),
      },
    );

    var updatedTasks = 0;
    var updatedProjects = 0;

    try {
      for (final taskId in uniqueTaskIds) {
        final task = await _taskRepository.getById(taskId);
        if (task == null) continue;

        await _taskRepository.update(
          id: task.id,
          name: task.name,
          completed: task.completed,
          description: task.description,
          startDate: task.startDate,
          deadlineDate: newDeadlineDay,
          projectId: task.projectId,
          priority: task.priority,
          repeatIcalRrule: task.repeatIcalRrule,
          repeatFromCompletion: task.repeatFromCompletion,
          seriesEnded: task.seriesEnded,
          valueIds: task.values.map((v) => v.id).toList(growable: false),
          isPinned: task.isPinned,
          context: baseContext.copyWith(entityType: 'task', entityId: task.id),
        );

        updatedTasks++;
      }

      for (final projectId in uniqueProjectIds) {
        final project = await _projectRepository.getById(projectId);
        if (project == null) continue;

        await _projectRepository.update(
          id: project.id,
          name: project.name,
          completed: project.completed,
          description: project.description,
          startDate: project.startDate,
          deadlineDate: newDeadlineDay,
          priority: project.priority,
          repeatIcalRrule: project.repeatIcalRrule,
          repeatFromCompletion: project.repeatFromCompletion,
          seriesEnded: project.seriesEnded,
          valueIds: project.values.map((v) => v.id).toList(growable: false),
          isPinned: project.isPinned,
          context: baseContext.copyWith(
            entityType: 'project',
            entityId: project.id,
          ),
        );

        updatedProjects++;
      }

      emit(
        ScheduledScreenReady(
          effect: ScheduledBulkDeadlineRescheduled(
            taskCount: updatedTasks,
            projectCount: updatedProjects,
            newDeadlineDay: newDeadlineDay,
          ),
        ),
      );
    } catch (e) {
      emit(ScheduledScreenReady(effect: ScheduledShowMessage(e.toString())));
    }
  }
}
