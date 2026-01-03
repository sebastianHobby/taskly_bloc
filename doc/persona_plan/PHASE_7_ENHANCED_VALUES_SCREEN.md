# Phase 7: Enhanced Values Screen

> **Status**: Not Started  
> **Effort**: 5-7 days  
> **Dependencies**: Phase 2 (Urgency Unification), Phase 6 (Reflector Mode)

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

### Presentation Layer Rules
- Use BLoC pattern for state management
- Widgets should be stateless where possible
- Use `context.l10n` for all user-facing strings
- Follow Material 3 theming conventions

---

## Objective

Transform the simple values list into a rich dashboard with statistics and trends:
- Show actual % vs target % for each value
- Display gap warnings when significantly off-target (configurable threshold)
- Add drag-to-reorder with auto-weight calculation
- Show trend sparklines (configurable weeks)
- Include "Unassigned Work" section at bottom

---

## Configurable Settings

These settings are defined in `DisplaySettings` (Phase 1) and used by this phase:

| Setting | Range | Default | Description |
|---------|-------|---------|-------------|
| `gapWarningThresholdPercent` | 5-50% | 15% | Show warning icon when actual % differs from target % by this amount |
| `sparklineWeeks` | 2-12 weeks | 4 weeks | Number of weeks to show in trend sparklines |

**Usage**: Read from `AllocationConfig.displaySettings` when building the values screen.

---

## Background

The current values screen is a simple list. Users have requested:
1. **Visibility** into how their time actually aligns with stated values
2. **Trend data** to see if they're improving
3. **Easy reordering** with automatic weight recalculation
4. **Gap warnings** when behavior deviates from intent (now configurable)

---

## Target UI Mockup

```
┌─────────────────────────────────────────┐
│  My Values                    [+ Add]   │
├─────────────────────────────────────────┤
│  ≡ 1. Health                            │
│    Target: 40%  │  Actual: 32%  │ -8%   │
│    ▁▂▃▂▁▃▄▃ (N weeks)                   │  ← N = sparklineWeeks setting
│    12 tasks · 2 projects                │
├─────────────────────────────────────────┤
│  ≡ 2. Work                              │
│    Target: 40%  │  Actual: 48%  │ +8% ⚠ │  ← ⚠ shown when gap >= gapWarningThresholdPercent
│    ▃▄▅▆▅▆▅▄ (N weeks)                   │
│    24 tasks · 5 projects                │
├─────────────────────────────────────────┤
│  ≡ 3. Social                            │
│    Target: 20%  │  Actual: 20%  │  0%   │
│    ▂▂▃▂▂▃▂▂ (N weeks)                   │
│    6 tasks · 1 project                  │
├─────────────────────────────────────────┤
│  Unassigned Work                        │
│    18 tasks · 3 projects     [View →]   │
└─────────────────────────────────────────┘
```

---

## Files to Create

### 1. `lib/presentation/features/labels/widgets/enhanced_value_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:taskly/domain/models/label/value_label.dart';

/// Data class for value statistics.
class ValueStats {
  const ValueStats({
    required this.targetPercent,
    required this.actualPercent,
    required this.taskCount,
    required this.projectCount,
    required this.weeklyTrend,
    this.gapWarningThreshold = 15,
  });

  final double targetPercent;
  final double actualPercent;
  final int taskCount;
  final int projectCount;
  
  /// Weekly completion percentages for sparkline.
  /// Length determined by DisplaySettings.sparklineWeeks.
  final List<double> weeklyTrend;
  
  /// Gap warning threshold from DisplaySettings.gapWarningThresholdPercent.
  /// Range: 5-50%, Default: 15%
  final int gapWarningThreshold;

  double get gap => actualPercent - targetPercent;
  bool get isSignificantGap => gap.abs() >= gapWarningThreshold;
}

/// Enhanced card showing value with statistics.
class EnhancedValueCard extends StatelessWidget {
  const EnhancedValueCard({
    super.key,
    required this.value,
    required this.stats,
    required this.rank,
    required this.onTap,
    required this.onReorder,
  });

  final ValueLabel value;
  final ValueStats stats;
  final int rank;
  final VoidCallback onTap;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with drag handle and rank
              Row(
                children: [
                  ReorderableDragStartListener(
                    index: rank - 1,
                    child: Icon(
                      Icons.drag_handle,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$rank.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (value.color != null)
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Color(value.color!),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      value.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Stats row
              _StatsRow(stats: stats, colorScheme: colorScheme),
              
              const SizedBox(height: 8),
              
              // Sparkline
              _Sparkline(data: stats.weeklyTrend, colorScheme: colorScheme),
              
              const SizedBox(height: 8),
              
              // Activity counts
              Text(
                '${stats.taskCount} tasks · ${stats.projectCount} projects',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.stats,
    required this.colorScheme,
  });

  final ValueStats stats;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = stats.gap;
    final gapColor = stats.isSignificantGap
        ? (gap > 0 ? colorScheme.error : colorScheme.tertiary)
        : colorScheme.onSurfaceVariant;

    return Row(
      children: [
        _StatChip(
          label: 'Target',
          value: '${stats.targetPercent.toStringAsFixed(0)}%',
          colorScheme: colorScheme,
        ),
        const SizedBox(width: 8),
        _StatChip(
          label: 'Actual',
          value: '${stats.actualPercent.toStringAsFixed(0)}%',
          colorScheme: colorScheme,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: stats.isSignificantGap
                ? gapColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${gap >= 0 ? '+' : ''}${gap.toStringAsFixed(0)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: gapColor,
                  fontWeight: stats.isSignificantGap 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                ),
              ),
              if (stats.isSignificantGap) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: gapColor,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({
    required this.data,
    required this.colorScheme,
  });

  final List<double> data;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(height: 24);
    }

    return SizedBox(
      height: 24,
      child: CustomPaint(
        size: const Size(double.infinity, 24),
        painter: _SparklinePainter(
          data: data,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.data,
    required this.color,
  });

  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal;

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = i * size.width / (data.length - 1);
      final normalizedY = range > 0 
          ? (data[i] - minVal) / range 
          : 0.5;
      final y = size.height - (normalizedY * size.height * 0.8 + size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

---

### 2. `lib/presentation/features/labels/widgets/value_detail_modal.dart`

```dart
import 'package:flutter/material.dart';
import 'package:taskly/domain/models/label/value_label.dart';

/// Modal showing detailed statistics for a value.
class ValueDetailModal extends StatelessWidget {
  const ValueDetailModal({
    super.key,
    required this.value,
    required this.stats,
  });

  final ValueLabel value;
  final ValueStats stats;

  static Future<void> show(
    BuildContext context, {
    required ValueLabel value,
    required ValueStats stats,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ValueDetailModal(value: value, stats: stats),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  if (value.color != null)
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Color(value.color!),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    value.name,
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Large trend chart
              _LargeTrendChart(data: stats.weeklyTrend),
              const SizedBox(height: 24),

              // Stats grid
              _StatsGrid(stats: stats),
              const SizedBox(height: 24),

              // Activity breakdown
              _ActivitySection(stats: stats),
            ],
          ),
        );
      },
    );
  }
}

class _LargeTrendChart extends StatelessWidget {
  const _LargeTrendChart({required this.data});

  final List<double> data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '4-Week Trend',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: _SparklinePainter(
                data: data,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final ValueStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _GridItem(label: 'Target', value: '${stats.targetPercent.toStringAsFixed(0)}%')),
        Expanded(child: _GridItem(label: 'Actual', value: '${stats.actualPercent.toStringAsFixed(0)}%')),
        Expanded(child: _GridItem(label: 'Gap', value: '${stats.gap >= 0 ? '+' : ''}${stats.gap.toStringAsFixed(0)}%')),
      ],
    );
  }
}

class _GridItem extends StatelessWidget {
  const _GridItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.stats});

  final ValueStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.task_alt),
          title: Text('${stats.taskCount} active tasks'),
          dense: true,
        ),
        ListTile(
          leading: const Icon(Icons.folder),
          title: Text('${stats.projectCount} projects'),
          dense: true,
        ),
      ],
    );
  }
}
```

---

## Files to Modify

### 3. `lib/domain/services/analytics/analytics_service.dart`

**Add methods:**

```dart
/// Returns completion distribution by value over the last [weeks] weeks.
/// 
/// Returns a map of valueId -> list of weekly completion percentages.
/// Each inner list has [weeks] elements, oldest first.
Future<Map<String, List<double>>> getValueWeeklyTrends({
  required int weeks,
});

/// Returns active task and project counts per value.
Future<Map<String, ValueActivityStats>> getValueActivityStats();
```

**Add supporting class (can be in same file or separate):**

```dart
/// Activity statistics for a single value.
class ValueActivityStats {
  const ValueActivityStats({
    required this.taskCount,
    required this.projectCount,
  });

  final int taskCount;
  final int projectCount;
}
```

---

### 4. `lib/data/features/analytics/services/analytics_service_impl.dart`

**Implement the methods using existing TaskQuery API:**

```dart
@override
Future<Map<String, List<double>>> getValueWeeklyTrends({
  required int weeks,
}) async {
  final trends = <String, List<double>>{};
  final now = DateTime.now();

  for (var i = weeks - 1; i >= 0; i--) {
    final weekStart = now.subtract(Duration(days: (i + 1) * 7));
    final weekEnd = now.subtract(Duration(days: i * 7));

    // Query completed tasks in range using existing TaskQuery API
    final query = TaskQuery(
      filter: QueryFilter<TaskPredicate>(
        shared: [
          const TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isTrue,
          ),
          TaskDatePredicate(
            field: TaskDateField.completedAt,
            operator: DateOperator.between,
            startDate: weekStart,
            endDate: weekEnd,
          ),
        ],
      ),
    );
    final completions = await _taskRepository.queryTasks(query);

    // Count total completions this week
    final totalThisWeek = completions.length;
    if (totalThisWeek == 0) continue;

    // Count per value and calculate percentage
    final valueCounts = <String, int>{};
    for (final task in completions) {
      final valueId = task.valueId;
      if (valueId != null && valueId.isNotEmpty) {
        valueCounts[valueId] = (valueCounts[valueId] ?? 0) + 1;
      }
    }

    for (final entry in valueCounts.entries) {
      trends.putIfAbsent(entry.key, () => List.filled(weeks, 0.0));
      final weekIndex = weeks - 1 - i;
      trends[entry.key]![weekIndex] = entry.value / totalThisWeek * 100;
    }
  }

  return trends;
}

@override
Future<Map<String, ValueActivityStats>> getValueActivityStats() async {
  final stats = <String, ValueActivityStats>{};

  // Get incomplete tasks using TaskQuery
  final taskQuery = TaskQuery(
    filter: const QueryFilter<TaskPredicate>(
      shared: [
        TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isFalse,
        ),
      ],
    ),
  );
  final tasks = await _taskRepository.queryTasks(taskQuery);
  
  final taskCounts = <String, int>{};
  for (final task in tasks) {
    final valueId = task.valueId;
    if (valueId != null && valueId.isNotEmpty) {
      taskCounts[valueId] = (taskCounts[valueId] ?? 0) + 1;
    }
  }

  // Get active projects (implementation depends on project repository API)
  final projects = await _projectRepository.getActiveProjects();
  final projectCounts = <String, int>{};
  for (final project in projects) {
    final valueId = project.valueId;
    if (valueId != null && valueId.isNotEmpty) {
      projectCounts[valueId] = (projectCounts[valueId] ?? 0) + 1;
    }
  }

  // Combine into stats
  final allValueIds = {...taskCounts.keys, ...projectCounts.keys};
  for (final valueId in allValueIds) {
    stats[valueId] = ValueActivityStats(
      taskCount: taskCounts[valueId] ?? 0,
      projectCount: projectCounts[valueId] ?? 0,
    );
  }

  return stats;
}
```

---

### 5. `lib/presentation/features/labels/view/value_overview_view.dart`

**Major rewrite required.** Key changes:

1. **Load statistics** for each value on init
2. **Replace simple list** with `ReorderableListView` of `EnhancedValueCard`
3. **Auto-recalculate weights** when reordered
4. **Add unassigned section** at bottom
5. **Handle card tap** to show detail modal

**Reorder weight calculation (rank-based decay):**

When user drags values to reorder, automatically recalculate weights using a rank-based decay formula. This provides intuitive weighting where higher-ranked values receive proportionally more weight.

```dart
/// Recalculates weights based on position using rank-based decay.
/// 
/// Formula: weight = (n - rank + 1) / (n * (n + 1) / 2)
/// 
/// Example with 5 values:
///   Rank 1: 5/15 = 33.3%
///   Rank 2: 4/15 = 26.7%
///   Rank 3: 3/15 = 20.0%
///   Rank 4: 2/15 = 13.3%
///   Rank 5: 1/15 = 6.7%
/// 
/// This creates a natural decay where top values get significantly more
/// allocation while bottom values still receive some.
void _onReorder(int oldIndex, int newIndex) {
  // Adjust for removal
  if (newIndex > oldIndex) newIndex--;
  
  final values = List<ValueLabel>.from(state.values);
  final item = values.removeAt(oldIndex);
  values.insert(newIndex, item);
  
  // Auto-calculate weights based on position (rank-based decay)
  final n = values.length;
  final triangularNumber = n * (n + 1) ~/ 2; // Sum of 1..n
  
  final updatedValues = <ValueLabel>[];
  for (var i = 0; i < n; i++) {
    final rank = i + 1;
    final weight = (n - rank + 1) / triangularNumber;
    updatedValues.add(values[i].copyWith(
      weight: weight,
      rank: rank,
    ));
  }
  
  // Update state
  context.read<ValuesBloc>().add(ValuesEvent.reordered(updatedValues));
}
```

**Weight distribution examples:**

| Values | Rank 1 | Rank 2 | Rank 3 | Rank 4 | Rank 5 |
|--------|--------|--------|--------|--------|--------|
| 2 | 66.7% | 33.3% | - | - | - |
| 3 | 50.0% | 33.3% | 16.7% | - | - |
| 4 | 40.0% | 30.0% | 20.0% | 10.0% | - |
| 5 | 33.3% | 26.7% | 20.0% | 13.3% | 6.7% |

**Unassigned section:**

```dart
// At bottom of list
Container(
  margin: const EdgeInsets.all(16),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: colorScheme.surfaceContainerHighest,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: colorScheme.outlineVariant),
  ),
  child: Row(
    children: [
      Icon(Icons.inbox, color: colorScheme.onSurfaceVariant),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unassigned Work',
              style: theme.textTheme.titleMedium,
            ),
            Text(
              '$unassignedTaskCount tasks · $unassignedProjectCount projects',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      TextButton(
        onPressed: () => _navigateToUnassigned(context),
        child: const Text('View →'),
      ),
    ],
  ),
);
```

---

## Step-by-Step Implementation

### Step 1: Add analytics methods
1. Add `getValueWeeklyTrends` to analytics service contract
2. Add `getValueActivityStats` to analytics service contract
3. Add `ValueActivityStats` class
4. Implement both methods in analytics service impl

### Step 2: Create EnhancedValueCard widget
Create `lib/presentation/features/labels/widgets/enhanced_value_card.dart`.

### Step 3: Create ValueDetailModal widget
Create `lib/presentation/features/labels/widgets/value_detail_modal.dart`.

### Step 4: Update value overview view
1. Replace list with ReorderableListView
2. Use EnhancedValueCard for each value
3. Load statistics on init
4. Implement reorder handler with weight recalculation
5. Add unassigned section at bottom

### Step 5: Add unassigned count
Query tasks/projects without values for the unassigned section.

### Step 6: Wire up detail modal
On card tap, show ValueDetailModal with stats.

### Step 7: Add localization strings
Add all new UI strings.

### Step 8: Run flutter analyze
```bash
flutter analyze
```
Fix all errors and warnings.

---

## Verification Checklist

- [ ] `getValueWeeklyTrends` method added to analytics contract
- [ ] `getValueWeeklyTrends` implemented correctly
- [ ] `getValueActivityStats` method added to analytics contract
- [ ] `getValueActivityStats` implemented correctly
- [ ] `ValueActivityStats` class created
- [ ] `EnhancedValueCard` widget created
- [ ] Card shows rank, name, color dot
- [ ] Card shows target %, actual %, gap
- [ ] Card shows warning icon for significant gaps (±15%)
- [ ] Card shows sparkline for 4-week trend
- [ ] Card shows task/project counts
- [ ] Cards are draggable for reordering
- [ ] `ValueDetailModal` widget created
- [ ] Modal shows large trend chart
- [ ] Modal shows stats grid
- [ ] Modal shows activity breakdown
- [ ] Value overview uses ReorderableListView
- [ ] Reordering recalculates weights automatically
- [ ] Unassigned section shows at bottom
- [ ] Unassigned section shows counts
- [ ] "View" navigates to unassigned filter
- [ ] Card tap opens detail modal
- [ ] All UI strings use `context.l10n`
- [ ] `flutter analyze` passes with 0 errors and 0 warnings

---

## Weight Calculation Options

### Option A: Linear (Recommended)
Rank 1 = 3x weight of last rank. Simple and predictable.

```
Values: 3
Rank 1: 3/(1+2+3) = 50%
Rank 2: 2/(1+2+3) = 33%
Rank 3: 1/(1+2+3) = 17%
```

### Option B: Equal
All values get equal weight regardless of order.

```
Values: 3
All: 1/3 = 33%
```

### Option C: Exponential
Steep drop-off for lower ranks.

```
Values: 3
Rank 1: 4/(1+2+4) = 57%
Rank 2: 2/(1+2+4) = 29%
Rank 3: 1/(1+2+4) = 14%
```

---

## Edge Cases

| Scenario | Expected Behavior |
|----------|-------------------|
| No values defined | Show empty state with "Add Value" CTA |
| Single value | 100% weight, no reordering |
| No completion history | Sparkline empty, actual = 0% |
| All tasks unassigned | Unassigned section prominent |
| Gap exactly ±15% | Show warning (threshold inclusive) |
| Very long value name | Truncate with ellipsis |

---

## Performance Notes

- Analytics queries may be expensive with large history
- Consider caching `getValueWeeklyTrends` result
- Only reload stats when returning to screen (not every build)
- Sparkline painting is cheap, no optimization needed
- Reorder should save immediately (optimistic UI)
