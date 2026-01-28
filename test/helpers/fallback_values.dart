import 'package:mocktail/mocktail.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_bloc/presentation/routing/page_key.dart';
import 'package:taskly_bloc/presentation/shared/models/sort_preferences.dart';

import '../fixtures/test_data.dart';

import 'package:taskly_domain/analytics.dart' as domain_analytics;
import 'package:taskly_domain/core.dart' as domain_core;
import 'package:taskly_domain/queries.dart' as domain_queries;
import 'package:taskly_domain/routines.dart' as domain_routines;

bool _fallbackValuesRegistered = false;

/// Fake implementations for mocktail's any() matcher.
class FakeTaskQuery extends Fake implements domain_queries.TaskQuery {}

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
  if (_fallbackValuesRegistered) return;
  _fallbackValuesRegistered = true;

  // Initialize talker for tests (safe to call multiple times)
  initializeLoggingForTest();

  // === Fake Types ===
  registerFallbackValue(FakeTaskQuery());

  // === Core Domain ===
  registerFallbackValue(TestData.task());
  registerFallbackValue(TestData.project());
  registerFallbackValue(TestData.value());
  registerFallbackValue(domain_core.ValuePriority.medium);
  registerFallbackValue(domain_queries.TaskQuery.all());
  registerFallbackValue(domain_queries.JournalQuery());
  registerFallbackValue(domain_routines.RoutineType.weeklyFixed);
  registerFallbackValue(PageKey.taskOverview);

  // === Views ===
  registerFallbackValue(const SortPreferences());

  // === Analytics ===
  registerFallbackValue(TestData.correlation());
  registerFallbackValue(TestData.insight());
  registerFallbackValue(TestData.dateRange());
  registerFallbackValue(domain_analytics.TrendGranularity.daily);
  registerFallbackValue(
    domain_analytics.CorrelationRequest.moodVsTracker(
      trackerId: 'tracker-1',
      range: TestData.dateRange(),
    ),
  );
}
