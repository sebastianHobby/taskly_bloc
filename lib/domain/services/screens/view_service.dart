import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/view_definition.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/services/screens/screen_query_builder.dart';

/// Service for fetching and filtering entities based on ViewDefinition.
///
/// This service acts as a bridge between ViewDefinition and the repository
/// layer, handling all entity fetching logic for different view types.
class ViewService {
  ViewService({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required LabelRepositoryContract labelRepository,
    required ScreenQueryBuilder queryBuilder,
    DateTime Function()? nowFactory,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _labelRepository = labelRepository,
       _queryBuilder = queryBuilder,
       _nowFactory = nowFactory ?? DateTime.now;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final LabelRepositoryContract _labelRepository;
  final ScreenQueryBuilder _queryBuilder;
  final DateTime Function() _nowFactory;

  /// Watch entities for a collection view
  Stream<List<dynamic>> watchCollectionView({
    required EntitySelector selector,
    required DisplayConfig display,
  }) {
    switch (selector.entityType) {
      case EntityType.task:
        final query = _queryBuilder.buildTaskQuery(
          selector: selector,
          display: display,
          now: _nowFactory(),
        );
        return _taskRepository.watchAll(query);

      case EntityType.project:
        final query = _queryBuilder.buildProjectQuery(
          selector: selector,
          display: display,
        );
        return _projectRepository.watchAllByQuery(query);

      case EntityType.label:
        return _labelRepository.watchAll();

      case EntityType.goal:
        // Goals are labels with type=value
        return _labelRepository.watchAll().map(
          (labels) => labels.where((l) => l.type == LabelType.value).toList(),
        );
    }
  }

  /// Watch entities for an agenda view (date-grouped)
  Stream<List<Task>> watchAgendaView({
    required EntitySelector selector,
    required DisplayConfig display,
    required AgendaConfig agendaConfig,
  }) {
    if (selector.entityType != EntityType.task) {
      throw ArgumentError('Agenda views only support tasks');
    }

    final query = _queryBuilder.buildTaskQuery(
      selector: selector,
      display: display,
      now: _nowFactory(),
    );

    return _taskRepository.watchAll(query).map((tasks) {
      // Filter tasks based on agenda date field
      return tasks.where((task) {
        final date = _getDateForAgendaField(task, agendaConfig.dateField);
        return date != null;
      }).toList();
    });
  }

  /// Watch entities for an allocated view (Next Actions)
  Stream<List<Task>> watchAllocatedView({
    required EntitySelector selector,
    required DisplayConfig display,
  }) {
    if (selector.entityType != EntityType.task) {
      throw ArgumentError('Allocated views only support tasks');
    }

    final query = _queryBuilder.buildTaskQuery(
      selector: selector,
      display: display,
      now: _nowFactory(),
    );

    return _taskRepository.watchAll(query);
  }

  /// Watch a single entity for detail view
  Stream<dynamic> watchDetailEntity({
    required DetailParentType parentType,
    required String entityId,
  }) {
    switch (parentType) {
      case DetailParentType.project:
        return _projectRepository.watch(entityId);

      case DetailParentType.label:
        return _labelRepository.watch(entityId);
    }
  }

  /// Get count for a view (for badges)
  Stream<int> watchViewCount({
    required EntitySelector selector,
    required DisplayConfig display,
  }) {
    switch (selector.entityType) {
      case EntityType.task:
        final query = _queryBuilder.buildTaskQuery(
          selector: selector,
          display: display,
          now: _nowFactory(),
        );
        return _taskRepository.watchCount(query);

      case EntityType.project:
        final query = _queryBuilder.buildProjectQuery(
          selector: selector,
          display: display,
        );
        return _projectRepository.watchCount(query);

      case EntityType.label:
      case EntityType.goal:
        return Stream.value(0); // No counts for labels/goals
    }
  }

  DateTime? _getDateForAgendaField(Task task, DateField field) {
    switch (field) {
      case DateField.deadlineDate:
        return task.deadlineDate;
      case DateField.startDate:
        return task.startDate;
      case DateField.scheduledFor:
        return task.startDate; // For now, use startDate as scheduledFor
    }
  }
}
