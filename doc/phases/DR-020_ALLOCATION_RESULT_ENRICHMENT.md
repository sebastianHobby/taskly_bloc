# DR-020: Enrich AllocationSectionResult

**Status**: Approved  
**Date**: 2026-01-03  
**Context**: Unified Screen Architecture - Allocation Parity

---

## Summary

Enrich `AllocationSectionResult` to include all data currently provided by `AllocationBloc`, enabling full feature parity when allocation screens use the unified `ScreenBloc + SectionDataService` architecture.

---

## Problem Statement

The current `AllocationSectionResult` is minimal:

```dart
const factory SectionDataResult.allocation({
  required List<Task> allocatedTasks,
  required int totalAvailable,
}) = AllocationSectionResult;
```

This loses significant data that `AllocationBloc` provides:

| Lost Data | Impact |
|-----------|--------|
| Pinned tasks (separate list) | Cannot show pinned section |
| Tasks grouped by value | Cannot show value-grouped UI |
| Excluded tasks | Cannot show excluded urgent warning |
| Allocation reasoning | Cannot show transparency info |
| Value metadata (weight, quota) | Cannot show allocation breakdown |
| Unranked value count | Cannot prompt user to rank values |

---

## Decision

Enrich `AllocationSectionResult` to include the full `AllocationResult` from the orchestrator:

```dart
const factory SectionDataResult.allocation({
  required List<AllocatedTask> pinnedTasks,
  required Map<String, AllocationGroup> tasksByValue,
  required List<ExcludedTask> excludedTasks,
  required AllocationReasoning reasoning,
  required int totalAvailable,
  required int unrankedValueCount,
}) = AllocationSectionResult;
```

### Changes Required

1. **Update `SectionDataResult.allocation`** in `section_data_result.dart`
2. **Update `SectionDataService._watchAllocationSection`** to populate all fields
3. **Update `SectionDataService._fetchAllocationSection`** to populate all fields
4. **Import `AllocationGroup` and related types** from allocation domain models

---

## Rationale

- Maintains feature parity with existing `AllocationBloc`
- Enables future deprecation of `AllocationBloc` in favor of unified architecture
- Provides all data needed for allocation-specific widgets
- Preserves allocation transparency (reasoning, excluded tasks)

---

## Implementation Notes

- Do NOT update `AllocationSection` configuration (that's DR-021)
- Do NOT add new events to `ScreenBloc` yet (that's a separate decision)
- This is a data model change only

---

## Related Decisions

- DR-017: Unified Screen Model
- DR-021: Allocation Section Configuration (TBD - workshop needed)
