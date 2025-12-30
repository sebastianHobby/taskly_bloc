# Consolidated Plan (Pending Work Only)

> **Status**: Active (single source of truth)
> 
> This document replaces:
> - `SCREEN_SYSTEM_PLAN.md`
> - `QUERY_OBJECT_CORE_PLAN.md`
> - `IMPLEMENTATION_PLAN.md`
>
> It lists **only work that is not completed / still pending** and calls out
> contradictions between the older plan docs and the current code + decisions
> captured in chat.

---

## Scope Decisions (Current)

- **Priority**: removed for now (no priority grouping/sorting work).
- **Soft gates**: required, but **workflow runs only** for now (no collection-screen warnings yet).
- **Soft gate definitions**:
   - **Urgent** when deadline due within **7 days** (or overdue).
   - **Stale** when **X days without updates** (based on `Task.updatedAt`).
  - All thresholds are **user-configurable settings** with sensible defaults.
- **Acknowledgments**: apply **per entity**.
- **Snooze default**: **7 days**.
- **Problem timestamps**: problems are **computed-only**; do not persist “detected at” / “resolved at” for now.
   - We only persist user actions (acknowledge/dismiss/snooze) with timestamps.
- **Workflow screen creation**: via a future editor UI (not part of current work).
- **Workflow screen seeding**: none for now.

---

## Pending Work

### 1) Support Blocks (Finish Stubbed Variants)

**Goal**: make support blocks beyond the already-working ones fully functional.

- Implement support blocks that are currently stubbed/placeholder:
  - `breakdown`
  - `filteredList`
  - `moodCorrelation`



---

### 2) Grouping Consolidation (Optional)

**Goal**: reduce duplicated grouping logic and make grouping deterministic.

- Consolidate remaining duplicated grouping logic into `EntityGrouper`.
- Make grouping deterministic by passing `now` instead of calling `DateTime.now()` in groupers.



---

### 3) Repo Health

- Run `flutter analyze` and tests after implementing the above.
- Address only issues directly introduced by the changes (do not chase unrelated lints).

---

## Contradictions / Outdated Assumptions to Ignore

These contradictions exist between the older plan docs and the current repo + decisions:

1. **“No implementation yet”** (QUERY_OBJECT_CORE_PLAN)
   - Contradicts the current codebase, which already contains the core screen/workflow models, drift tables, repositories, and workflow runner UI.

2. **Legacy “Reviews” migration steps** (both legacy docs)
   - The legacy reviews system is intended to be removed, not migrated.
   - Any steps describing “adapt ReviewDetailBloc / ReviewActionService” are outdated.

3. **Priority grouping/sorting**
   - Older docs include grouping by `priority` and other priority-driven UX.
   - Current decision: **priority removed for now**.

4. **Problem detection on collection screens**
   - Older docs included adding problems to collection screens.
   - Current decision: **workflow runs only** (collection deferred).

5. **Type shape differences (Trigger / DisplayConfig / enums)**
   - Older plans describe slightly different type names/variants (e.g., `Trigger` vs `TriggerConfig`).
   - The repo’s existing types should be treated as the source of truth.

---

## Clarifying Questions (Answer to unblock implementation)

Answered:
- Urgency does **not** consider start date.
- Stale uses `Task.updatedAt`.
- Acknowledgments apply **per entity**.
- **No workflow screen seeding** for now.
- Snooze default is **7 days**.

Remaining:
- For day-granularity checks, confirm we should use the device **local timezone** for “today” boundaries.
