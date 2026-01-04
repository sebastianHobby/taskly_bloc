# Phase 1c: My Day Screen Definition

> **Status:** Ready for implementation  
> **Depends on:** Phase 1a (Models), Phase 1b (Evaluator)  
> **Outputs:** My Day screen definition, removal of today/next_actions

## Overview

Create unified `my_day` screen definition and remove the legacy `today` and `next_actions` screens. This consolidates two navigation destinations into one.

## Changes to SystemScreenDefinitions

### File: `lib/domain/models/screens/system_screen_definitions.dart`

#### 1. Add My Day Definition

```dart
/// My Day screen - unified Focus view with allocation alerts
///
/// Replaces both Today and Next Actions screens.
/// Shows persona-driven allocation with alert banners for excluded tasks.
static final myDay = ScreenDefinition.dataDriven(
  id: 'my_day',
  screenKey: 'my_day',
  name: 'My Day',
  screenType: ScreenType.focus,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
  screenSource: ScreenSource.systemTemplate,
  category: ScreenCategory.workspace,
  sections: [
    const Section.allocation(
      displayMode: AllocationDisplayMode.pinnedFirst,
      showExcludedWarnings: true,
      showExcludedSection: true,  // NEW: enables bottom section
    ),
  ],
  // Note: No supportBlocks - alerts are handled within allocation section
);
```

#### 2. Remove Today Definition

Delete:
```dart
/// Today screen - tasks due/starting today
static final today = ScreenDefinition.dataDriven(
  // ... entire definition
);
```

#### 3. Remove Next Actions Definition

Delete:
```dart
/// Next Actions / Focus screen - allocated tasks
static final nextActions = ScreenDefinition.dataDriven(
  // ... entire definition
);
```

#### 4. Update `all` List

Change from:
```dart
static List<ScreenDefinition> get all => [
  inbox,
  today,       // REMOVE
  upcoming,
  logbook,
  projects,
  labels,
  values,
  nextActions, // REMOVE
  // Navigation-only screens
  settings,
  wellbeing,
  workflows,
  screenManagement,
];
```

To:
```dart
static List<ScreenDefinition> get all => [
  inbox,
  myDay,       // ADD
  upcoming,
  logbook,
  projects,
  labels,
  values,
  // Navigation-only screens
  settings,
  wellbeing,
  workflows,
  screenManagement,
];
```

#### 5. Update `getByKey` Switch

Change from:
```dart
static ScreenDefinition? getByKey(String screenKey) {
  return switch (screenKey) {
    'inbox' => inbox,
    'today' => today,             // REMOVE
    'upcoming' => upcoming,
    'logbook' => logbook,
    'projects' => projects,
    'labels' => labels,
    'values' => values,
    'next_actions' => nextActions, // REMOVE
    'orphan_tasks' => orphanTasks,
    'settings' => settings,
    'wellbeing' => wellbeing,
    'workflows' => workflows,
    'screen_management' => screenManagement,
    _ => null,
  };
}
```

To:
```dart
static ScreenDefinition? getByKey(String screenKey) {
  return switch (screenKey) {
    'inbox' => inbox,
    'my_day' => myDay,            // ADD
    'upcoming' => upcoming,
    'logbook' => logbook,
    'projects' => projects,
    'labels' => labels,
    'values' => values,
    'orphan_tasks' => orphanTasks,
    'settings' => settings,
    'wellbeing' => wellbeing,
    'workflows' => workflows,
    'screen_management' => screenManagement,
    _ => null,
  };
}
```

#### 6. Update `defaultSortOrders`

Change from:
```dart
static const Map<String, int> defaultSortOrders = {
  'inbox': 0,
  'today': 1,           // REMOVE
  'upcoming': 2,
  'logbook': 3,
  'next_actions': 4,    // REMOVE
  'projects': 5,
  'labels': 6,
  'values': 7,
  'orphan_tasks': 8,
  'settings': 100,
  'wellbeing': 101,
  'workflows': 102,
  'screen_management': 103,
};
```

To:
```dart
static const Map<String, int> defaultSortOrders = {
  'inbox': 0,
  'my_day': 1,          // ADD (takes today's position)
  'upcoming': 2,
  'logbook': 3,
  'projects': 4,        // Renumber
  'labels': 5,
  'values': 6,
  'orphan_tasks': 7,
  'settings': 100,
  'wellbeing': 101,
  'workflows': 102,
  'screen_management': 103,
};
```

## Update Section.allocation Model

### File: `lib/domain/models/screens/section.dart`

Add new field to allocation section:

```dart
/// Allocation section (Focus/Next Actions - uses AllocationOrchestrator)
@FreezedUnionValue('allocation')
const factory Section.allocation({
  /// Source filter for allocation (optional - defaults to all tasks)
  @NullableTaskQueryConverter() TaskQuery? sourceFilter,

  /// Max tasks to allocate (overrides global setting if set)
  int? maxTasks,

  /// Display mode for allocation results (DR-021)
  @Default(AllocationDisplayMode.pinnedFirst)
  AllocationDisplayMode displayMode,

  /// Whether to show excluded task warnings (legacy - use showExcludedSection)
  @Default(true) bool showExcludedWarnings,

  /// NEW: Whether to show the "Outside Focus" section at bottom
  /// When true, excluded tasks matching alert config are shown
  /// in a scrollable section below the Focus tasks.
  @Default(false) bool showExcludedSection,

  /// Optional section title
  String? title,
}) = AllocationSection;
```

## Update AllocationSectionResult

### File: `lib/domain/services/screens/section_data_result.dart`

Add alert evaluation result:

```dart
/// Allocation section result - tasks allocated for focus/next actions
const factory SectionDataResult.allocation({
  /// All allocated tasks (flat list for backward compatibility)
  required List<Task> allocatedTasks,

  /// Total tasks available for allocation (before filtering)
  required int totalAvailable,

  /// Pinned tasks (shown first, regardless of value)
  @Default([]) List<AllocatedTask> pinnedTasks,

  /// Tasks grouped by their qualifying value
  @Default({}) Map<String, AllocationValueGroup> tasksByValue,

  /// Reasoning behind allocation decisions
  AllocationReasoning? reasoning,

  /// Count of tasks excluded from allocation
  @Default(0) int excludedCount,

  /// Urgent tasks that were excluded from allocation
  @Default([]) List<ExcludedTask> excludedUrgentTasks,

  /// NEW: Full list of excluded tasks (for Outside Focus section)
  @Default([]) List<ExcludedTask> excludedTasks,

  /// NEW: Evaluated alerts based on user's alert config
  AlertEvaluationResult? alertEvaluationResult,

  /// Display mode for this allocation section
  @Default(AllocationDisplayMode.pinnedFirst)
  AllocationDisplayMode displayMode,

  /// NEW: Whether to show excluded section
  @Default(false) bool showExcludedSection,

  /// True if allocation cannot proceed because user has no values defined.
  @Default(false) bool requiresValueSetup,
}) = AllocationSectionResult;
```

## Update SectionDataService

### File: `lib/domain/services/screens/section_data_service.dart`

Modify the allocation section builder to include alert evaluation:

```dart
Future<AllocationSectionResult> _buildAllocationSection(
  AllocationSection section,
  // ... existing params
) async {
  // ... existing allocation logic ...
  
  final allocationResult = await _allocationOrchestrator.allocate(
    tasks: eligibleTasks,
    config: allocationConfig,
  );

  // NEW: Evaluate alerts if section wants excluded section
  AlertEvaluationResult? alertResult;
  if (section.showExcludedSection) {
    final alertSettings = await _settingsRepository.load(
      SettingsKey.allocationAlerts,
    );
    alertResult = _alertEvaluator.evaluate(
      excludedTasks: allocationResult.excludedTasks,
      config: alertSettings.config,
    );
  }

  return AllocationSectionResult(
    allocatedTasks: allocationResult.allocatedTasks.map((a) => a.task).toList(),
    totalAvailable: eligibleTasks.length,
    pinnedTasks: pinnedAllocatedTasks,
    tasksByValue: groupedByValue,
    reasoning: allocationResult.reasoning,
    excludedCount: allocationResult.excludedTasks.length,
    excludedUrgentTasks: allocationResult.excludedTasks
        .where((e) => e.isUrgent == true)
        .toList(),
    excludedTasks: allocationResult.excludedTasks,  // NEW
    alertEvaluationResult: alertResult,              // NEW
    displayMode: section.displayMode,
    showExcludedSection: section.showExcludedSection, // NEW
    requiresValueSetup: allocationResult.requiresValueSetup,
  );
}
```

## Persona-Named Section Titles

For the "Outside Focus" section, we need persona-specific names.

### Add to `lib/domain/models/settings/strategy_settings.dart`

Add extension method:

```dart
extension AllocationPersonaX on AllocationPersona {
  // ... existing methods ...

  /// Section title for excluded tasks in My Day view
  String get excludedSectionTitle => switch (this) {
    AllocationPersona.idealist => 'Needs Alignment',
    AllocationPersona.reflector => 'Worth Considering',
    AllocationPersona.realist => 'Overdue Attention',
    AllocationPersona.firefighter => 'Active Fires',
    AllocationPersona.custom => 'Outside Focus',
  };
}
```

## Localization

### Add to `lib/core/l10n/arb/app_en.arb`

```json
{
  "myDayTitle": "My Day",
  "@myDayTitle": {
    "description": "Title for the My Day screen"
  },
  "myDayAlertBannerSingular": "1 item outside Focus",
  "@myDayAlertBannerSingular": {
    "description": "Alert banner text for single item"
  },
  "myDayAlertBannerPlural": "{count} items outside Focus",
  "@myDayAlertBannerPlural": {
    "description": "Alert banner text for multiple items",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },
  "myDayAlertBannerReview": "Review",
  "@myDayAlertBannerReview": {
    "description": "Button text to review excluded items"
  },
  "excludedSectionNeedsAlignment": "Needs Alignment",
  "excludedSectionWorthConsidering": "Worth Considering", 
  "excludedSectionOverdueAttention": "Overdue Attention",
  "excludedSectionActiveFires": "Active Fires",
  "excludedSectionOutsideFocus": "Outside Focus"
}
```

## Tests

### Update `test/domain/models/screens/system_screen_definitions_test.dart`

```dart
group('SystemScreenDefinitions', () {
  test('myDay is defined correctly', () {
    final myDay = SystemScreenDefinitions.myDay;
    
    expect(myDay.screenKey, 'my_day');
    expect(myDay.name, 'My Day');
    expect(myDay.screenType, ScreenType.focus);
    expect(myDay.sections.length, 1);
    expect(myDay.sections.first, isA<AllocationSection>());
    
    final section = myDay.sections.first as AllocationSection;
    expect(section.showExcludedSection, isTrue);
  });

  test('today is no longer defined', () {
    expect(SystemScreenDefinitions.getByKey('today'), isNull);
  });

  test('next_actions is no longer defined', () {
    expect(SystemScreenDefinitions.getByKey('next_actions'), isNull);
  });

  test('all list contains myDay', () {
    expect(
      SystemScreenDefinitions.all.map((s) => s.screenKey),
      contains('my_day'),
    );
  });

  test('all list does not contain today or next_actions', () {
    final keys = SystemScreenDefinitions.all.map((s) => s.screenKey).toList();
    expect(keys, isNot(contains('today')));
    expect(keys, isNot(contains('next_actions')));
  });

  test('defaultSortOrders has myDay at position 1', () {
    expect(SystemScreenDefinitions.defaultSortOrders['my_day'], 1);
  });
});
```

### Update fixture references

Search and update any test files that reference `'today'` or `'next_actions'` screen keys.

## Migration Considerations

### User Screen Preferences

If users have customized visibility/order for `today` or `next_actions`, those preferences become orphaned. Options:

1. **Ignore** - Orphaned prefs don't cause issues, just unused
2. **Migrate** - Write migration to copy `next_actions` prefs to `my_day`
3. **Reset** - New screen gets default prefs

**Recommendation:** Option 1 (ignore) for Phase 1. The orphaned data is harmless and will be cleaned up naturally if user adjusts prefs.

### Navigation Badges

If `NavigationBadgeService` has special handling for `today` or `next_actions`, update to `my_day`:

```dart
// Check NavigationBadgeService for any screen-specific badge logic
Stream<int?> badgeStreamFor(ScreenDefinition screen) {
  return switch (screen.screenKey) {
    'my_day' => _myDayBadgeStream(),  // If needed
    // ...
  };
}
```

## AI Implementation Instructions

1. **Order matters:**
   - Update Section model first (add showExcludedSection)
   - Update SectionDataResult second (add new fields)
   - Update SystemScreenDefinitions last

2. **Run build_runner** after each freezed model change

3. **Search for references:**
   ```bash
   grep -r "today" lib/ test/ --include="*.dart" | grep -v "calendar_today"
   grep -r "next_actions" lib/ test/ --include="*.dart"
   grep -r "nextActions" lib/ test/ --include="*.dart"
   ```

4. **Don't forget localization** - Add ARB entries

5. **Test incrementally** - Run tests after each major change

## Checklist

- [ ] Update `Section.allocation` with `showExcludedSection` field
- [ ] Run build_runner
- [ ] Update `AllocationSectionResult` with new fields
- [ ] Run build_runner
- [ ] Update `SectionDataService` to populate new fields
- [ ] Add `myDay` to `SystemScreenDefinitions`
- [ ] Remove `today` from `SystemScreenDefinitions`
- [ ] Remove `nextActions` from `SystemScreenDefinitions`
- [ ] Update `all`, `getByKey`, `defaultSortOrders`
- [ ] Add persona extension for section titles
- [ ] Add localization strings
- [ ] Update/add tests
- [ ] Search and update any remaining references
