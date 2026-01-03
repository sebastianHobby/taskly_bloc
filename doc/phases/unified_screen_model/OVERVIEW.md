# Unified Screen Model Implementation Plan

## Overview

This plan implements the **Unified Screen Model** architecture where user-created screens become first-class citizens equal to system screens. All screens render through a single interpretation path.

**Core Problem Solved**: User-created screens via ScreenBuilder are currently second-class citizens with limited functionality compared to system screens (Inbox, Today, Upcoming, etc.).

---

## Design Decisions Summary

| # | Decision | Choice |
|---|----------|--------|
| D1 | Reactive updates | Streams via `ScreenDataInterpreter.watchScreen()` |
| D2 | Architecture | Service-driven + Thin Bloc (~80 LOC) |
| D3 | ScreenDefinitionBloc | Keep separate (SRP) |
| D4 | Navigation | Widget routes directly via `EntityNavigator` |
| D5 | Sort persistence | `SettingsRepository` keyed by screenId |
| D6 | EntityActionService scope | complete/uncomplete, delete, pin/unpin, move |
| D7 | Edit action | Widget handles directly (NOT in EntityActionService) |

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                      Presentation Layer                         │
├─────────────────────────────────────────────────────────────────┤
│  UnifiedScreenPage                                              │
│    ├── BlocProvider<ScreenBloc>                                 │
│    ├── StreamBuilder (watchScreen)                              │
│    └── SectionWidget (renders entities)                         │
│          └── onAction → EntityNavigator / EntityActionService   │
├─────────────────────────────────────────────────────────────────┤
│                        Domain Layer                             │
├─────────────────────────────────────────────────────────────────┤
│  ScreenDataInterpreter          EntityActionService             │
│    ├── watchScreen(def)           ├── completeTask()            │
│    ├── interpretSection()         ├── uncompleteTask()          │
│    └── Stream<ScreenData>         ├── completeProject()         │
│                                   ├── deleteEntity()            │
│  EntityNavigator                  ├── pinTask()                 │
│    ├── navigateToTask()           └── moveTask()                │
│    ├── navigateToProject()                                      │
│    └── navigateToArea()                                         │
├─────────────────────────────────────────────────────────────────┤
│                         Data Layer                              │
├─────────────────────────────────────────────────────────────────┤
│  TaskRepository    ProjectRepository    ScreenRepository        │
│  AreaRepository    SettingsRepository                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## Phases Overview

### Phase 0: Domain Services Foundation
**Goal**: Create core domain services that contain all business logic.

| Task | File | LOC Est. |
|------|------|----------|
| 0.1 | Create `ScreenDataInterpreter` | ~150 |
| 0.2 | Create `EntityActionService` | ~120 |
| 0.3 | Create `EntityNavigator` | ~50 |
| 0.4 | Create `ScreenData` model | ~40 |
| 0.5 | Update domain barrel exports | ~10 |

**Validation**: `flutter analyze` passes, services compile.

---

### Phase 1: Thin ScreenBloc
**Goal**: Create the thin ScreenBloc that delegates to domain services.

| Task | File | LOC Est. |
|------|------|----------|
| 1.1 | Create `ScreenEvent` (minimal) | ~30 |
| 1.2 | Create `ScreenState` | ~40 |
| 1.3 | Create `ScreenBloc` (thin delegate) | ~80 |
| 1.4 | Create bloc barrel export | ~5 |

**Validation**: `flutter analyze` passes, freezed generates.

---

### Phase 2: UnifiedScreenPage
**Goal**: Create the single page widget that renders all screens.

| Task | File | LOC Est. |
|------|------|----------|
| 2.1 | Create `UnifiedScreenPage` widget | ~150 |
| 2.2 | Integrate with `SectionWidget` | ~30 |
| 2.3 | Wire navigation callbacks | ~20 |
| 2.4 | Wire action callbacks | ~20 |

**Validation**: Widget compiles, can render test definition.

---

### Phase 3: Router Integration
**Goal**: Connect UnifiedScreenPage to app routing.

| Task | File | LOC Est. |
|------|------|----------|
| 3.1 | Add route for unified screen | ~20 |
| 3.2 | Update navigation service | ~15 |
| 3.3 | Create `ScreenRoute` helper | ~25 |

**Validation**: Can navigate to unified screen via route.

---

### Phase 4: Migrate Inbox Screen
**Goal**: First migration - simplest system screen.

| Task | Description |
|------|-------------|
| 4.1 | Create `InboxScreenDefinition` constant |
| 4.2 | Update Inbox route to use `UnifiedScreenPage` |
| 4.3 | Verify all Inbox functionality works |
| 4.4 | Mark `InboxView` as deprecated |

**Validation**: Inbox screen works identically via unified path.

---

### Phase 5: Migrate Simple List Screens
**Goal**: Migrate Logbook and similar simple screens.

| Task | Description |
|------|-------------|
| 5.1 | Create `LogbookScreenDefinition` |
| 5.2 | Migrate Logbook route |
| 5.3 | Verify functionality |
| 5.4 | Mark legacy views deprecated |

**Validation**: Simple screens work via unified path.

---

### Phase 6: Migrate Project Screens
**Goal**: Migrate screens with project-specific features.

| Task | Description |
|------|-------------|
| 6.1 | Create `ProjectDetailScreenDefinition` factory |
| 6.2 | Update project detail route |
| 6.3 | Handle project-specific actions (complete project) |
| 6.4 | Verify project screens work |

**Validation**: Project screens fully functional.

---

### Phase 7: Migrate Allocation Screens
**Goal**: Migrate Today/Upcoming with time-based sections.

| Task | Description |
|------|-------------|
| 7.1 | Create `TodayScreenDefinition` |
| 7.2 | Create `UpcomingScreenDefinition` |
| 7.3 | Handle allocation-specific actions (pin/unpin) |
| 7.4 | Verify date grouping works |

**Validation**: Today/Upcoming work with all features.

---

### Phase 8: User-Created Screen Parity
**Goal**: Ensure ScreenBuilder screens have full feature parity.

| Task | Description |
|------|-------------|
| 8.1 | Audit all system screen features |
| 8.2 | Verify ScreenBuilder can express all features |
| 8.3 | Add any missing SectionConfig options |
| 8.4 | Update ScreenBuilder UI if needed |

**Validation**: User screens can do everything system screens can.

---

### Phase 9: Cleanup Legacy Code
**Goal**: Remove deprecated blocs, pages, and views.

| Task | Files to Delete | LOC Removed |
|------|-----------------|-------------|
| 9.1 | `task_list_bloc.dart` | ~172 |
| 9.2 | `project_list_bloc.dart` | ~237 |
| 9.3 | `inbox_view.dart` | ~200 |
| 9.4 | `upcoming_view.dart` | ~413 |
| 9.5 | `screen_host_page.dart` | ~281 |
| 9.6 | Other legacy views | ~350 |
| 9.7 | Update all imports | — |
| 9.8 | Remove deprecated exports | — |

**Validation**: `flutter analyze` passes, app runs, no dead code.

---

## Projected Impact

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| Total LOC | ~2,200 | ~550 | **-1,650** |
| List Blocs | 5 | 1 | **-4** |
| Screen Pages | ~8 | 1 | **-7** |
| Test Suites | ~10 | ~4 | **-6** |

---

## AI Implementation Instructions

Copy to each phase file:

```markdown
## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each task. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Reuse**: Check existing patterns in codebase before creating new ones.
- **Imports**: Use absolute imports (`package:taskly_bloc/...`).
```

---

## File Index

| Phase | Detail File |
|-------|-------------|
| P0 | `PHASE_0_DOMAIN_SERVICES.md` |
| P1 | `PHASE_1_THIN_BLOC.md` |
| P2 | `PHASE_2_UNIFIED_PAGE.md` |
| P3 | `PHASE_3_ROUTER.md` |
| P4 | `PHASE_4_MIGRATE_INBOX.md` |
| P5 | `PHASE_5_MIGRATE_SIMPLE.md` |
| P6 | `PHASE_6_MIGRATE_PROJECTS.md` |
| P7 | `PHASE_7_MIGRATE_ALLOCATION.md` |
| P8 | `PHASE_8_USER_SCREEN_PARITY.md` |
| P9 | `PHASE_9_CLEANUP.md` |

---

## Dependencies Between Phases

```
P0 ──► P1 ──► P2 ──► P3 ──┬──► P4 ──► P5 ──► P6 ──► P7 ──► P8 ──► P9
                          │
                          └── (P4-P8 can partially parallelize)
```

- **P0-P3**: Sequential, each depends on previous
- **P4-P8**: Can be done in any order after P3
- **P9**: Must be last, after all migrations complete

---

## Getting Started

1. Read this overview
2. Open `PHASE_0_DOMAIN_SERVICES.md`
3. Complete all tasks in order
4. Run validation
5. Proceed to next phase
