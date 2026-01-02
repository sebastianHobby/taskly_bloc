import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/models/analytics/trend_data.dart';
import 'package:taskly_bloc/domain/models/page_key.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/screens/view_definition.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_action.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_definition.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_type.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_definition.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step_state.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/models/analytics/correlation_request.dart';

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
  registerFallbackValue(
    const ViewDefinition.collection(
      selector: EntitySelector(entityType: EntityType.task),
      display: DisplayConfig(),
    ),
  );
  registerFallbackValue(const ProblemAction.rescheduleToday());

  // === Core Domain ===
  registerFallbackValue(TestData.task());
  registerFallbackValue(TestData.project());
  registerFallbackValue(TestData.label());
  registerFallbackValue(TestData.labelType());
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
  registerFallbackValue(ProblemType.staleTasks);

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
