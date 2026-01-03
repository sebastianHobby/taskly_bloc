# Phase 6: Reflector Mode

> **Status**: Not Started  
> **Effort**: 4-5 days  
> **Dependencies**: Phase 2 (Urgency Unification)

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

### Domain Layer Rules
- Models must be immutable (`@immutable` annotation for non-freezed classes)
- Services should depend on repository contracts, not implementations
- Use constructor injection for dependencies
- Keep business logic in services, not BLoCs

---

## Objective

Implement the "Reflector" allocation mode that prioritizes neglected values:
- Add analytics method to get recent completions by value
- Create `NeglectBasedAllocator` that calculates neglect scores
- Integrate with orchestrator for Reflector persona
- **Support combo mode**: Accept `urgencyBoostMultiplier` for Custom mode combinations
- Values you've been ignoring rise to the top

---

## Background

The Reflector persona helps users maintain balance across their values. It works by:

1. **Looking back** at recent completions (configurable days)
2. **Calculating expected** completions per value based on weights
3. **Comparing actual vs expected** to find neglect
4. **Boosting neglected values** in allocation

**Example:**
- User has 3 values: Health (40%), Work (40%), Social (20%)
- Over last 7 days, completed 10 tasks: 6 Work, 4 Health, 0 Social
- Expected: 4 Work, 4 Health, 2 Social
- Neglect scores: Work -2, Health 0, Social +2
- Result: Social tasks get priority boost

---

## Algorithm

**Single-Pass Per-Task Scoring**: All factors are combined into ONE score per task. No sequential application.

```
// STEP 1: Calculate neglect scores per VALUE (lookup table)
For each value:
  recentCompletions = countCompletions(value, last N days)
  totalRecentCompletions = sum of all values' completions
  expectedShare = valueWeight / totalWeight
  expectedCompletions = totalRecentCompletions * expectedShare
  neglectScore = expectedCompletions - recentCompletions
  // Positive = neglected, Negative = over-represented, Zero = balanced

// STEP 2: Calculate combined score for EACH TASK
For each task:
  // Base score from value weight
  baseScore = task.value.weight / totalWeight
  
  // Neglect factor (from task's value)
  neglectFactor = 1.0 + (normalizedNeglectScore[task.valueId] * neglectInfluence)
  
  // Urgency factor (from task's deadline)
  urgencyFactor = isTaskUrgent(task) ? urgencyBoostMultiplier : 1.0
  
  // COMBINED SCORE (all factors multiplied together)
  task.allocationScore = baseScore * neglectFactor * urgencyFactor

// STEP 3: Sort all tasks by combined score, take top N
allocatedTasks = tasks.sortByScore().take(dailyLimit)
```

**Key principle**: Every task gets a single combined score. No sequential filtering or value-level-then-task-level application.

---

## Files to Create

### 1. `lib/domain/services/allocation/neglect_based_allocator.dart`

```dart
import 'package:taskly/domain/models/settings/allocation_config.dart';
import 'package:taskly/domain/models/task/task.dart';
import 'package:taskly/domain/models/label/value_label.dart';
import 'package:taskly/domain/services/allocation/allocation_strategy.dart';
import 'package:taskly/domain/services/allocation/urgency_detector.dart';

/// Allocator that prioritizes values the user has been neglecting.
/// 
/// Used by the Reflector persona to maintain balance across values.
/// Calculates neglect scores based on recent completion history.
/// 
/// **Combined Scoring**: All factors (value weight, neglect, urgency) are
/// combined into a single score per task. No sequential application.
/// This enables Custom mode combinations like "neglect + urgency".
class NeglectBasedAllocator implements AllocationStrategy {
  const NeglectBasedAllocator({
    required this.analyticsService,
  });

  final AnalyticsService analyticsService;

  @override
  Future<AllocationResult> allocate({
    required List<Task> tasks,
    required List<ValueLabel> values,
    required AllocationParameters parameters,
  }) async {
    if (tasks.isEmpty || values.isEmpty) {
      return AllocationResult(
        allocatedTasks: [],
        warnings: [],
      );
    }

    // Get recent completions by value
    final completionsByValue = await analyticsService.getRecentCompletionsByValue(
      days: parameters.neglectLookbackDays,
    );

    // Calculate neglect scores per value (lookup table)
    final neglectScores = _calculateNeglectScores(
      values: values,
      completionsByValue: completionsByValue,
    );

    // Normalize neglect scores to multiplier range
    final neglectMultipliers = _normalizeNeglectScores(
      neglectScores: neglectScores,
      neglectInfluence: parameters.neglectInfluence,
    );

    // Create urgency detector
    final detector = UrgencyDetector(
      taskThresholdDays: parameters.taskUrgencyThresholdDays,
      projectThresholdDays: parameters.projectUrgencyThresholdDays,
    );

    // Calculate total weight for normalization
    final totalWeight = values.fold(0.0, (sum, v) => sum + v.weight);

    // SINGLE-PASS: Calculate combined score for EACH task
    final scoredTasks = <_ScoredTask>[];
    for (final task in tasks) {
      if (task.valueId == null || task.valueId!.isEmpty) continue;
      
      final value = values.firstWhere(
        (v) => v.id == task.valueId,
        orElse: () => values.first,
      );
      
      // Base score from value weight
      final baseScore = value.weight / totalWeight;
      
      // Neglect factor (from task's value)
      final neglectFactor = neglectMultipliers[task.valueId] ?? 1.0;
      
      // Urgency factor (from task's deadline)
      final urgencyFactor = detector.isTaskUrgent(task) 
          ? parameters.urgencyBoostMultiplier 
          : 1.0;
      
      // COMBINED SCORE: all factors multiplied together
      final combinedScore = baseScore * neglectFactor * urgencyFactor;
      
      scoredTasks.add(_ScoredTask(
        task: task,
        score: combinedScore,
        isUrgent: detector.isTaskUrgent(task),
        isNeglectedValue: (neglectScores[task.valueId] ?? 0) > 0,
      ));
    }

    // Sort by combined score (highest first) and take top N
    scoredTasks.sort((a, b) => b.score.compareTo(a.score));
    final topTasks = scoredTasks.take(parameters.dailyLimit).toList();

    return AllocationResult(
      allocatedTasks: topTasks.map((scored) => AllocatedTask(
        task: scored.task,
        reason: _buildReason(scored),
      )).toList(),
      warnings: [],
    );
  }

  /// Calculate neglect score for each value.
  /// Positive = neglected, Negative = over-represented.
  Map<String, double> _calculateNeglectScores({
    required List<ValueLabel> values,
    required Map<String, int> completionsByValue,
  }) {
    final scores = <String, double>{};
    
    // Total completions across all values
    final totalCompletions = completionsByValue.values.fold(0, (a, b) => a + b);
    if (totalCompletions == 0) {
      // No history, all scores are 0
      for (final value in values) {
        scores[value.id] = 0;
      }
      return scores;
    }

    // Total weight for normalization
    final totalWeight = values.fold(0.0, (sum, v) => sum + v.weight);

    for (final value in values) {
      final actual = completionsByValue[value.id] ?? 0;
      final expectedShare = value.weight / totalWeight;
      final expected = totalCompletions * expectedShare;
      
      // Positive means neglected (expected more than actual)
      scores[value.id] = expected - actual;
    }

    return scores;
  }

  /// Blend base weights with neglect scores.
  /// Returns multiplier values (centered around 1.0) for each value.
  Map<String, double> _normalizeNeglectScores({
    required Map<String, double> neglectScores,
    required double neglectInfluence,
  }) {
    final multipliers = <String, double>{};

    // Find max absolute neglect score for normalization
    final maxNeglect = neglectScores.values
        .map((s) => s.abs())
        .fold(0.0, (a, b) => a > b ? a : b);
    
    if (maxNeglect == 0) {
      // No neglect data, all multipliers = 1.0 (no effect)
      for (final entry in neglectScores.entries) {
        multipliers[entry.key] = 1.0;
      }
      return multipliers;
    }

    for (final entry in neglectScores.entries) {
      // Scale neglect score to -1..+1 range
      final normalizedScore = entry.value / maxNeglect;
      
      // Convert to multiplier: 1.0 + (score * influence)
      // Neglected (positive score) → multiplier > 1.0
      // Over-represented (negative score) → multiplier < 1.0
      multipliers[entry.key] = 1.0 + (normalizedScore * neglectInfluence);
    }

    return multipliers;
  }

  String _buildReason(_ScoredTask scored) {
    if (scored.isUrgent && scored.isNeglectedValue) {
      return 'Urgent + balancing neglected value';
    } else if (scored.isNeglectedValue) {
      return 'Balancing neglected value';
    } else if (scored.isUrgent) {
      return 'Urgent task';
    }
    return 'Value alignment';
  }
}

/// Internal helper class for scoring tasks.
class _ScoredTask {
  const _ScoredTask({
    required this.task,
    required this.score,
    required this.isUrgent,
    required this.isNeglectedValue,
  });

  final Task task;
  final double score;
  final bool isUrgent;
  final bool isNeglectedValue;
}
```

---
    } else if (score < 0) {
      return 'Value alignment';
    }
    return 'Balanced allocation';
  }
}
```

---

## Files to Modify

### 2. `lib/domain/services/analytics/analytics_service.dart`

**Add method to contract:**

```dart
/// Returns count of completed tasks per value over the last [days] days.
/// 
/// Used by Reflector mode to calculate neglect scores.
/// Returns map of valueId -> completion count.
Future<Map<String, int>> getRecentCompletionsByValue({
  required int days,
});
```

---

### 3. `lib/data/features/analytics/services/analytics_service_impl.dart`

**Implement the method using existing TaskQuery API:**

```dart
@override
Future<Map<String, int>> getRecentCompletionsByValue({
  required int days,
}) async {
  final cutoff = DateTime.now().subtract(Duration(days: days));
  
  // Query completed tasks since cutoff using existing TaskQuery API
  final query = TaskQuery(
    filter: QueryFilter<TaskPredicate>(
      shared: [
        const TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isTrue,
        ),
        TaskDatePredicate(
          field: TaskDateField.completedAt,
          operator: DateOperator.onOrAfter,
          date: cutoff,
        ),
      ],
    ),
  );
  final completedTasks = await _taskRepository.queryTasks(query);
  
  // Count by value
  final counts = <String, int>{};
  for (final task in completedTasks) {
    final valueId = task.valueId;
    if (valueId != null && valueId.isNotEmpty) {
      counts[valueId] = (counts[valueId] ?? 0) + 1;
    }
  }
  
  return counts;
}
```

**Note:** Uses existing `TaskQuery` with `TaskDateField.completedAt` predicate. No new repository methods needed.

---

### 4. `lib/domain/services/allocation/allocation_orchestrator.dart`

**Use NeglectBasedAllocator when neglect weighting is enabled:**

The orchestrator should check `config.strategySettings.enableNeglectWeighting` rather than just the persona,
because Custom mode can enable neglect weighting combined with other features.

```dart
// In the orchestration logic
AllocationStrategy _getStrategy(AllocationConfig config) {
  final settings = config.strategySettings;
  
  // Check for neglect weighting first (enables combo mode in Custom)
  if (settings.enableNeglectWeighting) {
    return NeglectBasedAllocator(
      analyticsService: _analyticsService,
    );
  }
  
  // Otherwise use urgency-based or proportional
  if (settings.urgencyBoostMultiplier > 1.0 || 
      settings.urgentTaskBehavior == UrgentTaskBehavior.includeAll) {
    return UrgencyWeightedAllocator();
  }
  
  return ProportionalAllocator();
}
```

**Ensure parameters include all settings:**

```dart
final parameters = AllocationParameters(
  // Base settings
  dailyLimit: config.dailyLimit,
  
  // Urgency settings (for combo mode)
  urgentTaskBehavior: config.strategySettings.urgentTaskBehavior,
  taskUrgencyThresholdDays: config.strategySettings.taskUrgencyThresholdDays,
  projectUrgencyThresholdDays: config.strategySettings.projectUrgencyThresholdDays,
  urgencyBoostMultiplier: config.strategySettings.urgencyBoostMultiplier,
  
  // Neglect settings
  neglectLookbackDays: config.strategySettings.neglectLookbackDays,
  neglectInfluence: config.strategySettings.neglectInfluence,
);
```

---

### 5. `lib/domain/services/allocation/allocation_strategy.dart`

**Add Reflector parameters to AllocationParameters:**

```dart
/// Days to look back for completion history (Reflector mode).
final int reflectorLookbackDays;

/// Weight of neglect score vs base weight (0-1). (Reflector mode).
/// 0 = pure base weight, 1 = pure neglect-based.
final double neglectInfluence;
```

---

## Step-by-Step Implementation

### Step 1: Add analytics method
1. Add `getRecentCompletionsByValue` to analytics service contract
2. Implement in analytics service impl
3. Add repository method if needed (`getCompletedTasksSince`)

### Step 2: Update AllocationParameters
Add `reflectorLookbackDays` and `neglectInfluence` fields.

### Step 3: Create NeglectBasedAllocator
Create `lib/domain/services/allocation/neglect_based_allocator.dart` with full implementation.

### Step 4: Update AllocationOrchestrator
1. Import NeglectBasedAllocator
2. Add strategy selection based on persona
3. Pass Reflector parameters

### Step 5: Test neglect calculation manually
Verify the algorithm works correctly:
- With no history (all scores = 0)
- With balanced history
- With skewed history (some values neglected)

### Step 6: Run flutter analyze
```bash
flutter analyze
```
Fix all errors and warnings.

---

## Verification Checklist

- [ ] `getRecentCompletionsByValue` method added to analytics contract
- [ ] `getRecentCompletionsByValue` implemented in analytics service
- [ ] Method correctly queries completed tasks in date range
- [ ] Method groups by valueId and counts
- [ ] `AllocationParameters` has `neglectLookbackDays` field
- [ ] `AllocationParameters` has `neglectInfluence` field
- [ ] `NeglectBasedAllocator` created
- [ ] Allocator implements `AllocationStrategy` interface
- [ ] `_calculateNeglectScores` returns positive for neglected values
- [ ] `_calculateNeglectScores` returns negative for over-represented values
- [ ] `_calculateNeglectScores` handles zero completions
- [ ] `_calculateEffectiveWeights` blends base weight with neglect
- [ ] `neglectInfluence = 0` uses pure base weights
- [ ] `neglectInfluence = 1` uses pure neglect-based weights
- [ ] **COMBO MODE**: Allocator respects `urgencyBoostMultiplier` parameter
- [ ] **COMBO MODE**: When `urgencyBoostMultiplier > 1.0`, urgent tasks get boosted
- [ ] **COMBO MODE**: Reason text reflects both urgency and neglect when applicable
- [ ] Orchestrator uses NeglectBasedAllocator when `enableNeglectWeighting = true`
- [ ] Orchestrator passes all Reflector parameters including urgency settings
- [ ] Allocation reasons reflect neglect status
- [ ] "Building history" info banner shown when <7 days of data
- [ ] Localization strings added (English + Spanish)
- [ ] `flutter analyze` passes with 0 errors and 0 warnings

---

## "No History" UI Handling

When Reflector mode has insufficient history data, show an informational banner:

### Create: `lib/presentation/features/next_action/widgets/reflector_info_banner.dart`

```dart
/// Banner shown when Reflector mode lacks sufficient history.
class ReflectorInfoBanner extends StatelessWidget {
  const ReflectorInfoBanner({
    super.key,
    required this.completionCount,
    required this.lookbackDays,
  });

  final int completionCount;
  final int lookbackDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insights,
            color: colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reflectorBuildingHistory,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.reflectorHistoryExplanation(completionCount, lookbackDays),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Display Logic

Show banner in Focus screen when:
- `persona == AllocationPersona.reflector`
- Total completions in lookback period < 5

### Localization Strings

**app_en.arb:**
```json
"reflectorBuildingHistory": "Building your history...",
"@reflectorBuildingHistory": {
  "description": "Title for Reflector mode info banner"
},
"reflectorHistoryExplanation": "Reflector works best with more data. You have {count} completions in the last {days} days. Using value weights for now.",
"@reflectorHistoryExplanation": {
  "description": "Explanation for Reflector mode with insufficient history",
  "placeholders": {
    "count": { "type": "int" },
    "days": { "type": "int" }
  }
}
```

**app_es.arb:**
```json
"reflectorBuildingHistory": "Construyendo tu historial...",
"reflectorHistoryExplanation": "Reflector funciona mejor con más datos. Tienes {count} completadas en los últimos {days} días. Usando pesos de valores por ahora."
```

---

## Algorithm Examples

### Example 1: Neglected Social

**Setup:**
- Values: Health (40%), Work (40%), Social (20%)
- Last 7 days: 6 Work, 4 Health, 0 Social (10 total)

**Calculation:**
```
Expected (based on weights):
  Health: 10 * 0.4 = 4
  Work:   10 * 0.4 = 4
  Social: 10 * 0.2 = 2

Neglect scores (expected - actual):
  Health: 4 - 4 = 0  (balanced)
  Work:   4 - 6 = -2 (over-represented)
  Social: 2 - 0 = +2 (NEGLECTED)

With neglectInfluence = 0.7:
  Social gets significant boost
  Work gets reduced
  Health stays similar
```

### Example 2: Fresh Start (No History)

**Setup:**
- Values: A (50%), B (30%), C (20%)
- Last 7 days: 0 completions

**Calculation:**
```
All neglect scores = 0
Effective weights = base weights
Allocation is purely proportional
```

### Example 3: Perfectly Balanced

**Setup:**
- Values: A (50%), B (30%), C (20%)
- Last 7 days: 5 A, 3 B, 2 C (10 total, matches weights)

**Calculation:**
```
Expected: A=5, B=3, C=2
Actual:   A=5, B=3, C=2
Neglect scores: all 0
Effective weights = base weights
```

### Example 4: Combo Mode (Neglect + Urgency) - Per-Task Scoring

**Setup (Custom mode with both features enabled):**
- Values: Health (40%), Work (40%), Social (20%)
- Last 7 days: 6 Work, 4 Health, 0 Social (Social neglected)
- `enableNeglectWeighting = true`
- `urgencyBoostMultiplier = 1.5`
- Tasks:
  - Task A: Social value, no deadline
  - Task B: Work value, deadline in 2 days (urgent)
  - Task C: Health value, no deadline

**Calculation (per-task combined scoring):**
```
Step 1: Calculate neglect multipliers (per value)
  maxNeglect = 2
  Health: 1.0 + (0/2 * 0.7) = 1.0   (balanced)
  Work:   1.0 + (-2/2 * 0.7) = 0.3  (over-represented, penalized)
  Social: 1.0 + (2/2 * 0.7) = 1.7   (neglected, boosted)

Step 2: Calculate combined score for EACH task
  Task A (Social, not urgent):
    baseScore = 0.2
    neglectFactor = 1.7
    urgencyFactor = 1.0
    combinedScore = 0.2 * 1.7 * 1.0 = 0.34

  Task B (Work, urgent):
    baseScore = 0.4
    neglectFactor = 0.3
    urgencyFactor = 1.5  ← urgency boost applied!
    combinedScore = 0.4 * 0.3 * 1.5 = 0.18

  Task C (Health, not urgent):
    baseScore = 0.4
    neglectFactor = 1.0
    urgencyFactor = 1.0
    combinedScore = 0.4 * 1.0 * 1.0 = 0.40

Step 3: Sort by score, take top N
  Ranked: C (0.40) > A (0.34) > B (0.18)
```

**Result**: Health task ranks highest (balanced value, high weight), Social task second (neglect boost overcomes low weight), Work urgent task third (urgency boost partially compensates for over-representation penalty).

**Key insight**: All factors multiply together PER TASK. Urgency helps individual tasks compete, but doesn't override value-level neglect completely.

---

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| No completion history | Use base weights only |
| Only one value has tasks | That value gets all slots |
| All values equally neglected | Use base weights |
| `neglectInfluence = 0` | Pure proportional allocation |
| `neglectInfluence = 1` | Pure neglect-based allocation |
| New value (no history) | Treated as neglected |
| Deleted value in history | Ignored (no matching tasks) |

---

## Performance Notes

- `getRecentCompletionsByValue` may be expensive with large history
- Consider caching results for the session
- Lookback period should be reasonable (7-30 days)
- Very long lookback diminishes "recent" behavior detection
