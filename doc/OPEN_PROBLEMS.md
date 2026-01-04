# Open Problems for Discussion

This document captures unresolved problems identified during architectural review sessions. Use this to continue discussions in new AI sessions.

---

## Problem 1: Today/Upcoming Screen UX ✅ DESIGN PROPOSED

### Context
The Today and Upcoming screens were identified as candidates for UX improvement during a codebase review.

### Current State
- Comprehensive "My Day" design completed
- Banner system designed for surfacing problems outside Focus
- Persona-driven view variations documented
- Integration with allocation settings planned

### Proposed Solution
See **[05_MY_DAY_BANNER_SYSTEM.md](unified_predicate_plan/05_MY_DAY_BANNER_SYSTEM.md)** for full design.

**Key Design Decisions:**
1. **Contextual Banner (Option B)** - Collapsible banner above Focus showing problems
2. **Three severity levels** - Critical (red), Warning (amber), Notice (blue)
3. **User opt-in** - User enables specific problem types and sets their severity
4. **Persona defaults** - Each persona has sensible default alert configurations
5. **Auto-switch to Custom** - Changing alerts switches persona to Custom (like other settings)
6. **Reuse existing infrastructure** - `ProblemType`, `ProblemDetectorService`, `AllocationResult.excludedTasks`

### Persona View Variations
- **Idealist**: Banner shows unassigned tasks only; Focus grouped by value
- **Reflector**: Banner shows urgent + balance issues; Focus shows neglect indicators
- **Realist**: Banner shows overdue + urgent + unassigned; Focus has urgency markers
- **Firefighter**: No banner; View split by deadline (Overdue → Due Today → This Week)

### Implementation Phases
1. Data Model: `AlertConfig`, `AlertSeverity`, extend `DisplaySettings`
2. Settings UI: `FocusAlertsSection` with live preview
3. Banner Rendering: `AlertBannerWidget` per severity
4. Outside Focus Section: Grouped tasks with inline actions

### Files to Modify
- `lib/domain/models/settings/allocation_config.dart` - Add AlertConfig, AlertSeverity
- `lib/presentation/features/next_action/view/allocation_settings_page.dart` - Add alerts section
- `lib/domain/services/screens/support_block_computer.dart` - Extend for severity grouping
- `lib/presentation/widgets/section_widget.dart` - Add banner rendering

---

## Problem 2: Global Problem Detection Architecture ✅ RESOLVED

### Context
Discussion explored adding a "problem detection" system that could identify issues across the app (e.g., tasks overdue, projects stalled, habits broken).

### Resolution
**Already implemented** via `ProblemDetectorService` in `lib/domain/services/workflow/problem_detector_service.dart`.

The service:
- Uses opt-in detection based on `DisplayConfig.problemsToDetect`
- Detects: `taskOverdue`, `taskStale`, `taskOrphan`, `taskUrgentExcluded`, `projectIdle`, etc.
- Integrates with `SupportBlockComputer` for UI rendering
- Settings configurable via `SoftGatesSettings`

### Integration with Banner System
The new My Day banner system (Problem 1) reuses this infrastructure:
- `ProblemType` enum defines all problem types
- `ProblemDetectorService` provides detection logic
- User configures which problems to show and at what severity via `AlertConfig`
- See [05_MY_DAY_BANNER_SYSTEM.md](unified_predicate_plan/05_MY_DAY_BANNER_SYSTEM.md)

---

## Problem 3: TriggerConfig Architecture ✅ RESOLVED

### Context
`TriggerConfig` was mentioned as having architectural overlap with the predicate system.

### Resolution
**TriggerConfig is well-scoped and separate from predicates.**

Analysis found that `TriggerConfig` in `lib/domain/models/screens/trigger_config.dart`:
- Defines workflow trigger conditions (schedule, manual, notReviewedSince)
- Works at the **workflow level** (when to run a review)
- Does NOT overlap with task/entity filtering predicates

The distinction:
- **Predicates**: "Which tasks match?" (entity filtering)
- **TriggerConfig**: "When should this workflow run?" (scheduling)

No refactoring needed - these are appropriately separate concerns.

---

## Problem 4: Screen Definition / Query Coupling ✅ RESOLVED

### Context
During predicate architecture review, screen definitions were mentioned as consumers of query/predicate logic.

### Resolution
**Addressed by Unified Screen Model architecture.**

The current architecture in `lib/domain/models/screens/`:
- `ScreenDefinition` - Declarative screen configuration
- `Section` - Supports `data`, `allocation`, `agenda` types
- `EntitySelector` + `SelectorOptions` - Query configuration per section
- `SystemScreenDefinitions` - Predefined screens (Today, Upcoming, Focus)

Screens declaratively reference query configuration rather than duplicating logic:
- `EntitySelector` defines what to fetch
- `SelectorOptions` defines filtering/sorting
- `DisplayConfig` defines presentation
- Repositories handle actual query execution

No further coupling issues identified.

---

## How to Use This Document

### Starting a New Session

Copy the relevant problem section and use as initial prompt:

```
I'm working on a Flutter app (taskly_bloc) and want to continue discussing 
[Problem Name]. Here's the context:

[Paste problem section]

Current codebase uses:
- BLoC for state management
- Freezed for immutable data classes
- PowerSync for offline-first data

Please help me explore solutions for this problem.
```

### Updating This Document

After each discussion session:
1. Update "Current State" with new findings
2. Add new "Questions to Explore" that emerged
3. Document any decisions made
4. Remove resolved problems or move to an "Archive" section

---

## Session Notes

### Session: Jan 4, 2026 - PowerSync Sync Bounce Investigation
- **Problem**: UI flicker when changing theme settings (value shows → reverts → shows again)
- **Root Cause**: **CDC timing race** + timezone mismatch, NOT a PowerSync checkpoint bug
- **Evidence from logs**:
  - Local write at `17:53:55.604773` (local time, no 'Z')
  - Supabase stored `06:53:55.314977Z` (UTC)
  - These are the SAME moment (UTC+11 timezone)
  - BUT checkpoint contained OLD content (`themeMode: system`) with NEW timestamp
- **Why CDC race occurs**:
  1. Client writes to Supabase → WAL entry created
  2. PowerSync CDC stream is slightly behind WAL
  3. Checkpoint created from CDC position that hasn't seen new write yet
  4. Checkpoint has correct timestamp but stale content
- **Why `user_profiles` is affected more than other tables**:
  - Single row per user (vs. many rows for tasks/projects)
  - Every settings change touches same row
  - JSON blob columns replaced entirely (no field-level merge)
  - High-frequency updates during settings changes
- **Analysis of `trackPreviousValues`**:
  - NOT directly solving the problem
  - Designed for diffing in `uploadData` for custom backend merge logic
  - Doesn't prevent client-side overwrite from stale checkpoint
- **Analysis of `ignoreEmptyUpdates`**:
  - Skips uploading if no data changed
  - Doesn't help when sync *downloads* stale data
  - Still useful to reduce churn - added to schema
- **Resolution**: 
  - The existing `_pendingSave` pattern in `GlobalSettingsBloc` IS the correct approach
  - Fixed `DateTime.now()` → `DateTime.now().toUtc()` for consistent timestamp comparison
- **Changes Made**:
  - Added `trackPreviousValues: true` and `ignoreEmptyUpdates: true` to `user_profiles` schema
  - Changed `DateTime.now()` to `DateTime.now().toUtc()` in `_buildCompanion`
  - Documented in OPEN_PROBLEMS.md
- **Alternative Approaches Considered**:
  1. Server-side optimistic locking (check `updated_at` before upsert) - adds complexity
  2. Supabase Edge Function with version number - overkill for settings
  3. Wait for PowerSync to improve CDC timing - not actionable
- **Recommendation**: Keep `_pendingSave` pattern; it's the correct architectural solution

### Session: [Date of UPA Discussion]
- **Decision**: Unified Predicate Architecture (UPA) selected as solution for query duplication
- **Plan Created**: `doc/unified_predicate_plan/`
- **Scope**: Predicates, mappers, evaluators - NOT TriggerConfig or problem detection (deferred)

### Session: Jan 4, 2026 - My Day Banner Design
- **Problem 1**: Designed comprehensive My Day banner system
- **Problem 2**: Found existing `ProblemDetectorService` - already resolved
- **Problem 3**: Confirmed TriggerConfig is appropriately scoped - resolved
- **Problem 4**: Confirmed Unified Screen Model addresses this - resolved
- **Output**: Created [05_MY_DAY_BANNER_SYSTEM.md](unified_predicate_plan/05_MY_DAY_BANNER_SYSTEM.md)

### Design Decision: Separated Alert Architecture
**Decision**: Keep allocation alerts SEPARATE from query-based problems.

**Rationale**:
- Query-based problems (overdue, stale, orphan) can be expressed as database queries
- Allocation alerts (urgent excluded, unbalanced) are runtime algorithm outputs
- Mixing them in one enum creates special-case handling throughout the codebase
- Separated model has cleaner data flow and testability

**Architecture**:
- `ProblemType` enum: Query-based only (taskOverdue, taskStale, taskOrphan, projectIdle)
- `AllocationAlertType` enum: New, allocation-specific (urgentExcluded, unbalanced)
- `AllocationResult.alerts`: Allocation layer produces alerts directly
- `Section.allocation` gets `AllocationAlertConfig` for per-section configuration
- `SupportBlock.problemSummary` only handles query-based problems (not allocation)

### Design Decision: Phase 1 Allocation Alerts
**Decision**: Implement Phase 1 with 5 simple toggle options using existing data.

**Scope - 5 Alert Types (toggle + severity each)**:
1. **Overdue** - `task.deadlineDate < now` (derived from `ExcludedTask.task`)
2. **Urgent** - `isUrgent == true` (existing `ExcludedTask.isUrgent` flag)
3. **No Value** - `exclusionType == noCategory`
4. **Low Priority** - `exclusionType == lowPriority`
5. **Quota Full** - `exclusionType == categoryLimitReached`

**New Components**:
- `AllocationAlertType` enum (5 values)
- `AllocationAlertConfig` model (type + enabled + severity)
- `AlertSeverity` enum (critical, warning, notice)
- `AllocationAlertEvaluator` service
- `TriggeredAlert` result model
- Settings UI section with live preview
- Banner rendering in `SectionWidget`

**No Changes To**:
- `ExcludedTask` model (use existing fields)
- Allocator implementations
- `AllocationResult` structure

**Excluded from Phase 1** (deferred to Phase 2):
- Custom day thresholds
- Compound conditions (urgent AND no value)
- Days overdue threshold
- Custom rule names/descriptions
- Min count threshold (alert if 3+)

**Persona Defaults**:
- Idealist: noValue (Notice)
- Reflector: urgent (Warning), noValue (Notice)
- Realist: overdue (Critical), urgent (Warning), noValue (Notice)
- Firefighter: none (view structure handles urgency)
- Custom: user configures

**Status**: Ready for implementation.

### Next Session Topics
1. Implement Phase 1 allocation alerts
2. Design "Outside Focus" section UI widget
3. Update concept document with final architecture
