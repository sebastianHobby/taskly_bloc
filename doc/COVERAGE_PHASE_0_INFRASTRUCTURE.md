# Phase 0: Test Infrastructure Review & Enhancements

## Overview
**Goal:** Ensure consistent test architecture across all test files by establishing clear patterns and updating existing infrastructure.

**Status:** REVIEW & STANDARDIZATION
**Coverage Impact:** Indirect - enables consistent testing patterns

---

## Current Test Infrastructure

### 1. Test Helpers (`test/helpers/`)

#### `bloc_test_helpers.dart`
Stream testing utilities:
- `waitForStreamEmissions<T>()` - Wait for specific number of emissions
- `waitForStreamMatch<T>()` - Wait until predicate matches
- `expectStreamEmits<T>()` - Assert emissions match expected values

#### `test_helpers.dart`
Timeout wrappers:
- `testWidgetsSafe()` - Widget tests with configurable timeout
- `testSafe()` - Unit tests with configurable timeout

#### `pump_helpers.dart`
Widget test pump extensions:
- Extensions for pumping widgets with proper settling

#### `fallback_values.dart`
Mocktail fallback value registration:
- `registerAllFallbackValues()` - Call in `setUpAll()`

### 2. Mock Infrastructure (`test/mocks/`)

#### `repository_mocks.dart`
Mocktail mock classes:
```dart
class MockTaskRepositoryContract extends Mock implements TaskRepositoryContract {}
class MockProjectRepositoryContract extends Mock implements ProjectRepositoryContract {}
class MockLabelRepositoryContract extends Mock implements LabelRepositoryContract {}
class MockSettingsRepositoryContract extends Mock implements SettingsRepositoryContract {}
```

#### `fake_repositories.dart`
In-memory fake implementations for integration tests:
```dart
class FakeTaskRepository implements TaskRepositoryContract { ... }
class FakeProjectRepository implements ProjectRepositoryContract { ... }
class FakeLabelRepository implements LabelRepositoryContract { ... }
class FakeSettingsRepository implements SettingsRepositoryContract { ... }
```

### 3. Test Fixtures (`test/fixtures/`)

#### `test_data.dart`
Object Mother pattern for domain objects:
```dart
TestData.task(name: 'My Task', completed: true)
TestData.project(name: 'My Project')
TestData.label(name: 'Urgent', type: LabelType.value)
TestData.occurrenceData(date: DateTime.now())
TestData.screenDefinition(...)
TestData.workflowDefinition(...)
```

---

## Standardized Test Patterns

### Pattern 1: Unit Test Structure
```dart
import 'package:flutter_test/flutter_test.dart';
import '../../fixtures/test_data.dart';
import '../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('ClassName', () {
    group('constructor', () {
      test('creates with required fields', () {
        // Arrange - use TestData builders
        // Act
        // Assert
      });
      
      test('creates with optional fields', () {
        // Test all optional parameters
      });
    });

    group('fromJson', () {
      test('parses valid JSON', () { ... });
      test('handles missing optional fields', () { ... });
      test('handles null values', () { ... });
    });

    group('toJson', () {
      test('serializes all fields', () { ... });
      test('round-trips through fromJson', () { ... });
    });

    group('copyWith', () {
      test('copies with no changes', () { ... });
      test('copies with single field change', () { ... });
      test('copies with all fields changed', () { ... });
    });

    group('equality', () {
      test('equal when all fields match', () { ... });
      test('not equal when field differs', () { ... });
      test('hashCode consistent with equality', () { ... });
    });

    group('business logic method', () {
      test('returns expected result for normal case', () { ... });
      test('handles edge case', () { ... });
    });
  });
}
```

### Pattern 2: Rule/Predicate Test Structure
```dart
void main() {
  setUpAll(registerAllFallbackValues);

  group('RuleName', () {
    final today = DateTime(2025, 6, 15);
    final context = EvaluationContext(today: today);

    group('evaluate', () {
      test('matches task meeting condition', () {
        final rule = RuleName(operator: Operator.someValue);
        final task = TestData.task(/* conditions to match */);
        
        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task failing condition', () {
        final rule = RuleName(operator: Operator.someValue);
        final task = TestData.task(/* conditions to fail */);
        
        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('validate', () {
      test('returns empty for valid rule', () {
        final rule = RuleName(/* valid config */);
        expect(rule.validate(), isEmpty);
      });

      test('returns errors for invalid config', () {
        final rule = RuleName(/* invalid config */);
        expect(rule.validate(), contains(/* expected error */));
      });
    });

    group('serialization', () {
      test('round-trips through JSON', () {
        final rule = RuleName(/* config */);
        final json = rule.toJson();
        final restored = RuleName.fromJson(json);
        
        expect(restored, equals(rule));
      });
    });
  });
}
```

### Pattern 3: Settings Model Test Structure
```dart
void main() {
  group('SettingsClass', () {
    group('construction', () {
      test('creates with defaults', () {
        const settings = SettingsClass();
        expect(settings.field, defaultValue);
      });

      test('creates with custom values', () {
        final settings = SettingsClass(field: customValue);
        expect(settings.field, customValue);
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () { ... });
      test('uses defaults for missing fields', () { ... });
      test('handles malformed values gracefully', () { ... });
    });

    group('toJson', () {
      test('serializes all fields', () { ... });
      test('round-trips correctly', () { ... });
    });

    group('copyWith', () {
      test('preserves values when no override', () { ... });
      test('applies overrides correctly', () { ... });
    });

    group('equality', () {
      test('instances with same values are equal', () { ... });
      test('instances with different values are not equal', () { ... });
    });
  });
}
```

---

## Required Infrastructure Updates

### 1. Add TestData Extensions for Rules

**File:** `test/fixtures/test_data.dart`

Add the following builders:

```dart
// === Task Rules ===

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

static BooleanRule booleanRule({
  BooleanRuleField field = BooleanRuleField.completed,
  BooleanRuleOperator operator = BooleanRuleOperator.isFalse,
}) {
  return BooleanRule(field: field, operator: operator);
}

static LabelRule labelRule({
  LabelRuleOperator operator = LabelRuleOperator.hasAny,
  List<String> labelIds = const [],
  LabelType labelType = LabelType.label,
}) {
  return LabelRule(
    operator: operator,
    labelIds: labelIds,
    labelType: labelType,
  );
}

static ValueRule valueRule({
  ValueRuleOperator operator = ValueRuleOperator.hasAny,
  List<String> labelIds = const [],
}) {
  return ValueRule(operator: operator, labelIds: labelIds);
}

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

static TaskRuleSet taskRuleSet({
  RuleSetOperator operator = RuleSetOperator.and,
  List<TaskRule> rules = const [],
}) {
  return TaskRuleSet(operator: operator, rules: rules);
}

static TaskPriorityBucketRule priorityBucketRule({
  int priority = 1,
  String name = 'Test Bucket',
  List<TaskRuleSet> ruleSets = const [],
  int? limit,
  SortCriterion? sortCriterion,
}) {
  return TaskPriorityBucketRule(
    priority: priority,
    name: name,
    ruleSets: ruleSets,
    limit: limit,
    sortCriterion: sortCriterion,
  );
}
```

### 2. Add TestData Extensions for Settings

```dart
// === Settings ===

static AllocationSettings allocationSettings({
  AllocationStrategyType strategyType = AllocationStrategyType.proportional,
  double urgencyInfluence = 0.4,
  int minimumTasksPerCategory = 1,
  int topNCategories = 3,
  int dailyTaskLimit = 10,
  bool showExcludedUrgentWarning = true,
}) {
  return AllocationSettings(
    strategyType: strategyType,
    urgencyInfluence: urgencyInfluence,
    minimumTasksPerCategory: minimumTasksPerCategory,
    topNCategories: topNCategories,
    dailyTaskLimit: dailyTaskLimit,
    showExcludedUrgentWarning: showExcludedUrgentWarning,
  );
}

static NextActionsSettings nextActionsSettings({
  int tasksPerProject = 2,
  List<TaskPriorityBucketRule>? bucketRules,
  bool includeInboxTasks = true,
  bool excludeFutureStartDates = true,
  SortPreferences sortPreferences = const SortPreferences(),
}) {
  return NextActionsSettings(
    tasksPerProject: tasksPerProject,
    bucketRules: bucketRules ?? [],
    includeInboxTasks: includeInboxTasks,
    excludeFutureStartDates: excludeFutureStartDates,
    sortPreferences: sortPreferences,
  );
}

static AppSettings appSettings({
  GlobalSettings global = const GlobalSettings(),
  Map<String, SortPreferences> pageSortPreferences = const {},
  Map<String, PageDisplaySettings> pageDisplaySettings = const {},
  Map<String, ScreenPreferences> screenPreferences = const {},
  AllocationSettings allocation = const AllocationSettings(),
  ValueRanking valueRanking = const ValueRanking(),
  SoftGatesSettings? softGates,
  NextActionsSettings? nextActions,
}) {
  return AppSettings(
    global: global,
    pageSortPreferences: pageSortPreferences,
    pageDisplaySettings: pageDisplaySettings,
    screenPreferences: screenPreferences,
    allocation: allocation,
    valueRanking: valueRanking,
    softGates: softGates,
    nextActions: nextActions,
  );
}
```

### 3. Add TestData Extensions for Predicates

```dart
// === Query Predicates ===

static TaskBoolPredicate taskBoolPredicate({
  TaskBoolField field = TaskBoolField.completed,
  BoolOperator operator = BoolOperator.isFalse,
}) {
  return TaskBoolPredicate(field: field, operator: operator);
}

static TaskDatePredicate taskDatePredicate({
  TaskDateField field = TaskDateField.deadlineDate,
  DateOperator operator = DateOperator.isNotNull,
  DateTime? date,
  DateTime? startDate,
  DateTime? endDate,
  RelativeComparison? relativeComparison,
  int? relativeDays,
}) {
  return TaskDatePredicate(
    field: field,
    operator: operator,
    date: date,
    startDate: startDate,
    endDate: endDate,
    relativeComparison: relativeComparison,
    relativeDays: relativeDays,
  );
}

static TaskProjectPredicate taskProjectPredicate({
  ProjectOperator operator = ProjectOperator.isNull,
  String? projectId,
  List<String>? projectIds,
}) {
  return TaskProjectPredicate(
    operator: operator,
    projectId: projectId,
    projectIds: projectIds,
  );
}

static TaskLabelPredicate taskLabelPredicate({
  LabelOperator operator = LabelOperator.hasAny,
  List<String> labelIds = const [],
  LabelType labelType = LabelType.label,
}) {
  return TaskLabelPredicate(
    operator: operator,
    labelIds: labelIds,
    labelType: labelType,
  );
}
```

---

## Test File Organization

Create the following directory structure:
```
test/
├── domain/
│   ├── filtering/
│   │   ├── task_rules/
│   │   │   ├── date_rule_test.dart
│   │   │   ├── boolean_rule_test.dart
│   │   │   ├── label_rule_test.dart
│   │   │   ├── value_rule_test.dart
│   │   │   ├── project_rule_test.dart
│   │   │   ├── task_rule_set_test.dart
│   │   │   └── task_priority_bucket_rule_test.dart
│   │   └── evaluation_context_test.dart
│   ├── models/
│   │   └── settings/
│   │       ├── allocation_settings_test.dart
│   │       ├── next_actions_settings_test.dart
│   │       ├── global_settings_test.dart
│   │       ├── value_ranking_test.dart
│   │       ├── soft_gates_settings_test.dart
│   │       ├── page_display_settings_test.dart
│   │       ├── screen_preferences_test.dart
│   │       └── app_settings_test.dart
│   └── queries/
│       ├── task_predicate_test.dart
│       ├── project_predicate_test.dart
│       └── task_query_test.dart
```

---

## Implementation Tasks

### Task 0.1: Update TestData with Rule Builders
- [ ] Add `dateRule()` builder
- [ ] Add `booleanRule()` builder
- [ ] Add `labelRule()` builder
- [ ] Add `valueRule()` builder
- [ ] Add `projectRule()` builder
- [ ] Add `taskRuleSet()` builder
- [ ] Add `priorityBucketRule()` builder

### Task 0.2: Update TestData with Settings Builders
- [ ] Add `allocationSettings()` builder
- [ ] Add `nextActionsSettings()` builder
- [ ] Add `appSettings()` builder
- [ ] Add `globalSettings()` builder
- [ ] Add `valueRanking()` builder
- [ ] Add `softGatesSettings()` builder
- [ ] Add `pageDisplaySettings()` builder
- [ ] Add `screenPreferences()` builder

### Task 0.3: Update TestData with Predicate Builders
- [ ] Add `taskBoolPredicate()` builder
- [ ] Add `taskDatePredicate()` builder
- [ ] Add `taskProjectPredicate()` builder
- [ ] Add `taskLabelPredicate()` builder
- [ ] Add `projectBoolPredicate()` builder
- [ ] Add `projectDatePredicate()` builder
- [ ] Add `projectLabelPredicate()` builder

### Task 0.4: Create Test Directory Structure
- [ ] Create `test/domain/filtering/` directory
- [ ] Create `test/domain/filtering/task_rules/` directory
- [ ] Create `test/domain/models/settings/` directory
- [ ] Create `test/domain/queries/` (if not exists)

---

## Verification

After Phase 0 completion:
1. All TestData builders compile without errors
2. Imports work correctly in test files
3. Test directory structure matches plan
4. `flutter test test/fixtures/` passes

---

## Next Phase
Proceed to **Phase 1: Domain Filtering Rules Tests** after completing infrastructure updates.
