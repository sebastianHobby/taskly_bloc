import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/analytics_insight.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/correlation_result.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/date_range.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_action.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_action_type.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_query.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/entity_type.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/models/journal_entry.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/models/mood_rating.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/models/tracker.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/models/tracker_response.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/models/tracker_response_config.dart';

/// Test data builders (Object Mother pattern) for creating domain objects
/// in tests with sensible defaults and optional overrides.
///
/// Usage:
/// ```dart
/// final task = TestData.task(name: 'My Task', completed: true);
/// final correlation = TestData.correlation(coefficient: 0.85);
/// ```
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
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
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
      repeatIcalRrule: repeatIcalRrule,
      repeatFromCompletion: repeatFromCompletion,
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
    List<Label>? labels,
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
      labels: labels ?? [],
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
      trackerResponses: trackerResponses ?? [],
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

  // === Reviews ===

  static Review review({
    String? id,
    String name = 'Test Review',
    ReviewQuery? query,
    String rrule = 'FREQ=WEEKLY',
    DateTime? nextDueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    DateTime? lastCompletedAt,
    DateTime? deletedAt,
  }) {
    final now = DateTime.now();
    return Review(
      id: id ?? _nextId('review'),
      name: name,
      query:
          query ??
          const ReviewQuery(
            entityType: EntityType.task,
          ),
      rrule: rrule,
      nextDueDate: nextDueDate ?? now.add(const Duration(days: 7)),
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      description: description,
      lastCompletedAt: lastCompletedAt,
      deletedAt: deletedAt,
    );
  }

  static ReviewQuery reviewQuery({
    EntityType entityType = EntityType.task,
    List<String>? projectIds,
    List<String>? labelIds,
    List<String>? valueIds,
    bool? includeCompleted,
    DateTime? completedBefore,
    DateTime? completedAfter,
    DateTime? createdBefore,
    DateTime? createdAfter,
  }) {
    return ReviewQuery(
      entityType: entityType,
      projectIds: projectIds,
      labelIds: labelIds,
      valueIds: valueIds,
      includeCompleted: includeCompleted,
      completedBefore: completedBefore,
      completedAfter: completedAfter,
      createdBefore: createdBefore,
      createdAfter: createdAfter,
    );
  }

  static ReviewAction reviewAction({
    ReviewActionType type = ReviewActionType.skip,
    Map<String, dynamic>? updateData,
    String? notes,
  }) {
    return ReviewAction(
      type: type,
      updateData: updateData,
      notes: notes,
    );
  }

  /// Reset the counter (useful between test groups)
  static void resetCounter() {
    _counter = 0;
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
