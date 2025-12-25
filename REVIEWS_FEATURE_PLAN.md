# Reviews Feature Plan

**Created:** December 25, 2025  
**Status:** Planning  
**Estimated Effort:** 3-4 days

---

## Overview

Reviews are **recurring saved queries** that surface parent entities (projects, labels, values) for periodic review. Tasks are never directly reviewed—they appear as linked children when reviewing their parent entity.

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Tasks cannot have their own reviews | Only projects, labels, values can be reviewed; tasks appear as children |
| Queries select parent entities | Linked tasks displayed within entity review page |
| Per-entity completion tracking | Occurrence auto-completes when all entities reviewed |
| Review actions are extensible | Strategy pattern allows easy addition of new actions |
| Occurrence expansion configurable | Per-review setting for how many days to expand recurring tasks |

---

## Database Schema

### Reviews Table

```sql
CREATE TABLE reviews (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  name TEXT NOT NULL,
  description TEXT,
  review_type TEXT NOT NULL,           -- 'project_health', 'label_review', 'value_review', 'stale_tasks', 'custom'
  query_entity_type TEXT NOT NULL,     -- 'project', 'label', 'value'
  query_rules_json TEXT NOT NULL,      -- Serialized entity filter rules
  enabled_actions_json TEXT NOT NULL,  -- List of enabled ReviewAction identifiers
  occurrence_expansion_days INTEGER,   -- Days to expand task occurrences (null = no expansion)
  repeat_ical_rrule TEXT,
  repeat_from_completion INTEGER DEFAULT 1,
  series_ended INTEGER DEFAULT 0,
  start_date INTEGER,                  -- Unix timestamp
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

### Review Completion History

```sql
CREATE TABLE review_completion_history (
  id TEXT PRIMARY KEY,
  review_id TEXT NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  user_id TEXT,
  occurrence_date INTEGER NOT NULL,
  original_occurrence_date INTEGER,
  completed_at INTEGER NOT NULL,
  notes TEXT,
  created_at INTEGER NOT NULL
);
```

### Review Entity History (Per-Entity Tracking)

```sql
CREATE TABLE review_entity_history (
  id TEXT PRIMARY KEY,
  review_id TEXT NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  user_id TEXT,
  entity_type TEXT NOT NULL,           -- 'project', 'label', 'value'
  entity_id TEXT NOT NULL,
  review_occurrence_date INTEGER NOT NULL,
  reviewed_at INTEGER NOT NULL,
  notes TEXT,
  created_at INTEGER NOT NULL
);

CREATE INDEX idx_review_entity_history_lookup 
  ON review_entity_history(review_id, review_occurrence_date);
CREATE UNIQUE INDEX idx_review_entity_unique 
  ON review_entity_history(review_id, entity_type, entity_id, review_occurrence_date);
```

### Review Recurrence Exceptions

```sql
CREATE TABLE review_recurrence_exceptions (
  id TEXT PRIMARY KEY,
  review_id TEXT NOT NULL REFERENCES reviews(id) ON DELETE CASCADE,
  user_id TEXT,
  original_date INTEGER NOT NULL,
  exception_type TEXT NOT NULL,        -- 'skip', 'reschedule'
  new_date INTEGER,
  created_at INTEGER NOT NULL
);
```

---

## Domain Models

### Review

**File:** `lib/domain/review.dart`

```dart
@immutable
class Review {
  final String id;
  final String name;
  final String? description;
  final ReviewType type;
  final QueryEntityType queryEntityType;
  final ReviewQuery query;
  final List<ReviewActionType> enabledActions;
  final int? occurrenceExpansionDays;  // Days to expand linked task occurrences
  final String? repeatIcalRrule;
  final bool repeatFromCompletion;
  final bool seriesEnded;
  final DateTime? startDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Populated for expanded review occurrences
  final OccurrenceData? occurrence;
  
  Review copyWith({...});
}
```

### Review Type

```dart
/// Determines overall UI layout and available actions
enum ReviewType {
  projectHealth,   // Project-focused with health metrics
  labelReview,     // Label organization and usage
  valueReview,     // Value label distribution
  staleTasks,      // Focus on stale items
  custom,          // User-defined, minimal defaults
}

extension ReviewTypeConfig on ReviewType {
  String get displayName => switch (this) {
    ReviewType.projectHealth => 'Project Health',
    ReviewType.labelReview => 'Label Review',
    ReviewType.valueReview => 'Value Review',
    ReviewType.staleTasks => 'Stale Task Review',
    ReviewType.custom => 'Custom Review',
  };
  
  Set<QueryEntityType> get allowedEntityTypes => switch (this) {
    ReviewType.projectHealth => {QueryEntityType.project},
    ReviewType.labelReview => {QueryEntityType.label},
    ReviewType.valueReview => {QueryEntityType.value},
    ReviewType.staleTasks => {QueryEntityType.project, QueryEntityType.label},
    ReviewType.custom => QueryEntityType.values.toSet(),
  };
  
  Set<ReviewActionType> get defaultActions => switch (this) {
    ReviewType.projectHealth => {
      ReviewActionType.showStaleTaskCount,
      ReviewActionType.showCompletionRate,
      ReviewActionType.showNextActionsPreview,
    },
    ReviewType.staleTasks => {
      ReviewActionType.showStaleTaskCount,
      ReviewActionType.highlightStaleTasks,
    },
    // ...
  };
}
```

### Query Entity Type

```dart
enum QueryEntityType { 
  project, 
  label, 
  value,  // Labels with type == LabelType.value
}
```

### Review Entity History

**File:** `lib/domain/review_entity_history.dart`

```dart
@immutable
class ReviewEntityHistory {
  final String id;
  final String reviewId;
  final QueryEntityType entityType;
  final String entityId;
  final DateTime reviewOccurrenceDate;
  final DateTime reviewedAt;
  final String? notes;
}
```

---

## Review Actions (Extensible)

### Action Types

**File:** `lib/domain/review_action.dart`

```dart
/// Identifier for review actions. New actions added here.
enum ReviewActionType {
  // Analysis actions (show stats)
  showStaleTaskCount,
  showCompletionRate,
  showAvgDaysToComplete,
  showNextActionsPreview,
  showTaskVelocity,
  showOverdueCount,
  
  // Highlight actions (visual emphasis)
  highlightStaleTasks,
  highlightOverdueTasks,
  
  // Interactive actions (user prompts)
  promptArchiveStale,
  promptRescheduleOverdue,
  promptSetNextAction,
  
  // Future extensibility
  // showBurndownChart,
  // promptBulkUpdate,
  // exportReport,
}

extension ReviewActionConfig on ReviewActionType {
  String get displayName => switch (this) {
    ReviewActionType.showStaleTaskCount => 'Show stale task count',
    ReviewActionType.showCompletionRate => 'Show completion rate',
    ReviewActionType.showAvgDaysToComplete => 'Show average days to complete',
    ReviewActionType.showNextActionsPreview => 'Show next actions preview',
    ReviewActionType.showTaskVelocity => 'Show task velocity',
    ReviewActionType.showOverdueCount => 'Show overdue count',
    ReviewActionType.highlightStaleTasks => 'Highlight stale tasks',
    ReviewActionType.highlightOverdueTasks => 'Highlight overdue tasks',
    ReviewActionType.promptArchiveStale => 'Prompt to archive stale',
    ReviewActionType.promptRescheduleOverdue => 'Prompt to reschedule overdue',
    ReviewActionType.promptSetNextAction => 'Prompt to set next action',
  };
  
  String get description => switch (this) {
    ReviewActionType.showStaleTaskCount => 'Display count of tasks with no activity for 14+ days',
    ReviewActionType.showCompletionRate => 'Display percentage of completed tasks',
    // ...
  };
  
  /// Which entity types this action applies to
  Set<QueryEntityType> get applicableEntityTypes => switch (this) {
    ReviewActionType.showStaleTaskCount => QueryEntityType.values.toSet(),
    ReviewActionType.showNextActionsPreview => {QueryEntityType.project},
    // ...
  };
  
  /// Category for grouping in UI
  ReviewActionCategory get category => switch (this) {
    ReviewActionType.showStaleTaskCount => ReviewActionCategory.analysis,
    ReviewActionType.showCompletionRate => ReviewActionCategory.analysis,
    ReviewActionType.showAvgDaysToComplete => ReviewActionCategory.analysis,
    ReviewActionType.showNextActionsPreview => ReviewActionCategory.analysis,
    ReviewActionType.showTaskVelocity => ReviewActionCategory.analysis,
    ReviewActionType.showOverdueCount => ReviewActionCategory.analysis,
    ReviewActionType.highlightStaleTasks => ReviewActionCategory.highlight,
    ReviewActionType.highlightOverdueTasks => ReviewActionCategory.highlight,
    ReviewActionType.promptArchiveStale => ReviewActionCategory.interactive,
    ReviewActionType.promptRescheduleOverdue => ReviewActionCategory.interactive,
    ReviewActionType.promptSetNextAction => ReviewActionCategory.interactive,
  };
}

enum ReviewActionCategory { analysis, highlight, interactive }
```

### Action Service (Strategy Pattern)

**File:** `lib/features/reviews/services/review_action_service.dart`

```dart
/// Service for computing review action results
class ReviewActionService {
  const ReviewActionService();
  
  /// Compute results for a single action
  Future<ReviewActionResult> compute({
    required ReviewActionType action,
    required dynamic entity,  // Project | Label
    required List<Task> linkedTasks,
  }) async {
    return switch (action) {
      ReviewActionType.showStaleTaskCount => _computeStaleCount(linkedTasks),
      ReviewActionType.showCompletionRate => _computeCompletionRate(linkedTasks),
      ReviewActionType.showAvgDaysToComplete => _computeAvgCompletion(linkedTasks),
      ReviewActionType.showNextActionsPreview => _computeNextActions(linkedTasks),
      ReviewActionType.showOverdueCount => _computeOverdueCount(linkedTasks),
      ReviewActionType.highlightStaleTasks => _identifyStaleTasks(linkedTasks),
      ReviewActionType.highlightOverdueTasks => _identifyOverdueTasks(linkedTasks),
      _ => ReviewActionResult.empty(action),
    };
  }
  
  /// Compute all enabled actions for an entity
  Future<Map<ReviewActionType, ReviewActionResult>> computeAll({
    required List<ReviewActionType> enabledActions,
    required dynamic entity,
    required List<Task> linkedTasks,
  }) async {
    final results = <ReviewActionType, ReviewActionResult>{};
    for (final action in enabledActions) {
      results[action] = await compute(
        action: action,
        entity: entity,
        linkedTasks: linkedTasks,
      );
    }
    return results;
  }
  
  // Private computation methods
  ReviewActionResult _computeStaleCount(List<Task> tasks) {
    const staleDays = 14;
    final cutoff = DateTime.now().subtract(const Duration(days: staleDays));
    final staleCount = tasks.where((t) => 
      !t.completed && t.updatedAt.isBefore(cutoff)
    ).length;
    
    return ReviewActionResult.stat(
      action: ReviewActionType.showStaleTaskCount,
      value: staleCount,
      label: 'Stale tasks (14+ days)',
      severity: staleCount > 5 ? Severity.warning : Severity.normal,
    );
  }
  
  ReviewActionResult _computeCompletionRate(List<Task> tasks) {
    if (tasks.isEmpty) {
      return ReviewActionResult.stat(
        action: ReviewActionType.showCompletionRate,
        value: 0,
        label: 'Completion rate',
        formattedValue: 'N/A',
      );
    }
    final completed = tasks.where((t) => t.completed).length;
    final rate = (completed / tasks.length * 100).round();
    
    return ReviewActionResult.stat(
      action: ReviewActionType.showCompletionRate,
      value: rate,
      label: 'Completion rate',
      formattedValue: '$rate%',
      severity: rate < 50 ? Severity.warning : Severity.normal,
    );
  }
  
  // ... other computation methods
}
```

### Action Results

```dart
/// Result of a review action computation
sealed class ReviewActionResult {
  final ReviewActionType action;
  
  const ReviewActionResult({required this.action});
  
  factory ReviewActionResult.stat({
    required ReviewActionType action,
    required num value,
    required String label,
    String? formattedValue,
    Severity severity = Severity.normal,
  }) = StatResult;
  
  factory ReviewActionResult.taskList({
    required ReviewActionType action,
    required List<Task> tasks,
    required String label,
  }) = TaskListResult;
  
  factory ReviewActionResult.empty(ReviewActionType action) = EmptyResult;
}

class StatResult extends ReviewActionResult {
  final num value;
  final String label;
  final String? formattedValue;
  final Severity severity;
  
  const StatResult({
    required super.action,
    required this.value,
    required this.label,
    this.formattedValue,
    this.severity = Severity.normal,
  });
}

class TaskListResult extends ReviewActionResult {
  final List<Task> tasks;
  final String label;
  
  const TaskListResult({
    required super.action,
    required this.tasks,
    required this.label,
  });
}

class EmptyResult extends ReviewActionResult {
  const EmptyResult(ReviewActionType action) : super(action: action);
}

enum Severity { normal, warning, critical }
```

---

## Review Query (Entity Selection)

### ReviewQuery

**File:** `lib/domain/queries/review_query.dart`

```dart
@immutable
class ReviewQuery {
  final QueryEntityType entityType;
  final List<EntityFilterRule> rules;
  final List<SortCriterion> sortCriteria;
  
  const ReviewQuery({
    required this.entityType,
    this.rules = const [],
    this.sortCriteria = const [],
  });
  
  // Factory methods
  factory ReviewQuery.allProjects() => ReviewQuery(
    entityType: QueryEntityType.project,
    rules: [ProjectFilterRule.active()],
  );
  
  factory ReviewQuery.allLabels() => ReviewQuery(
    entityType: QueryEntityType.label,
    rules: [],
  );
  
  factory ReviewQuery.allValues() => ReviewQuery(
    entityType: QueryEntityType.value,
    rules: [],
  );
  
  Map<String, dynamic> toJson();
  factory ReviewQuery.fromJson(Map<String, dynamic> json);
}
```

### Entity Filter Rules

**File:** `lib/domain/queries/entity_filter_rules.dart`

```dart
/// Base class for entity filtering rules
sealed class EntityFilterRule {
  bool evaluate(dynamic entity);
  Map<String, dynamic> toJson();
  
  static EntityFilterRule fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'project' => ProjectFilterRule.fromJson(json),
      'label' => LabelFilterRule.fromJson(json),
      'value' => ValueFilterRule.fromJson(json),
      _ => throw ArgumentError('Unknown rule type: $type'),
    };
  }
}

/// Rules for filtering projects
class ProjectFilterRule extends EntityFilterRule {
  final ProjectFilterField field;
  final FilterOperator operator;
  final dynamic value;
  
  ProjectFilterRule({
    required this.field,
    required this.operator,
    this.value,
  });
  
  // Convenience factories
  factory ProjectFilterRule.active() => ProjectFilterRule(
    field: ProjectFilterField.completed,
    operator: FilterOperator.equals,
    value: false,
  );
  
  factory ProjectFilterRule.completed() => ProjectFilterRule(
    field: ProjectFilterField.completed,
    operator: FilterOperator.equals,
    value: true,
  );
  
  factory ProjectFilterRule.hasLabel(String labelId) => ProjectFilterRule(
    field: ProjectFilterField.labels,
    operator: FilterOperator.contains,
    value: labelId,
  );
  
  @override
  bool evaluate(dynamic entity) {
    if (entity is! Project) return false;
    final project = entity;
    
    return switch (field) {
      ProjectFilterField.completed => _evaluateBool(project.completed),
      ProjectFilterField.name => _evaluateString(project.name),
      ProjectFilterField.startDate => _evaluateDate(project.startDate),
      ProjectFilterField.deadlineDate => _evaluateDate(project.deadlineDate),
      ProjectFilterField.createdAt => _evaluateDate(project.createdAt),
      ProjectFilterField.labels => _evaluateLabels(project.labels),
    };
  }
  
  // ... evaluation helpers
  
  @override
  Map<String, dynamic> toJson() => {
    'type': 'project',
    'field': field.name,
    'operator': operator.name,
    'value': value,
  };
  
  factory ProjectFilterRule.fromJson(Map<String, dynamic> json) => ProjectFilterRule(
    field: ProjectFilterField.values.byName(json['field'] as String),
    operator: FilterOperator.values.byName(json['operator'] as String),
    value: json['value'],
  );
}

enum ProjectFilterField { completed, name, startDate, deadlineDate, createdAt, labels }

/// Rules for filtering labels
class LabelFilterRule extends EntityFilterRule {
  final LabelFilterField field;
  final FilterOperator operator;
  final dynamic value;
  
  LabelFilterRule({
    required this.field,
    required this.operator,
    this.value,
  });
  
  @override
  bool evaluate(dynamic entity) {
    if (entity is! Label) return false;
    // Evaluation logic...
  }
  
  @override
  Map<String, dynamic> toJson() => {
    'type': 'label',
    'field': field.name,
    'operator': operator.name,
    'value': value,
  };
  
  factory LabelFilterRule.fromJson(Map<String, dynamic> json) => LabelFilterRule(
    field: LabelFilterField.values.byName(json['field'] as String),
    operator: FilterOperator.values.byName(json['operator'] as String),
    value: json['value'],
  );
}

enum LabelFilterField { name, type, createdAt }

/// Rules for filtering values (labels with type == value)
class ValueFilterRule extends EntityFilterRule {
  final LabelFilterField field;
  final FilterOperator operator;
  final dynamic value;
  
  // Similar to LabelFilterRule but constrained to value type
  
  @override
  bool evaluate(dynamic entity) {
    if (entity is! Label || entity.type != LabelType.value) return false;
    // Evaluation logic...
  }
}

/// Shared operators
enum FilterOperator {
  equals,
  notEquals,
  contains,
  isNull,
  isNotNull,
  onOrBefore,
  onOrAfter,
  between,
}
```

---

## Repository Contract

**File:** `lib/domain/contracts/review_repository_contract.dart`

```dart
abstract class ReviewRepositoryContract {
  // CRUD
  Stream<List<Review>> watchAll();
  Stream<Review?> watchById(String id);
  Future<Review?> getById(String id);
  
  Future<void> create({
    required String name,
    String? description,
    required ReviewType type,
    required QueryEntityType queryEntityType,
    required List<EntityFilterRule> queryRules,
    required List<ReviewActionType> enabledActions,
    int? occurrenceExpansionDays,
    String? repeatIcalRrule,
    bool repeatFromCompletion = true,
    DateTime? startDate,
  });
  
  Future<void> update({
    required String id,
    required String name,
    String? description,
    required ReviewType type,
    required QueryEntityType queryEntityType,
    required List<EntityFilterRule> queryRules,
    required List<ReviewActionType> enabledActions,
    int? occurrenceExpansionDays,
    String? repeatIcalRrule,
    bool repeatFromCompletion,
    DateTime? startDate,
  });
  
  Future<void> delete(String id);
  
  // Occurrences
  Stream<List<Review>> watchOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  });
  
  Future<void> completeOccurrence({
    required String reviewId,
    required DateTime occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
  });
  
  Future<void> skipOccurrence({
    required String reviewId,
    required DateTime occurrenceDate,
  });
  
  Future<void> rescheduleOccurrence({
    required String reviewId,
    required DateTime originalDate,
    required DateTime newDate,
  });
  
  // Per-entity tracking
  Future<void> markEntityReviewed({
    required String reviewId,
    required QueryEntityType entityType,
    required String entityId,
    required DateTime occurrenceDate,
    String? notes,
  });
  
  /// Entity IDs reviewed for a specific occurrence
  Stream<Set<String>> watchReviewedEntityIds({
    required String reviewId,
    required DateTime occurrenceDate,
  });
  
  /// Last reviewed dates across all occurrences (for "last reviewed X days ago")
  Stream<Map<String, DateTime>> watchEntityLastReviewedDates({
    required String reviewId,
    required List<String> entityIds,
  });
  
  /// Check if occurrence should auto-complete
  Future<bool> checkOccurrenceComplete({
    required String reviewId,
    required DateTime occurrenceDate,
    required int totalEntityCount,
  });
}
```

---

## BLoC Architecture

### Review List BLoC

```dart
// Events
sealed class ReviewListEvent {
  const ReviewListEvent();
}
class ReviewListSubscriptionRequested extends ReviewListEvent {}
class ReviewListViewModeToggled extends ReviewListEvent {
  final ReviewViewMode mode;
  const ReviewListViewModeToggled(this.mode);
}
class ReviewListDateRangeChanged extends ReviewListEvent {
  final DateTime start;
  final DateTime end;
  const ReviewListDateRangeChanged(this.start, this.end);
}

enum ReviewViewMode { list, agenda }

// State
@freezed
class ReviewListState with _$ReviewListState {
  const factory ReviewListState.initial() = _Initial;
  const factory ReviewListState.loading() = _Loading;
  const factory ReviewListState.loaded({
    required List<Review> reviews,
    required ReviewViewMode viewMode,
    DateTime? agendaStart,
    DateTime? agendaEnd,
  }) = _Loaded;
  const factory ReviewListState.error({required Object error}) = _Error;
}
```

### Review Detail BLoC

```dart
// Events
sealed class ReviewDetailEvent {
  const ReviewDetailEvent();
}
class ReviewDetailSubscriptionRequested extends ReviewDetailEvent {
  final String reviewId;
  final DateTime occurrenceDate;
  const ReviewDetailSubscriptionRequested(this.reviewId, this.occurrenceDate);
}
class ReviewDetailEntitySelected extends ReviewDetailEvent {
  final String entityId;
  const ReviewDetailEntitySelected(this.entityId);
}

// State
@freezed
class ReviewDetailState with _$ReviewDetailState {
  const factory ReviewDetailState.initial() = _Initial;
  const factory ReviewDetailState.loading() = _Loading;
  const factory ReviewDetailState.loaded({
    required Review review,
    required DateTime occurrenceDate,
    required List<dynamic> entities,  // Project | Label
    required Set<String> reviewedEntityIds,
    required Map<String, DateTime> lastReviewedDates,
    required int totalCount,
    required int reviewedCount,
  }) = _Loaded;
  const factory ReviewDetailState.error({required Object error}) = _Error;
}
```

### Entity Review BLoC

```dart
// Events
sealed class EntityReviewEvent {
  const EntityReviewEvent();
}
class EntityReviewSubscriptionRequested extends EntityReviewEvent {
  final String reviewId;
  final String entityId;
  final QueryEntityType entityType;
  final DateTime occurrenceDate;
  const EntityReviewSubscriptionRequested({
    required this.reviewId,
    required this.entityId,
    required this.entityType,
    required this.occurrenceDate,
  });
}
class EntityReviewMarkReviewed extends EntityReviewEvent {
  final String? notes;
  const EntityReviewMarkReviewed({this.notes});
}

// State
@freezed
class EntityReviewState with _$EntityReviewState {
  const factory EntityReviewState.initial() = _Initial;
  const factory EntityReviewState.loading() = _Loading;
  const factory EntityReviewState.loaded({
    required String reviewId,
    required DateTime occurrenceDate,
    required dynamic entity,  // Project | Label
    required List<Task> linkedTasks,
    required Map<ReviewActionType, ReviewActionResult> actionResults,
    required DateTime? lastReviewedAt,
    required List<ReviewActionType> enabledActions,
  }) = _Loaded;
  const factory EntityReviewState.reviewed() = _Reviewed;
  const factory EntityReviewState.error({required Object error}) = _Error;
}
```

---

## UI Structure

```
lib/features/reviews/
├── bloc/
│   ├── review_list_bloc.dart
│   ├── review_list_bloc.freezed.dart
│   ├── review_detail_bloc.dart
│   ├── review_detail_bloc.freezed.dart
│   ├── entity_review_bloc.dart
│   ├── entity_review_bloc.freezed.dart
│   ├── review_form_bloc.dart
│   └── review_form_bloc.freezed.dart
├── view/
│   ├── reviews_page.dart              -- List/agenda with toggle
│   ├── review_detail_page.dart        -- Entity list + progress
│   ├── entity_review_page.dart        -- Single entity + tasks + actions
│   └── review_form_page.dart          -- Create/edit with type/query/actions
├── widgets/
│   ├── review_list_item.dart
│   ├── review_agenda_view.dart
│   ├── review_progress_indicator.dart
│   ├── entity_review_card.dart
│   ├── review_action_result_card.dart -- Displays action results
│   ├── review_type_selector.dart
│   ├── review_action_picker.dart      -- Multi-select enabled actions
│   └── entity_query_builder.dart      -- Build entity filter rules
└── services/
    └── review_action_service.dart
```

---

## UI Flow

```
┌─────────────────────────────────────────────────────────────────┐
│ ReviewsPage                                                      │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ [List] [Agenda]                                    [+ New]  │ │
│ ├─────────────────────────────────────────────────────────────┤ │
│ │ ┌─────────────────────────────────────────────────────────┐ │ │
│ │ │ 📋 Weekly Project Health                                │ │ │
│ │ │    Next: Dec 28 • 5 projects                            │ │ │
│ │ └─────────────────────────────────────────────────────────┘ │ │
│ │ ┌─────────────────────────────────────────────────────────┐ │ │
│ │ │ 🏷️ Monthly Label Review                                 │ │ │
│ │ │    Next: Jan 1 • 12 labels                              │ │ │
│ │ └─────────────────────────────────────────────────────────┘ │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (tap)
┌─────────────────────────────────────────────────────────────────┐
│ ReviewDetailPage                                                 │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Weekly Project Health                                       │ │
│ │ Due: Dec 28, 2025                                          │ │
│ │ ████████░░░░░░░░ 3/5 reviewed                              │ │
│ ├─────────────────────────────────────────────────────────────┤ │
│ │ ✅ Project Alpha          reviewed 2h ago                  │ │
│ │ ✅ Project Beta           reviewed 1h ago                  │ │
│ │ ✅ Project Gamma          reviewed 30m ago                 │ │
│ │ ☐  Project Delta          last: 7 days ago                 │ │
│ │ ☐  Project Epsilon        never reviewed                   │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (tap Delta)
┌─────────────────────────────────────────────────────────────────┐
│ EntityReviewPage                                                 │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ 📁 Project Delta                                           │ │
│ │ Status: Active • 23 tasks                                  │ │
│ ├─────────────────────────────────────────────────────────────┤ │
│ │ Review Insights (from enabled actions)                     │ │
│ │ ┌───────────────┐ ┌───────────────┐ ┌───────────────┐     │ │
│ │ │ ⚠️ 5 stale    │ │ 68% complete │ │ 2 overdue     │     │ │
│ │ │   tasks       │ │              │ │               │     │ │
│ │ └───────────────┘ └───────────────┘ └───────────────┘     │ │
│ ├─────────────────────────────────────────────────────────────┤ │
│ │ Linked Tasks (expanded if configured)                      │ │
│ │ ┌─────────────────────────────────────────────────────────┐ │ │
│ │ │ ⚠️ Task 1 - stale 21 days                              │ │ │
│ │ │ ⚠️ Task 2 - stale 18 days                              │ │ │
│ │ │    Task 3 - Due tomorrow                                │ │ │
│ │ │    Task 4 - No deadline                                 │ │ │
│ │ │    ...                                                  │ │ │
│ │ └─────────────────────────────────────────────────────────┘ │ │
│ ├─────────────────────────────────────────────────────────────┤ │
│ │              [✓ Mark as Reviewed]                          │ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (Mark as Reviewed)
                    Returns to ReviewDetailPage
                    Progress: 4/5
                              │
                              ▼ (review last entity)
                    Auto-completes occurrence
                    Shows completion confirmation
```

---

## Review Form

```
┌─────────────────────────────────────────────────────────────────┐
│ Create Review                                                    │
├─────────────────────────────────────────────────────────────────┤
│ Name: [Weekly Project Health____________]                       │
│                                                                  │
│ Description (optional):                                          │
│ [Review active projects for stale tasks_]                       │
│                                                                  │
│ Review Type:                                                     │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ ● Project Health                                            │ │
│ │ ○ Label Review                                              │ │
│ │ ○ Value Review                                              │ │
│ │ ○ Stale Tasks                                               │ │
│ │ ○ Custom                                                    │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│ Query: Select Projects                                           │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ + Add filter rule                                           │ │
│ │ • Completed = false                                ❌       │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│ Enabled Actions:                                                 │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Analysis                                                    │ │
│ │   ☑ Show stale task count                                  │ │
│ │   ☑ Show completion rate                                   │ │
│ │   ☐ Show avg days to complete                              │ │
│ │   ☑ Show next actions preview                              │ │
│ │ Highlights                                                  │ │
│ │   ☑ Highlight stale tasks                                  │ │
│ │   ☐ Highlight overdue tasks                                │ │
│ │ Interactive                                                 │ │
│ │   ☐ Prompt to archive stale                                │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│ Task Occurrence Expansion: [7 days ▼]                           │
│                                                                  │
│ Schedule:                                                        │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ Start date: [Dec 28, 2025]                                  │ │
│ │ Repeat: [Weekly on Sunday ▼]                                │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                  │
│              [Cancel]              [Create Review]              │
└─────────────────────────────────────────────────────────────────┘
```

---

## Files to Create

```
lib/domain/
├── review.dart                            # Review, ReviewType, QueryEntityType
├── review_action.dart                     # ReviewActionType, ReviewActionConfig, ReviewActionResult
├── review_entity_history.dart             # ReviewEntityHistory
├── queries/
│   ├── review_query.dart                  # ReviewQuery
│   └── entity_filter_rules.dart           # EntityFilterRule, ProjectFilterRule, etc.
└── contracts/
    └── review_repository_contract.dart

lib/data/
├── drift/
│   └── drift_database.dart                # Add new tables
├── repositories/
│   └── review_repository.dart
└── mappers/
    └── review_mappers.dart

lib/features/reviews/
├── bloc/
│   ├── review_list_bloc.dart (+.freezed)
│   ├── review_detail_bloc.dart (+.freezed)
│   ├── entity_review_bloc.dart (+.freezed)
│   └── review_form_bloc.dart (+.freezed)
├── view/
│   ├── reviews_page.dart
│   ├── review_detail_page.dart
│   ├── entity_review_page.dart
│   └── review_form_page.dart
├── widgets/
│   ├── review_list_item.dart
│   ├── review_agenda_view.dart
│   ├── review_progress_indicator.dart
│   ├── entity_review_card.dart
│   ├── review_action_result_card.dart
│   ├── review_type_selector.dart
│   ├── review_action_picker.dart
│   └── entity_query_builder.dart
└── services/
    └── review_action_service.dart

lib/core/dependency_injection/
└── dependency_injection.dart              # Register ReviewRepository

lib/routing/
└── router.dart                            # Add review routes
```

---

## Implementation Order

```
Phase 1: Foundation (Day 1)
├── Database tables (Drift)
├── Domain models (Review, ReviewEntityHistory, enums)
├── Entity filter rules (ProjectFilterRule, LabelFilterRule, ValueFilterRule)
└── Repository contract + implementation

Phase 2: Core BLoCs (Day 2)
├── ReviewListBloc (list + agenda)
├── ReviewDetailBloc (entity list + progress)
├── EntityReviewBloc (single entity + tasks)
└── Review action service (initial actions)

Phase 3: UI (Day 2-3)
├── ReviewsPage (list/agenda toggle)
├── ReviewDetailPage
├── EntityReviewPage
└── Supporting widgets

Phase 4: Form & Polish (Day 3-4)
├── ReviewFormBloc
├── ReviewFormPage
├── Review type selector
├── Review action picker
├── Entity query builder
└── Routing integration
```

---

## Extensibility Guide

### Adding a New Review Action

1. **Add enum value** to `ReviewActionType` in `lib/domain/review_action.dart`
2. **Add config** in `ReviewActionConfig` extension (displayName, description, applicableEntityTypes, category)
3. **Add computation** in `ReviewActionService._compute()` switch statement
4. **Add UI widget** if action has unique display requirements (optional)

### Adding a New Query Entity Type

1. **Add enum value** to `QueryEntityType` in `lib/domain/review.dart`
2. **Create** new filter rule class (e.g., `AreaFilterRule extends EntityFilterRule`)
3. **Update** `EntityFilterRule.fromJson()` to handle new type
4. **Update** `ReviewRepository` to query new entity type
5. **Update** `EntityReviewBloc` to load new entity + linked tasks
6. **Update** `ReviewTypeConfig.allowedEntityTypes` for relevant review types

### Adding a New Review Type

1. **Add enum value** to `ReviewType` in `lib/domain/review.dart`
2. **Add config** in `ReviewTypeConfig` extension (displayName, allowedEntityTypes, defaultActions)
3. **Update** UI type selector widget

---

## Completion Logic

```dart
/// In ReviewRepository or ReviewDetailBloc
Future<void> markEntityReviewed({
  required String reviewId,
  required String entityId,
  required DateTime occurrenceDate,
}) async {
  // 1. Insert/update review_entity_history
  await _insertEntityHistory(reviewId, entityId, occurrenceDate);
  
  // 2. Check if all entities in query are reviewed for this occurrence
  final queryResult = await _getEntitiesForReview(reviewId);
  final reviewedIds = await _getReviewedEntityIds(reviewId, occurrenceDate);
  
  if (reviewedIds.length >= queryResult.length &&
      reviewedIds.containsAll(queryResult.map((e) => e.id))) {
    // 3. Auto-complete the occurrence
    await completeOccurrence(reviewId: reviewId, occurrenceDate: occurrenceDate);
  }
}
```

---

## Analytics Architecture

### Current Approach: On-Demand (Tier 1-2)

Analytics are computed **on-demand** when user views entity review page (not stored). This keeps the design simple and data always fresh.

**Tier 1 - Simple Aggregations (implemented in MVP):**
- Task counts by status
- Stale task count (no activity 14+ days)
- Overdue count
- Completion rate

**Tier 2 - Time-Windowed Metrics:**
- Completed this week/month
- Average days to complete
- On-time completion rate

**Performance:** ~50-200ms per entity on modern devices, acceptable for most use cases.

---

### Future Enhancement: Hybrid Approach (Tier 3)

When users request historical trends or performance becomes an issue on lower-end devices, add server-side snapshots.

#### Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                   Hybrid Analytics Strategy                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Real-time metrics (client-side, keep as-is):                   │
│  ├── Stale task count                                           │
│  ├── Completion rate                                            │
│  ├── Overdue count                                              │
│  └── Computed on-demand when viewing review                     │
│                                                                  │
│  Trend metrics (server-side snapshots, add later):              │
│  ├── Velocity over time (tasks completed per week)              │
│  ├── Historical completion rate trend                           │
│  ├── Staleness trend (improving or degrading?)                  │
│  └── Pre-computed daily via Supabase, synced to device          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

#### Database Schema (Postgres/Supabase)

```sql
CREATE TABLE analytics_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL,        -- 'project', 'label', 'review'
  entity_id UUID NOT NULL,
  snapshot_date DATE NOT NULL,
  metrics JSONB NOT NULL,           -- Flexible metric storage
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, entity_type, entity_id, snapshot_date)
);

CREATE INDEX idx_analytics_snapshots_lookup 
  ON analytics_snapshots(user_id, entity_type, entity_id, snapshot_date DESC);
```

#### Metrics JSON Structure

```json
{
  "task_count": 15,
  "completed_count": 8,
  "stale_count": 3,
  "overdue_count": 2,
  "avg_completion_days": 4.2,
  "completed_this_week": 5,
  "on_time_rate": 0.75
}
```

#### Supabase Edge Function (Daily Cron)

```typescript
// supabase/functions/generate-analytics-snapshots/index.ts
import { createClient } from '@supabase/supabase-js';

Deno.serve(async () => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  // Generate project snapshots
  const { error } = await supabase.rpc('generate_project_snapshots');
  
  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }
  
  return new Response(JSON.stringify({ success: true }));
});
```

```sql
-- Postgres function called by Edge Function
CREATE OR REPLACE FUNCTION generate_project_snapshots()
RETURNS void AS $$
BEGIN
  INSERT INTO analytics_snapshots (user_id, entity_type, entity_id, snapshot_date, metrics)
  SELECT 
    p.user_id,
    'project',
    p.id,
    CURRENT_DATE,
    jsonb_build_object(
      'task_count', COALESCE(t.total, 0),
      'completed_count', COALESCE(t.completed, 0),
      'stale_count', COALESCE(t.stale, 0),
      'overdue_count', COALESCE(t.overdue, 0),
      'avg_completion_days', t.avg_completion_days,
      'completed_this_week', COALESCE(t.completed_week, 0)
    )
  FROM projects p
  LEFT JOIN LATERAL (
    SELECT 
      COUNT(*) as total,
      COUNT(*) FILTER (WHERE completed) as completed,
      COUNT(*) FILTER (WHERE NOT completed AND updated_at < NOW() - INTERVAL '14 days') as stale,
      COUNT(*) FILTER (WHERE NOT completed AND deadline_date < CURRENT_DATE) as overdue,
      AVG(EXTRACT(EPOCH FROM (completed_at - created_at))/86400) 
        FILTER (WHERE completed) as avg_completion_days,
      COUNT(*) FILTER (WHERE completed AND completed_at > NOW() - INTERVAL '7 days') as completed_week
    FROM tasks 
    WHERE tasks.project_id = p.id
  ) t ON true
  ON CONFLICT (user_id, entity_type, entity_id, snapshot_date) 
  DO UPDATE SET metrics = EXCLUDED.metrics;
END;
$$ LANGUAGE plpgsql;
```

#### PowerSync Sync Rules

```yaml
# Add to powersync.yaml bucket_definitions
bucket_definitions:
  user_data:
    parameters: SELECT auth.uid() AS user_id
    data:
      # ... existing tables ...
      
      - table: analytics_snapshots
        where: |
          user_id = bucket.user_id 
          AND snapshot_date >= CURRENT_DATE - INTERVAL '90 days'
```

#### Drift Table (Local)

```dart
class AnalyticsSnapshotsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().named('user_id')();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();
  DateTimeColumn get snapshotDate => dateTime().named('snapshot_date')();
  TextColumn get metricsJson => text().named('metrics')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

#### Domain Model

```dart
@immutable
class AnalyticsSnapshot {
  final String id;
  final String entityType;
  final String entityId;
  final DateTime snapshotDate;
  final AnalyticsMetrics metrics;
  
  const AnalyticsSnapshot({...});
}

@immutable
class AnalyticsMetrics {
  final int taskCount;
  final int completedCount;
  final int staleCount;
  final int overdueCount;
  final double? avgCompletionDays;
  final int completedThisWeek;
  final double? onTimeRate;
  
  factory AnalyticsMetrics.fromJson(Map<String, dynamic> json);
}
```

#### Updated ReviewActionService

```dart
class ReviewActionService {
  final AnalyticsSnapshotRepository? _snapshotRepo;
  
  /// Compute with optional trend data
  Future<ReviewActionResult> compute({
    required ReviewActionType action,
    required dynamic entity,
    required List<Task> linkedTasks,
    bool includeTrends = false,  // Enable when snapshots available
  }) async {
    final baseResult = _computeRealtime(action, linkedTasks);
    
    if (includeTrends && _snapshotRepo != null) {
      final snapshots = await _snapshotRepo!.getSnapshots(
        entityId: entity.id,
        days: 90,
      );
      return baseResult.withTrend(_computeTrend(snapshots, action));
    }
    
    return baseResult;
  }
}
```

#### Performance Comparison

| Scenario | Client-Only | With Server Snapshots |
|----------|-------------|----------------------|
| View review (simple metrics) | 50-200ms | 50-200ms (unchanged) |
| View 90-day trend chart | 2-5s (scan all history) | 50ms (read 90 rows) |
| Battery for daily use | Higher | Lower |
| Offline trend viewing | ❌ Not feasible | ✅ Works |
| Initial sync size | Unchanged | +50-100KB |

#### When to Implement

Add server-side snapshots when:
1. Users request historical trend charts
2. Performance issues on lower-end devices (>500ms for analytics)
3. Building a web dashboard
4. Dataset grows beyond ~5000 tasks per user

#### Cost Estimate (Supabase)

| Resource | Usage | Cost |
|----------|-------|------|
| Edge Function | 1 invocation/day | Free tier |
| Database compute | ~100ms/day | Negligible |
| Storage | ~1MB/100 users/year | Free tier |
| Sync bandwidth | ~100KB/user/day | Free tier |

**Verdict:** Effectively free for typical usage patterns.
