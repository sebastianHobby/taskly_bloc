import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/models/analytics/analytics_insight.dart';
import 'package:taskly_bloc/domain/models/analytics/correlation_result.dart';
import 'package:taskly_bloc/domain/models/analytics/date_range.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/wellbeing/daily_tracker_response.dart';
import 'package:taskly_bloc/domain/models/wellbeing/journal_entry.dart';
import 'package:taskly_bloc/domain/models/wellbeing/mood_rating.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker_response.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker_response_config.dart';

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
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    bool seriesEnded = false,
    List<Label>? labels,
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
      repeatIcalRrule: repeatIcalRrule,
      repeatFromCompletion: repeatFromCompletion,
      seriesEnded: seriesEnded,
      labels: labels ?? [],
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
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    bool seriesEnded = false,
    List<Label>? labels,
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
      repeatIcalRrule: repeatIcalRrule,
      repeatFromCompletion: repeatFromCompletion,
      seriesEnded: seriesEnded,
      labels: labels ?? [],
      occurrence: occurrence,
    );
  }

  static Label label({
    String? id,
    String name = 'Test Label',
    LabelType type = LabelType.label,
    String? color,
    String? iconName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return Label(
      id: id ?? _nextId('label'),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      name: name,
      type: type,
      color: color,
      iconName: iconName,
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

  /// Returns a default LabelType for fallback registration
  static LabelType labelType() => LabelType.label;

  // === Screens ===

  /// Creates a screen definition for testing
  static ScreenDefinition screenDefinition({
    String? id,
    String? userId,
    String? screenId,
    String name = 'Test Screen',
    EntitySelector? selector,
    DisplayConfig? display,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final now = DateTime.now();
    return ScreenDefinition.collection(
      id: id ?? _nextId('screen'),
      userId: userId ?? 'user-1',
      screenId: screenId ?? 'screen-id-1',
      name: name,
      selector: selector ?? const EntitySelector(entityType: EntityType.task),
      display: display ?? const DisplayConfig(),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
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

  static Label sampleLabel() => label(
    id: 'sample-label-1',
    name: 'Sample Label',
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

  /// Creates multiple labels with sequential IDs
  static List<Label> labels(int count) {
    return List.generate(
      count,
      (i) => label(id: 'label-$i', name: 'Label $i'),
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

  /// Creates a task with project and labels
  static Task taskWithRelations({
    String? id,
    String name = 'Task with Relations',
    String? projectId,
    List<Label>? labels,
  }) {
    return task(
      id: id,
      name: name,
      projectId: projectId ?? 'project-1',
      labels: labels ?? [label(name: 'Label 1'), label(name: 'Label 2')],
    );
  }

  /// Creates a project with labels
  static Project projectWithLabels({
    String? id,
    String name = 'Project with Labels',
    List<Label>? labels,
  }) {
    return project(
      id: id,
      name: name,
      labels: labels ?? [label(name: 'Label 1'), label(name: 'Label 2')],
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

  /// Creates an urgent label
  static Label urgentLabel() {
    return label(
      id: 'urgent',
      name: 'Urgent',
      color: '#FF0000',
    );
  }

  /// Creates a high priority label
  static Label highPriorityLabel() {
    return label(
      id: 'high-priority',
      name: 'High Priority',
      color: '#FF9900',
    );
  }

  /// Creates a work label
  static Label workLabel() {
    return label(
      id: 'work',
      name: 'Work',
      color: '#0066CC',
    );
  }

  /// Creates a personal label
  static Label personalLabel() {
    return label(
      id: 'personal',
      name: 'Personal',
      color: '#00CC66',
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
