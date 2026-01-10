# Stitch Prompt — Taskly My Day (Component Library + Declarative Requirements)

You are designing **mockups of components** used on Taskly’s **My Day** screen (Flutter, Material 3).

## Non-Negotiables
- **My Day only**: include only components required to build the My Day screen experience.
- **Component-library only**: do not design screens/pages.
- **Declarative only**: do not describe *how* to present data (no layout/spacing/typography/color/elevation rules). Only specify **what data must be shown** and **what actions exist**.
- **Data completeness**: the mockup must show every field listed for a component (or a defined empty/hidden state when that field is not present).
- **No invention**: do not add new user-visible fields beyond those listed below.
- **No new variants**: do not invent new tile variants beyond:
  - Task tile variant: `list_tile`
  - Project tile variant: `list_tile`
  - Attention item tile variant: `standard`
  - Review item tile variant: `standard`

## Data Type Legend
`text`, `bool`, `int`, `double`, `date`, `list<T>`, `enum`, `id`, `color_hex`, `map<K,V>`.

## My Day — Declarative Requirements (must be supported)
My Day is the user’s daily focus surface. It must support:
- Showing the user’s current **focus mode** and the resulting **allocated set** of tasks for “today”.
- Supporting multiple **allocation display modes** (e.g., flat vs grouped).
- Showing **pinned/Next Action** tasks as a first-class part of My Day.
- Summarizing **issues** (attention items) relevant to My Day.
- Summarizing **allocation alerts** (excluded-from-allocation reasons) relevant to My Day.
- Summarizing **due reviews** and providing a **start check-in** action.
- Allowing the user to:
  - Toggle completion on tasks (and on projects when projects are shown in My Day contexts).
  - Open a task or project.
  - Remove Next Action / pinned status when an unpin callback exists.
- Supporting empty/hidden states for the above sections when they have no data.

---

## Output Format (required)
For each component below, provide exactly:
1) **Component Name**
2) **Purpose** (one sentence)
3) **Data it must show** (field name + type)
4) **User actions it must support** (what actions exist; no UI details)
5) **States it must support** (default; hidden/empty; unavailable actions when callbacks are missing)

---

## 1) `TaskListTile` (variant: `list_tile`)
Purpose: Represents a single task in My Day allocation and related My Day contexts.
Data it must show:
- `taskId: id`
- `name: text`
- `completed: bool`
- `project: { projectId: id, projectName: text }`
- `deadlineDate: date`
- `startDate: date`
- `repeatIcalRrule: text`
- `primaryValue: { valueId: id, name: text, icon: text, color: color_hex }`
- `secondaryValues: list<{ valueId: id, name: text, icon: text, color: color_hex }>`
- `isPinned: bool` (Next Action)
- `isInFocus: bool` (allocated for today)
- `description: text`
- `reasonText: text` (contextual explanation from the section/view-model)
- `deadlineStatus: enum{overdue, due_today, due_soon, normal}` (derived)
User actions it must support:
- Toggle completion.
- Tap to open task.
- Remove Next Action when unpin callback exists.
States it must support:
- Completed vs not completed.
- Hidden/empty state for `project` when no project exists.
- Hidden/empty state for `deadlineDate`, `startDate`, `repeatIcalRrule`, `description`, `reasonText` when not present.
- Unpin action unavailable when callback is missing.

---

## 2) `ProjectListTile` (variant: `list_tile`)
Purpose: Represents a project when projects are shown in My Day-related contexts (e.g., agenda-like sections or project-focused group headers).
Data it must show:
- `projectId: id`
- `name: text`
- `completed: bool`
- `taskCount: int`
- `completedTaskCount: int`
- `progress: double` (derived from counts)
- `deadlineDate: date`
- `startDate: date`
- `repeatIcalRrule: text`
- `primaryValue: { valueId: id, name: text, icon: text, color: color_hex }`
- `secondaryValues: list<{ valueId: id, name: text, icon: text, color: color_hex }>`
- `description: text`
- `nextTaskName: text` (recommendation context)
- `isPinned: bool`
- `isInFocus: bool`
- `deadlineStatus: enum{overdue, due_today, due_soon, normal}` (derived)
User actions it must support:
- Toggle completion.
- Tap to open project.
States it must support:
- Completed vs not completed.
- Hidden/empty state for counts/progress when counts are unavailable.
- Hidden/empty state for `deadlineDate`, `startDate`, `repeatIcalRrule`, `description`, `nextTaskName` when not present.

---

## 3) `AllocationSection` (My Day)
Purpose: Displays the allocated items for “today”, including pinned tasks and excluded-task context.
Data it must show:
- `activeFocusMode: enum{responsive, intentional, sustainable, personalized}`
- `displayMode: enum{flat, groupedByValue, groupedByProject, pinnedFirst}`
- `allocatedTasks: list<TaskListTileData>` (must support all TaskListTile fields)
- `pinnedTasks: list<TaskListTileData>` (must support all TaskListTile fields)
- `tasksByValue: map<id,{ valueId: id, valueName: text, tasks: list<TaskListTileData>, weight: double, quota: int, valuePriority: enum{high, medium, low}, color: color_hex, iconName: text }>`
- `reasoning: { strategyUsed: text, categoryAllocations: map<id,int>, categoryWeights: map<id,double>, urgencyInfluence: double, explanation: text }`
- `excludedCount: int`
- `excludedUrgentTasks: list<{ task: TaskListTileData, reason: text, exclusionType: enum{noCategory, lowPriority, categoryLimitReached, completed} }>`
- `excludedTasks: list<{ task: TaskListTileData, reason: text, exclusionType: enum{noCategory, lowPriority, categoryLimitReached, completed} }>`
- `showExcludedSection: bool`
- `requiresValueSetup: bool`
User actions it must support:
- Task toggle and task tap via the task tile.
- Remove Next Action via the task tile when unpin callback exists.
States it must support:
- Empty state when there are no allocated tasks and no pinned tasks.
- Hidden state for excluded lists when `excludedCount == 0`.
- Hidden state for `reasoning` when not provided.
- Value-setup-required state when `requiresValueSetup == true`.

---

## 4) `IssuesSummarySection`
Purpose: Summarizes “issues” (attention items) that block or degrade progress on My Day.
Data it must show:
- `items: list<{ severity: enum{critical, warning, info}, title: text, description: text }>`
- `criticalCount: int`
- `warningCount: int`
- `infoCount: int` (derived)
- `emptyMessage: text` (when no issues)
- `viewAllLabel: text` (when list is truncated)
- `viewAllRouteScreenKey: id` (navigation target)
User actions it must support:
- “View all” navigation when truncation applies.
States it must support:
- Empty state when `items` is empty.

---

## 5) `AllocationAlertsSection`
Purpose: Summarizes allocation alerts (tasks excluded from My Day allocation).
Data it must show:
- `alerts: list<{ severity: enum{critical, warning, info}, title: text, description: text }>`
- `totalExcluded: int`
- `summaryText: text` (derived from `totalExcluded`)
- `viewAllLabel: text` (when list is truncated)
- `viewAllRouteScreenKey: id` (navigation target)
User actions it must support:
- “View all” navigation when truncation applies.
States it must support:
- Hidden when `alerts` is empty.

---

## 6) `CheckInSummarySection`
Purpose: Summarizes due reviews and provides a start action.
Data it must show:
- `dueReviews: list<{ title: text, description: text }>`
- `hasOverdue: bool`
- `overdueMessage: text` (when `hasOverdue=true`)
- `primaryActionLabel: text`
- `primaryActionRouteScreenKey: id`
User actions it must support:
- Trigger primary action.
States it must support:
- Hidden when `dueReviews` is empty.

---

## Field Confirmation Checklist (please confirm)
Confirm whether the My Day contract should match:
- **A) Current code models** (lean):
  - `AllocationSectionResult` fields: `allocatedTasks`, `pinnedTasks`, `tasksByValue`, `reasoning`, `excludedCount`, `excludedUrgentTasks`, `excludedTasks`, `activeFocusMode`, `displayMode`, `showExcludedSection`, `requiresValueSetup`.
  - `IssuesSummarySectionResult` fields: `items`, `criticalCount`, `warningCount` (and `infoCount` derived).
  - `AllocationAlertsSectionResult` fields: `alerts`, `totalExcluded`.
  - `CheckInSummarySectionResult` fields: `dueReviews`, `hasOverdue`.

- **B) Screen-model contract fields** (richer, as in the unified prompt):
  - Add: `emptyMessage`, `viewAllLabel`, `viewAllRouteScreenKey`, `summaryText`, `primaryActionLabel`, `primaryActionRouteScreenKey`, etc.

Choose A or B (or a hybrid), and tell me which extra fields (if any) should be required.
