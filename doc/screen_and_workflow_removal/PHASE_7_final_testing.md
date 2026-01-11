# Phase 7: Final Testing & Validation

**Risk Level:** Critical  
**Estimated Time:** 45 minutes  
**Dependencies:** All phases 1-6 complete

---

## Objective

Run the complete test suite and validate that the application works correctly
after all removals.

---

## Pre-Test Checklist

- [ ] Phase 1: Screen create UI removed
- [ ] Phase 2: Workflow domain models removed
- [ ] Phase 3: Workflow presentation removed
- [ ] Phase 4: Workflow data layer removed
- [ ] Phase 5: Overlapping components removed
- [ ] Phase 6: Backend DB + PowerSync sync rules updated
- [ ] `flutter analyze` passes with no errors
- [ ] Code generation completed successfully

---

## Test Execution Plan

### 1. Clean Build

```bash
flutter clean
rm -rf .dart_tool/
rm -rf build/

flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 2. Static Analysis

```bash
flutter analyze
```

### 3. Run Full Test Suite

```bash
flutter test
```

Optional:

```bash
flutter test -r expanded
flutter test --coverage
```

---

## Manual Testing Checklist

### Critical User Flows

#### Authentication & Onboarding
- [ ] Login works
- [ ] Signup works
- [ ] Onboarding wizard works
- [ ] Focus setup wizard works

#### Core Task Management
- [ ] Create/edit/complete/delete task
- [ ] Task list loads

#### Core Project Management
- [ ] Create/edit/complete/delete project
- [ ] Project list loads

#### My Day / Allocation
- [ ] My Day loads
- [ ] Allocation section displays
- [ ] Tasks can be checked off

#### Attention System
- [ ] Issues summary section displays
- [ ] Attention items can be dismissed

#### Values Management
- [ ] Create/edit/delete value
- [ ] Assign value to task/project

#### Navigation
- [ ] All screens accessible
- [ ] Back button works

### Verify No References to Removed Features

- [ ] No "Workflows" menu item
- [ ] No "Screen Management" menu item
- [ ] No "Orphan Tasks" screen
- [ ] No broken navigation links

---

## PowerSync Validation

Verify sync activity in logs:

- [ ] No errors about missing workflow tables
- [ ] No errors about `last_reviewed_at`
- [ ] Tasks sync correctly
- [ ] Projects sync correctly

---

## Expected Test Failures (Fix Required)

These are common failure points after the removals:

1. **DisplayConfig** tests expecting `problemsToDetect`
   - Update: `test/domain/models/screens/display_config_test.dart`

2. **Attention engine** tests expecting `workflowStep`
   - Update: `test/domain/attention/engine/attention_engine_test.dart`

3. **Mocks/fakes** still implementing removed repository APIs
   - Update: `test/mocks/` and `test/helpers/`

4. **System screen** tests expecting removed screens
   - Update: `test/domain/models/screens/system_screen_definitions_test.dart`

---

## Success Criteria

 `flutter analyze` passes with 0 issues  
 `flutter test` passes with 0 failures  
 App runs without errors  
 PowerSync syncs without errors  
 No references to removed features in UI
