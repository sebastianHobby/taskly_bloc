import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';
import 'package:taskly_bloc/domain/models/analytics/analytics_insight.dart';
import 'package:taskly_bloc/domain/models/analytics/correlation_result.dart';
import 'package:taskly_bloc/domain/models/analytics/date_range.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart'
    as display;
import 'package:taskly_bloc/domain/models/screens/screen_chrome.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/screen_source.dart';
import 'package:taskly_bloc/domain/models/screens/section_ref.dart';
import 'package:taskly_bloc/domain/models/screens/section_template_id.dart';
import 'package:taskly_bloc/domain/models/screens/templates/data_list_section_params.dart';
import 'package:taskly_bloc/domain/models/screens/templates/screen_item_tile_variants.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/wellbeing/daily_tracker_response.dart';
import 'package:taskly_bloc/domain/models/wellbeing/journal_entry.dart';
import 'package:taskly_bloc/domain/models/wellbeing/mood_rating.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker_response.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker_response_config.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_definition.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step_state.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart' as predicates;
import 'package:taskly_bloc/domain/queries/task_query.dart';

/// Test data builders using the Object Mother pattern.
///
/// Provides factory methods for creating domain objects with sensible defaults
/// and optional overrides. This centralizes test data creation and makes tests
/// more maintainable when domain models change.
///
/// Usage:
/// ```dart
/// // Simple usage with defaults
/// final task = TestData.task();
///
/// // Override specific properties
/// final completedTask = TestData.task(
///   name: 'My Task',
///   completed: true,
///   deadlineDate: DateTime(2025, 12, 31),
/// );
///
/// // Complex objects
/// final project = TestData.project(
///   name: 'My Project',
///   labels: [TestData.label(name: 'Urgent')],
/// );
/// ```
///
/// Benefits:
/// - Reduces test boilerplate
/// - Provides consistent test data
/// - Single place to update when models change
/// - Makes test intent clear through named parameters
class TestData {
  static int _counter = 0;

  static String _nextId(String prefix) => '$prefix-${_counter++}';

  // === Core Domain ===

  static Task task({
    String? id,
    String name = 'Test Task',
    bool completed = false,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    Project? project,
    int? priority,
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    bool seriesEnded = false,
    List<Value>? values,
    OccurrenceData? occurrence,
  }) {
    final now = DateTime.now();
    return Task(
      id: id ?? _nextId('task'),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      name: name,
      completed: completed,
      description: description,
      startDate: startDate,
      deadlineDate: deadlineDate,
      projectId: projectId,
      project: project,
      priority: priority,
      repeatIcalRrule: repeatIcalRrule,
      repeatFromCompletion: repeatFromCompletion,
      seriesEnded: seriesEnded,
      values: values ?? [],
      occurrence: occurrence,
    );
  }

  static Project project({
    String? id,
    String name = 'Test Project',
    bool completed = false,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startDate,
    DateTime? deadlineDate,
    int? priority,
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    bool seriesEnded = false,
    List<Value>? values,
    OccurrenceData? occurrence,
  }) {
    final now = DateTime.now();
    return Project(
      id: id ?? _nextId('project'),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      name: name,
      completed: completed,
      description: description,
      startDate: startDate,
      deadlineDate: deadlineDate,
      priority: priority,
      repeatIcalRrule: repeatIcalRrule,
      repeatFromCompletion: repeatFromCompletion,
      seriesEnded: seriesEnded,
      values: values ?? [],
      occurrence: occurrence,
    );
  }

  static Value value({
    String? id,
    String name = 'Test Value',
    String? color,
    String? iconName,
    ValuePriority priority = ValuePriority.medium,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastReviewedAt,
  }) {
    final now = DateTime.now();
    return Value(
      id: id ?? _nextId('value'),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      name: name,
      color: color,
      iconName: iconName,
      priority: priority,
      lastReviewedAt: lastReviewedAt,
    );
  }

  // === Occurrence Data ===

  static OccurrenceData occurrenceData({
    DateTime? date,
    DateTime? deadline,
    DateTime? originalDate,
    bool isRescheduled = false,
    String? completionId,
    DateTime? completedAt,
    String? completionNotes,
  }) {
    return OccurrenceData(
      date: date ?? DateTime.now(),
      deadline: deadline,
      originalDate: originalDate,
      isRescheduled: isRescheduled,
      completionId: completionId,
      completedAt: completedAt,
      completionNotes: completionNotes,
    );
  }

  // === Analytics ===

  static CorrelationResult correlation({
    String sourceLabel = 'Source',
    String targetLabel = 'Target',
    String? sourceId,
    String? targetId,
    double coefficient = 0.75,
    CorrelationStrength strength = CorrelationStrength.strongPositive,
    double? valueWithSource,
    double? valueWithoutSource,
    double? differencePercent,
    StatisticalSignificance? statisticalSignificance,
    PerformanceMetrics? performanceMetrics,
  }) {
    return CorrelationResult(
      sourceLabel: sourceLabel,
      targetLabel: targetLabel,
      sourceId: sourceId,
      targetId: targetId,
      coefficient: coefficient,
      strength: strength,
      valueWithSource: valueWithSource,
      valueWithoutSource: valueWithoutSource,
      differencePercent: differencePercent,
      statisticalSignificance: statisticalSignificance,
      performanceMetrics: performanceMetrics,
    );
  }

  static StatisticalSignificance statisticalSignificance({
    double pValue = 0.01,
    double tStatistic = 3.5,
    int degreesOfFreedom = 18,
    double standardError = 0.05,
    bool isSignificant = true,
    List<double> confidenceInterval = const [0.65, 0.85],
  }) {
    return StatisticalSignificance(
      pValue: pValue,
      tStatistic: tStatistic,
      degreesOfFreedom: degreesOfFreedom,
      standardError: standardError,
      isSignificant: isSignificant,
      confidenceInterval: confidenceInterval,
    );
  }

  static PerformanceMetrics performanceMetrics({
    int calculationTimeMs = 15,
    int dataPoints = 20,
    String algorithm = 'pearson_simd',
    int? memoryUsedBytes,
  }) {
    return PerformanceMetrics(
      calculationTimeMs: calculationTimeMs,
      dataPoints: dataPoints,
      algorithm: algorithm,
      memoryUsedBytes: memoryUsedBytes,
    );
  }

  static AnalyticsInsight insight({
    String? id,
    InsightType insightType = InsightType.correlationDiscovery,
    String title = 'Test Insight',
    String description = 'Test insight description',
    DateTime? generatedAt,
    DateTime? periodStart,
    DateTime? periodEnd,
    Map<String, dynamic> metadata = const {},
    double? score,
    double? confidence,
    bool isPositive = true,
  }) {
    final now = DateTime.now();
    return AnalyticsInsight(
      id: id ?? _nextId('insight'),
      insightType: insightType,
      title: title,
      description: description,
      generatedAt: generatedAt ?? now,
      periodStart: periodStart ?? now.subtract(const Duration(days: 7)),
      periodEnd: periodEnd ?? now,
      metadata: metadata,
      score: score,
      confidence: confidence,
      isPositive: isPositive,
    );
  }

  static DateRange dateRange({
    DateTime? start,
    DateTime? end,
  }) {
    final now = DateTime.now();
    return DateRange(
      start: start ?? now.subtract(const Duration(days: 7)),
      end: end ?? now,
    );
  }

  // === Wellbeing ===

  static JournalEntry journalEntry({
    String? id,
    DateTime? entryDate,
    DateTime? entryTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    MoodRating? moodRating,
    String? journalText,
    List<TrackerResponse>? trackerResponses,
  }) {
    final now = DateTime.now();
    return JournalEntry(
      id: id ?? _nextId('journal'),
      entryDate: entryDate ?? now,
      entryTime: entryTime ?? now,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      moodRating: moodRating,
      journalText: journalText,
      perEntryTrackerResponses: trackerResponses ?? [],
    );
  }

  static Tracker tracker({
    String? id,
    String name = 'Test Tracker',
    TrackerResponseType responseType = TrackerResponseType.scale,
    TrackerResponseConfig? config,
    TrackerEntryScope entryScope = TrackerEntryScope.allDay,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    int sortOrder = 0,
  }) {
    final now = DateTime.now();
    return Tracker(
      id: id ?? _nextId('tracker'),
      name: name,
      responseType: responseType,
      config: config ?? const TrackerResponseConfig.scale(),
      entryScope: entryScope,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      description: description,
      sortOrder: sortOrder,
    );
  }

  static TrackerResponse trackerResponse({
    String? id,
    String? journalEntryId,
    String? trackerId,
    TrackerResponseValue? value,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return TrackerResponse(
      id: id ?? _nextId('response'),
      journalEntryId: journalEntryId ?? 'journal-1',
      trackerId: trackerId ?? 'tracker-1',
      value: value ?? const TrackerResponseValue.scale(value: 5),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  static DailyTrackerResponse dailyTrackerResponse({
    String? id,
    DateTime? responseDate,
    String? trackerId,
    TrackerResponseValue? value,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return DailyTrackerResponse(
      id: id ?? _nextId('daily-response'),
      responseDate: responseDate ?? DateTime(now.year, now.month, now.day),
      trackerId: trackerId ?? 'tracker-1',
      value: value ?? const TrackerResponseValue.yesNo(value: true),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  /// Reset the counter (useful between test groups)
  static void resetCounter() {
    _counter = 0;
  }

  // === Enums and Simple Types ===

  // === Workflows ===

  /// Creates a workflow definition for testing
  static WorkflowDefinition workflowDefinition({
    String? id,
    String name = 'Test Workflow',
    List<WorkflowStep>? steps,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastCompletedAt,
    String? description,
    String? iconName,
    bool isSystem = false,
    bool isActive = true,
  }) {
    final now = DateTime.now();
    return WorkflowDefinition(
      id: id ?? _nextId('workflow-def'),
      name: name,
      steps: steps ?? [workflowStep()],
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      lastCompletedAt: lastCompletedAt,
      description: description,
      iconName: iconName,
      isSystem: isSystem,
      isActive: isActive,
    );
  }

  /// Creates a workflow step for testing
  static WorkflowStep workflowStep({
    String? id,
    String name = 'Test Step',
    int order = 0,
    List<SectionRef>? sections,
    String? description,
  }) {
    return WorkflowStep(
      id: id ?? _nextId('workflow-step'),
      name: name,
      order: order,
      sections:
          sections ??
          [
            SectionRef(
              templateId: SectionTemplateId.taskList,
              params: DataListSectionParams(
                config: DataConfig.task(query: TaskQuery.all()),
                taskTileVariant: TaskTileVariant.listTile,
                projectTileVariant: ProjectTileVariant.listTile,
                valueTileVariant: ValueTileVariant.compactCard,
                display: const display.DisplayConfig(),
              ).toJson(),
              overrides: const SectionOverrides(title: 'Test Section'),
            ),
          ],
      description: description,
    );
  }

  /// Creates a workflow (runtime instance) for testing
  static Workflow workflow({
    String? id,
    String? workflowDefinitionId,
    WorkflowStatus status = WorkflowStatus.inProgress,
    List<WorkflowStepState>? stepStates,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    int currentStepIndex = 0,
  }) {
    final now = DateTime.now();
    return Workflow(
      id: id ?? _nextId('workflow'),
      workflowDefinitionId: workflowDefinitionId ?? 'workflow-def-1',
      status: status,
      stepStates: stepStates ?? [workflowStepState()],
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      completedAt: completedAt,
      currentStepIndex: currentStepIndex,
    );
  }

  /// Creates a workflow step state for testing
  static WorkflowStepState workflowStepState({
    int stepIndex = 0,
    List<String> reviewedEntityIds = const [],
    List<String> skippedEntityIds = const [],
    List<String> pendingEntityIds = const [],
  }) {
    return WorkflowStepState(
      stepIndex: stepIndex,
      reviewedEntityIds: reviewedEntityIds,
      skippedEntityIds: skippedEntityIds,
      pendingEntityIds: pendingEntityIds,
    );
  }

  // === Screens ===

  /// Creates a screen definition for testing.
  ///
  /// Historically tests used a DataDrivenScreenDefinition; this now returns the
  /// unified [ScreenDefinition] shape.
  static ScreenDefinition screenDefinition({
    String? id,
    String? screenKey,
    String name = 'Test Screen',
    List<SectionRef>? sections,
    display.DisplayConfig? displayConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? iconName,
    ScreenSource screenSource = ScreenSource.userDefined,
  }) {
    final now = DateTime.now();
    return ScreenDefinition(
      id: id ?? _nextId('screen'),
      screenKey: screenKey ?? 'screen-key-1',
      name: name,
      sections:
          sections ??
          [
            SectionRef(
              templateId: SectionTemplateId.taskList,
              params: DataListSectionParams(
                config: DataConfig.task(query: TaskQuery.all()),
                taskTileVariant: TaskTileVariant.listTile,
                projectTileVariant: ProjectTileVariant.listTile,
                valueTileVariant: ValueTileVariant.compactCard,
                display: displayConfig ?? const display.DisplayConfig(),
              ).toJson(),
              overrides: const SectionOverrides(title: 'Test Section'),
            ),
          ],
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      chrome: ScreenChrome(iconName: iconName),
      screenSource: screenSource,
    );
  }

  /// Creates a navigation-only screen definition for testing.
  ///
  /// A navigation-only screen is represented as a [ScreenDefinition] with no
  /// sections.
  static ScreenDefinition navigationOnlyScreen({
    String? id,
    String? screenKey,
    String name = 'Test Navigation Screen',
    DateTime? createdAt,
    DateTime? updatedAt,
    String? iconName,
    ScreenSource screenSource = ScreenSource.userDefined,
  }) {
    final now = DateTime.now();
    return ScreenDefinition(
      id: id ?? _nextId('nav-screen'),
      screenKey: screenKey ?? 'nav-screen-key-1',
      name: name,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      screenSource: screenSource,
      sections: const [],
      chrome: ScreenChrome(iconName: iconName),
    );
  }

  // === Pre-built Sample Entities ===
  // These are ready-to-use entities with sensible defaults,
  // eliminating the need for inline DateTime.now() calls in tests.

  static Task sampleTask() => task(
    id: 'sample-task-1',
    name: 'Sample Task',
    createdAt: TestConstants.referenceDate,
    updatedAt: TestConstants.referenceDate,
  );

  static Project sampleProject() => project(
    id: 'sample-project-1',
    name: 'Sample Project',
    createdAt: TestConstants.referenceDate,
    updatedAt: TestConstants.referenceDate,
  );

  static Value sampleValue() => value(
    id: 'sample-value-1',
    name: 'Sample Value',
    createdAt: TestConstants.referenceDate,
    updatedAt: TestConstants.referenceDate,
  );

  // === Enhanced Factory Methods ===

  /// Creates multiple tasks with sequential IDs
  static List<Task> tasks(int count) {
    return List.generate(
      count,
      (i) => task(id: 'task-$i', name: 'Task $i'),
    );
  }

  /// Creates multiple projects with sequential IDs
  static List<Project> projects(int count) {
    return List.generate(
      count,
      (i) => project(id: 'project-$i', name: 'Project $i'),
    );
  }

  /// Creates multiple values with sequential IDs
  static List<Value> values(int count) {
    return List.generate(
      count,
      (i) => value(id: 'value-$i', name: 'Value $i'),
    );
  }

  /// Creates a completed task
  static Task completedTask({
    String? id,
    String name = 'Completed Task',
    DateTime? completedAt,
  }) {
    return task(
      id: id,
      name: name,
      completed: true,
      updatedAt: completedAt ?? DateTime.now(),
    );
  }

  /// Creates an overdue task (deadline in the past)
  static Task overdueTask({
    String? id,
    String name = 'Overdue Task',
    int daysOverdue = 1,
  }) {
    return task(
      id: id,
      name: name,
      deadlineDate: DateTime.now().subtract(Duration(days: daysOverdue)),
    );
  }

  /// Creates a recurring daily task
  static Task recurringDailyTask({
    String? id,
    String name = 'Daily Task',
  }) {
    return task(
      id: id,
      name: name,
      repeatIcalRrule: 'FREQ=DAILY',
      startDate: DateTime.now(),
    );
  }

  /// Creates a recurring weekly task
  static Task recurringWeeklyTask({
    String? id,
    String name = 'Weekly Task',
  }) {
    return task(
      id: id,
      name: name,
      repeatIcalRrule: 'FREQ=WEEKLY',
      startDate: DateTime.now(),
    );
  }

  /// Creates a task with project and values
  static Task taskWithRelations({
    String? id,
    String name = 'Task with Relations',
    String? projectId,
    List<Value>? values,
  }) {
    return task(
      id: id,
      name: name,
      projectId: projectId ?? 'project-1',
      values: values ?? [value(name: 'Value 1'), value(name: 'Value 2')],
    );
  }

  /// Creates a project with values
  static Project projectWithValues({
    String? id,
    String name = 'Project with Values',
    List<Value>? values,
  }) {
    return project(
      id: id,
      name: name,
      values: values ?? [value(name: 'Value 1'), value(name: 'Value 2')],
    );
  }

  /// Creates a task due today
  static Task taskDueToday({
    String? id,
    String name = 'Due Today',
  }) {
    return task(
      id: id,
      name: name,
      deadlineDate: DateTime.now(),
    );
  }

  /// Creates a task due tomorrow
  static Task taskDueTomorrow({
    String? id,
    String name = 'Due Tomorrow',
  }) {
    return task(
      id: id,
      name: name,
      deadlineDate: DateTime.now().add(const Duration(days: 1)),
    );
  }

  /// Creates an urgent value
  static Value urgentValue() {
    return value(
      id: 'urgent',
      name: 'Urgent',
      color: '#FF0000',
      priority: ValuePriority.high,
    );
  }

  /// Creates a high priority value
  static Value highPriorityValue() {
    return value(
      id: 'high-priority',
      name: 'High Priority',
      color: '#FF9900',
      priority: ValuePriority.high,
    );
  }

  /// Creates a work value
  static Value workValue() {
    return value(
      id: 'work',
      name: 'Work',
      color: '#0066CC',
    );
  }

  /// Creates a personal value
  static Value personalValue() {
    return value(
      id: 'personal',
      name: 'Personal',
      color: '#00CC66',
    );
  }

  // === Task Rules ===

  /// Creates a DateRule for filtering tasks by date fields.
  static DateRule dateRule({
    DateRuleField field = DateRuleField.deadlineDate,
    DateRuleOperator operator = DateRuleOperator.onOrBefore,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    RelativeComparison? relativeComparison,
    int? relativeDays,
  }) {
    return DateRule(
      field: field,
      operator: operator,
      date: date,
      startDate: startDate,
      endDate: endDate,
      relativeComparison: relativeComparison,
      relativeDays: relativeDays,
    );
  }

  /// Creates a BooleanRule for filtering tasks by boolean fields.
  static BooleanRule booleanRule({
    BooleanRuleField field = BooleanRuleField.completed,
    BooleanRuleOperator operator = BooleanRuleOperator.isFalse,
  }) {
    return BooleanRule(field: field, operator: operator);
  }

  /// Creates a ValueRule for filtering tasks by value labels.
  static ValueRule valueRule({
    ValueRuleOperator operator = ValueRuleOperator.hasAny,
    List<String> valueIds = const [],
  }) {
    return ValueRule(operator: operator, valueIds: valueIds);
  }

  /// Creates a ProjectRule for filtering tasks by project.
  static ProjectRule projectRule({
    ProjectRuleOperator operator = ProjectRuleOperator.matches,
    String? projectId,
    List<String> projectIds = const [],
  }) {
    return ProjectRule(
      operator: operator,
      projectId: projectId,
      projectIds: projectIds,
    );
  }

  /// Creates a TaskRuleSet containing multiple rules.
  static TaskRuleSet taskRuleSet({
    RuleSetOperator operator = RuleSetOperator.and,
    List<TaskRule> rules = const [],
  }) {
    return TaskRuleSet(operator: operator, rules: rules);
  }

  /// Creates an EvaluationContext for rule evaluation.
  static EvaluationContext evaluationContext({DateTime? today}) {
    return EvaluationContext(today: today ?? DateTime(2025, 6, 15));
  }

  // === Settings ===

  /// Creates AllocationConfig for allocation strategy configuration.
  static AllocationConfig allocationConfig({
    int dailyLimit = 10,
    AllocationPersona persona = AllocationPersona.realist,
    StrategySettings strategySettings = const StrategySettings(),
    DisplaySettings displaySettings = const DisplaySettings(),
  }) {
    return AllocationConfig(
      dailyLimit: dailyLimit,
      persona: persona,
      strategySettings: strategySettings,
      displaySettings: displaySettings,
    );
  }

  /// Creates NextActionsSettings for next actions configuration.
  static NextActionsSettings nextActionsSettings({
    int tasksPerProject = 2,
    bool includeInboxTasks = true,
    bool excludeFutureStartDates = true,
    SortPreferences sortPreferences = const SortPreferences(),
  }) {
    return NextActionsSettings(
      tasksPerProject: tasksPerProject,
      includeInboxTasks: includeInboxTasks,
      excludeFutureStartDates: excludeFutureStartDates,
      sortPreferences: sortPreferences,
    );
  }

  /// Creates AppSettings with optional overrides.
  static AppSettings appSettings({
    GlobalSettings global = const GlobalSettings(),
    Map<String, SortPreferences> pageSortPreferences = const {},
    Map<String, PageDisplaySettings> pageDisplaySettings = const {},
    AllocationConfig allocation = const AllocationConfig(),
    SoftGatesSettings? softGates,
    NextActionsSettings? nextActions,
  }) {
    return AppSettings(
      global: global,
      pageSortPreferences: pageSortPreferences,
      pageDisplaySettings: pageDisplaySettings,
      allocation: allocation,
      softGates: softGates,
      nextActions: nextActions,
    );
  }

  // === Query Predicates ===

  /// Creates a TaskBoolPredicate for boolean field filtering.
  static predicates.TaskBoolPredicate taskBoolPredicate({
    predicates.TaskBoolField field = predicates.TaskBoolField.completed,
    predicates.BoolOperator operator = predicates.BoolOperator.isFalse,
  }) {
    return predicates.TaskBoolPredicate(field: field, operator: operator);
  }

  /// Creates a TaskDatePredicate for date field filtering.
  static predicates.TaskDatePredicate taskDatePredicate({
    predicates.TaskDateField field = predicates.TaskDateField.deadlineDate,
    predicates.DateOperator operator = predicates.DateOperator.isNotNull,
    DateTime? date,
    DateTime? startDate,
    DateTime? endDate,
    predicates.RelativeComparison? relativeComparison,
    int? relativeDays,
  }) {
    return predicates.TaskDatePredicate(
      field: field,
      operator: operator,
      date: date,
      startDate: startDate,
      endDate: endDate,
      relativeComparison: relativeComparison,
      relativeDays: relativeDays,
    );
  }

  /// Creates a TaskProjectPredicate for project filtering.
  static predicates.TaskProjectPredicate taskProjectPredicate({
    predicates.ProjectOperator operator = predicates.ProjectOperator.isNull,
    String? projectId,
    List<String> projectIds = const [],
  }) {
    return predicates.TaskProjectPredicate(
      operator: operator,
      projectId: projectId,
      projectIds: projectIds,
    );
  }

  /// Creates a TaskValuePredicate for value filtering.
  static predicates.TaskValuePredicate taskValuePredicate({
    predicates.ValueOperator operator = predicates.ValueOperator.hasAny,
    List<String> valueIds = const [],
    bool includeInherited = false,
  }) {
    return predicates.TaskValuePredicate(
      operator: operator,
      valueIds: valueIds,
      includeInherited: includeInherited,
    );
  }
}

/// Centralized test constants to avoid magic values across tests.
class TestConstants {
  /// Reference date for consistent test data (2025-01-15 12:00)
  static final referenceDate = DateTime(2025, 1, 15, 12);

  /// Standard wait duration for async operations in tests
  static const defaultWait = Duration(milliseconds: 100);

  /// Reference date for filter tests
  static final filterReferenceDate = DateTime(2024, 6, 15);
}
