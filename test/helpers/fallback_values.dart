import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';
import 'package:taskly_bloc/domain/analytics/model/trend_data.dart';
import 'package:taskly_bloc/presentation/routing/page_key.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/display_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/entity_selector.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/style_pack_v2.dart';
import 'package:taskly_bloc/presentation/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/analytics/model/correlation_request.dart';

import '../fixtures/test_data.dart';

bool _fallbackValuesRegistered = false;

/// Fake implementations for mocktail's any() matcher.
class FakeTaskQuery extends Fake implements TaskQuery {}

class FakeEntitySelector extends Fake implements EntitySelector {}

class FakeDisplayConfig extends Fake implements DisplayConfig {}

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
  initializeTalkerForTest();

  // === Fake Types ===
  registerFallbackValue(FakeTaskQuery());
  registerFallbackValue(FakeEntitySelector());
  registerFallbackValue(FakeDisplayConfig());
  registerFallbackValue(
    SectionRef(
      templateId: SectionTemplateId.taskListV2,
      params: ListSectionParamsV2(
        config: DataConfig.task(query: TaskQuery.all()),
        pack: StylePackV2.standard,
      ).toJson(),
      overrides: const SectionOverrides(title: 'Fallback Section'),
    ),
  );

  // === Core Domain ===
  registerFallbackValue(TestData.task());
  registerFallbackValue(TestData.project());
  registerFallbackValue(TestData.value());
  registerFallbackValue(ValuePriority.medium);
  registerFallbackValue(TaskQuery.all());
  registerFallbackValue(PageKey.taskOverview);

  // === Screens & Views ===
  registerFallbackValue(const EntitySelector(entityType: EntityType.task));
  registerFallbackValue(const DisplayConfig());
  registerFallbackValue(const SortPreferences());

  // === Analytics ===
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
}
