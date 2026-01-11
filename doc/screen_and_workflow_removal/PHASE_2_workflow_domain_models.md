# Phase 2: Remove Workflow Domain Models

**Risk Level:** Medium  
**Estimated Time:** 20 minutes  
**Dependencies:** Phase 1 complete

---

## Objective

Remove workflow domain models and the problem detection service. This removes the core business logic for workflows while leaving data layer intact temporarily (for Phase 4).

---

## Files to Delete (11 files)

### Workflow Models (8 files)
```
lib/domain/workflow/model/problem_acknowledgment.dart
lib/domain/workflow/model/problem_definition.dart
lib/domain/workflow/model/problem_type.dart
lib/domain/workflow/model/workflow_definition.dart
lib/domain/workflow/model/workflow_filter.dart
lib/domain/workflow/model/workflow_run_state.dart
lib/domain/workflow/model/workflow_step_definition.dart
lib/domain/workflow/model/workflow_step_state.dart
```

### Services (2 files)
```
lib/domain/services/workflow/problem_detector_service.dart
lib/domain/services/workflow/ (entire folder if only problem_detector_service.dart exists)
```

### Contracts (1 file)
```
lib/domain/interfaces/workflow_repository_contract.dart
```

---

## Files to Modify (5 files)

### 1. Remove from Dependency Injection

**File:** `lib/core/di/dependency_injection.dart`

**Action:** Remove ProblemDetectorService registration (lines ~557-560)

**Find and remove:**
```dart
  ..registerLazySingleton<ProblemDetectorService>(
    () => ProblemDetectorService(
      settingsRepository: getIt<SettingsRepositoryContract>(),
    ),
  )
```

### 2. Remove DisplayConfig.problemsToDetect Field

**File:** `lib/domain/screens/language/models/display_config.dart`

**Find:** (around line 65)
```dart
@Default([]) List<ProblemType> problemsToDetect,
```

**Remove:**
- The field declaration
- Import for `ProblemType`
- Any references in `fromJson`/`toJson` methods
- Any references in `copyWith` method

### 3. Remove AttentionRuleType.workflowStep

**File:** `lib/domain/attention/model/attention_rule.dart`

**Find:** (around line 14)
```dart
enum AttentionRuleType {
  @JsonValue('problem')
  problem,

  @JsonValue('review')
  review,

  @JsonValue('workflowStep')
  workflowStep,

  @JsonValue('allocationWarning')
  allocationWarning,
}
```

**Remove:**
```dart
  @JsonValue('workflowStep')
  workflowStep,
```

### 4. Remove workflowStep Case in AttentionEngine

**File:** `lib/domain/attention/engine/attention_engine.dart`

**Find:** (around line 183)
```dart
return switch (rule.ruleType) {
  AttentionRuleType.problem => _evaluateProblemRule(
    rule,
    tasks: tasks,
    projects: projects,
  ),
  AttentionRuleType.review => _evaluateReviewRule(rule),
  AttentionRuleType.allocationWarning => _evaluateAllocationRule(
    rule,
    tasks: tasks,
    projects: projects,
    snapshot: snapshot,
  ),
  AttentionRuleType.workflowStep => const <AttentionItem>[],
};
```

**Remove:**
```dart
  AttentionRuleType.workflowStep => const <AttentionItem>[],
```

### 5. Remove EntityType Workflow Enum Values

**File:** `lib/domain/screens/language/models/entity_selector.dart`

**Search for:** `workflow` in EntityType enum (if exists)

**Remove:** any workflow-related enum values

---

## Test Files to Delete

Find and delete all test files for removed models:
```bash
rm test/domain/models/workflow/*.dart
rm -rf test/domain/models/workflow/
rm test/domain/services/workflow/*.dart
rm -rf test/domain/services/workflow/
```

---

## Validation Steps

### 1. Delete domain model files
```bash
rm -rf lib/domain/workflow/
rm lib/domain/interfaces/workflow_repository_contract.dart
rm lib/domain/services/workflow/problem_detector_service.dart
```

### 2. Make modifications to remaining files
- Edit `dependency_injection.dart`
- Edit `display_config.dart`
- Edit `attention_rule.dart`
- Edit `attention_engine.dart`
- Edit `entity_selector.dart` (if needed)

### 3. Delete test files
```bash
rm -rf test/domain/models/workflow/
rm -rf test/domain/services/workflow/
```

### 4. Run code generation (for freezed models)
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 5. Run analysis
```bash
flutter analyze
```

### 6. Fix any import errors
Common issues:
- Data layer still importing workflow models
- Presentation layer still importing workflow models
- Other services referencing ProblemType

### 7. Verify no references remain
```bash
grep -r "ProblemType" lib/ --exclude-dir=.dart_tool
grep -r "ProblemDetectorService" lib/ --exclude-dir=.dart_tool
grep -r "workflow_definition" lib/ --exclude-dir=.dart_tool
grep -r "WorkflowDefinition" lib/ --exclude-dir=.dart_tool
```

---

## Expected Issues and Fixes

### Issue 1: DisplayConfig tests failing
**Fix:** Update display_config_test.dart to remove problemsToDetect test cases

### Issue 2: Attention engine tests referencing workflowStep
**Fix:** Update attention tests to remove workflowStep test cases (Phase 7)

---

## Expected Analyze Output

```
Analyzing taskly_bloc...
No issues found!
```

---
---

## Next Phase

→ **Phase 3:** Remove workflow presentation layer
