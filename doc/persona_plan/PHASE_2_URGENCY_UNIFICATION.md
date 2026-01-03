# Phase 2: Urgency Unification

> **Status**: Not Started  
> **Effort**: 2-3 days  
> **Dependencies**: Phase 1 (Model Foundation)

---

## AI Implementation Instructions

### General Guidelines
1. **Follow existing patterns** - Match code style, naming conventions, and architecture patterns already in the codebase
2. **Do NOT run or update tests** - If tests break, leave them; they will be fixed separately
3. **Run `flutter analyze` at end of phase** - Fix ALL errors and warnings before marking phase complete
4. **Format code** - Use `dart format` or the dart_format tool for Dart files

### Build Runner
- **Assume `build_runner` is running in watch mode** in background
- **Do NOT run `dart run build_runner build` manually**
- After creating/modifying freezed files, wait for `.freezed.dart` / `.g.dart` files to regenerate
- If generated files don't update after ~45 seconds, there's likely a **syntax error in the source .dart file** - review and fix

### Freezed Syntax (Project Convention)
- Use **`sealed class`** for union types (multiple factory constructors / variants):
  ```dart
  @freezed
  sealed class MyEvent with _$MyEvent {
    const factory MyEvent.started() = _Started;
    const factory MyEvent.loaded(Data data) = _Loaded;
  }
  ```
- Use **`abstract class`** for single-class models with copyWith:
  ```dart
  @freezed
  abstract class MyModel with _$MyModel {
    const factory MyModel({
      required String id,
      required String name,
    }) = _MyModel;
  }
  ```

### Compatibility - IMPORTANT
- **No backwards compatibility** - Remove old fields/code completely
- **No deprecation annotations** - Just delete obsolete code
- **No migration logic** - Clean break, assume fresh state

---

## Objective

Create shared urgency detection logic and implement `UrgentTaskBehavior` throughout the allocation system:
- Create `UrgencyDetector` class with task and project urgency methods
- Update `AllocationParameters` to include `urgentTaskBehavior`
- Modify allocators to use the new unified urgency handling
- Generate project deadline warnings

---

## Files to Create

### 1. `lib/domain/services/allocation/urgency_detector.dart`

```dart
import 'package:taskly/domain/models/project/project.dart';
import 'package:taskly/domain/models/task/task.dart';

/// Shared urgency detection logic for tasks and projects.
/// 
/// Urgency is determined by proximity to deadline:
/// - Tasks are urgent when deadline is within [taskThresholdDays]
/// - Projects are urgent when deadline is within [projectThresholdDays]
class UrgencyDetector {
  const UrgencyDetector({
    required this.taskThresholdDays,
    required this.projectThresholdDays,
  });

  /// Days before deadline at which a task becomes urgent.
  final int taskThresholdDays;

  /// Days before deadline at which a project becomes urgent.
  final int projectThresholdDays;

  /// Returns true if [task] is urgent based on its deadline.
  /// 
  /// A task is urgent if:
  /// - It has a deadline, AND
  /// - The deadline is within [taskThresholdDays] days from now
  bool isTaskUrgent(Task task) {
    final deadline = task.deadline;
    if (deadline == null) return false;
    
    final now = DateTime.now();
    final daysUntilDeadline = deadline.difference(now).inDays;
    return daysUntilDeadline <= taskThresholdDays;
  }

  /// Returns true if [project] is urgent based on its deadline.
  /// 
  /// A project is urgent if:
  /// - It has a deadline, AND
  /// - The deadline is within [projectThresholdDays] days from now
  bool isProjectUrgent(Project project) {
    final deadline = project.deadline;
    if (deadline == null) return false;
    
    final now = DateTime.now();
    final daysUntilDeadline = deadline.difference(now).inDays;
    return daysUntilDeadline <= projectThresholdDays;
  }

  /// Filters [tasks] to return only urgent tasks.
  List<Task> findUrgentTasks(List<Task> tasks) {
    return tasks.where(isTaskUrgent).toList();
  }

  /// Filters [projects] to return only urgent projects.
  List<Project> findUrgentProjects(List<Project> projects) {
    return projects.where(isProjectUrgent).toList();
  }

  /// Returns tasks that are urgent but have no value assigned.
  /// 
  /// These are the tasks that trigger warnings in `warnOnly` mode
  /// or get included in `includeAll` mode.
  List<Task> findUrgentValuelessTasks(List<Task> tasks) {
    return tasks.where((task) {
      final hasNoValue = task.valueId == null || task.valueId!.isEmpty;
      return hasNoValue && isTaskUrgent(task);
    }).toList();
  }

  /// Creates an UrgencyDetector from AllocationSettings.
  factory UrgencyDetector.fromSettings(AllocationSettings settings) {
    return UrgencyDetector(
      taskThresholdDays: settings.taskUrgencyThresholdDays,
      projectThresholdDays: settings.projectUrgencyThresholdDays,
    );
  }
}
```

**Note**: Adjust imports based on actual project structure. The `AllocationSettings` import will be needed for the factory constructor.

---

## Files to Modify

### 2. `lib/domain/services/allocation/allocation_strategy.dart`

**Add to `AllocationParameters`:**

```dart
/// How to handle urgent tasks without values.
final UrgentTaskBehavior urgentTaskBehavior;

/// Days threshold for task urgency.
final int taskUrgencyThresholdDays;

/// Boost multiplier for urgent tasks that have values.
final double valueAlignedUrgencyBoost;
```

**Update constructor** to include these fields with appropriate defaults.

---

### 3. `lib/domain/services/allocation/allocation_orchestrator.dart`

**Changes required:**

1. **Remove hardcoded urgency threshold** - Replace any `urgencyThresholdDays = 3` with value from settings
2. **Create UrgencyDetector instance** from settings
3. **Handle UrgentTaskBehavior**:
   - `ignore`: Do not generate warnings for urgent value-less tasks
   - `warnOnly`: Generate `WarningType.urgentTaskExcluded` for urgent value-less tasks
   - `includeAll`: Include urgent value-less tasks in result with `isUrgentOverride = true`
4. **Generate project warnings**: Create `WarningType.projectDeadlineApproaching` for urgent projects

**Pseudo-code for urgency handling:**
```dart
// Create detector from settings
final detector = UrgencyDetector.fromSettings(settings);

// Find urgent value-less tasks
final urgentValueless = detector.findUrgentValuelessTasks(allTasks);

// Handle based on behavior
switch (settings.urgentTaskBehavior) {
  case UrgentTaskBehavior.ignore:
    // Do nothing, these tasks are excluded
    break;
  case UrgentTaskBehavior.warnOnly:
    // Add warnings for each urgent value-less task
    for (final task in urgentValueless) {
      warnings.add(AllocationWarning(
        type: WarningType.urgentTaskExcluded,
        taskId: task.id,
        // ...
      ));
    }
    break;
  case UrgentTaskBehavior.includeAll:
    // Add these tasks to allocated list with override flag
    for (final task in urgentValueless) {
      allocatedTasks.add(AllocatedTask(
        task: task,
        reason: 'Urgent override',
        isUrgentOverride: true,
      ));
    }
    break;
}

// Project deadline warnings
final urgentProjects = detector.findUrgentProjects(allProjects);
for (final project in urgentProjects) {
  warnings.add(AllocationWarning(
    type: WarningType.projectDeadlineApproaching,
    projectId: project.id,
    message: 'Project "${project.name}" deadline approaching',
  ));
}
```

---

### 4. `lib/domain/services/allocation/proportional_allocator.dart`

**Changes:**
- Remove references to `alwaysIncludeUrgent` and `showExcludedUrgentWarning`
- Use `urgentTaskBehavior` from parameters instead
- Apply `valueAlignedUrgencyBoost` to urgent tasks that have values

---

### 5. `lib/domain/services/allocation/urgency_weighted_allocator.dart`

**Changes:**
- Remove references to old urgency flags
- Use `UrgencyDetector` for urgency checks
- When `includeAll` is active, include urgent value-less tasks in allocation
- Apply boost multiplier from settings

---

## Step-by-Step Implementation

### Step 1: Create UrgencyDetector
Create `lib/domain/services/allocation/urgency_detector.dart` with the full implementation.

### Step 2: Update AllocationParameters
Add `urgentTaskBehavior`, `taskUrgencyThresholdDays`, and `valueAlignedUrgencyBoost` fields.

### Step 3: Update AllocationOrchestrator
1. Import `UrgencyDetector` and `UrgentTaskBehavior`
2. Create detector from settings
3. Remove any hardcoded threshold values
4. Implement the switch logic for `UrgentTaskBehavior`
5. Add project deadline warning generation

### Step 4: Update ProportionalAllocator
Remove old flags, use new behavior enum.

### Step 5: Update UrgencyWeightedAllocator
Implement `includeAll` logic to add urgent value-less tasks.

### Step 6: Run flutter analyze
```bash
flutter analyze
```
Fix all errors and warnings.

---

## Verification Checklist

- [ ] `urgency_detector.dart` created
- [ ] `UrgencyDetector.isTaskUrgent()` uses configurable threshold
- [ ] `UrgencyDetector.isProjectUrgent()` uses configurable threshold
- [ ] `UrgencyDetector.findUrgentValuelessTasks()` works correctly
- [ ] `UrgencyDetector.fromSettings()` factory constructor works
- [ ] `AllocationParameters` has `urgentTaskBehavior` field
- [ ] `AllocationParameters` has `taskUrgencyThresholdDays` field
- [ ] `AllocationParameters` has `valueAlignedUrgencyBoost` field
- [ ] Orchestrator creates `UrgencyDetector` from settings
- [ ] Orchestrator handles `UrgentTaskBehavior.ignore` (no warnings)
- [ ] Orchestrator handles `UrgentTaskBehavior.warnOnly` (generates warnings)
- [ ] Orchestrator handles `UrgentTaskBehavior.includeAll` (adds tasks with `isUrgentOverride`)
- [ ] Orchestrator generates `projectDeadlineApproaching` warnings
- [ ] No hardcoded `urgencyThresholdDays = 3` remains in codebase
- [ ] No references to `alwaysIncludeUrgent` remain
- [ ] No references to `showExcludedUrgentWarning` remain
- [ ] `flutter analyze` passes with 0 errors and 0 warnings

---

## Testing Notes

When behavior is implemented correctly:

| Behavior | Value-less Urgent Task | Result |
|----------|----------------------|--------|
| `ignore` | Task with deadline tomorrow, no value | Not in Focus, no warning |
| `warnOnly` | Task with deadline tomorrow, no value | Not in Focus, warning shown |
| `includeAll` | Task with deadline tomorrow, no value | In Focus with `isUrgentOverride = true` |

| Behavior | Task with Value + Urgent | Result |
|----------|-------------------------|--------|
| All modes | Task with deadline tomorrow, has value | In Focus with boosted priority |
