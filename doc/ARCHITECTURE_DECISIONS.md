# Architecture Decision Records

This document captures design decisions made during the screen architecture redesign.

---

## DR-001: Remove NavigationSection

**Status**: Approved  
**Context**: NavigationSection was redundant with app-level navigation  
**Decision**: Remove NavigationSection from Section types  
**Consequence**: Simpler section model, navigation handled at app level

---

## DR-002: Query Embedded in DataConfig

**Status**: Approved  
**Context**: Need to define what data a section displays  
**Decision**: Embed query object directly in DataConfig (Model C-1)  
**Consequence**: Self-contained section definitions, clear data ownership

---

## DR-003: ValueQuery = LabelQuery Typedef

**Status**: Approved  
**Context**: Values are labels with type=value  
**Decision**: `typedef ValueQuery = LabelQuery` with type constraint  
**Consequence**: Reuse existing LabelQuery, no new types needed

---

## DR-004: LabelMatchMode Enum

**Status**: Approved  
**Context**: Need to specify how multiple labels match  
**Decision**: Create `LabelMatchMode` enum (any, all, none)  
**Consequence**: Clear semantics for label filtering

---

## DR-005: Remove ValueHierarchyOptions

**Status**: Approved  
**Context**: Value hierarchy display was over-engineered  
**Decision**: Remove ValueHierarchyOptions, use related data instead  
**Consequence**: Simpler model, hierarchy handled via RelatedDataConfig

---

## DR-006: Query Convenience Factories

**Status**: Approved  
**Context**: Common queries should be easy to create  
**Decision**: Add factory methods like `TaskQuery.dueToday()`, `TaskQuery.byProject()`  
**Consequence**: Better DX, self-documenting code

---

## DR-007: No Repository Coupling

**Status**: Approved  
**Context**: Queries shouldn't know about repositories  
**Decision**: Queries are pure data, repositories interpret them  
**Consequence**: Clean separation, testable queries

---

## DR-008: Hybrid Data Fetching

**Status**: Approved  
**Context**: Some views need eager loading, some need lazy  
**Decision**: RelatedDataConfig controls eager vs lazy per-section  
**Consequence**: Flexible, performance-optimized data fetching

---

## DR-009: Related Entity Filtering + Inheritance

**Status**: Approved  
**Context**: Tasks can inherit values from projects  
**Decision**: Support `LabelInheritance` mode (explicit, inherited, both)  
**Consequence**: Accurate value-based filtering across hierarchy

---

## DR-010: Repository Params for Related Data

**Status**: Approved  
**Context**: Need to filter related entities without coupling  
**Decision**: `watchAll({query, relatedTaskFilter, relatedLabelFilter})` flat params  
**Consequence**: No nesting, prevents infinite recursion, clear API

---

## DR-011: Entity Widget Default Navigation

**Status**: Approved  
**Context**: 6+ duplicate `_showTaskDetailSheet` methods across screens  
**Decision**: EntityNavigator centralized navigation, widgets have optional onTap with default  
**Consequence**: DRY code, consistent navigation behavior

---

## DR-012: Unified ScreenBloc

**Status**: Approved  
**Context**: ViewBloc + TaskOverviewBloc + ProjectOverviewBloc + LabelOverviewBloc overlap  
**Decision**: Single ScreenBloc driven by ScreenConfig  
**Consequence**: -5 BLoCs, -2 mixins, simpler architecture

---

## DR-015: Three-Mode Urgency Handling

**Status**: Approved  
**Date**: 2026-01-03  
**Context**: Focus screen builder had confusing interaction between:
- Strategy selection (Proportional vs Urgency Weighted)
- Urgency influence slider (0-100%)
- "Always include urgent" checkbox

Users couldn't understand how these controls related to each other.

**Decision**: Replace with three mutually exclusive urgency modes:

| Mode | UI Name | Technical Mapping | Behavior |
|------|---------|-------------------|----------|
| 1 | ⚖️ Values Only | `strategyType: proportional`, `urgencyInfluence: 0.0` | Pure value-based selection, deadlines ignored |
| 2 | 🔀 Balanced | `strategyType: urgencyWeighted`, `urgencyInfluence: 0.4` (adjustable) | Values + deadlines combined, slider for fine-tuning |
| 3 | 🚨 Urgent First | `strategyType: proportional`, `alwaysIncludeUrgent: true` | Urgent tasks always appear, remaining slots by values |

**Default**: 🔀 Balanced with 40% urgency weight (matches existing `urgencyInfluence = 0.4` default)

**UI Behavior**:
- Radio selection between three modes
- Urgency slider only visible when Balanced selected
- Warning shown when Urgent First selected ("May exceed your maximum task limit")

**Consequence**: 
- Clear mental model for users
- Single control instead of three interacting controls
- Maps cleanly to existing technical implementation
- Easy to extend with future modes

---

## DR-016: Focus Screen Builder UI Pattern

**Status**: Approved  
**Date**: 2026-01-03  
**Context**: Need to design screen builder UI for Focus/Allocation screens

**Decision**: Progressive Single Page with All Sections Visible

**Structure**:
```
┌─────────────────────────────────────────────────┐
│ Screen name: [____________]                     │
├─────────────────────────────────────────────────┤
│ ⭐ URGENCY MODE (DR-015)                        │
│   ○ Values Only                                 │
│   ● Balanced [slider: 40%]                      │
│   ○ Urgent First                                │
│   Maximum tasks: [slider: 10]                   │
├─────────────────────────────────────────────────┤
│ ⚙️ FINE-TUNE                                    │
│   Urgency definition: [3] days                  │
│   ☑ Warn when urgent excluded                   │
│   Min tasks per value: [1]                      │
│   ☐ Allow exceeding limit for minimums          │
├─────────────────────────────────────────────────┤
│ 📁 NARROW SOURCE                                │
│   ● All tasks                                   │
│   ○ Specific projects: [Select...]              │
│   ○ Custom filters: [Add filter...]             │
│   ☑ Include inbox  ☑ Exclude future starts      │
├─────────────────────────────────────────────────┤
│ PREVIEW                                         │
│   10 tasks • Balanced: 4 Career + 3 Family...   │
└─────────────────────────────────────────────────┘
```

**Key Principles**:
1. All sections visible (no hidden options)
2. All fine-tune options visible (no "More options..." for core settings)
3. Source narrowing uses radio + reveal pattern
4. Live preview always visible
5. Single scrollable page

**Consequence**: Users see all options exist, can create Focus screen in 2 clicks with defaults, power users can tune without hunting for settings

---

## DR-017: Unified Screen Model

**Status**: Approved  
**Date**: 2026-01-03  
**Context**: Currently have separate concepts: Screen, Section, Dashboard. This creates complexity in the builder UI and model layer.

**Decision**: All screens are multi-section by design

- Every screen has 1+ sections
- A "simple" screen is just a screen with one section
- Dashboards are screens with multiple sections
- Focus screens are screens with focus-specific section type

**Structure**:
```dart
class Screen {
  String id;
  String name;
  ScreenType type;           // list, dashboard, focus, workflow
  List<Section> sections;    // Always 1+
  List<SupportBlock> supportBlocks;  // System + user configured
}
```

**Consequence**: 
- One unified model
- Screen builder always shows "Add Section" option
- Simplifies Dashboard vs Screen distinction
- Support blocks can be system-injected or user-configured

---

## DR-018: Problem Detection as Configurable SupportBlock (Hybrid)

**Status**: Approved  
**Date**: 2026-01-03  
**Context**: Problem detection currently exists as a separate system (`ProblemDetectorService` + `DisplayConfig.problemsToDetect`). Need to integrate with SupportBlock infrastructure while maintaining inline task indicators.

**Decision**: Hybrid approach with two layers

### Layer 1: Summary Banner (SupportBlock)
```dart
const factory SupportBlock.problemSummary({
  @Default([]) List<ProblemType> problemTypes,  // Opt-in to 1..M types
  @Default(true) bool showInlineIndicators,     // Also mark tasks inline
}) = ProblemSummaryBlock;
```

### Layer 2: Inline Indicators (Retained)
Keep ⚠️ indicators on individual affected tasks for immediate visibility.

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  GLOBAL SETTINGS: Problem Rules (thresholds)                    │
│                                                                 │
│  Built-in:                                                      │
│  - urgentDeadlineWithinDays: 7                                  │
│  - staleAfterDaysWithoutUpdates: 30                             │
│                                                                 │
│  Custom (Future - Phase 2):                                     │
│  - User-defined problem rules stored in Settings                │
│  - e.g., "Stale high-priority" = no update in 14d + priority=high│
│  - Each custom rule gets a ProblemType identifier               │
└─────────────────────────────────────────────────────────────────┘
                              ↓ defines available problems
┌─────────────────────────────────────────────────────────────────┐
│  PER-BLOCK: SupportBlock.problemSummary()                       │
│                                                                 │
│  - Selects 1..M problem types to detect                         │
│  - Checkboxes for easy multi-select                             │
│  - Both built-in and custom rules available                     │
└─────────────────────────────────────────────────────────────────┘
```

### UI for Configuration
```
┌─────────────────────────────────────────────────────────────────┐
│ Add Support Section: Problem Detection                          │
├─────────────────────────────────────────────────────────────────┤
│ Select problems to detect:                                      │
│                                                                 │
│ Built-in:                                                       │
│ ☑ Urgent tasks (due within 7 days)                              │
│ ☑ Overdue tasks                                                 │
│ ☐ Stale tasks (no updates in 30 days)                           │
│ ☐ No next actions (projects without active tasks)               │
│ ☐ Unbalanced allocation                                         │
│                                                                 │
│ Custom Rules: (Future)                                          │
│ ☐ Stale high-priority (defined in Settings)                     │
│ [+ Define new rule in Settings...]                              │
│                                                                 │
│ ☑ Show inline indicators on affected items                      │
└─────────────────────────────────────────────────────────────────┘
```

### Phase 1 (MVP)
- `ProblemSummaryBlock` with predefined `ProblemType` enum selection
- Multi-select checkboxes for easy 1..M selection
- Reuses existing `ProblemDetectorService`
- Global thresholds via `SoftGatesSettings`

### Phase 2 (Future)
- Custom problem rules defined in **Global Settings**
- Each custom rule becomes selectable in problem blocks
- Per-rule threshold overrides
- Complex conditions with filters

**Consequence**: 
- Unified rendering via SupportBlock infrastructure
- Users control which problems matter per screen/section
- Problem definitions stay global (DRY)
- Easy multi-select UX for picking problem types
- Maintains inline indicators for immediate task-level visibility

---

## DR-019: WorkflowProgressBlock is System-Only

**Status**: Approved  
**Date**: 2026-01-03  
**Context**: `WorkflowProgressBlock` shows "3 of 7 reviewed" during workflow execution.

**Decision**: WorkflowProgressBlock is automatically injected by the system for workflow screens. Users cannot add/remove it.

**Rationale**:
- Only meaningful during active workflow
- Not user-configurable (no options to set)
- System always knows when to show it

**Consequence**: 
- Not shown in "Add Support Section" picker
- System injects it when screen is workflow type
- Reduces user confusion about irrelevant options

---

## Summary Table

| DR | Decision | Status |
|----|----------|--------|
| DR-001 | Remove NavigationSection | ✅ Approved |
| DR-002 | Query in DataConfig | ✅ Approved |
| DR-003 | ValueQuery = LabelQuery typedef | ✅ Approved |
| DR-004 | LabelMatchMode enum | ✅ Approved |
| DR-005 | Remove ValueHierarchyOptions | ✅ Approved |
| DR-006 | Query convenience factories | ✅ Approved |
| DR-007 | No repository coupling | ✅ Approved |
| DR-008 | Hybrid data fetching | ✅ Approved |
| DR-009 | Related entity filtering + inheritance | ✅ Approved |
| DR-010 | Repository params for related data | ✅ Approved |
| DR-011 | Entity widget default navigation | ✅ Approved |
| DR-012 | Unified ScreenBloc | ✅ Approved |
| DR-015 | Three-mode urgency handling | ✅ Approved |
| DR-016 | Focus screen builder UI pattern | ✅ Approved |
| DR-017 | Unified Screen Model | ✅ Approved |
| DR-018 | Problem Detection as SupportBlock (Hybrid) | ✅ Approved |
| DR-019 | WorkflowProgressBlock system-only | ✅ Approved |
