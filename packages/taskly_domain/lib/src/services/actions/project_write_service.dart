import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';

/// Write facade for project mutations.
///
/// Centralizes validation and side-effects for project edits and actions.
final class ProjectWriteService {
  ProjectWriteService({
    required ProjectRepositoryContract projectRepository,
    required AllocationOrchestrator allocationOrchestrator,
    required OccurrenceCommandService occurrenceCommandService,
  }) : _projectRepository = projectRepository,
       _allocationOrchestrator = allocationOrchestrator,
       _occurrenceCommandService = occurrenceCommandService,
       _commandHandler = ProjectCommandHandler(
         projectRepository: projectRepository,
       );

  final ProjectRepositoryContract _projectRepository;
  final AllocationOrchestrator _allocationOrchestrator;
  final OccurrenceCommandService _occurrenceCommandService;
  final ProjectCommandHandler _commandHandler;

  Future<CommandResult> create(
    CreateProjectCommand command, {
    OperationContext? context,
  }) {
    return _commandHandler.handleCreate(command, context: context);
  }

  Future<CommandResult> update(
    UpdateProjectCommand command, {
    OperationContext? context,
  }) {
    return _commandHandler.handleUpdate(command, context: context);
  }

  Future<void> delete(String projectId, {OperationContext? context}) {
    return _projectRepository.delete(projectId, context: context);
  }

  Future<void> setPinned(
    String projectId, {
    required bool isPinned,
    OperationContext? context,
  }) async {
    if (isPinned) {
      await _allocationOrchestrator.pinProject(projectId, context: context);
    } else {
      await _allocationOrchestrator.unpinProject(projectId, context: context);
    }
  }

  Future<void> complete(
    String projectId, {
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    OperationContext? context,
  }) {
    return _occurrenceCommandService.completeProject(
      projectId: projectId,
      occurrenceDate: occurrenceDate,
      originalOccurrenceDate: originalOccurrenceDate,
      context: context,
    );
  }

  Future<void> uncomplete(
    String projectId, {
    DateTime? occurrenceDate,
    OperationContext? context,
  }) {
    return _occurrenceCommandService.uncompleteProject(
      projectId: projectId,
      occurrenceDate: occurrenceDate,
      context: context,
    );
  }

  Future<void> completeSeries(String projectId, {OperationContext? context}) {
    return _occurrenceCommandService.completeProjectSeries(
      projectId: projectId,
      context: context,
    );
  }

  Future<int> bulkRescheduleDeadlines(
    Iterable<String> projectIds,
    DateTime newDeadlineDate, {
    OperationContext? context,
  }) {
    return _projectRepository.bulkRescheduleDeadlines(
      projectIds: projectIds,
      deadlineDate: newDeadlineDate,
      context: context,
    );
  }
}
