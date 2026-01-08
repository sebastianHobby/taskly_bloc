# Phase 3 — My Day (Tasks Grouped by Project)

## Goal
Implement the agreed My Day UX shape “B”:
- A *task list* for today
- Grouped by project

The allocation remains a set of tasks, but grouping provides project context.

## Non-goals
- A separate project-first “My Day” page.
- New filters, new pages, or new UI beyond grouping.

Explicitly out of scope:
- Adding new “planning style” pickers or new settings surfaces. (If needed, those are separate UX work.)

## Data requirements
- Need the current day’s allocation snapshot entries for tasks.
- Need to map each task to its project (or “No Project”).

Additional requirement from agreed model
- The UI must reflect **effective values**:
   - project has primary + secondary values
   - tasks inherit project values by default
   - tasks can override by setting their own values

## Implementation steps

### 1) Build a My Day view-model source
Create a small presentation/service layer that:
1. Reads today’s allocated tasks from allocation snapshot.
2. Loads corresponding `Task` models.
3. Groups tasks by `projectId`.
4. For each project group, optionally compute:
   - recommended next task label (existing `ProjectNextTaskResolver` can be reused)

Also compute, per task, a minimal “value display model”:
- `effectivePrimaryValue`
- `effectiveSecondaryValues`
- `isInheritingValues` (true when task has no explicit values but project does)

Guideline: get these from a single shared domain helper (the same one used by scoring/allocation) so the UI and allocator never disagree.

### 2) Grouping rules
- If task has a project: group under that project.
- Else: group under “No Project” (or existing equivalent).

Keep ordering minimal:
- Project groups sorted by (a) has urgent tasks, then (b) name.
- Tasks within a group sorted by existing task sort (or stable by name).

Do not add additional sorting by values or priorities in this phase.

### 3) UI implementation
In the My Day screen/widget:
- Replace flat list with a grouped list.
- Each group has a header (project title).
- Under each header, render tasks.

Value display guidelines (minimal, no new components required):
- Project header shows project’s primary value + secondary values (if the design already has value chips).
- Task tiles show effective values.
- If a task is inheriting values:
   - show the same chips, but indicate inherited vs explicit using existing affordances only (e.g., an “Inherited” label if one already exists; otherwise rely on the fact the task has no explicit value selection in edit UI).

If the current design system lacks an inherited indicator, keep it as a tooltip/secondary text only and do not invent new visuals.

## Acceptance criteria
- My Day shows allocated tasks grouped by project.
- A task moving between projects updates grouping.
- Tasks without a project appear under a “No Project” group.

Additional acceptance criteria
- Effective values shown on task tiles match the effective values used for allocation scoring.
- If a task has explicit values, those display (override); otherwise project values display (inherit).

## Tests
- Widget test: given tasks with mixed project IDs, verify grouping headers and counts.
- View-model test: stable ordering and grouping.

## Notes / risks
- Ensure My Day reads from persisted allocation snapshot (not transient allocation stream) once Phase 1 is in place.
- Avoid expensive per-task DB queries; batch-load tasks by IDs.

Added risk
- If some legacy projects have no primary value, inherited display will be empty; Phase 2 should surface a warning and Phase 0/Phase 1 prerequisites should close the data hole.
