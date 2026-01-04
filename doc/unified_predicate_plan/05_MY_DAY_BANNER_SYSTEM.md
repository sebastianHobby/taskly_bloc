# My Day Banner System - Concept Document

## Overview

This document defines the design for a configurable alert banner system that surfaces problems with tasks outside the user's Focus allocation. The system integrates with existing allocation settings and persona presets.

## Design Philosophy

- **User opts-in** to specific problem types (no global threshold)
- **User sets severity** per problem type (Critical, Warning, Notice)
- **Enabled = Displayed** - anything enabled appears in My Day
- **No dismiss state** - banners are computed from allocation, not persisted
- **Persona-aligned defaults** - each persona has sensible default configurations

---

## Severity Levels

### Three-Level System

| Severity | Color | Icon | Banner Style | Use Case |
|----------|-------|------|--------------|----------|
| **Critical** | 🔴 Red (`errorContainer`) | ⚠️ | Full-width, bold | Overdue, blocking issues |
| **Warning** | 🟡 Amber (`tertiaryContainer`) | ⚠ | Full-width, tinted | Urgent deadlines, needs attention soon |
| **Notice** | 🔵 Blue (`primaryContainer` 30%) | ℹ | Inline chip | Informational, act when convenient |

### Banner Stacking Order
1. Critical banners appear first (top)
2. Warning banners appear below critical
3. Notice banners appear as inline chips below focus list

---

## Problem Types

Reuse existing `ProblemType` enum from `problem_type.dart`:

| Problem Type | Description | Suggested Default Severity |
|--------------|-------------|---------------------------|
| `taskOverdue` | Task past deadline | Critical |
| `taskUrgentExcluded` | Urgent task excluded from Focus | Warning |
| `taskOrphan` | Task without value label | Notice |
| `taskStale` | Task not updated recently | Notice |
| `allocationUnbalanced` | Values weighted unevenly | Notice |
| `projectIdle` | Project with no actionable tasks | Notice |

---

## Persona Default Configurations

### Idealist
**Philosophy:** Pure value focus. Deadlines are noise unless value-aligned.

| Problem Type | Enabled | Severity |
|--------------|---------|----------|
| `taskOrphan` | ✅ | Notice |
| Others | ❌ | - |

**Banner:** Only shows unassigned tasks count.

### Reflector
**Philosophy:** Balanced values. Surface neglected areas.

| Problem Type | Enabled | Severity |
|--------------|---------|----------|
| `taskUrgentExcluded` | ✅ | Warning |
| `allocationUnbalanced` | ✅ | Notice |
| `taskOrphan` | ✅ | Notice |

**Banner:** Shows urgent excluded + balance issues.

### Realist ★ RECOMMENDED
**Philosophy:** Value-aligned with urgency awareness.

| Problem Type | Enabled | Severity |
|--------------|---------|----------|
| `taskOverdue` | ✅ | Critical |
| `taskUrgentExcluded` | ✅ | Warning |
| `taskOrphan` | ✅ | Notice |

**Banner:** Shows overdue + urgent + unassigned.

### Firefighter
**Philosophy:** Urgency drives everything. No banner needed.

| Problem Type | Enabled | Severity |
|--------------|---------|----------|
| None | - | - |

**Banner:** None - urgency IS the view structure.

### Custom
**Philosophy:** User defines all settings.

| Problem Type | Enabled | Severity |
|--------------|---------|----------|
| User-configured | User-configured | User-configured |

---

## UI Design: Allocation Settings Integration

### Location
Banner configuration lives in **Allocation Settings** page, under a new "Focus Alerts" section between "Display Options" and "Value Rankings".

### Settings UI Structure

```
┌─────────────────────────────────────────────────────────────┐
│ ← Allocation Settings                              [Save]   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. PERSONA SELECTION                                       │
│     [Idealist] [Reflector] [Realist★] [Firefighter] [Custom]│
│                                                             │
│  2. URGENCY THRESHOLDS                                      │
│     Task urgency days: [3]                                  │
│     Project urgency days: [7]                               │
│                                                             │
│  3. DISPLAY OPTIONS                                         │
│     Show unassigned task count: [ON]                        │
│     Show project next task: [ON]                            │
│     Daily task limit: [10]                                  │
│                                                             │
│  4. FOCUS ALERTS  ← NEW SECTION                             │
│     ┌───────────────────────────────────────────────────┐   │
│     │ [Live Preview - see below]                        │   │
│     └───────────────────────────────────────────────────┘   │
│     [Alert configuration cards - see below]                 │
│                                                             │
│  5. ADVANCED SETTINGS (Custom persona only)                 │
│     ...                                                     │
│                                                             │
│  6. VALUE RANKINGS                                          │
│     ...                                                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Focus Alerts Section Detail

```
┌─ FOCUS ALERTS ──────────────────────────────────────────────┐
│                                                             │
│  ┌─ Live Preview ───────────────────────────────────────┐   │
│  │                                                       │   │
│  │  ┌─────────────────────────────────────────────────┐  │   │
│  │  │🔴 ⚠️ 2 overdue tasks                   View → │  │   │
│  │  └─────────────────────────────────────────────────┘  │   │
│  │  ┌─────────────────────────────────────────────────┐  │   │
│  │  │⚠ 3 urgent tasks outside focus          View → │  │   │
│  │  └─────────────────────────────────────────────────┘  │   │
│  │  ┌─────────────────────────────────────────────────┐  │   │
│  │  │ℹ 5 tasks without values                Assign →│  │   │
│  │  └─────────────────────────────────────────────────┘  │   │
│  │                                                       │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐   │
│  │ ◉  Overdue tasks                    🔴 Critical ▼    │   │
│  │    Tasks past their deadline                          │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐   │
│  │ ◉  Urgent excluded                  🟡 Warning ▼     │   │
│  │    Deadline soon, not in Focus                        │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐   │
│  │ ◉  Unassigned tasks                 🔵 Notice ▼      │   │
│  │    Tasks without a value label                        │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐   │
│  │ ○  Stale tasks                             [Enable]   │   │
│  │    Not updated in 14+ days                            │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌───────────────────────────────────────────────────────┐   │
│  │ ○  Unbalanced allocation                   [Enable]   │   │
│  │    Values weighted unevenly                           │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Auto-Switch to Custom Persona

When user modifies alert configuration:
1. Compare current alert settings against current persona's defaults
2. If different, auto-switch to `AllocationPersona.custom`
3. Show snackbar: "Switched to custom mode"
4. This matches existing behavior for strategy settings

---

## My Day View: Full Mockups by Persona

### Realist View (Recommended)

```
┌─────────────────────────────────────────────────────────────┐
│  My Day                                    Sun, Jan 4       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 🔴 1 overdue • ⚠ 2 urgent outside focus         ▼  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ═══════════════════════════════════════════════════════   │
│  YOUR FOCUS                                        10 tasks │
│  ───────────────────────────────────────────────────────── │
│                                                             │
│  ⏰ STARTING TODAY                                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ☐  Project kickoff meeting             Starts 10am  │   │
│  │    📁 Work  •  🏷 Career                            │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  📋 VALUE-ALIGNED                                           │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ☐  Write quarterly report              ⚡ Due Fri   │   │
│  │    📁 Work  •  🏷 Career                            │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │ ☐  Call mom                                         │   │
│  │    📁 Personal  •  🏷 Family                        │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │ ☐  Morning yoga                                     │   │
│  │    📁 Personal  •  🏷 Health                        │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ═══════════════════════════════════════════════════════   │
│                                                             │
│  ┌─ Outside Focus ───────────────────────────────────┐     │
│  │                                                   │     │
│  │  🔴 OVERDUE                                       │     │
│  │  ┌─────────────────────────────────────────────┐  │     │
│  │  │ ☐  Submit expense report          Due Jan 2 │  │     │
│  │  │    📁 Work  •  No value                     │  │     │
│  │  │                    [Assign Value] [Defer]   │  │     │
│  │  └─────────────────────────────────────────────┘  │     │
│  │                                                   │     │
│  │  🟡 URGENT                                        │     │
│  │  ┌─────────────────────────────────────────────┐  │     │
│  │  │ ☐  Review contract               Due Tue   │  │     │
│  │  │    📁 Work  •  No value                     │  │     │
│  │  ├─────────────────────────────────────────────┤  │     │
│  │  │ ☐  Client follow-up              Due Wed   │  │     │
│  │  │    📁 Work  •  No value                     │  │     │
│  │  └─────────────────────────────────────────────┘  │     │
│  │                                                   │     │
│  │  ℹ WITHOUT VALUES (5 tasks)               View → │     │
│  │                                                   │     │
│  └───────────────────────────────────────────────────┘     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Firefighter View (No Banner)

```
┌─────────────────────────────────────────────────────────────┐
│  My Day                                    Sun, Jan 4       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ═══════════════════════════════════════════════════════   │
│  🔴 OVERDUE                                         1 task  │
│  ───────────────────────────────────────────────────────── │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ☐  Submit expense report                   Jan 2   │   │
│  │    📁 Work  •  2 days overdue                       │   │
│  │                         [Do Now] [Reschedule]       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ═══════════════════════════════════════════════════════   │
│  ⏰ DUE TODAY                                        2 tasks │
│  ───────────────────────────────────────────────────────── │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ☐  Project kickoff meeting              10:00 AM    │   │
│  │ ☐  Send weekly report                   5:00 PM     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ═══════════════════════════════════════════════════════   │
│  🟡 DUE THIS WEEK                                    5 tasks │
│  ───────────────────────────────────────────────────────── │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ☐  Review contract                      Tue Jan 6  │   │
│  │ ☐  Client follow-up                     Wed Jan 7  │   │
│  │ ☐  Write quarterly report               Fri Jan 9  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ═══════════════════════════════════════════════════════   │
│  📋 OTHER FOCUS TASKS                                8 tasks │
│  ───────────────────────────────────────────────────────── │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ☐  Call mom                                         │   │
│  │ ☐  Morning yoga                                     │   │
│  │ ☐  Meal prep for week                               │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Model Changes

### New: AlertConfig

```dart
/// Configuration for a single alert type
@freezed
class AlertConfig with _$AlertConfig {
  const factory AlertConfig({
    required ProblemType problemType,
    required bool enabled,
    required AlertSeverity severity,
  }) = _AlertConfig;

  factory AlertConfig.fromJson(Map<String, dynamic> json) =>
      _$AlertConfigFromJson(json);
}

/// Severity levels for alerts (3-level system)
enum AlertSeverity {
  @JsonValue('critical')
  critical,  // Red, top of stack

  @JsonValue('warning')
  warning,   // Amber, below critical

  @JsonValue('notice')
  notice,    // Blue chip, below focus
}
```

### Extended: DisplaySettings

```dart
@freezed
abstract class DisplaySettings with _$DisplaySettings {
  const factory DisplaySettings({
    @Default(true) bool showOrphanTaskCount,
    @Default(true) bool showProjectNextTask,
    @Default(15) int gapWarningThresholdPercent,
    @Default(4) int sparklineWeeks,
    
    /// User-configured alert settings.
    /// Empty list = no alerts shown (Firefighter default).
    /// Persona selection populates with persona defaults.
    @Default([]) List<AlertConfig> alertConfigs,
  }) = _DisplaySettings;
  
  factory DisplaySettings.fromJson(Map<String, dynamic> json) =>
      _$DisplaySettingsFromJson(json);
}
```

### Extended: DisplaySettings Factory

```dart
extension DisplaySettingsDefaults on DisplaySettings {
  /// Get default alert configs for a persona
  static List<AlertConfig> alertsForPersona(AllocationPersona persona) {
    switch (persona) {
      case AllocationPersona.idealist:
        return const [
          AlertConfig(
            problemType: ProblemType.taskOrphan,
            enabled: true,
            severity: AlertSeverity.notice,
          ),
        ];
      
      case AllocationPersona.reflector:
        return const [
          AlertConfig(
            problemType: ProblemType.taskUrgentExcluded,
            enabled: true,
            severity: AlertSeverity.warning,
          ),
          AlertConfig(
            problemType: ProblemType.allocationUnbalanced,
            enabled: true,
            severity: AlertSeverity.notice,
          ),
          AlertConfig(
            problemType: ProblemType.taskOrphan,
            enabled: true,
            severity: AlertSeverity.notice,
          ),
        ];
      
      case AllocationPersona.realist:
        return const [
          AlertConfig(
            problemType: ProblemType.taskOverdue,
            enabled: true,
            severity: AlertSeverity.critical,
          ),
          AlertConfig(
            problemType: ProblemType.taskUrgentExcluded,
            enabled: true,
            severity: AlertSeverity.warning,
          ),
          AlertConfig(
            problemType: ProblemType.taskOrphan,
            enabled: true,
            severity: AlertSeverity.notice,
          ),
        ];
      
      case AllocationPersona.firefighter:
        return const []; // No alerts - urgency is the view
      
      case AllocationPersona.custom:
        return const []; // User configures
    }
  }
}
```

---

## Architecture Integration

### Reuse Strategy

| Component | Reuse? | Notes |
|-----------|--------|-------|
| `ProblemType` enum | ✅ Yes | Already defines all relevant problem types |
| `ProblemDefinition` | ✅ Partial | Use for descriptions, icons; ignore its severity (user-defined) |
| `ProblemDetectorService` | ✅ Yes | Core detection logic reused |
| `AllocationResult.excludedTasks` | ✅ Yes | Already provides excluded task data |
| `SupportBlock.problemSummary` | ✅ Extend | Add severity grouping capability |
| `DisplaySettings` | ✅ Extend | Add `alertConfigs` field |

### New Components

| Component | Purpose |
|-----------|---------|
| `AlertConfig` | User's enabled/severity choice per problem type |
| `AlertSeverity` | 3-level severity enum (Critical, Warning, Notice) |
| `AlertBannerWidget` | Renders banners based on severity |
| `FocusAlertsSection` | Settings UI for alert configuration |
| `AlertPreviewWidget` | Live preview in settings |

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                        Settings                             │
│  AllocationConfig.displaySettings.alertConfigs              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  AllocationOrchestrator                     │
│  - Computes allocatedTasks and excludedTasks               │
│  - Returns AllocationResult with excludedUrgentTasks       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  SupportBlockComputer                       │
│  - Receives excludedUrgentTasks                            │
│  - Cross-references with alertConfigs                      │
│  - Groups by user-defined severity                         │
│  - Returns SupportBlockResult.alertBanner(...)             │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    SectionWidget                            │
│  - Renders AlertBannerWidget for each severity             │
│  - Renders "Outside Focus" section with grouped tasks      │
└─────────────────────────────────────────────────────────────┘
```

### Key Integration Points

1. **AllocationSettingsPage** (`allocation_settings_page.dart`)
   - Add new `_buildFocusAlertsSection()` method
   - Include alert config in save operation
   - Trigger auto-switch to Custom when alerts modified

2. **DisplaySettings** (`allocation_config.dart`)
   - Add `alertConfigs` field
   - Add `alertsForPersona()` factory

3. **SupportBlockComputer** (`support_block_computer.dart`)
   - Extend `_computeProblemSummary()` to group by user severity
   - Pass alert configs to computation

4. **SectionWidget** (`section_widget.dart`)
   - Add `_buildAlertBanner()` method
   - Render banners above focus section

5. **New Widget: AlertBannerWidget**
   - Takes severity + count + message
   - Renders appropriate style per severity
   - Tappable to expand/scroll to details

---

## Implementation Phases

### Phase 1: Data Model
- [ ] Add `AlertSeverity` enum
- [ ] Add `AlertConfig` model
- [ ] Extend `DisplaySettings` with `alertConfigs`
- [ ] Add `alertsForPersona()` factory method
- [ ] Update serialization/code generation

### Phase 2: Settings UI
- [ ] Add `FocusAlertsSection` widget
- [ ] Add `AlertPreviewWidget` for live preview
- [ ] Integrate into `AllocationSettingsPage`
- [ ] Implement auto-switch to Custom persona
- [ ] Add localization strings

### Phase 3: Banner Rendering
- [ ] Create `AlertBannerWidget`
- [ ] Extend `SupportBlockComputer` for severity grouping
- [ ] Add banner rendering to `SectionWidget`
- [ ] Style banners per severity (Critical, Warning, Notice)

### Phase 4: Outside Focus Section
- [ ] Create `OutsideFocusSection` widget
- [ ] Group tasks by severity within section
- [ ] Add inline actions (Assign Value, Defer)
- [ ] Connect banner tap to scroll-to-section

---

## Open Questions

1. **Should Firefighter have any alerts?** Current design: No, urgency is the view structure. Alternative: Allow optional overdue alert.

2. **Should Notice severity appear as banner or only in section?** Current design: Inline chip below focus list. Alternative: Collapsible banner.

3. **Should we support custom problem types?** Current design: No, reuse existing `ProblemType`. Future: Could add user-defined problem types.

4. **How to handle zero-state?** When no problems exist, show nothing (clean focus view).
