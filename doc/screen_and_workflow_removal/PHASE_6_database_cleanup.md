# Phase 6: Database Cleanup

**Risk Level:** HIGH   
**Estimated Time:** 30 minutes + coordination  
**Dependencies:** Phase 5 complete

---

##  CRITICAL: Coordinate with Backend Team

This phase changes the backend database schema and the PowerSync sync rules.
Coordination required with:

- Supabase database administrator
- PowerSync sync rules maintainer

Do not proceed without:

1. Backup confirmation
2. Change review approval

---

## Objective

- Remove workflow tables from the backend database.
- Ensure PowerSync sync rules do not reference removed workflow tables.
- Confirm tasks/projects do not include a `last_reviewed_at` column.

---

## Backend Database Changes

### Tables to Drop (Workflow)

From Supabase (PostgreSQL):

```sql
DROP TABLE IF EXISTS workflow_step_executions CASCADE;
DROP TABLE IF EXISTS workflow_steps CASCADE;
DROP TABLE IF EXISTS workflow_definitions CASCADE;
```

### Columns to Verify

Confirm these columns do not exist:

```sql
SELECT table_name, column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND (
    (table_name = 'tasks' AND column_name = 'last_reviewed_at')
    OR (table_name = 'projects' AND column_name = 'last_reviewed_at')
  );
```

---

## PowerSync Schema

**File:** `lib/data/infrastructure/powersync/schema.dart`

Verification:

- Ensure no workflow tables are defined.
- Ensure tasks/projects do not define `last_reviewed_at`.

---

## PowerSync Sync Rules

**File:** `supabase/powersync-sync-rules.yaml`

Actions:

1. Remove rules that select from `workflow_definitions` and `workflow_steps`.
2. Ensure task/project selects do not reference `last_reviewed_at`.

---

## Validation

1. Static analysis:

```bash
flutter analyze
```

2. Confirm workflow tables are absent:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE '%workflow%';
```

3. Run the app and verify:

- Login works
- Tasks/projects load
- No sync errors about missing tables/columns

---

## Next Phase

 **Phase 7:** Final testing and validation
