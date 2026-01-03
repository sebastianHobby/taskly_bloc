# DR-021: Allocation Section Configuration

**Status**: Draft (Workshop Needed)  
**Date**: 2026-01-03  
**Context**: Unified Screen Architecture - Allocation Configuration

---

## Summary

Enrich `AllocationSection` configuration to support different display modes, urgency settings, and per-section overrides. **Design TBD - requires workshop.**

---

## Current State

```dart
const factory Section.allocation({
  @NullableTaskQueryConverter() TaskQuery? sourceFilter,
  int? maxTasks,
  String? title,
}) = AllocationSection;
```

---

## Potential Configuration Options

### A. Display Modes (Under Discussion)

| Mode | Description | UI Pattern |
|------|-------------|------------|
| `focusSingle` | One task at a time | Single card, swipe to complete |
| `groupedByValue` | Tasks grouped by qualifying value | Current `NextActionsView` |
| `flatList` | Simple prioritized list | Standard list view |
| `timeline` | Time-based slots | Quick/medium/deep work buckets |
| `matrix` | Eisenhower urgent×important | 2×2 grid |

### B. Urgency Settings (Under Discussion)

- `urgencyThresholdDays: int?` - Days before deadline = "urgent"
- `showExcludedWarning: bool?` - Whether to show excluded urgent banner
- `urgencyMode: UrgencyDisplayMode?` - How to highlight urgent tasks

### C. Strategy Overrides (Under Discussion)

- `strategyOverride: AllocationStrategyType?` - Per-section strategy
- `customWeights: Map<String, double>?` - Per-section value weights

### D. Completion Behavior (Under Discussion)

- `showRecentlyCompleted: bool?` - Include recently completed tasks
- `completionCelebration: bool?` - Show celebration when all done
- `autoRefreshOnEmpty: bool?` - Auto-fetch more when list empty

---

## Open Questions for Workshop

1. **Which display modes are MVP vs future?**
2. **Should urgency settings be global (AppSettings) or per-section?**
3. **Do we need strategy override or is global sufficient?**
4. **How does allocation interact with screen-level SupportBlocks?**
5. **Should pinned tasks be a separate section or embedded?**

---

## Dependencies

- DR-020: Must complete result enrichment first
- AllocationSettings in AppSettings (global configuration)
- Value ranking system

---

## Related Decisions

- DR-017: Unified Screen Model
- DR-020: AllocationSectionResult Enrichment
