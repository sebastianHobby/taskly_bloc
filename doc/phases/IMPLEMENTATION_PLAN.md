# Screen Architecture Implementation Plan

> **Version**: 2.0  
> **Date**: 2026-01-03  
> **Status**: Active  
> **Reference**: See `ARCHITECTURE_DECISIONS.md` for all design decisions (DR-001 to DR-019)

---

## Overview

This plan implements the unified screen architecture based on 19 approved design decisions.

### Key Goals
1. Unified Screen Model (DR-017) - All screens are multi-section
2. Workflow parity - Workflows use same Section model
3. Problem Detection as SupportBlock (DR-018)
4. Focus/Allocation screens with 3-mode urgency (DR-015, DR-016)
5. Unified ScreenBloc (DR-012)

### What's NOT in Scope (Future)
- Custom Problem Rules (DR-018 Phase 2) - user-defined problem criteria
- Screen Builder UI - deferred to end
- Query Builder UI (DR-013, DR-014) - deferred to end

---

## ⚠️ IMPORTANT: Clean Slate Approach

**All user data has been deleted. No migration required.**

This means:
- **DELETE old code** - do not deprecate or maintain backward compatibility
- **Replace in-place** - no dual-write, no fallback reads
- **Clean schema** - remove old columns, add new ones directly
- **No converters** - no legacy format support needed

When implementing, **delete** these files/code as you encounter them:
- `view_definition.dart` → replaced by `Section`
- `entity_selector.dart` → replaced by `DataConfig`
- Old `display_config.dart` fields → merged into `Section`
- `ViewBloc` → replaced by `ScreenBloc`
- Legacy screen seeder data → recreate with new model

---

## AI Implementation Instructions

Include these instructions at the top of each phase document:

```markdown
## AI Implementation Instructions

### Environment Setup
- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each file creation. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

### Clean Slate Rules
- **DELETE old code** - do not keep for backward compatibility
- **No migration logic** - user data has been wiped
- **Replace in-place** - update files directly, no parallel implementations
```

---

## Database Schema Changes

### Strategy: Replace In-Place (No Migration)

Since all user data is deleted, we can cleanly replace the schema.

### Columns to DELETE from `screen_definitions`

| Column | Reason |
|--------|--------|
| `selector_config` | Replaced by `sections_config` |
| `display_config` | Merged into `Section` model |
| `entity_type` | Embedded in `DataConfig` |
| `view_type` | Inferred from screen/section type |

### Columns to ADD to `screen_definitions`

| Column | Type | Purpose |
|--------|------|---------|
| `sections_config` | TEXT (JSON) | `List<Section>` - main content |
| `support_blocks_config` | TEXT (JSON) | `List<SupportBlock>` - analytics/banners |

### Final Schema Shape

```sql
screen_definitions (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  screen_type TEXT,        -- 'list' | 'dashboard' | 'focus' | 'workflow'
  screen_key TEXT,
  name TEXT,
  icon_name TEXT,
  is_system INTEGER,
  is_active INTEGER,
  sort_order INTEGER,
  category TEXT,
  sections_config TEXT,    -- JSON: List<Section>
  support_blocks_config TEXT, -- JSON: List<SupportBlock>
  trigger_config TEXT,     -- workflows only
  trigger_type TEXT,
  next_trigger_at TEXT,
  created_at TEXT,
  updated_at TEXT
)
```

---

## Phase Overview

| Phase | Name | Size | Focus | Document |
|-------|------|------|-------|----------|
| **1A** | Query Foundation - LabelQuery | Small | Create LabelQuery, LabelPredicate | [PHASE_1A](PHASE_1A_LABEL_QUERY.md) |
| **1B** | Query Foundation - Enhancements | Small | LabelMatchMode, convenience factories | [PHASE_1B](PHASE_1B_QUERY_ENHANCEMENTS.md) |
| **2A** | Section Model | Medium | Section, DataConfig, RelatedDataConfig | [PHASE_2A](PHASE_2A_SECTION_MODEL.md) |
| **2B** | Schema Update | Small | Update schema, delete old columns | [PHASE_2B](PHASE_2B_SCHEMA_UPDATE.md) |
| **2C** | Screen Definition Update | Medium | Update ScreenDefinition, delete ViewDefinition | [PHASE_2C](PHASE_2C_SCREEN_DEFINITION.md) |
| **3A** | SupportBlock Evolution | Small | ProblemSummaryBlock, system-only blocks | [PHASE_3A](PHASE_3A_SUPPORT_BLOCK.md) |
| **3B** | SupportBlock Integration | Small | SupportBlockComputer updates | [PHASE_3B](PHASE_3B_SUPPORT_BLOCK_INTEGRATION.md) |
| **4A** | Data Fetching - Service | Medium | SectionDataService | [PHASE_4A](PHASE_4A_DATA_SERVICE.md) |
| **4B** | Data Fetching - Repository Updates | Medium | Repository query params (DR-010) | [PHASE_4B](PHASE_4B_REPOSITORY_UPDATES.md) |
| **5A** | Unified ScreenBloc - Core | Medium | ScreenBloc events/state | [PHASE_5A](PHASE_5A_SCREEN_BLOC_CORE.md) |
| **5B** | Unified ScreenBloc - Handlers | Medium | ScreenBloc event handlers, DELETE ViewBloc | [PHASE_5B](PHASE_5B_SCREEN_BLOC_HANDLERS.md) |
| **6A** | Entity Navigation | Small | EntityNavigator (DR-011) | [PHASE_6A](PHASE_6A_ENTITY_NAVIGATION.md) |
| **6B** | Widget Updates | Small | Update entity widgets with default onTap | [PHASE_6B](PHASE_6B_WIDGET_UPDATES.md) |
| **7A** | Workflow Model Update | Medium | WorkflowStep uses Section | [PHASE_7A](PHASE_7A_WORKFLOW_MODEL.md) |
| **7B** | Workflow Bloc Integration | Medium | WorkflowRunBloc uses ScreenBloc patterns | [PHASE_7B](PHASE_7B_WORKFLOW_BLOC.md) |
| **8** | System Screen Seeder | Medium | Recreate 11 system screens with new model | [PHASE_8](PHASE_8_SYSTEM_SEEDER.md) |
| **9** | Final Cleanup | Medium | Delete remaining legacy code, fix tests | [PHASE_9](PHASE_9_FINAL_CLEANUP.md) |

---

## Phase Dependencies

```
1A ─► 1B ─► 2A ─► 2B ─► 2C ─► 3A ─► 3B ─► 4A ─► 4B ─► 5A ─► 5B ─► 6A ─► 6B ─► 7A ─► 7B ─► 8 ─► 9
```

**Note**: Phases are sequential. Each phase deletes old code as it goes, so parallel execution is not possible.

---

## Files to DELETE (Throughout Implementation)

Delete these files as you encounter dependencies on them:

| File | Delete In Phase | Replaced By |
|------|-----------------|-------------|
| `lib/domain/models/screens/view_definition.dart` | 2C | `Section` |
| `lib/domain/models/screens/entity_selector.dart` | 2C | `DataConfig` |
| `lib/presentation/features/screens/bloc/view_bloc.dart` | 5B | `ScreenBloc` |
| `lib/data/drift/converters/entity_selector_converter.dart` | 2B | `SectionConverter` |
| Old display_config JSON converter (if separate) | 2B | Merged into Section |

---

## Detailed Phase Breakdown

### Phase 1A: Query Foundation - LabelQuery
**Goal**: Create LabelQuery and LabelPredicate (mirrors TaskQuery pattern)

**Files to Create**:
- `lib/domain/queries/label_predicate.dart`
- `lib/domain/queries/label_query.dart`

**Decisions Implemented**: DR-003 (ValueQuery = LabelQuery typedef)

---

### Phase 1B: Query Foundation - Enhancements  
**Goal**: Add LabelMatchMode, query convenience factories

**Files to Create/Update**:
- `lib/domain/queries/label_match_mode.dart`
- Update `task_query.dart` with factory methods
- Update `project_query.dart` with factory methods
- Update `label_query.dart` with factory methods

**Decisions Implemented**: DR-004, DR-006

---

### Phase 2A: Section Model
**Goal**: Create Section sealed class and supporting types

**Files to Create**:
- `lib/domain/models/screens/data_config.dart`
- `lib/domain/models/screens/related_data_config.dart`
- `lib/domain/models/screens/section.dart`

**Decisions Implemented**: DR-001, DR-002, DR-005, DR-017

---

### Phase 2B: Schema Update
**Goal**: Update database schema - DELETE old columns, ADD new columns

**Files to Update**:
- `lib/data/drift/features/screen_tables.drift.dart` - remove old columns, add new
- `lib/data/powersync/schema.dart` - remove old columns, add new
- Create `lib/data/drift/converters/section_converters.dart`

**Files to DELETE**:
- Any legacy converter files for entity_selector, display_config

---

### Phase 2C: Screen Definition Update
**Goal**: Update ScreenDefinition to use sections, DELETE ViewDefinition

**Files to Update**:
- `lib/domain/models/screens/screen_definition.dart` - replace `view` with `sections`
- `lib/data/features/screens/repositories/screen_definitions_repository.dart`

**Files to DELETE**:
- `lib/domain/models/screens/view_definition.dart`
- `lib/domain/models/screens/view_definition.freezed.dart`
- `lib/domain/models/screens/view_definition.g.dart`
- `lib/domain/models/screens/entity_selector.dart`
- `lib/domain/models/screens/entity_selector.freezed.dart`
- `lib/domain/models/screens/entity_selector.g.dart`

---

### Phase 3A: SupportBlock Evolution
**Goal**: Add ProblemSummaryBlock, mark WorkflowProgressBlock as system-only

**Files to Update**:
- `lib/domain/models/screens/support_block.dart`

**Decisions Implemented**: DR-018, DR-019

---

### Phase 3B: SupportBlock Integration
**Goal**: Update SupportBlockComputer to handle new block types

**Files to Update**:
- `lib/domain/services/screens/support_block_computer.dart`
- `lib/presentation/features/screens/widgets/support_block_renderer.dart`

---

### Phase 4A: Data Fetching - Service
**Goal**: Create SectionDataService for fetching section data

**Files to Create**:
- `lib/domain/services/screens/section_data_service.dart`
- `lib/domain/models/screens/section_data.dart` (fetch result types)

**Decisions Implemented**: DR-008

---

### Phase 4B: Data Fetching - Repository Updates
**Goal**: Update repositories with flat query params

**Files to Update**:
- Repository contracts and implementations for related data filtering

**Decisions Implemented**: DR-010

---

### Phase 5A: Unified ScreenBloc - Core
**Goal**: Create ScreenBloc events and state

**Files to Create**:
- `lib/presentation/features/screens/bloc/screen_bloc.dart`

**Decisions Implemented**: DR-012

---

### Phase 5B: Unified ScreenBloc - Handlers
**Goal**: Implement ScreenBloc event handlers, DELETE ViewBloc

**Files to Update**:
- `lib/presentation/features/screens/bloc/screen_bloc.dart`

**Files to DELETE**:
- `lib/presentation/features/screens/bloc/view_bloc.dart`
- `lib/presentation/features/screens/bloc/view_bloc.freezed.dart`

---

### Phase 6A: Entity Navigation
**Goal**: Create centralized EntityNavigator

**Files to Create**:
- `lib/presentation/navigation/entity_navigator.dart`

**Decisions Implemented**: DR-011

---

### Phase 6B: Widget Updates
**Goal**: Update entity widgets with default onTap

**Files to Update**:
- `lib/presentation/widgets/task_tile.dart`
- `lib/presentation/widgets/project_tile.dart`
- etc.

---

### Phase 7A: Workflow Model Update
**Goal**: Update WorkflowStep to use Section

**Files to Update**:
- `lib/domain/models/workflow/workflow_step.dart`

---

### Phase 7B: Workflow Bloc Integration
**Goal**: Update WorkflowRunBloc to use ScreenBloc patterns

**Files to Update**:
- `lib/presentation/features/workflow/bloc/workflow_run_bloc.dart`

---

### Phase 8: System Screen Seeder
**Goal**: Recreate all 11 system screens with new Section-based model

**Files to Update**:
- `lib/data/services/system_screen_seeder.dart` - complete rewrite with new model

---

### Phase 9: Final Cleanup
**Goal**: Delete any remaining legacy code, fix all tests

**Cleanup Tasks**:
1. Search codebase for any remaining references to deleted types
2. Fix all test files that reference old models
3. Remove any unused imports
4. Run full test suite

**Final Validation**:
- [ ] `flutter analyze` returns 0 errors
- [ ] `flutter test` passes (after fixing tests)
- [ ] App runs and all screens render correctly

> ⚠️ **REMINDER - FUTURE WORK**: After completing this phase, consider implementing:
> - **DR-018 Phase 2**: Custom Problem Rules (user-defined problem criteria in Settings)
> - **Screen Builder UI**: Focus screen builder with 3-mode urgency (DR-015, DR-016)
> - **Query Builder UI**: Predicate metadata and preset registry (DR-013, DR-014)

---

## Validation Checklist (Per Phase)

Each phase must pass before proceeding:

- [ ] `flutter analyze` returns 0 errors, 0 warnings
- [ ] All `.freezed.dart` files generated
- [ ] All `.g.dart` files generated (if JSON serialization used)
- [ ] Old code deleted as specified in phase
- [ ] Phase document checklist complete

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Compile errors from deletions | Sequential phases, fix all errors before proceeding |
| Missing functionality | Each phase tests that app still runs |
| Workflow breakage | Phase 7 specifically updates workflows |

---

## Success Criteria

1. All 11 system screens render correctly with new model
2. Workflows execute with Section-based steps  
3. ScreenBloc handles all screen types
4. **ViewBloc deleted**
5. **ViewDefinition deleted**
6. **EntitySelector deleted**
7. All tests pass after Phase 9
8. `flutter analyze` clean
