# Phase 3B: SupportBlock Integration

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each phase/subphase. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files - do not fix errors for compilation of tests.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

---

## Goal

Update `SupportBlockComputer` to handle new block variants and integrate with problem detection.

**Decisions Implemented**: DR-018, DR-019

---

## Prerequisites

- Phase 3A complete (SupportBlock enhanced)
- Existing `SupportBlockComputer` class exists

---

## Task 1: Locate Existing SupportBlockComputer

Search for the existing implementation:

```bash
# Find the file (for reference)
grep -r "SupportBlockComputer" lib/
```

Expected location: `lib/domain/services/support_block_computer.dart` or similar.

---

## Task 2: Add ProblemSummaryBlock Handler

Update `SupportBlockComputer` to handle the new `ProblemSummaryBlock`:

```dart
// In the compute method, add handling for ProblemSummaryBlock:

SupportBlockResult computeProblemSummary(
  ProblemSummaryBlock block,
  List<Task> tasks,
  List<Project> projects,
) {
  // Get problems from ProblemDetectionService
  final allProblems = _problemDetectionService.detectProblems(
    tasks: tasks,
    projects: projects,
  );

  // Filter by problem types if specified
  final filteredProblems = block.problemTypes != null
      ? allProblems.where((p) => block.problemTypes!.contains(p.type)).toList()
      : allProblems;

  return SupportBlockResult.problemSummary(
    problems: filteredProblems,
    showCount: block.showCount,
    showList: block.showList,
    maxListItems: block.maxListItems,
    title: block.title ?? 'Issues',
  );
}
```

---

## Task 3: Create SupportBlockResult Type

If not already exists, create a result type:

**File**: `lib/domain/services/support_block_result.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/problem.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';

part 'support_block_result.freezed.dart';

/// Result of computing a support block's data
@freezed
sealed class SupportBlockResult with _$SupportBlockResult {
  /// Result for WorkflowProgressBlock
  const factory SupportBlockResult.workflowProgress({
    required int currentStep,
    required int totalSteps,
    required String currentStepName,
    required double progressPercent,
  }) = WorkflowProgressResult;

  /// Result for QuickActionsBlock
  const factory SupportBlockResult.quickActions({
    required List<QuickAction> actions,
  }) = QuickActionsResult;

  /// Result for ContextSummaryBlock
  const factory SupportBlockResult.contextSummary({
    required String title,
    String? description,
    Map<String, String>? metadata,
  }) = ContextSummaryResult;

  /// Result for RelatedEntitiesBlock
  const factory SupportBlockResult.relatedEntities({
    required List<RelatedEntityInfo> entities,
    required int totalCount,
  }) = RelatedEntitiesResult;

  /// Result for StatsBlock
  const factory SupportBlockResult.stats({
    required List<ComputedStat> stats,
  }) = StatsResult;

  /// Result for ProblemSummaryBlock (DR-018)
  const factory SupportBlockResult.problemSummary({
    required List<Problem> problems,
    required bool showCount,
    required bool showList,
    required int maxListItems,
    required String title,
  }) = ProblemSummaryResult;

  /// Result for EmptyStateBlock
  const factory SupportBlockResult.emptyState({
    required String message,
    String? icon,
    String? actionLabel,
    String? actionRoute,
  }) = EmptyStateResult;
}

/// Information about a related entity
@freezed
class RelatedEntityInfo with _$RelatedEntityInfo {
  const factory RelatedEntityInfo({
    required String id,
    required String name,
    required String entityType,
    String? route,
  }) = _RelatedEntityInfo;
}

/// A computed statistic
@freezed
class ComputedStat with _$ComputedStat {
  const factory ComputedStat({
    required String label,
    required String value,
    String? icon,
    String? trend,
  }) = _ComputedStat;
}
```

---

## Task 4: Update SupportBlockComputer Main Logic

**File**: `lib/domain/services/support_block_computer.dart`

Ensure the main `compute` method handles all block types:

```dart
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/services/support_block_result.dart';
import 'package:taskly_bloc/domain/services/problem_detection_service.dart';

class SupportBlockComputer {
  final ProblemDetectionService _problemDetectionService;

  SupportBlockComputer({
    required ProblemDetectionService problemDetectionService,
  }) : _problemDetectionService = problemDetectionService;

  /// Compute result for a support block
  SupportBlockResult compute(
    SupportBlock block, {
    required List<Task> tasks,
    required List<Project> projects,
    WorkflowRun? workflowRun,
  }) {
    return switch (block) {
      WorkflowProgressBlock() => _computeWorkflowProgress(
          block,
          workflowRun,
        ),
      QuickActionsBlock(:final actions) => SupportBlockResult.quickActions(
          actions: actions,
        ),
      ContextSummaryBlock() => _computeContextSummary(block, projects),
      RelatedEntitiesBlock() => _computeRelatedEntities(block, tasks, projects),
      StatsBlock() => _computeStats(block, tasks, projects),
      ProblemSummaryBlock() => _computeProblemSummary(block, tasks, projects),
      EmptyStateBlock(:final message, :final icon, :final actionLabel, :final actionRoute) =>
          SupportBlockResult.emptyState(
        message: message,
        icon: icon,
        actionLabel: actionLabel,
        actionRoute: actionRoute,
      ),
    };
  }

  SupportBlockResult _computeProblemSummary(
    ProblemSummaryBlock block,
    List<Task> tasks,
    List<Project> projects,
  ) {
    final allProblems = _problemDetectionService.detectProblems(
      tasks: tasks,
      projects: projects,
    );

    final filteredProblems = block.problemTypes != null
        ? allProblems.where((p) => block.problemTypes!.contains(p.type)).toList()
        : allProblems;

    return SupportBlockResult.problemSummary(
      problems: filteredProblems,
      showCount: block.showCount,
      showList: block.showList,
      maxListItems: block.maxListItems,
      title: block.title ?? 'Issues',
    );
  }

  // ... other compute methods
}
```

---

## Task 5: Ensure ProblemDetectionService Exists

Verify that `ProblemDetectionService` exists and has the `detectProblems` method.

If it doesn't exist, create a stub:

**File**: `lib/domain/services/problem_detection_service.dart`

```dart
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/problem.dart';

/// Service for detecting problems in tasks and projects
class ProblemDetectionService {
  /// Detect problems in the given entities
  List<Problem> detectProblems({
    required List<Task> tasks,
    required List<Project> projects,
  }) {
    final problems = <Problem>[];

    // Detect overdue tasks
    final now = DateTime.now();
    for (final task in tasks) {
      if (task.deadlineDate != null &&
          task.deadlineDate!.isBefore(now) &&
          !task.isCompleted) {
        problems.add(Problem(
          type: 'overdue',
          entityId: task.id,
          entityType: 'task',
          message: 'Task "${task.title}" is overdue',
          severity: ProblemSeverity.warning,
        ));
      }
    }

    // Add more detection rules as needed

    return problems;
  }
}
```

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] `SupportBlockComputer` handles all `SupportBlock` variants
- [ ] `SupportBlockResult` has all result types
- [ ] `ProblemSummaryBlock` computes correctly
- [ ] Pattern matching is exhaustive (no missing cases)

---

## Files Created/Modified

| File | Change |
|------|--------|
| `lib/domain/services/support_block_result.dart` | Create if not exists |
| `lib/domain/services/support_block_computer.dart` | Update with new handlers |
| `lib/domain/services/problem_detection_service.dart` | Create if not exists |

---

## Next Phase

Proceed to **Phase 4A: Data Fetching - Service** after validation passes.
