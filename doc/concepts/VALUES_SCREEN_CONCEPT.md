# Values Screen Concept Exploration

> **Status**: Concept / UX Exploration  
> **Created**: 2026-01-03  
> **Related Features**: Allocation, Wellbeing, Focus Screen

---

## Overview

Taskly's core philosophy is helping users **align their values with what they do**. This document explores an enhanced Values screen that:

1. Replaces the current simple values list
2. Shows users the gap between **stated priorities** and **actual work**
3. Serves as a **prerequisite gateway** for allocation features

---

## Problem Statement

Currently:
- Values are just labels with ranking weights
- Users can't see if their actual work matches their stated priorities
- Allocation features work without values, missing the core purpose
- No connection between values and wellbeing insights

---

## Proposed Solution: Enhanced Values Screen

### Mockup: My Values Screen

```
╔═══════════════════════════════════════════════════════════╗
║                    MY VALUES                               ║
║              (These guide your task allocation)            ║
╠═══════════════════════════════════════════════════════════╣
║                                                            ║
║  Drag to reorder priority • Weights auto-calculated        ║
║                                                            ║
║  ┌─────────────────────────────────────────────────┐      ║
║  │ 1. 🏃 Health & Wellness              Weight: 10 │      ║
║  │    ═════════════════════════════════════════    │      ║
║  │    Tasks: 12 active • Projects: 3               │      ║
║  │    📊 Last 30 days: 18% of completed work       │      ║
║  │    🎯 Target: ~30% (based on #1 ranking)        │      ║
║  └─────────────────────────────────────────────────┘      ║
║                                                            ║
║  ┌─────────────────────────────────────────────────┐      ║
║  │ 2. 👨‍👩‍👧 Family & Relationships         Weight: 9  │      ║
║  │    ════════════════════════════════════════     │      ║
║  │    Tasks: 8 active • Projects: 2                │      ║
║  │    📊 Last 30 days: 22% of completed work       │      ║
║  │    🎯 Target: ~25%                              │      ║
║  └─────────────────────────────────────────────────┘      ║
║                                                            ║
║  ┌─────────────────────────────────────────────────┐      ║
║  │ 3. 💼 Career Growth                  Weight: 8  │      ║
║  │    ═══════════════════════════════════════      │      ║
║  │    Tasks: 24 active • Projects: 5               │      ║
║  │    📊 Last 30 days: 45% of completed work  ⚠️   │      ║
║  │    🎯 Target: ~22%                              │      ║
║  │    ────────────────────────────────────────     │      ║
║  │    ⚠️ Over-indexing: 2x your intended focus    │      ║
║  └─────────────────────────────────────────────────┘      ║
║                                                            ║
║  ┌─────────────────────────────────────────────────┐      ║
║  │ 4. 📚 Learning                       Weight: 7  │      ║
║  │    ═════════════════════════════════════        │      ║
║  │    Tasks: 5 active • Projects: 1                │      ║
║  │    📊 Last 30 days: 8% of completed work        │      ║
║  │    🎯 Target: ~15%                              │      ║
║  └─────────────────────────────────────────────────┘      ║
║                                                            ║
║  ── Unassigned Work ──────────────────────────────        ║
║  📊 Last 30 days: 7% of completed work                    ║
║  💡 Consider assigning values to these tasks              ║
║                                                            ║
║              [ + Add Value ]        [ See Details ]        ║
╚═══════════════════════════════════════════════════════════╝
```

### Key Features

| Feature | Description |
|---------|-------------|
| **Ranking Order** | Drag to reorder; weights auto-calculated (10, 9, 8...) |
| **Active Count** | Shows tasks + projects currently assigned to this value |
| **Actual %** | Percentage of completed work (last 30 days) with this value |
| **Target %** | Expected % based on ranking position and weight |
| **Gap Warning** | Visual indicator when actual diverges significantly from target |
| **Unassigned Section** | Shows work not tied to any value (opportunity to assign) |

### Target % Calculation

```dart
// Simplified: weight / sum(all weights) * 100
// With 4 values ranked 10, 9, 8, 7:
// Total = 34
// Health (10): 10/34 = 29.4% → ~30%
// Family (9):  9/34 = 26.5%  → ~25%
// Career (8):  8/34 = 23.5%  → ~22%
// Learning (7): 7/34 = 20.6% → ~15% (rounded display)
```

### Gap Detection Thresholds

| Gap | Indicator | Tone |
|-----|-----------|------|
| Within ±5% | None | On track |
| ±5-15% | Subtle ↑↓ arrow | Gentle awareness |
| >15% | ⚠️ Warning | "Over/under-indexing" |

---

## Allocation Integration: Values as Prerequisite

### Problem

Currently, users can access Focus/Allocation screens without defining any values. This defeats the purpose of values-based allocation.

### Proposal: Redirect to Values Screen

When a user navigates to **Focus** or **Allocation Settings** with **zero values defined**:

```
╔═══════════════════════════════════════════════════════════╗
║  🎯 FOCUS                                                  ║
╠═══════════════════════════════════════════════════════════╣
║                                                            ║
║                                                            ║
║                    ┌─────────────────┐                    ║
║                    │       💎        │                    ║
║                    └─────────────────┘                    ║
║                                                            ║
║              Define Your Values First                      ║
║                                                            ║
║     Taskly's Focus view allocates tasks based on          ║
║     what matters most to you.                             ║
║                                                            ║
║     To get started, define 2-5 values that represent      ║
║     the areas of life you want to prioritize:             ║
║                                                            ║
║     Examples: Health, Family, Career, Learning,           ║
║               Creativity, Finances, Community             ║
║                                                            ║
║                                                            ║
║              [ Set Up My Values ]                          ║
║                                                            ║
║     ─────────────────────────────────────────────         ║
║     Or use Focus without values:                          ║
║     [ Show all tasks by deadline only ]                   ║
║                                                            ║
╚═══════════════════════════════════════════════════════════╝
```

### Implementation Options

#### Option A: Hard Gate (Recommended)

- Focus screen **requires** at least 1 value
- Redirect to Values screen with onboarding message
- Clear "skip" option for deadline-only mode

```dart
// In AllocationOrchestrator or FocusScreenBloc
if (valueLabels.isEmpty) {
  return AllocationResult.noValuesConfigured(
    fallbackMode: FallbackMode.deadlineOnly,
  );
}
```

#### Option B: Soft Nudge

- Focus screen works but shows persistent banner
- "Define values to unlock smart allocation"
- Degrades gracefully to deadline-based sorting

#### Option C: Hybrid (Best UX)

- **First visit**: Full-screen onboarding (Option A)
- **Subsequent visits**: Soft banner if still no values
- **User can dismiss**: Remembers preference

### Suggested User Flow

```
┌─────────────────┐     No values     ┌─────────────────┐
│  User taps      │ ────────────────► │  Values Setup   │
│  "Focus" tab    │                   │  Screen         │
└─────────────────┘                   └─────────────────┘
                                              │
                                              │ User creates 1+ values
                                              ▼
                                      ┌─────────────────┐
                                      │  Focus Screen   │
                                      │  (with values)  │
                                      └─────────────────┘
```

---

## Value Card Detailed View (Tap to Expand)

When user taps a value card:

```
╔═══════════════════════════════════════════════════════════╗
║  🏃 Health & Wellness                              [ ✕ ]  ║
╠═══════════════════════════════════════════════════════════╣
║                                                            ║
║  Rank: #1 • Weight: 10                                    ║
║                                                            ║
║  ── Statistics ─────────────────────────────────────      ║
║                                                            ║
║  Active Tasks:     12                                     ║
║  Active Projects:   3                                     ║
║  Completed (30d):  28 tasks                               ║
║                                                            ║
║  ── Allocation ─────────────────────────────────────      ║
║                                                            ║
║  Target Share:     ~30%                                   ║
║  Actual Share:     18%                                    ║
║  Gap:              -12% ⚠️                                ║
║                                                            ║
║  ── Trend (Last 4 Weeks) ───────────────────────────      ║
║                                                            ║
║  Week 1:  ████████████████████████████  32%               ║
║  Week 2:  ██████████████████████        24%               ║
║  Week 3:  ██████████████                16%               ║
║  Week 4:  ██████████████████            18%  ← Current    ║
║                                                            ║
║  ── Wellbeing Correlation ──────────────────────────      ║
║                                                            ║
║  Days with Health tasks: avg mood 4.2 😊                  ║
║  Days without:           avg mood 3.1 😐                  ║
║  Correlation: +0.72 (Strong Positive) ✨                  ║
║                                                            ║
║  💡 Completing Health tasks correlates with 35%           ║
║     higher mood scores for you.                           ║
║                                                            ║
║  ────────────────────────────────────────────────────     ║
║                                                            ║
║  [ View Tasks ]  [ View Projects ]  [ Edit Value ]        ║
║                                                            ║
╚═══════════════════════════════════════════════════════════╝
```

---

## Technical Considerations

### Data Requirements

| Data Point | Source | Notes |
|------------|--------|-------|
| Active tasks/projects | `TaskRepository`, `ProjectRepository` | Filter by value label |
| Completed work % | `AnalyticsService.getTaskStats()` | New stat type needed |
| Target % | `ValueRanking.items[].weight` | Calculate from weights |
| Mood correlation | `AnalyticsService.calculateCorrelation()` | Existing `moodVsEntity` |

### New Analytics Needed

```dart
/// Get completion distribution by value over a date range
Future<Map<String, double>> getValueCompletionDistribution({
  required DateRange range,
});

/// Get completion trend for a specific value
Future<List<WeeklyValueStat>> getValueTrend({
  required String valueId,
  required DateRange range,
});
```

### Screen Definition Changes

The Values screen would need a new `ScreenType` or enhanced `Section`:

```dart
// Option: New section type for values screen
const Section.valueOverview(
  showStats: true,
  showTrend: true,
  showCorrelation: true,
);
```

---

## Orphan Tasks (No Value, No Deadline)

Tasks without values AND without deadlines are "orphans" - invisible to the allocation system.

### Problem

- User creates quick tasks without categorizing
- Tasks accumulate invisibly  
- User thinks they're "on top of things" but orphan tasks pile up

### Solution: Aggregate Count Display

Show non-intrusive count in Focus footer (configurable via `showOrphanTaskCount` setting).

```
╔═══════════════════════════════════════════════════════════╗
│  FOCUS                                        ⚖️ Realist  │
╠═══════════════════════════════════════════════════════════╣
│  ...allocated tasks by value...                           │
│                                                           │
│  ─────────────────────────────────────────────────────   │
│  📥 12 tasks not assigned to any value                   │
│     (no deadlines - review when ready)        [ View → ] │
╚═══════════════════════════════════════════════════════════╝
```

### Complete Task Visibility Matrix

| Task Type | Has Value | Has Deadline | Urgent? | Idealist | Reflector | Realist | Firefighter |
|-----------|-----------|--------------|---------|----------|-----------|---------|-------------|
| Standard | ✅ | Any | Any | ✅ Allocated | ✅ Allocated | ✅ Allocated | ✅ Allocated |
| Urgent unvalued | ❌ | ✅ | ✅ | ❌ Hidden | ⚠️ Warning | ⚠️ Warning | ✅ **Included** |
| Non-urgent unvalued | ❌ | ✅ | ❌ | ❌ Hidden | 📊 Count | 📊 Count | 📊 Count |
| Orphan (no deadline) | ❌ | ❌ | ❌ | ❌ Hidden | 📊 Count | 📊 Count | 📊 Count |
| Inherited value | ❌→✅ | Any | Any | ✅ Allocated | ✅ Allocated | ✅ Allocated | ✅ Allocated |

---

## Project Deadline Warnings

Projects are not first-class citizens in allocation (only tasks are allocated), but project deadlines should generate warnings.

### Separate Threshold Setting

Users can configure different urgency thresholds for tasks vs projects:

| Setting | Default | Purpose |
|---------|---------|---------|
| `taskUrgencyThresholdDays` | `3` | Days before task deadline = urgent |
| `projectUrgencyThresholdDays` | `7` | Days before project deadline = warning |

Projects typically need more lead time for awareness.

### Warning Generation

```dart
class ProjectWarningGenerator {
  List<AllocationWarning> generateProjectWarnings({
    required List<Project> projects,
    required int thresholdDays,
  }) {
    final warnings = <AllocationWarning>[];
    final now = DateTime.now();
    
    for (final project in projects) {
      if (project.deadlineDate == null || project.completed) continue;
      
      final daysUntil = project.deadlineDate!.difference(now).inDays;
      if (daysUntil <= thresholdDays) {
        warnings.add(AllocationWarning(
          type: WarningType.projectDeadlineApproaching,  // NEW type
          message: 'Project "${project.name}" due in $daysUntil days',
          suggestedAction: 'Review project tasks and prioritize',
          affectedProjectId: project.id,
        ));
      }
    }
    
    return warnings;
  }
}
```

---

## Project "Next Task" Recommendation

Show the recommended next action for each project, using the same scoring logic as allocation.

### Determination Logic

```dart
class ProjectNextTaskResolver {
  Task? getNextTask({
    required Project project,
    required List<Task> projectTasks,
    required AllocationSettings settings,
  }) {
    final incompleteTasks = projectTasks.where((t) => !t.completed).toList();
    if (incompleteTasks.isEmpty) return null;
    
    final scored = incompleteTasks.map((task) {
      final urgencyScore = _calculateUrgencyScore(task, settings);
      final valueScore = _calculateValueScore(task, project, settings);
      return (task: task, score: urgencyScore + valueScore);
    }).toList();
    
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.first.task;
  }
}
```

### Project List View Mockup

```
╔═══════════════════════════════════════════════════════════╗
│  PROJECTS                                                  │
╠═══════════════════════════════════════════════════════════╣
│                                                            │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ 🏃 Marathon Training              Due: Jan 15       │  │
│  │    Health & Wellness                                │  │
│  │    ────────────────────────────────────────────    │  │
│  │    → Next: Schedule physio appointment (due Jan 5) │  │
│  │    12 tasks remaining                               │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                            │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ 💼 Q1 Planning                    Due: Jan 31       │  │
│  │    Career Growth                                    │  │
│  │    ────────────────────────────────────────────    │  │
│  │    → Next: Review last quarter metrics              │  │
│  │    8 tasks remaining                                │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                            │
╚═══════════════════════════════════════════════════════════╝
```

### Project Detail View (Header)

```
╔═══════════════════════════════════════════════════════════╗
│  ← Marathon Training                              ⋮       │
╠═══════════════════════════════════════════════════════════╣
│                                                            │
│  🏃 Health & Wellness              Due: Jan 15 (12 days)  │
│                                                            │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ ⭐ RECOMMENDED NEXT ACTION                          │  │
│  │                                                     │  │
│  │ ☐ Schedule physio appointment                      │  │
│  │   Due: Jan 5 (2 days) • High priority              │  │
│  │                                          [ Start ] │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                            │
│  ── All Tasks (12) ───────────────────────────────────    │
│  ...                                                      │
╚═══════════════════════════════════════════════════════════╝
```

### "Start" Action

Tapping "Start" pins the task to Focus, making it immediately actionable.

### Edge Cases

| Scenario | "Next Task" Behavior |
|----------|---------------------|
| All tasks completed | Show "🎉 Project complete!" |
| No tasks yet | Show "Add your first task" |
| Multiple tasks same score | Use creation date as tiebreaker (oldest first) |

---

## Open Questions

1. ~~**Should unassigned work always show?**~~ → Resolved: Show count with toggle setting

2. **How to handle tasks with multiple values?** 
   - Split credit proportionally?
   - Count toward primary value only?
   - Count toward all (may exceed 100%)?

3. **Minimum data threshold for correlations?**
   - Don't show correlation until N days of mood + task data?
   - Show with "insufficient data" disclaimer?

4. **Should target % be user-adjustable?**
   - Currently auto-calculated from rank
   - Some users may want explicit % control

---

## Allocation Personas

Users select a **persona** that represents their relationship with deadlines and values. Each persona has a distinct philosophy.

### The Spectrum

```
        VALUES-ONLY                                    DEADLINE-ONLY
             │                                              │
   ┌─────────┼──────────────┬───────────────┬──────────────┤
   │         │              │               │              │
💎 IDEALIST  🔮 REFLECTOR   ⚖️ REALIST      🔥 FIREFIGHTER
Pure values  Self-correcting  Balanced       Deadline-first
No warnings  + warnings       + manual add   All urgent shown
```

---

### 💎 THE IDEALIST

```
╔═══════════════════════════════════════════════════════════╗
│ 💎 THE IDEALIST                                           │
╠═══════════════════════════════════════════════════════════╣
│                                                           │
│  "Values only. A deliberate choice."                     │
│                                                           │
│  ┌───────────────────────────────────────────────────┐   │
│  │  HOW IT WORKS                                     │   │
│  │  ─────────────────────────────────────────────── │   │
│  │  ✓ Tasks ranked by value weights only            │   │
│  │  ✗ No urgency weighting                          │   │
│  │  ✗ No warnings for excluded deadlines            │   │
│  └───────────────────────────────────────────────────┘   │
│                                                           │
│  Focus stays free from deadline pressure.                │
│  Use Today and Upcoming for time-sensitive work.         │
│                                                           │
│  BEST FOR                                                 │
│  • Separating "important" from "urgent"                  │
│  • Intentional, values-driven planning                   │
│  • When deadlines live elsewhere                         │
│                                                           │
╚═══════════════════════════════════════════════════════════╝
```

**Settings:**
```dart
AllocationSettings(
  strategyType: AllocationStrategyType.proportional,
  urgencyInfluence: 0.0,
  urgentTaskBehavior: UrgentTaskBehavior.ignore,
)
```

---

### 🔮 THE REFLECTOR

```
╔═══════════════════════════════════════════════════════════╗
│ 🔮 THE REFLECTOR                                          │
╠═══════════════════════════════════════════════════════════╣
│                                                           │
│  "Show me where I've been under-investing."              │
│                                                           │
│  ┌───────────────────────────────────────────────────┐   │
│  │  HOW IT WORKS                                     │   │
│  │  ─────────────────────────────────────────────── │   │
│  │  ✓ Prioritizes neglected values                  │   │
│  │  ✓ Recent completions lower a value's priority   │   │
│  │  ○ Deadlines shown but don't affect order        │   │
│  │  ✓ Warning if urgent task excluded               │   │
│  └───────────────────────────────────────────────────┘   │
│                                                           │
│  If you've done lots of Career tasks this week,          │
│  Focus will surface Health and Family instead.           │
│                                                           │
│  BEST FOR                                                 │
│  • Self-correcting value alignment                       │
│  • Noticing blind spots automatically                    │
│  • When one value tends to dominate your time            │
│                                                           │
╚═══════════════════════════════════════════════════════════╝
```

**Algorithm:**
```
For each value:
  recentCompletions = countCompletions(value, last7Days)
  expectedCompletions = totalCompletions * valueWeightRatio
  neglectScore = expectedCompletions - recentCompletions
  
// Higher neglectScore = prioritized in Focus
// Values you've been ignoring rise to the top
```

**Settings:**
```dart
AllocationSettings(
  strategyType: AllocationStrategyType.proportional,
  urgencyInfluence: 0.0,
  neglectInfluence: 0.7,  // NEW
  reflectorLookbackDays: 7,  // NEW
  urgentTaskBehavior: UrgentTaskBehavior.warnOnly,
)
```

---

### ⚖️ THE REALIST (Recommended)

```
╔═══════════════════════════════════════════════════════════╗
│ ⚖️ THE REALIST                              ★ Recommended │
╠═══════════════════════════════════════════════════════════╣
│                                                           │
│  "Values first, with a nudge when deadlines need me."    │
│                                                           │
│  ┌───────────────────────────────────────────────────┐   │
│  │  HOW IT WORKS                                     │   │
│  │  ─────────────────────────────────────────────── │   │
│  │  ✓ Ranked by value weight + urgency boost        │   │
│  │  ✓ Daily limit respected                         │   │
│  │  ⚠️ Warning if urgent task excluded              │   │
│  │  ✓ Add urgent tasks manually (can exceed limit)  │   │
│  └───────────────────────────────────────────────────┘   │
│                                                           │
│  You stay in control. Urgent tasks surface as warnings,  │
│  and YOU decide whether to add them to Focus.            │
│                                                           │
│  BEST FOR                                                 │
│  • Daily use with mindful deadline handling              │
│  • Staying focused without auto-interruptions            │
│  • Balancing values with real-world demands              │
│                                                           │
╚═══════════════════════════════════════════════════════════╝
```

**Warning UI:**
```
┌─────────────────────────────────────────────────────────────┐
│ ⚠️ 2 urgent tasks not in Focus                              │
│                                                             │
│ ☐ Submit tax forms          Due tomorrow    [ + Add ]      │
│ ☐ Pay electricity bill      Due in 2 days   [ + Add ]      │
│                                                             │
│ Adding will exceed your daily limit of 7 tasks.            │
│                                                             │
│              [ Add All ]              [ Dismiss ]           │
└─────────────────────────────────────────────────────────────┘
```

**Settings:**
```dart
AllocationSettings(
  strategyType: AllocationStrategyType.urgencyWeighted,
  urgencyInfluence: 0.5,
  valueAlignedUrgencyBoost: 1.5,  // NEW
  urgencyThresholdDays: 3,
  urgentTaskBehavior: UrgentTaskBehavior.warnOnly,
)
```

---

### 🔥 THE FIREFIGHTER

```
╔═══════════════════════════════════════════════════════════╗
│ 🔥 THE FIREFIGHTER                                        │
╠═══════════════════════════════════════════════════════════╣
│                                                           │
│  "Deadlines first. Always. No exceptions."               │
│                                                           │
│  ┌───────────────────────────────────────────────────┐   │
│  │  HOW IT WORKS                                     │   │
│  │  ─────────────────────────────────────────────── │   │
│  │  ✓ All urgent tasks shown - with OR without value│   │
│  │  ✓ No daily limit for urgent tasks               │   │
│  │  ✓ Sorted by deadline (soonest first)            │   │
│  │  ○ Values as tiebreaker only                     │   │
│  └───────────────────────────────────────────────────┘   │
│                                                           │
│  If you have 15 urgent tasks, you'll see all 15 -        │
│  even tasks you haven't assigned to any value.           │
│  Non-urgent tasks fill remaining slots by value.         │
│                                                           │
│  BEST FOR                                                 │
│  • Crunch time / deadline avalanche                      │
│  • Catching up after time away                           │
│  • When missing a deadline isn't an option               │
│                                                           │
╚═══════════════════════════════════════════════════════════╝
```

**Settings:**
```dart
AllocationSettings(
  strategyType: AllocationStrategyType.urgencyWeighted,
  urgencyInfluence: 1.0,
  urgencyThresholdDays: 3,
  urgentTaskBehavior: UrgentTaskBehavior.includeAll, // Includes value-less!
)
```

---

### 🛠️ CUSTOM

```
╔═══════════════════════════════════════════════════════════╗
│ 🛠️ CUSTOM                                                 │
╠═══════════════════════════════════════════════════════════╣
│                                                           │
│  "Full control over allocation behavior."                │
│                                                           │
│  ┌───────────────────────────────────────────────────┐   │
│  │  Configure your own combination of:               │   │
│  │  ─────────────────────────────────────────────── │   │
│  │  • Value weighting strategy                      │   │
│  │  • Urgency influence (0-100%)                    │   │
│  │  • Value-aligned urgency boost                   │   │
│  │  • Warning preferences                           │   │
│  │  • Daily task limits                             │   │
│  │  • Neglect-based rebalancing                     │   │
│  └───────────────────────────────────────────────────┘   │
│                                                           │
│  [ Configure → ]                                         │
│                                                           │
╚═══════════════════════════════════════════════════════════╝
```

---

### Persona Comparison Matrix

| Aspect | 💎 Idealist | 🔮 Reflector | ⚖️ Realist | 🔥 Firefighter |
|--------|-------------|--------------|------------|----------------|
| **Primary sort** | Value weight | Neglect score | Value + urgency | Deadline |
| **Urgency weighting** | ✗ None | ✗ None | ✓ Boosted | ✓ Primary |
| **Urgent task behavior** | `ignore` | `warnOnly` | `warnOnly` | `includeAll` |
| **Value-less urgent tasks** | Excluded | Warning | Warning | **Included** |
| **Daily limit** | Enforced | Enforced | Enforced (can override) | Bypassed for urgent |
| **Self-adjusts** | No | Yes (weekly) | No | No |
| **Philosophy** | Pure values | Balanced values | Values + reality | Reality first |

---

### Persona Selection UI

```
╔═══════════════════════════════════════════════════════════╗
║  ⚙️ FOCUS MODE                                            ║
╠═══════════════════════════════════════════════════════════╣
║                                                            ║
║  Choose how Focus selects your next actions:              ║
║                                                            ║
║  ┌─────────────────────────────────────────────────────┐  ║
║  │ 💎 THE IDEALIST                                     │  ║
║  │ Values only. A deliberate choice.                   │  ║
║  └─────────────────────────────────────────────────────┘  ║
║                                                            ║
║  ┌─────────────────────────────────────────────────────┐  ║
║  │ 🔮 THE REFLECTOR                                    │  ║
║  │ Prioritize neglected values. Self-correcting.       │  ║
║  └─────────────────────────────────────────────────────┘  ║
║                                                            ║
║  ┌─────────────────────────────────────────────────────┐  ║
║  │ ⚖️ THE REALIST                      ★ Recommended   │▓▓║
║  │ Values + urgency warnings. You decide what to add.  │▓▓║
║  └─────────────────────────────────────────────────────┘  ║
║                                                            ║
║  ┌─────────────────────────────────────────────────────┐  ║
║  │ 🔥 THE FIREFIGHTER                                  │  ║
║  │ Deadlines first. All urgent tasks, no exceptions.   │  ║
║  └─────────────────────────────────────────────────────┘  ║
║                                                            ║
║  ┌─────────────────────────────────────────────────────┐  ║
║  │ 🛠️ CUSTOM                                           │  ║
║  │ Full control over allocation behavior.              │  ║
║  └─────────────────────────────────────────────────────┘  ║
║                                                            ║
║  ─────────────────────────────────────────────────────    ║
║  Daily task limit: [ 7 ]                 [ Save ]         ║
║                                                            ║
╚═══════════════════════════════════════════════════════════╝
```

---

### Urgent Task Handling (Unified Logic)

The system uses **shared logic** to detect urgent tasks, then applies persona-specific behavior.

#### Urgency Detection (Shared)

```dart
/// Shared urgency detection - used by both warning and inclusion logic
class UrgencyDetector {
  const UrgencyDetector({required this.urgencyThresholdDays});
  
  final int urgencyThresholdDays;
  
  /// Returns all urgent tasks from a list, regardless of value assignment
  List<Task> findUrgentTasks(List<Task> tasks) {
    final now = DateTime.now();
    return tasks.where((task) {
      if (task.deadlineDate == null) return false;
      final daysUntilDeadline = task.deadlineDate!.difference(now).inDays;
      return daysUntilDeadline <= urgencyThresholdDays;
    }).toList();
  }
  
  bool isUrgent(Task task) {
    if (task.deadlineDate == null) return false;
    final daysUntilDeadline = task.deadlineDate!.difference(DateTime.now()).inDays;
    return daysUntilDeadline <= urgencyThresholdDays;
  }
}
```

#### Urgent Task Behavior (Per-Persona)

```dart
/// How to handle urgent tasks that would otherwise be excluded
enum UrgentTaskBehavior {
  /// Ignore urgency entirely - pure values only (Idealist)
  ignore,
  
  /// Show warning but don't auto-include (Reflector, Realist)
  warnOnly,
  
  /// Auto-include ALL urgent tasks, even without values (Firefighter)
  includeAll,
}
```

#### Behavior by Persona

| Persona | `urgentTaskBehavior` | Urgent WITH value | Urgent WITHOUT value |
|---------|---------------------|-------------------|----------------------|
| 💎 Idealist | `ignore` | Excluded silently | Excluded silently |
| 🔮 Reflector | `warnOnly` | Warning shown | Warning shown |
| ⚖️ Realist | `warnOnly` | Warning + manual add | Warning + manual add |
| 🔥 Firefighter | `includeAll` | **Auto-included** | **Auto-included** |

#### Implementation in Allocator

```dart
AllocationResult allocate(AllocationParameters params) {
  final detector = UrgencyDetector(
    urgencyThresholdDays: params.urgencyThresholdDays,
  );
  
  // Step 1: If includeAll, gather ALL urgent tasks first (with OR without values)
  if (params.urgentTaskBehavior == UrgentTaskBehavior.includeAll) {
    final allUrgent = detector.findUrgentTasks(params.tasks);
    // Add to allocated list immediately, sorted by deadline
    allUrgent.sort((a, b) => a.deadlineDate!.compareTo(b.deadlineDate!));
    for (final task in allUrgent) {
      allocatedTasks.add(AllocatedTask(
        task: task,
        qualifyingValueId: task.getEffectiveValues().firstOrNull?.id ?? 'urgent',
        allocationScore: 100.0, // Max score for urgent
        isUrgentOverride: true, // NEW: Flag for UI styling
      ));
    }
    // Remaining slots filled by value-based allocation (excluding already-added)
  }
  
  // Step 2: Normal value-based allocation...
  
  // Step 3: Generate warnings if warnOnly
  if (params.urgentTaskBehavior == UrgentTaskBehavior.warnOnly) {
    final excludedUrgent = excludedTasks.where((et) => detector.isUrgent(et.task));
    if (excludedUrgent.isNotEmpty) {
      warnings.add(AllocationWarning(
        type: WarningType.excludedUrgentTask,
        message: '${excludedUrgent.length} urgent task(s) not in Focus',
        affectedTaskIds: excludedUrgent.map((e) => e.task.id).toList(),
      ));
    }
  }
}
```

---

### Data Model Changes

```dart
enum AllocationPersona {
  idealist,
  reflector,
  realist,
  firefighter,
  custom,
}

/// How to handle urgent tasks that would otherwise be excluded
enum UrgentTaskBehavior {
  ignore,    // Pure values - no urgency consideration
  warnOnly,  // Show warning, user adds manually
  includeAll, // Auto-include all urgent (even without values)
}

class AllocationSettings {
  // ... existing fields ...
  
  /// NEW: Selected persona (determines defaults for other settings)
  final AllocationPersona persona;
  
  /// NEW: Multiplier for tasks that are both urgent AND value-aligned
  final double valueAlignedUrgencyBoost;
  
  /// NEW: Days until TASK deadline to consider "urgent"
  final int taskUrgencyThresholdDays;
  
  /// NEW: Days until PROJECT deadline to generate warning
  final int projectUrgencyThresholdDays;
  
  /// NEW: Lookback window for Reflector mode (days)
  final int reflectorLookbackDays;
  
  /// NEW: How much to weight neglect vs base value ranking (0.0-1.0)
  final double neglectInfluence;
  
  /// NEW: Unified urgent task handling (replaces separate warning/include flags)
  final UrgentTaskBehavior urgentTaskBehavior;
  
  /// NEW: Show count of tasks without values in Focus footer
  final bool showOrphanTaskCount;
  
  /// NEW: Show "next task" recommendation in project views
  final bool showProjectNextTask;
}
```

### Default Values

```dart
const AllocationSettings({
  this.persona = AllocationPersona.realist,
  this.taskUrgencyThresholdDays = 3,
  this.projectUrgencyThresholdDays = 7,  // Projects get more lead time
  this.showOrphanTaskCount = true,       // On by default
  this.showProjectNextTask = true,       // On by default
  this.valueAlignedUrgencyBoost = 1.5,
  this.reflectorLookbackDays = 7,
  this.neglectInfluence = 0.7,
  this.urgentTaskBehavior = UrgentTaskBehavior.warnOnly,
  // ...existing fields...
});
```

### Persona to Settings Mapping

```dart
extension AllocationPersonaSettings on AllocationPersona {
  AllocationSettings toSettings() {
    return switch (this) {
      AllocationPersona.idealist => const AllocationSettings(
        persona: AllocationPersona.idealist,
        strategyType: AllocationStrategyType.proportional,
        urgencyInfluence: 0.0,
        urgentTaskBehavior: UrgentTaskBehavior.ignore,
        showOrphanTaskCount: false,  // Pure values - hide orphans
      ),
      AllocationPersona.reflector => const AllocationSettings(
        persona: AllocationPersona.reflector,
        strategyType: AllocationStrategyType.proportional,
        urgencyInfluence: 0.0,
        neglectInfluence: 0.7,
        reflectorLookbackDays: 7,
        urgentTaskBehavior: UrgentTaskBehavior.warnOnly,
        showOrphanTaskCount: true,
      ),
      AllocationPersona.realist => const AllocationSettings(
        persona: AllocationPersona.realist,
        strategyType: AllocationStrategyType.urgencyWeighted,
        urgencyInfluence: 0.5,
        valueAlignedUrgencyBoost: 1.5,
        taskUrgencyThresholdDays: 3,
        projectUrgencyThresholdDays: 7,
        urgentTaskBehavior: UrgentTaskBehavior.warnOnly,
        showOrphanTaskCount: true,
      ),
      AllocationPersona.firefighter => const AllocationSettings(
        persona: AllocationPersona.firefighter,
        strategyType: AllocationStrategyType.urgencyWeighted,
        urgencyInfluence: 1.0,
        taskUrgencyThresholdDays: 3,
        projectUrgencyThresholdDays: 7,
        urgentTaskBehavior: UrgentTaskBehavior.includeAll,
        showOrphanTaskCount: true,
      ),
      AllocationPersona.custom => const AllocationSettings(
        persona: AllocationPersona.custom,
      ),
    };
  }
}
```

### New Warning Type

```dart
enum WarningType {
  excludedUrgentTask,
  unbalancedAllocation,
  noTasksInCategory,
  exceededTotalLimit,
  projectDeadlineApproaching,  // NEW
}
```

---

### Settings UI Mockup

```
╔═══════════════════════════════════════════════════════════╗
│  ⚙️ ALLOCATION SETTINGS                                   │
╠═══════════════════════════════════════════════════════════╣
│                                                            │
│  ── Persona ───────────────────────────────────────────   │
│  [ ⚖️ Realist ▼ ]                                         │
│                                                            │
│  ── Urgency Thresholds ────────────────────────────────   │
│                                                            │
│  Task urgency threshold                                   │
│  Days before deadline to flag task as urgent              │
│  [ 3 ] days                                               │
│                                                            │
│  Project urgency threshold                                │
│  Days before deadline to warn about project               │
│  [ 7 ] days                                               │
│                                                            │
│  ── Display Options ───────────────────────────────────   │
│                                                            │
│  Show uncategorized task count              [ ● ON  ]     │
│  Display count of tasks without values in Focus           │
│                                                            │
│  Show project next task                     [ ● ON  ]     │
│  Highlight recommended task in project views              │
│                                                            │
│  Daily focus limit                                        │
│  [ 7 ] tasks                                              │
│                                                            │
╚═══════════════════════════════════════════════════════════╝
```

---

### Key Design Decisions

1. **Shared `UrgencyDetector`**: Single source of truth for "is this task urgent?"
2. **`UrgentTaskBehavior` enum**: Replaces separate `alwaysIncludeUrgent` + `showExcludedUrgentWarning` flags
3. **Firefighter includes value-less urgent tasks**: The `includeAll` behavior explicitly includes tasks without values
4. **`isUrgentOverride` flag on `AllocatedTask`**: Allows UI to style urgent-override tasks differently
5. **Separate task/project urgency thresholds**: Projects typically need more lead time (7 days default vs 3 for tasks)
6. **Orphan task count**: Non-intrusive awareness of uncategorized work (toggleable)
7. **Project "Next Task"**: Brings allocation logic to project views without making projects first-class in Focus

---

## Next Steps

1. [ ] Validate concept with user feedback
2. [ ] Design empty state / onboarding flow
3. [ ] Define analytics service extensions
4. [ ] Create detailed UI specifications
5. [ ] Plan phased implementation

---

## Related Documents

- [Allocation Settings](../phases/unified_screen_model/PHASE_8_USER_SCREEN_PARITY.md)
- [Wellbeing Dashboard](../ARCHITECTURE_DECISIONS.md)
- [Analytics Service](../../lib/domain/services/analytics/analytics_service.dart)
