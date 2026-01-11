import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';
import 'package:taskly_bloc/domain/analytics/model/trend_data.dart';
import 'package:taskly_bloc/domain/preferences/model/page_key.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/display_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/entity_selector.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/data_list_section_params.dart';
import 'package:taskly_bloc/domain/screens/templates/params/screen_item_tile_variants.dart';
import 'package:taskly_bloc/domain/settings/settings.dart';
import 'package:taskly_bloc/domain/preferences/model/sort_preferences.dart';
import 'package:taskly_bloc/domain/core/model/value_priority.dart';
import 'package:taskly_bloc/domain/workflow/model/problem_action.dart';
import 'package:taskly_bloc/domain/workflow/model/problem_definition.dart';
import 'package:taskly_bloc/domain/workflow/model/problem_type.dart';
import 'package:taskly_bloc/domain/workflow/model/workflow.dart';
import 'package:taskly_bloc/domain/workflow/model/workflow_definition.dart';
import 'package:taskly_bloc/domain/workflow/model/workflow_step.dart';
import 'package:taskly_bloc/domain/workflow/model/workflow_step_state.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/analytics/model/correlation_request.dart';

import '../fixtures/test_data.dart';

/// Fake implementations for mocktail's any() matcher.
class FakeTaskQuery extends Fake implements TaskQuery {}

// Note: ViewDefinition is sealed, so we use a real instance as fallback
// Note: ProblemAction is sealed, so we use a real instance as fallback

class FakeWorkflowDefinition extends Fake implements WorkflowDefinition {}

class FakeWorkflow extends Fake implements Workflow {}

class FakeEntitySelector extends Fake implements EntitySelector {}

class FakeDisplayConfig extends Fake implements DisplayConfig {}

class FakeWorkflowStep extends Fake implements WorkflowStep {}

class FakeWorkflowStepState extends Fake implements WorkflowStepState {}

class FakeProblemDefinition extends Fake implements ProblemDefinition {}

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

  // === Fake Types ===
  registerFallbackValue(FakeTaskQuery());
  registerFallbackValue(FakeWorkflowDefinition());
  registerFallbackValue(FakeWorkflow());
  registerFallbackValue(FakeEntitySelector());
  registerFallbackValue(FakeDisplayConfig());
  registerFallbackValue(FakeWorkflowStep());
  registerFallbackValue(FakeWorkflowStepState());
  registerFallbackValue(FakeProblemDefinition());

  // === Sealed Classes (use real instances) ===
  registerFallbackValue(const ProblemAction.rescheduleToday());
  registerFallbackValue(
    SectionRef(
      templateId: SectionTemplateId.taskList,
      params: DataListSectionParams(
        config: DataConfig.task(query: TaskQuery.all()),
        taskTileVariant: TaskTileVariant.listTile,
        projectTileVariant: ProjectTileVariant.listTile,
        valueTileVariant: ValueTileVariant.compactCard,
        display: const DisplayConfig(),
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
  registerFallbackValue(TestData.screenDefinition());
  registerFallbackValue(const EntitySelector(entityType: EntityType.task));
  registerFallbackValue(const DisplayConfig());
  registerFallbackValue(const SortPreferences());
  registerFallbackValue(const PageDisplaySettings());

  // === Workflows ===
  registerFallbackValue(TestData.workflowDefinition());
  registerFallbackValue(TestData.workflow());
  registerFallbackValue(TestData.workflowStep());
  registerFallbackValue(TestData.workflowStepState());
  registerFallbackValue(WorkflowStatus.inProgress);
  registerFallbackValue(ProblemType.taskStale);

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

  // === Wellbeing ===
  registerFallbackValue(TestData.journalEntry());
  registerFallbackValue(TestData.tracker());
  registerFallbackValue(TestData.dailyTrackerResponse());
}
