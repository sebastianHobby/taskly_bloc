import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/models/analytics/trend_data.dart';
import 'package:taskly_bloc/domain/models/page_key.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/models/analytics/correlation_request.dart';

import '../fixtures/test_data.dart';

/// Shared fake implementations for mocktail's any() matcher.
class FakeTaskQuery extends Fake implements TaskQuery {}

/// Registers fallback values for mocktail's `any()` matcher.
///
/// Also initializes the global talker for test environments.
///
/// Call this once in your test file's `setUpAll()` to enable using `any()`
/// with domain objects without creating individual `_Fake` classes.
///
/// Usage:
/// ```dart
/// void main() {
///   setUpAll(registerAllFallbackValues);
///
///   test('example', () {
///     when(() => mockRepo.create(any())).thenAnswer((_) async {});
///   });
/// }
/// ```
void registerAllFallbackValues() {
  // Initialize talker for tests (safe to call multiple times)
  initializeTalkerForTest();
  // Register fake query type
  registerFallbackValue(FakeTaskQuery());
  // Core domain
  registerFallbackValue(TestData.task());
  registerFallbackValue(TestData.project());
  registerFallbackValue(TestData.label());
  registerFallbackValue(TestData.labelType());
  registerFallbackValue(TaskQuery.all());
  registerFallbackValue(PageKey.taskOverview);

  // Analytics
  registerFallbackValue(TestData.correlation());
  registerFallbackValue(TestData.insight());
  registerFallbackValue(TestData.dateRange());
  registerFallbackValue(TrendGranularity.daily);
  registerFallbackValue(
    CorrelationRequest.moodVsTracker(
      trackerId: 'tracker-1',
      range: TestData.dateRange(),
    ),
  );

  // Wellbeing
  registerFallbackValue(TestData.journalEntry());
  registerFallbackValue(TestData.tracker());
  registerFallbackValue(TestData.dailyTrackerResponse());

  // Screens
  registerFallbackValue(TestData.screenDefinition());

  // Sort preferences
  registerFallbackValue(const SortPreferences());

  // Display settings
  registerFallbackValue(const PageDisplaySettings());
}
