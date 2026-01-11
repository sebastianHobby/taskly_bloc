import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/domain/allocation/contracts/allocation_snapshot_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/allocation/model/allocation_snapshot.dart';
import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/someday_backlog_section_params.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';
import 'package:taskly_bloc/domain/queries/project_predicate.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/section_template_interpreter.dart';
import 'package:taskly_bloc/domain/services/time/home_day_key_service.dart';

/// Section template for Someday backlog: unscheduled tasks and projects.
///
/// The interpreter returns the full unscheduled dataset; grouping and filtering
/// is handled in the renderer as ephemeral UI state.
class SomedayBacklogSectionInterpreter
    implements SectionTemplateInterpreter<SomedayBacklogSectionParams> {
  SomedayBacklogSectionInterpreter({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required AllocationSnapshotRepositoryContract allocationSnapshotRepository,
    required HomeDayKeyService dayKeyService,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _allocationSnapshotRepository = allocationSnapshotRepository,
       _dayKeyService = dayKeyService;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final AllocationSnapshotRepositoryContract _allocationSnapshotRepository;
  final HomeDayKeyService _dayKeyService;

  @override
  String get templateId => SectionTemplateId.somedayBacklog;

  static const String _focusTaskIdsKey = 'focusTaskIds';
  static const String _focusProjectIdsKey = 'focusProjectIds';

  @override
  Stream<SectionDataResult> watch(SomedayBacklogSectionParams params) {
    final tasksStream = _taskRepository.watchAll(_taskQuery());
    final projectsStream = _projectRepository.watchAll(_projectQuery());

    final dayUtc = _dayKeyService.todayDayKeyUtc();
    final snapshotStream = _allocationSnapshotRepository.watchLatestForUtcDay(
      dayUtc,
    );

    return Rx.combineLatest3(
      tasksStream,
      projectsStream,
      snapshotStream,
      (List<Task> tasks, List<Project> projects, AllocationSnapshot? snapshot) {
        return _buildResult(
          tasks: tasks,
          projects: projects,
          snapshot: snapshot,
        );
      },
    );
  }

  @override
  Future<SectionDataResult> fetch(SomedayBacklogSectionParams params) async {
    final tasks = await _taskRepository.getAll(_taskQuery());
    final projects = await _projectRepository.getAll(_projectQuery());

    final snapshot = await _allocationSnapshotRepository.getLatestForUtcDay(
      _dayKeyService.todayDayKeyUtc(),
    );

    return _buildResult(tasks: tasks, projects: projects, snapshot: snapshot);
  }

  static TaskQuery _taskQuery() {
    return const TaskQuery(
      filter: QueryFilter<TaskPredicate>(
        shared: [
          TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
          TaskDatePredicate(
            field: TaskDateField.startDate,
            operator: DateOperator.isNull,
          ),
          TaskDatePredicate(
            field: TaskDateField.deadlineDate,
            operator: DateOperator.isNull,
          ),
        ],
      ),
    );
  }

  static ProjectQuery _projectQuery() {
    return const ProjectQuery(
      filter: QueryFilter<ProjectPredicate>(
        shared: [
          ProjectBoolPredicate(
            field: ProjectBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
          ProjectDatePredicate(
            field: ProjectDateField.startDate,
            operator: DateOperator.isNull,
          ),
          ProjectDatePredicate(
            field: ProjectDateField.deadlineDate,
            operator: DateOperator.isNull,
          ),
        ],
      ),
    );
  }

  SectionDataResult _buildResult({
    required List<Task> tasks,
    required List<Project> projects,
    required AllocationSnapshot? snapshot,
  }) {
    final focusTaskIds = <String>{};
    final focusProjectIds = <String>{};

    if (snapshot != null) {
      for (final entry in snapshot.allocated) {
        switch (entry.entity.type) {
          case AllocationSnapshotEntityType.task:
            focusTaskIds.add(entry.entity.id);
          case AllocationSnapshotEntityType.project:
            focusProjectIds.add(entry.entity.id);
        }
      }
    }

    final items = <ScreenItem>[
      ...projects.map(ScreenItem.project),
      ...tasks.map(ScreenItem.task),
    ];

    // Stable default sort: updatedAt desc.
    items.sort((a, b) {
      final aKey = _sortKeyFor(a);
      final bKey = _sortKeyFor(b);

      final byKey = bKey.compareTo(aKey);
      if (byKey != 0) return byKey;

      return _stableId(a).compareTo(_stableId(b));
    });

    return SectionDataResult.data(
      items: items,
      relatedEntities: <String, List<Object>>{
        _focusTaskIdsKey: focusTaskIds.toList(growable: false),
        _focusProjectIdsKey: focusProjectIds.toList(growable: false),
      },
    );
  }

  DateTime _sortKeyFor(ScreenItem item) {
    return switch (item) {
      ScreenItemTask(:final task) => task.updatedAt,
      ScreenItemProject(:final project) => project.updatedAt,
      _ => DateTime.utc(0),
    };
  }

  String _stableId(ScreenItem item) {
    return switch (item) {
      ScreenItemTask(:final task) => 't:${task.id}',
      ScreenItemProject(:final project) => 'p:${project.id}',
      _ => item.runtimeType.toString(),
    };
  }
}
