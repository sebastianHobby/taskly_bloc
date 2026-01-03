# Values Screen & Personas - Implementation Analysis

> **Status**: Implementation Planning  
> **Created**: 2026-01-03  
> **Source**: [VALUES_SCREEN_CONCEPT.md](./VALUES_SCREEN_CONCEPT.md)

---

## Executive Summary

This document analyzes the current codebase state against the proposed Values Screen and Allocation Personas concept. It identifies what exists, what's missing, and provides implementation estimates.

---

## Current State Analysis

### 1. AllocationSettings (✅ Exists - Needs Extension)

**File**: [allocation_settings.dart](../../lib/domain/models/settings/allocation_settings.dart)

**Current Fields:**
| Field | Type | Default | Status |
|-------|------|---------|--------|
| `strategyType` | `AllocationStrategyType` | `proportional` | ✅ Exists |
| `urgencyInfluence` | `double` | `0.4` | ✅ Exists |
| `alwaysIncludeUrgent` | `bool` | `false` | ✅ Exists |
| `minimumTasksPerCategory` | `int` | `1` | ✅ Exists |
| `topNCategories` | `int` | `3` | ✅ Exists |
| `dailyTaskLimit` | `int` | `10` | ✅ Exists |
| `showExcludedUrgentWarning` | `bool` | `true` | ✅ Exists |

**Fields Needed (from concept):**
| Field | Type | Default | Purpose |
|-------|------|---------|---------|
| `persona` | `AllocationPersona` | `realist` | ❌ **NEW** - Primary persona selection |
| `valueAlignedUrgencyBoost` | `double` | `1.5` | ❌ **NEW** - Boost for urgent+value-aligned tasks |
| `urgencyThresholdDays` | `int` | `3` | ⚠️ Used in code but NOT persisted |
| `neglectInfluence` | `double` | `0.7` | ❌ **NEW** - For Reflector mode |
| `reflectorLookbackDays` | `int` | `7` | ❌ **NEW** - Lookback for neglect calculation |

**Current UrgencyMode Enum (DR-015):**
```dart
enum UrgencyMode {
  valuesOnly,   // Maps to Idealist
  balanced,     // Maps to Realist (partially)
  urgentFirst,  // Maps to Firefighter (partially)
}
```

### 2. AllocationPersona (❌ Does Not Exist)

**Required Implementation:**
```dart
enum AllocationPersona {
  idealist,
  reflector,
  realist,
  firefighter,
  custom,
}
```

**Mapping to existing UrgencyMode:**
| Persona | UrgencyMode | Notes |
|---------|-------------|-------|
| Idealist | `valuesOnly` | Direct mapping |
| Reflector | N/A | ❌ No equivalent - needs new logic |
| Realist | `balanced` | Partial - needs warning enhancement |
| Firefighter | `urgentFirst` | Direct mapping |
| Custom | N/A | User-configurable |

### 3. AllocationOrchestrator (✅ Exists - Needs Enhancement)

**File**: [allocation_orchestrator.dart](../../lib/domain/services/allocation/allocation_orchestrator.dart)

**Current Capabilities:**
- ✅ Watches allocation settings + value rankings
- ✅ Partitions pinned vs regular tasks
- ✅ Generates `AllocationWarning` for excluded urgent tasks
- ✅ Uses `ProportionalAllocator` and `UrgencyWeightedAllocator`

**Missing for Personas:**
- ❌ Reflector/neglect-based allocation strategy
- ❌ `valueAlignedUrgencyBoost` logic
- ❌ Persona-aware strategy selection
- ⚠️ `urgencyThresholdDays` hardcoded to 3 (line 105)

### 4. Allocation Strategies (✅ Partial)

**File**: [allocation_strategy.dart](../../lib/domain/services/allocation/allocation_strategy.dart)

**Implemented:**
- ✅ `ProportionalAllocator` - For Idealist
- ✅ `UrgencyWeightedAllocator` - For Realist/Firefighter

**Missing:**
- ❌ `NeglectBasedAllocator` - For Reflector persona
- ❌ Boost calculation for value-aligned urgent tasks

### 5. ValueRanking (✅ Exists - Sufficient)

**File**: [value_ranking.dart](../../lib/domain/models/settings/value_ranking.dart)

**Current Fields:**
- `items: List<ValueRankItem>` - Contains `labelId`, `weight`, `sortOrder`

**Status**: ✅ Sufficient for all personas

### 6. Value Overview Screen (✅ Exists - Needs Major Enhancement)

**File**: [value_overview_view.dart](../../lib/presentation/features/labels/view/value_overview_view.dart)

**Current State:**
- Simple list of value labels with `LabelListTile`
- Sort functionality
- Add/edit value via modal sheet

**Missing for Concept (Mockup 1):**
| Feature | Status |
|---------|--------|
| Active tasks/projects count per value | ❌ Missing |
| Completed work % (last 30 days) | ❌ Missing |
| Target % (from weight) | ❌ Missing |
| Gap warning (actual vs target) | ❌ Missing |
| Drag-to-reorder (with auto weights) | ❌ Missing |
| Trend chart (4 weeks) | ❌ Missing |
| Mood correlation per value | ❌ Missing |
| Unassigned work section | ❌ Missing |

### 7. Analytics Service (✅ Exists - Needs Extension)

**File**: [analytics_service.dart](../../lib/domain/services/analytics/analytics_service.dart)

**Current Capabilities:**
- ✅ `getTaskStat()` - Various task statistics
- ✅ `getMoodTrend()` - Mood over time
- ✅ `calculateCorrelation()` - Mood vs entity
- ✅ `getTopMoodCorrelations()` - Top 5/10 correlations

**Missing Methods:**
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

/// Get active task/project count per value
Future<Map<String, ValueActivityStats>> getValueActivityStats();

/// Get recent completions by value (for Reflector neglect score)
Future<Map<String, int>> getRecentCompletionsByValue({
  required int lookbackDays,
});
```

### 8. Allocation Settings UI (✅ Exists - Needs Persona Redesign)

**File**: [allocation_settings_page.dart](../../lib/presentation/features/next_action/view/allocation_settings_page.dart)

**Current UI:**
- Radio buttons for `AllocationStrategyType` (6 options, only 2 enabled)
- Sliders/inputs for settings
- Value ranking via drag-to-reorder list

**Issues:**
- Too technical (shows strategy types directly)
- No persona-based selection
- `urgencyThresholdDays` displayed but NOT persisted

### 9. Wellbeing Dashboard (✅ Exists - Partial)

**File**: [wellbeing_dashboard_screen.dart](../../lib/presentation/features/wellbeing/view/wellbeing_dashboard_screen.dart)

**Current:**
- ✅ Mood trend chart
- ✅ Top mood correlations (via `CorrelationCard`)

**Missing:**
- ❌ Per-value mood correlation breakdown
- ❌ "Days with X tasks: avg mood Y" insight
- ❌ Value-specific wellbeing view

---

## Gap Summary

### Model Layer (Domain)

| Component | Gap | Effort |
|-----------|-----|--------|
| `AllocationPersona` enum | Create new | S |
| `AllocationSettings` fields | Add 4 new fields | M |
| `AllocationSettings.fromJson/toJson` | Update serialization | S |
| `AllocationSettings.withPersona()` | New method | S |
| `ValueActivityStats` model | Create new | S |
| `WeeklyValueStat` model | Create new | S |

### Service Layer

| Component | Gap | Effort |
|-----------|-----|--------|
| `NeglectBasedAllocator` | New strategy class | L |
| `AllocationOrchestrator` persona routing | Enhance existing | M |
| `AnalyticsService` value distribution | New methods | M |
| `AnalyticsService` neglect calculation | New method | M |

### Presentation Layer

| Component | Gap | Effort |
|-----------|-----|--------|
| `ValueOverviewView` enhanced | Major rewrite | XL |
| Persona selection UI | New widget | L |
| Allocation settings page | Redesign | L |
| Value detail modal | New/enhanced widget | L |
| "Values required" gateway | New widget | M |

### Data Layer

| Component | Gap | Effort |
|-----------|-----|--------|
| Settings persistence | Add new fields | S |
| Task completion queries by value | New repository method | M |

---

## Implementation Phases

### Phase 1: Model Foundation (Est: 2-3 days)

1. **Add `AllocationPersona` enum**
   - Create enum with 5 values
   - Add extension method `toSettings()`
   
2. **Extend `AllocationSettings`**
   - Add `persona` field (default: `realist`)
   - Add `valueAlignedUrgencyBoost` (default: `1.5`)
   - Add `urgencyThresholdDays` (default: `3`) - persisted
   - Add `neglectInfluence` (default: `0.7`)
   - Add `reflectorLookbackDays` (default: `7`)
   - Update `fromJson`/`toJson`
   - Update `copyWith`
   - Add `withPersona(AllocationPersona)` method

3. **Update tests**
   - [allocation_settings_test.dart](../../test/domain/models/settings/allocation_settings_test.dart)

### Phase 2: Service Enhancement (Est: 3-4 days)

1. **Create `NeglectBasedAllocator`**
   - Implement `AllocationStrategy` interface
   - Calculate neglect score per value
   - Require lookback days + completions data

2. **Enhance `AllocationOrchestrator`**
   - Add persona-aware strategy selection
   - Support `valueAlignedUrgencyBoost`
   - Pass `urgencyThresholdDays` from settings (not hardcoded)

3. **Extend `AnalyticsService`**
   - Add `getValueCompletionDistribution()`
   - Add `getRecentCompletionsByValue()`
   - Add `getValueActivityStats()`

### Phase 3: Persona Selection UI (Est: 2-3 days)

1. **Create `PersonaSelectionCard` widget**
   - Shows icon, name, tagline
   - Recommended badge for Realist
   - Expandable "How it works" section

2. **Redesign `AllocationSettingsPage`**
   - Replace strategy radio with persona selection
   - Show Custom configuration only when Custom selected
   - Remove technical strategy types from UI

### Phase 4: Enhanced Values Screen (Est: 5-7 days)

1. **Create `ValueStatisticsService`**
   - Aggregate active tasks/projects
   - Calculate target % from weights
   - Detect gaps

2. **Create `EnhancedValueCard` widget**
   - Display actual vs target %
   - Gap warning badge
   - Tap to expand with trend/correlation

3. **Create `ValueDetailModal`**
   - Statistics section
   - 4-week trend chart
   - Mood correlation insight
   - Navigation to tasks/projects

4. **Add "Unassigned Work" section**

5. **Add drag-to-reorder with auto-weights**

### Phase 5: Values Gateway (Est: 1-2 days)

1. **Create `ValuesRequiredGateway` widget**
   - Full-screen when 0 values
   - Banner mode for gentle reminder
   
2. **Integrate with Focus/Next Actions screens**

### Phase 6: Reflector Mode (Est: 3-4 days)

1. **Implement neglect score calculation**
2. **Wire into allocation flow**
3. **Add "Why this?" tooltip showing neglect reasoning**

---

## Effort Estimates

| Phase | Effort | Dependencies |
|-------|--------|--------------|
| Phase 1: Model | 2-3 days | None |
| Phase 2: Services | 3-4 days | Phase 1 |
| Phase 3: Persona UI | 2-3 days | Phase 1 |
| Phase 4: Values Screen | 5-7 days | Phase 2 |
| Phase 5: Gateway | 1-2 days | Phase 1 |
| Phase 6: Reflector | 3-4 days | Phase 2 |

**Total Estimate**: 16-23 days (assuming sequential phases)

**Parallelization Opportunity**: Phase 3 + Phase 5 can run in parallel with Phase 2.

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Neglect calculation performance | Medium | Medium | Cache results, limit lookback |
| Breaking existing allocation preferences | Low | High | Migration path with defaults |
| UI complexity for non-technical users | Medium | Medium | User testing, progressive disclosure |
| Insufficient historical data for correlations | High | Low | Show "insufficient data" gracefully |

---

## Recommended Approach

1. **Start with Phase 1** - Foundation enables all other work
2. **Phase 3 early** - Persona selection simplifies user mental model
3. **Phase 4 last** - Most complex, can be iterative
4. **Phase 6 optional** - Reflector is most novel, can defer

---

## Files Requiring Changes

### Domain Layer
- `lib/domain/models/settings/allocation_settings.dart` - Extend
- `lib/domain/models/settings/allocation_persona.dart` - **NEW**
- `lib/domain/services/allocation/allocation_orchestrator.dart` - Enhance
- `lib/domain/services/allocation/neglect_based_allocator.dart` - **NEW**
- `lib/domain/services/analytics/analytics_service.dart` - Extend interface

### Data Layer
- `lib/data/features/analytics/services/analytics_service_impl.dart` - Implement new methods
- Repository queries for value-based task aggregations

### Presentation Layer
- `lib/presentation/features/next_action/view/allocation_settings_page.dart` - Redesign
- `lib/presentation/features/labels/view/value_overview_view.dart` - Major enhancement
- `lib/presentation/features/labels/widgets/` - New widgets for cards/modals

### Tests
- `test/domain/models/settings/allocation_settings_test.dart` - Update
- `test/domain/services/allocation/` - New strategy tests
- `test/presentation/features/labels/` - Widget tests

---

## Open Questions

1. **Migration**: How to handle users with existing allocation settings?
   - *Recommendation*: Default to `realist` persona, preserve custom settings

2. **Reflector lookback**: 7 days default - should this be user-configurable?
   - *Recommendation*: Yes, but hidden in Custom mode

3. **Multi-value tasks**: How to count completion for tasks with multiple values?
   - *Recommendation*: Count toward all values (may exceed 100% - document this)

4. **Performance**: Analytics queries could be expensive with large task counts.
   - *Recommendation*: Cache value stats, refresh on task completion events

---

## Next Steps

1. [ ] Review and approve implementation phases
2. [ ] Create tickets/issues for each phase
3. [ ] Begin Phase 1 implementation
4. [ ] Design user testing plan for Phase 3 UI

