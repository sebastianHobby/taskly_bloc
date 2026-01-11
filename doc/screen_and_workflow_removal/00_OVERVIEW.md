# Screen Create & Workflow Removal - Overview

**Date:** 2026-01-12  
**Scope:** Complete removal of workflow and screen create features  
**Approach:** Phased removal with validation after each phase

---

## Rationale

### Features to Remove

1. **Workflow Feature**
   - Full CRUD for workflow definitions
   - Runtime workflow execution engine
   - Problem detection service (duplicates AttentionEngine)
   - ~22 files, ~95 tests

2. **Screen Create Feature**
   - Custom screen creation/management UI
   - Repository methods for custom screens
   - ~3 files, minimal tests

3. **Overlapping/Unused Components**
   - `ProblemDetectorService` (duplicated by AttentionEngine)
   - `ProblemType` enum and related models
   - `DisplayConfig.problemsToDetect` field (always empty)
   - `orphan_tasks` system screen (analytics-only)
   - `Task/Project.lastReviewedAt` fields (not in DB schema)
   - `AttentionRuleType.workflowStep` enum value (unused)

---

## Phase Breakdown

| Phase | Description | Risk | Files | Validation |
|-------|-------------|------|-------|------------|
| 1 | Screen Create UI | Low | ~3 | `flutter analyze` |
| 2 | Workflow Domain Models | Medium | ~8 | `flutter analyze` |
| 3 | Workflow Presentation | Medium | ~5 | `flutter analyze` |
| 4 | Workflow Data & Services | Medium | ~3 | `flutter analyze` |
| 5 | Overlapping Components | Low | ~10 | `flutter analyze` |
| 6 | Database Cleanup | High | ~2 | Manual verification |
| 7 | Final Testing | Critical | All | Full test suite |

---

## Success Criteria

- ✅ All phases complete without `flutter analyze` errors
- ✅ No broken imports or dead code
- ✅ All tests pass (run in Phase 7)
- ✅ User confirms Supabase/PowerSync rules updated

---

## Important Notes

1. **No test execution** until Phase 7 (final validation)
2. **Database changes** require backend coordination
3. **PowerSync sync rules** must be updated to match schema changes
4. Each phase is independently executable and reversible
5. Create checkpoints after each phase (optional)

---

## Files Overview

- `00_OVERVIEW.md` - This file
- `PHASE_1_screen_create_ui.md` - Remove screen creation/management UI
- `PHASE_2_workflow_domain_models.md` - Remove workflow domain models
- `PHASE_3_workflow_presentation.md` - Remove workflow presentation layer
- `PHASE_4_workflow_data_services.md` - Remove workflow data layer
- `PHASE_5_overlapping_components.md` - Remove duplicated/unused components
- `PHASE_6_database_cleanup.md` - Remove unused database tables/columns
- `PHASE_7_final_testing.md` - Run full test suite and validate

---

## Execution Checklist

- [ ] Review all phase files
- [ ] Execute Phase 1
- [ ] Execute Phase 2
- [ ] Execute Phase 3
- [ ] Execute Phase 4
- [ ] Execute Phase 5
- [ ] Execute Phase 6 (coordinate with DB admin)
- [ ] Execute Phase 7
- [ ] User confirms PowerSync rules updated
- [ ] Create PR for review
