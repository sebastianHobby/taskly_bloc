import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/correlation_request.dart';

import '../fixtures/test_data.dart';

/// Shared fake implementations for mocktail's any() matcher.
class FakeTaskQuery extends Fake implements TaskQuery {}

/// Registers fallback values for mocktail's `any()` matcher.
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
  // Register fake query type
  registerFallbackValue(FakeTaskQuery());
  // Core domain
  registerFallbackValue(TestData.task());
  registerFallbackValue(TestData.project());
  registerFallbackValue(TestData.label());
  registerFallbackValue(TaskQuery.all());

  // Analytics
  registerFallbackValue(TestData.correlation());
  registerFallbackValue(TestData.insight());
  registerFallbackValue(TestData.dateRange());
  registerFallbackValue(
    CorrelationRequest.moodVsTracker(
      trackerId: 'tracker-1',
      range: TestData.dateRange(),
    ),
  );

  // Wellbeing
  registerFallbackValue(TestData.journalEntry());
  registerFallbackValue(TestData.tracker());

  // Reviews
  registerFallbackValue(TestData.review());
  registerFallbackValue(TestData.reviewQuery());
}
