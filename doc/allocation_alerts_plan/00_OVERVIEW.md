# Allocation Alerts Plan - Overview

> **Status:** Planning  
> **Created:** 2026-01-04  
> **Scope:** My Day unified view + allocation alert system

## Executive Summary

Replace `Today` and `Next Actions` screens with unified `My Day` view featuring:
- Persona-driven Focus allocation (existing)
- Configurable alert banners for excluded tasks (new)
- Actionable "Outside Focus" section with full task interaction (new)

## Design Decisions

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| 1 | Alert templates | Code-defined constants | Simple Phase 1, extensible later |
| 2 | Alert types | 5 types (urgent, overdue, noValue, lowPriority, quotaFull) | Maps to existing ExcludedTask data |
| 3 | Agenda section | Not included | Upcoming screen handles deadlines |
| 4 | Banner interaction | Hybrid: compact banner + scroll to bottom section | Clean Focus, full task interaction |
| 5 | ProblemType.taskUrgentExcluded | Remove entirely | Replaced by AllocationAlertType |
| 6 | Route migration | Hard remove /today, /next-actions | No redirects needed |
| 7 | Settings persistence | Separate AllocationAlertSettings key | Independent of allocation strategy |

## Architecture: Two Separate Systems

```
┌─────────────────────────────────────────────────────────────────┐
│                        SCREEN DEFINITION                        │
├─────────────────────────────────────────────────────────────────┤
│  SupportBlock.problemSummary     │  Section.allocation          │
│  ────────────────────────────    │  ─────────────────────────   │
│  Query-based problems:           │  Allocation alerts:          │
│  • taskOverdue                   │  • urgentExcluded            │
│  • taskStale                     │  • overdueExcluded           │
│  • taskOrphan                    │  • noValueExcluded           │
│  • projectIdle                   │  • lowPriorityExcluded       │
│                                  │  • quotaFullExcluded         │
│                                  │                              │
│  Rendered: Above sections        │  Rendered: Within allocation │
│  Purpose: "What's wrong?"        │  Purpose: "Why not in Focus?"|
└─────────────────────────────────────────────────────────────────┘
```

## My Day Screen Definition

```dart
static final myDay = ScreenDefinition.dataDriven(
  id: 'my_day',
  screenKey: 'my_day',
  name: 'My Day',
  screenType: ScreenType.focus,
  sections: [
    Section.allocation(
      displayMode: AllocationDisplayMode.pinnedFirst,
      showExcludedSection: true,  // NEW: enables bottom section
    ),
  ],
  // Note: No agenda section - Upcoming handles deadlines
);
```

## UI Layout

```
┌─────────────────────────────────────────┐
│ My Day                          [gear]  │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ 🔴 3 items outside Focus   [Review→]│ │ ← Alert banner (if any)
│ └─────────────────────────────────────┘ │
│                                         │
│ ══ Pinned ══════════════════════════   │
│   [ ] Critical fix            📌        │
│                                         │
│ ══ Health (2/3) ════════════════════   │
│   [ ] Morning workout         🔥        │
│   [ ] Meal prep               🔥        │
│                                         │
│ ══ Career (1/2) ════════════════════   │
│   [ ] Review PR               ⭐        │
│                                         │
│ ══ Needs Attention (3) ═════════════   │ ← Persona-named section
│   Overdue                               │
│     [!] Fix login bug         Jan 2    │
│   Urgent                                │
│     [ ] Review specs          ⚡ 2d    │
│     [ ] Call supplier         ⚡ today │
└─────────────────────────────────────────┘
```

## Persona Section Names

| Persona | Section Title |
|---------|---------------|
| Idealist | "Needs Alignment" |
| Reflector | "Worth Considering" |
| Realist | "Overdue Attention" |
| Firefighter | "Active Fires" |
| Custom | "Outside Focus" |

## Phase Overview

### Phase 1: Core Implementation
- **1a:** Alert models and templates
- **1b:** AllocationAlertEvaluator service
- **1c:** My Day screen definition (replace today/next_actions)
- **1d:** Banner widget + Outside Focus section
- **1e:** Settings integration (AllocationAlertSettings)

### Phase 2: Cleanup
- **2a:** Remove ProblemType.taskUrgentExcluded
- **2b:** Delete legacy widgets
- **2c:** Update tests
- **2d:** Remove old routes

### Phase 3: Polish
- **3a:** Settings UI for alert configuration
- **3b:** Persona defaults auto-apply
- **3c:** Accessibility review

## File Changes Summary

| Category | Files | Action |
|----------|-------|--------|
| Create | 5-6 | Alert models, evaluator, banner, section widget, settings |
| Modify | 8-10 | SystemScreenDefinitions, Section model, SectionWidget, settings |
| Delete | 3-4 | Legacy widgets, ProblemType bridge code |
| Test | 12-15 | New tests + updates to existing |

## Dependencies

```
Phase 1a (Models) 
    ↓
Phase 1b (Evaluator) → Phase 1c (Screen Definition)
    ↓                         ↓
Phase 1d (UI) ←───────────────┘
    ↓
Phase 1e (Settings)
    ↓
Phase 2 (Cleanup)
    ↓
Phase 3 (Polish)
```

## Success Criteria

- [ ] My Day renders with allocation section
- [ ] Alert banner shows when excluded tasks match enabled rules
- [ ] Banner click scrolls to Outside Focus section
- [ ] Outside Focus section shows grouped tasks with full interaction
- [ ] Section hidden when no alerts triggered
- [ ] Persona templates apply correct defaults
- [ ] Settings persist per user
- [ ] All existing tests pass or updated

---

## AI Implementation Instructions

When implementing this plan:

1. **Read phase document first** - Each phase has detailed specs
2. **Follow existing patterns** - Match freezed model style, BLoC patterns
3. **Run tests after each file** - Catch issues early
4. **Use existing infrastructure** - ExcludedTask, SectionWidget, etc.
5. **Don't over-engineer** - Phase 1 is intentionally simple
