import 'package:taskly_bloc/domain/time/date_only.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/display_config.dart'
    as screen_models;
import 'package:taskly_bloc/domain/screens/language/models/entity_selector.dart'
    as screen_models;
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/allocation_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/data_list_section_params.dart';
import 'package:taskly_bloc/presentation/shared/models/sort_preferences.dart'
    as sort_preferences;
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

/// Builds concrete query objects from persisted screen definitions.
class ScreenQueryBuilder {
  /// Builds a [TaskQuery] from a screen [selector] and [display] config.
  TaskQuery buildTaskQuery({
    required screen_models.EntitySelector selector,
    required screen_models.DisplayConfig display,
    required DateTime now,
  }) {
    if (selector.entityType != screen_models.EntityType.task) {
      throw ArgumentError(
        'Expected EntityType.task, got ${selector.entityType}',
      );
    }

    final baseFilter = selector.taskFilter ?? const QueryFilter.matchAll();

    final normalized = _normalizeTaskFilter(baseFilter, now: now);
    final withCompletion = display.showCompleted
        ? normalized
        : _ensureIncomplete(normalized);

    return TaskQuery(
      filter: withCompletion,
      sortCriteria: _mapSortCriteria(display.sorting),
    );
  }

  /// Builds a [ProjectQuery] from a screen [selector] and [display] config.
  ProjectQuery buildProjectQuery({
    required screen_models.EntitySelector selector,
    required screen_models.DisplayConfig display,
  }) {
    if (selector.entityType != screen_models.EntityType.project) {
      throw ArgumentError(
        'Expected EntityType.project, got ${selector.entityType}',
      );
    }

    final baseFilter = selector.projectFilter ?? const QueryFilter.matchAll();

    return ProjectQuery(
      filter: baseFilter,
      sortCriteria: _mapSortCriteria(display.sorting),
    );
  }

  QueryFilter<TaskPredicate> _ensureIncomplete(QueryFilter<TaskPredicate> f) {
    final alreadyHasCompletionPredicate = f.shared.any(
      (p) =>
          p is TaskBoolPredicate &&
          p.field == TaskBoolField.completed &&
          p.operator == BoolOperator.isFalse,
    );

    if (alreadyHasCompletionPredicate) return f;

    return f.copyWith(
      shared: [
        const TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isFalse,
        ),
        ...f.shared,
      ],
    );
  }

  QueryFilter<TaskPredicate> _normalizeTaskFilter(
    QueryFilter<TaskPredicate> filter, {
    required DateTime now,
  }) {
    TaskPredicate normalize(TaskPredicate predicate) {
      if (predicate is! TaskDatePredicate) return predicate;
      if (predicate.operator != DateOperator.relative) return predicate;

      final relativeDays = predicate.relativeDays ?? 0;
      final pivot = dateOnly(now).add(Duration(days: relativeDays));
      final comparison = predicate.relativeComparison ?? RelativeComparison.on;

      final mappedOperator = switch (comparison) {
        RelativeComparison.on => DateOperator.on,
        RelativeComparison.before => DateOperator.before,
        RelativeComparison.after => DateOperator.after,
        RelativeComparison.onOrAfter => DateOperator.onOrAfter,
        RelativeComparison.onOrBefore => DateOperator.onOrBefore,
      };

      return TaskDatePredicate(
        field: predicate.field,
        operator: mappedOperator,
        date: pivot,
      );
    }

    return filter.copyWith(
      shared: filter.shared.map(normalize).toList(growable: false),
      orGroups: filter.orGroups
          .map((group) => group.map(normalize).toList(growable: false))
          .toList(growable: false),
    );
  }

  List<sort_preferences.SortCriterion> _mapSortCriteria(
    List<screen_models.SortCriterion> criteria,
  ) {
    return criteria
        .map(_mapSortCriterion)
        .whereType<sort_preferences.SortCriterion>()
        .toList(growable: false);
  }

  sort_preferences.SortCriterion? _mapSortCriterion(
    screen_models.SortCriterion criterion,
  ) {
    final field = switch (criterion.field) {
      screen_models.SortField.name => sort_preferences.SortField.name,
      screen_models.SortField.createdAt =>
        sort_preferences.SortField.createdDate,
      screen_models.SortField.updatedAt =>
        sort_preferences.SortField.updatedDate,
      screen_models.SortField.deadlineDate =>
        sort_preferences.SortField.deadlineDate,
      screen_models.SortField.startDate => sort_preferences.SortField.startDate,
      screen_models.SortField.priority => null,
    };

    if (field == null) return null;

    final direction = switch (criterion.direction) {
      screen_models.SortDirection.asc =>
        sort_preferences.SortDirection.ascending,
      screen_models.SortDirection.desc =>
        sort_preferences.SortDirection.descending,
    };

    return sort_preferences.SortCriterion(field: field, direction: direction);
  }

  /// Builds a [TaskQuery] from a [SectionRef] if it represents a task list.
  TaskQuery? buildTaskQueryFromSectionRef({
    required SectionRef section,
    required DateTime now,
  }) {
    if (section.templateId != SectionTemplateId.taskList) return null;

    final params = DataListSectionParams.fromJson(section.params);
    final config = params.config;
    final display = params.display ?? const screen_models.DisplayConfig();

    return switch (config) {
      TaskDataConfig(:final query) => _applyDisplay(query, display),
      _ => null,
    };
  }

  TaskQuery _applyDisplay(
    TaskQuery query,
    screen_models.DisplayConfig display,
  ) {
    final filter = display.showCompleted
        ? query.filter
        : _ensureIncomplete(query.filter);

    return TaskQuery(
      filter: filter,
      sortCriteria: query.sortCriteria.isEmpty
          ? _mapSortCriteria(display.sorting)
          : query.sortCriteria,
    );
  }

  /// Builds a [TaskQuery] from a [SectionRef] if it represents an allocation.
  TaskQuery? buildTaskQueryFromAllocationSectionRef({
    required SectionRef section,
    required DateTime now,
  }) {
    if (section.templateId != SectionTemplateId.allocation) return null;

    final params = AllocationSectionParams.fromJson(section.params);
    final query = params.sourceFilter;
    if (query != null) return query;

    // Default: all incomplete tasks
    return TaskQuery(
      filter: const QueryFilter(
        shared: [
          TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
        ],
      ),
    );
  }

  /// Builds a [TaskQuery] from a [SectionRef] if it represents an agenda.
  TaskQuery? buildTaskQueryFromAgendaSectionRef({
    required SectionRef section,
    required DateTime now,
  }) {
    if (section.templateId != SectionTemplateId.agenda) return null;

    final params = AgendaSectionParams.fromJson(section.params);
    final baseFilter =
        params.additionalFilter?.filter ?? const QueryFilter.matchAll();

    // Add incomplete predicate
    final withCompletion = _ensureIncomplete(baseFilter);

    // Add date field predicate based on dateField
    final dateField = switch (params.dateField) {
      AgendaDateField.deadlineDate => TaskDateField.deadlineDate,
      AgendaDateField.startDate => TaskDateField.startDate,
      AgendaDateField.scheduledFor => TaskDateField.deadlineDate,
    };

    // Only include tasks that have the date field set
    final withDateFilter = withCompletion.copyWith(
      shared: [
        ...withCompletion.shared,
        TaskDatePredicate(
          field: dateField,
          operator: DateOperator.onOrAfter,
          date: dateOnly(now).subtract(const Duration(days: 365)), // Past year
        ),
      ],
    );

    return TaskQuery(filter: withDateFilter);
  }
}
