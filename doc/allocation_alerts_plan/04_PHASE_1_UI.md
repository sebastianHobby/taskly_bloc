# Phase 1d: UI Components

> **Status:** Ready for implementation  
> **Depends on:** Phase 1a (Models), Phase 1b (Evaluator), Phase 1c (My Day)  
> **Outputs:** Alert banner widget, Outside Focus section, SectionWidget integration

## Overview

Build the UI components for displaying allocation alerts:
1. **Alert Banner** - Compact notification at top of allocation section
2. **Outside Focus Section** - Full task list at bottom with grouping by alert type
3. **Integration** - Wire into existing SectionWidget allocation rendering

## New Widgets

### 1. `lib/presentation/widgets/allocation_alert_banner.dart`

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';
import 'package:taskly_bloc/domain/models/settings/evaluated_alert.dart';

/// Compact banner showing allocation alert summary.
///
/// Displays count of items outside Focus with severity-based styling.
/// Tapping triggers scroll to Outside Focus section.
class AllocationAlertBanner extends StatelessWidget {
  const AllocationAlertBanner({
    required this.alertResult,
    required this.onReviewTap,
    super.key,
  });

  final AlertEvaluationResult alertResult;
  final VoidCallback onReviewTap;

  @override
  Widget build(BuildContext context) {
    if (!alertResult.hasAlerts) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    
    final severity = alertResult.highestSeverity!;
    final colors = _colorsForSeverity(severity, colorScheme);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onReviewTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  _iconForSeverity(severity),
                  color: colors.foreground,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatMessage(alertResult.totalCount, l10n),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.foreground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  l10n.myDayAlertBannerReview,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  color: colors.foreground,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatMessage(int count, AppLocalizations l10n) {
    if (count == 1) {
      return l10n.myDayAlertBannerSingular;
    }
    return l10n.myDayAlertBannerPlural(count);
  }

  IconData _iconForSeverity(AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.critical => Icons.error_outline,
      AlertSeverity.warning => Icons.warning_amber_outlined,
      AlertSeverity.notice => Icons.info_outline,
    };
  }

  _BannerColors _colorsForSeverity(
    AlertSeverity severity,
    ColorScheme colorScheme,
  ) {
    return switch (severity) {
      AlertSeverity.critical => _BannerColors(
        background: colorScheme.errorContainer,
        foreground: colorScheme.onErrorContainer,
      ),
      AlertSeverity.warning => _BannerColors(
        background: Color.alphaBlend(
          Colors.amber.withOpacity(0.2),
          colorScheme.surface,
        ),
        foreground: Colors.amber.shade800,
      ),
      AlertSeverity.notice => _BannerColors(
        background: colorScheme.primaryContainer,
        foreground: colorScheme.onPrimaryContainer,
      ),
    };
  }
}

class _BannerColors {
  const _BannerColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
```

### 2. `lib/presentation/widgets/outside_focus_section.dart`

```dart
import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_type.dart';
import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';
import 'package:taskly_bloc/domain/models/settings/evaluated_alert.dart';
import 'package:taskly_bloc/domain/models/settings/strategy_settings.dart';
import 'package:taskly_bloc/presentation/widgets/task_list_tile.dart';

/// Section displaying tasks outside Focus, grouped by alert type.
///
/// Shown at bottom of My Day when alerts are triggered.
/// Full task interaction (complete, edit, pin) available.
class OutsideFocusSection extends StatelessWidget {
  const OutsideFocusSection({
    required this.alertResult,
    required this.persona,
    required this.onTaskTap,
    required this.onTaskComplete,
    this.scrollKey,
    super.key,
  });

  final AlertEvaluationResult alertResult;
  final AllocationPersona persona;
  final void Function(ExcludedTask) onTaskTap;
  final void Function(ExcludedTask, bool) onTaskComplete;
  
  /// Key for scroll-to functionality
  final GlobalKey? scrollKey;

  @override
  Widget build(BuildContext context) {
    if (!alertResult.hasAlerts) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Column(
      key: scrollKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        
        // Section header with persona-specific title
        _SectionHeader(
          title: persona.excludedSectionTitle,
          count: alertResult.totalCount,
        ),
        const SizedBox(height: 12),

        // Groups by alert type
        ...alertResult.byType.entries.map((entry) {
          return _AlertTypeGroup(
            alertType: entry.key,
            alerts: entry.value,
            onTaskTap: onTaskTap,
            onTaskComplete: onTaskComplete,
          );
        }),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          Icons.visibility_off_outlined,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _AlertTypeGroup extends StatelessWidget {
  const _AlertTypeGroup({
    required this.alertType,
    required this.alerts,
    required this.onTaskTap,
    required this.onTaskComplete,
  });

  final AllocationAlertType alertType;
  final List<EvaluatedAlert> alerts;
  final void Function(ExcludedTask) onTaskTap;
  final void Function(ExcludedTask, bool) onTaskComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get highest severity in this group for styling
    final severity = alerts
        .map((a) => a.severity)
        .reduce((a, b) => a.sortOrder < b.sortOrder ? a : b);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                _SeverityIndicator(severity: severity),
                const SizedBox(width: 8),
                Text(
                  alertType.displayName,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Task tiles
          ...alerts.map((alert) {
            return _ExcludedTaskTile(
              alert: alert,
              onTap: () => onTaskTap(alert.excludedTask),
              onComplete: (completed) => onTaskComplete(
                alert.excludedTask,
                completed,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SeverityIndicator extends StatelessWidget {
  const _SeverityIndicator({required this.severity});

  final AlertSeverity severity;

  @override
  Widget build(BuildContext context) {
    final color = switch (severity) {
      AlertSeverity.critical => Theme.of(context).colorScheme.error,
      AlertSeverity.warning => Colors.amber.shade700,
      AlertSeverity.notice => Theme.of(context).colorScheme.primary,
    };

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ExcludedTaskTile extends StatelessWidget {
  const _ExcludedTaskTile({
    required this.alert,
    required this.onTap,
    required this.onComplete,
  });

  final EvaluatedAlert alert;
  final VoidCallback onTap;
  final void Function(bool) onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final task = alert.excludedTask.task;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: task.completed,
                  onChanged: (value) => onComplete(value ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 12),
              
              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.completed
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.reason,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _reasonColor(alert.severity, colorScheme),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Chevron
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _reasonColor(AlertSeverity severity, ColorScheme colorScheme) {
    return switch (severity) {
      AlertSeverity.critical => colorScheme.error,
      AlertSeverity.warning => Colors.amber.shade700,
      AlertSeverity.notice => colorScheme.primary,
    };
  }
}
```

## Integration: Update SectionWidget

### File: `lib/presentation/widgets/section_widget.dart`

Add alert banner and outside focus section to allocation rendering.

#### 1. Add scroll key field

```dart
class SectionWidget extends StatefulWidget {
  const SectionWidget({
    required this.section,
    required this.result,
    required this.displayConfig,
    this.persona,  // NEW: for section title
    super.key,
  });

  final Section section;
  final SectionDataResult result;
  final DisplayConfig displayConfig;
  final AllocationPersona? persona;  // NEW
}

class _SectionWidgetState extends State<SectionWidget> {
  final _outsideFocusKey = GlobalKey();  // NEW: for scroll-to
  
  // ...
}
```

#### 2. Update _buildAllocationSection

```dart
Widget _buildAllocationSection(
  BuildContext context,
  AllocationSectionResult result,
) {
  // Existing display mode switch...
  final content = switch (result.displayMode) {
    AllocationDisplayMode.flat => _buildFlatAllocation(context, result),
    AllocationDisplayMode.groupedByValue => _buildGroupedAllocation(
      context,
      result,
    ),
    AllocationDisplayMode.pinnedFirst => _buildPinnedFirstAllocation(
      context,
      result,
    ),
  };

  // NEW: Wrap with banner and outside focus section
  final alertResult = result.alertEvaluationResult;
  final showExcluded = result.showExcludedSection && 
      alertResult != null && 
      alertResult.hasAlerts;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Alert banner (if alerts present)
      if (showExcluded)
        AllocationAlertBanner(
          alertResult: alertResult!,
          onReviewTap: () => _scrollToOutsideFocus(),
        ),
      
      // Main allocation content
      content,
      
      // Outside Focus section (if enabled and has alerts)
      if (showExcluded)
        OutsideFocusSection(
          alertResult: alertResult!,
          persona: widget.persona ?? AllocationPersona.custom,
          onTaskTap: _handleExcludedTaskTap,
          onTaskComplete: _handleExcludedTaskComplete,
          scrollKey: _outsideFocusKey,
        ),
    ],
  );
}
```

#### 3. Add scroll and action handlers

```dart
void _scrollToOutsideFocus() {
  final context = _outsideFocusKey.currentContext;
  if (context != null) {
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

void _handleExcludedTaskTap(ExcludedTask excluded) {
  Routing.toTask(context, excluded.task);
}

void _handleExcludedTaskComplete(ExcludedTask excluded, bool completed) {
  // Dispatch completion event
  context.read<TaskBloc>().add(
    TaskEvent.toggleComplete(taskId: excluded.task.id, completed: completed),
  );
}
```

## Update UnifiedScreenPage

Pass persona to SectionWidget.

### File: `lib/presentation/features/screens/view/unified_screen_page.dart`

```dart
// In _ScreenContent or wherever SectionWidget is built

// Fetch current persona from settings (or provide via ScreenData)
final persona = screenData.allocationPersona; // Add to ScreenData if needed

SectionWidget(
  section: section,
  result: sectionResult,
  displayConfig: displayConfig,
  persona: persona,  // NEW
)
```

### Update ScreenData to include persona

File: `lib/domain/services/screens/screen_data.dart`

```dart
@freezed
abstract class ScreenData with _$ScreenData {
  const factory ScreenData({
    required ScreenDefinition definition,
    required List<SectionDataResult> sectionResults,
    required List<SupportBlockResult> supportBlockResults,
    @Default([]) List<Task> allTasks,
    @Default([]) List<Project> allProjects,
    
    /// Current allocation persona (for My Day section titles)
    AllocationPersona? allocationPersona,  // NEW
  }) = _ScreenData;
}
```

## Tests

### `test/presentation/widgets/allocation_alert_banner_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/presentation/widgets/allocation_alert_banner.dart';
import 'package:taskly_bloc/test/helpers/pump_app.dart';

void main() {
  group('AllocationAlertBanner', () {
    testWidgets('renders nothing when no alerts', (tester) async {
      await tester.pumpApp(
        AllocationAlertBanner(
          alertResult: AlertEvaluationResult.empty,
          onReviewTap: () {},
        ),
      );

      expect(find.byType(AllocationAlertBanner), findsOneWidget);
      expect(find.byType(Material), findsNothing); // SizedBox.shrink
    });

    testWidgets('renders banner with correct count', (tester) async {
      final result = AlertEvaluationResult(
        alerts: [
          EvaluatedAlert(
            type: AllocationAlertType.overdueExcluded,
            severity: AlertSeverity.critical,
            excludedTask: _createExcludedTask(),
            reason: 'Overdue',
          ),
          EvaluatedAlert(
            type: AllocationAlertType.urgentExcluded,
            severity: AlertSeverity.warning,
            excludedTask: _createExcludedTask(),
            reason: 'Urgent',
          ),
        ],
        byType: {},
        bySeverity: {},
      );

      await tester.pumpApp(
        AllocationAlertBanner(
          alertResult: result,
          onReviewTap: () {},
        ),
      );

      expect(find.textContaining('2'), findsOneWidget);
    });

    testWidgets('calls onReviewTap when tapped', (tester) async {
      var tapped = false;
      final result = _createSingleAlertResult();

      await tester.pumpApp(
        AllocationAlertBanner(
          alertResult: result,
          onReviewTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('shows critical styling for critical severity', (tester) async {
      final result = AlertEvaluationResult(
        alerts: [
          EvaluatedAlert(
            type: AllocationAlertType.overdueExcluded,
            severity: AlertSeverity.critical,
            excludedTask: _createExcludedTask(),
            reason: 'Overdue',
          ),
        ],
        byType: {},
        bySeverity: {AlertSeverity.critical: []},
      );

      await tester.pumpApp(
        AllocationAlertBanner(
          alertResult: result,
          onReviewTap: () {},
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}

ExcludedTask _createExcludedTask() {
  return ExcludedTask(
    task: TestData.createTask(name: 'Test'),
    reason: 'Test',
    exclusionType: ExclusionType.lowPriority,
  );
}

AlertEvaluationResult _createSingleAlertResult() {
  return AlertEvaluationResult(
    alerts: [
      EvaluatedAlert(
        type: AllocationAlertType.overdueExcluded,
        severity: AlertSeverity.warning,
        excludedTask: _createExcludedTask(),
        reason: 'Test',
      ),
    ],
    byType: {},
    bySeverity: {},
  );
}
```

### `test/presentation/widgets/outside_focus_section_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/presentation/widgets/outside_focus_section.dart';
import 'package:taskly_bloc/test/helpers/pump_app.dart';

void main() {
  group('OutsideFocusSection', () {
    testWidgets('renders nothing when no alerts', (tester) async {
      await tester.pumpApp(
        OutsideFocusSection(
          alertResult: AlertEvaluationResult.empty,
          persona: AllocationPersona.reflector,
          onTaskTap: (_) {},
          onTaskComplete: (_, __) {},
        ),
      );

      expect(find.byType(OutsideFocusSection), findsOneWidget);
      expect(find.text('Worth Considering'), findsNothing);
    });

    testWidgets('shows persona-specific title', (tester) async {
      final result = _createAlertResult();

      await tester.pumpApp(
        OutsideFocusSection(
          alertResult: result,
          persona: AllocationPersona.firefighter,
          onTaskTap: (_) {},
          onTaskComplete: (_, __) {},
        ),
      );

      expect(find.text('Active Fires'), findsOneWidget);
    });

    testWidgets('groups tasks by alert type', (tester) async {
      final result = _createMultiTypeResult();

      await tester.pumpApp(
        SingleChildScrollView(
          child: OutsideFocusSection(
            alertResult: result,
            persona: AllocationPersona.realist,
            onTaskTap: (_) {},
            onTaskComplete: (_, __) {},
          ),
        ),
      );

      expect(find.text('Overdue tasks'), findsOneWidget);
      expect(find.text('Urgent tasks'), findsOneWidget);
    });

    testWidgets('calls onTaskTap when task tapped', (tester) async {
      ExcludedTask? tappedTask;
      final result = _createAlertResult();

      await tester.pumpApp(
        SingleChildScrollView(
          child: OutsideFocusSection(
            alertResult: result,
            persona: AllocationPersona.custom,
            onTaskTap: (task) => tappedTask = task,
            onTaskComplete: (_, __) {},
          ),
        ),
      );

      await tester.tap(find.byType(Card).first);
      expect(tappedTask, isNotNull);
    });
  });
}

AlertEvaluationResult _createAlertResult() {
  final alert = EvaluatedAlert(
    type: AllocationAlertType.overdueExcluded,
    severity: AlertSeverity.critical,
    excludedTask: ExcludedTask(
      task: TestData.createTask(name: 'Overdue Task'),
      reason: 'Overdue',
      exclusionType: ExclusionType.lowPriority,
    ),
    reason: 'Overdue by 2 days',
  );

  return AlertEvaluationResult(
    alerts: [alert],
    byType: {AllocationAlertType.overdueExcluded: [alert]},
    bySeverity: {AlertSeverity.critical: [alert]},
  );
}

AlertEvaluationResult _createMultiTypeResult() {
  final overdueAlert = EvaluatedAlert(
    type: AllocationAlertType.overdueExcluded,
    severity: AlertSeverity.critical,
    excludedTask: ExcludedTask(
      task: TestData.createTask(name: 'Overdue'),
      reason: 'Overdue',
      exclusionType: ExclusionType.lowPriority,
    ),
    reason: 'Overdue',
  );

  final urgentAlert = EvaluatedAlert(
    type: AllocationAlertType.urgentExcluded,
    severity: AlertSeverity.warning,
    excludedTask: ExcludedTask(
      task: TestData.createTask(name: 'Urgent'),
      reason: 'Urgent',
      exclusionType: ExclusionType.categoryLimitReached,
      isUrgent: true,
    ),
    reason: 'Urgent',
  );

  return AlertEvaluationResult(
    alerts: [overdueAlert, urgentAlert],
    byType: {
      AllocationAlertType.overdueExcluded: [overdueAlert],
      AllocationAlertType.urgentExcluded: [urgentAlert],
    },
    bySeverity: {
      AlertSeverity.critical: [overdueAlert],
      AlertSeverity.warning: [urgentAlert],
    },
  );
}
```

## Accessibility

Ensure proper accessibility:

```dart
// In AllocationAlertBanner
Semantics(
  label: 'Alert: ${alertResult.totalCount} items need attention. '
         'Tap to review.',
  button: true,
  child: // ... existing InkWell
)

// In _ExcludedTaskTile
Semantics(
  label: '${task.name}. ${alert.reason}. '
         '${task.completed ? "Completed" : "Not completed"}',
  child: // ... existing Card
)
```

## AI Implementation Instructions

1. **Create widgets first** - Banner and section are standalone
2. **Test widgets in isolation** - Before integration
3. **Then integrate** - Update SectionWidget carefully
4. **Scroll behavior** - Test on actual device/emulator
5. **Dark mode** - Verify colors work in both themes

## Checklist

- [ ] Create `allocation_alert_banner.dart`
- [ ] Create `outside_focus_section.dart`
- [ ] Update `SectionWidget` with integration
- [ ] Add scroll-to functionality
- [ ] Update `ScreenData` with persona
- [ ] Pass persona through widget tree
- [ ] Add accessibility labels
- [ ] Create banner tests
- [ ] Create section tests
- [ ] Test scroll behavior manually
- [ ] Verify dark mode styling
