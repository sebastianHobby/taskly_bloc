# Stitch Prompt — Taskly Unified Screen Model (Component Library, Declarative Data Contract)

You are designing **mockups of components** in the Taskly component library (Flutter, Material 3).

## Non-Negotiables
- **Component-library only**: do not design screens/pages.
- **Declarative only**: do not describe *how* to present data (no layout/spacing/typography/color/elevation rules). Only specify **what data must be shown**.
- **Data completeness**: the mockup must show every field listed for a component.
- **No invention**: do not add new user-visible fields beyond those listed below.
- **No new variants**: do not invent new tile variants beyond:
  - Task tile variant: `list_tile`
  - Project tile variant: `list_tile`
  - Value tile variant: `compact_card`
  - Attention item tile variant: `standard`
  - Review item tile variant: `standard`

## Data Type Legend
`text`, `bool`, `int`, `double`, `date`, `list<T>`, `enum`, `id`, `color_hex`.

## Output Format (required)
For each component below, provide exactly:
1) **Component Name**
2) **Purpose** (one sentence)
3) **Data it must show** (field name + type)
4) **User actions it must support** (what actions exist; no UI details)
5) **States it must support** (default; hidden/empty; unavailable actions when callbacks are missing)

---

## 1) `ResponsiveNavScaffold`
Purpose: Lets users navigate between Taskly’s main destinations and shows the active content.
Data it must show:
- `destinations: list<{ screenId: id, label: text, iconName: text, selectedIconName: text }>`
- `activeScreenId: id`
- `badgeCountByDestination: map<id,int>` (only show counts when `> 0`)
- `bottomVisibleCount: int` (how many destinations are visible before overflow)
User actions it must support:
- Select destination by `screenId`.
- Open overflow destinations when present.
States it must support:
- Default.
- Overflow present when destinations exceed visible capacity.

---

## 2) `TaskListTile` (variant: `list_tile`)
Purpose: Represents a single task in lists, My Day allocation, and agenda contexts.
Data it must show:
- `name: text`
- `completed: bool`
- `project: { projectId: id, projectName: text }`
- `deadlineDate: date`
- `startDate: date`
- `repeatIcalRrule: text`
- `primaryValue: { valueId: id, name: text, icon: text, color: color_hex }`
- `secondaryValues: list<{ valueId: id, name: text, icon: text, color: color_hex }>`
- `isPinned: bool` (Next Action)
- `description: text`
- `reasonText: text` (contextual explanation coming from the section/view-model)
- `deadlineStatus: enum{overdue, due_today, due_soon, normal}` (derived)
User actions it must support:
- Toggle completion.
- Tap to open task.
- Remove Next Action when unpin callback exists.
States it must support:
- Completed vs not completed.
- Every listed field is shown.
- Unpin action unavailable when callback is missing.

---

## 3) `ProjectListTile` (variant: `list_tile`)
Purpose: Represents a single project in lists and agenda contexts.
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
- `deadlineStatus: enum{overdue, due_today, due_soon, normal}` (derived)
User actions it must support:
- Toggle completion.
- Tap to open project.
States it must support:
- Completed vs not completed.
- Every listed field is shown.

---

## 4) `ValueCardCompact` (variant: `compact_card`)
Purpose: Represents a value and the value’s stats.
Data it must show:
- `valueId: id`
- `name: text`
- `icon: text` (emoji)
- `color: color_hex`
- `rank: int`
- `stats: { targetPercent: double, actualPercent: double, taskCount: int, projectCount: int, weeklyTrend: list<double>, gapWarningThreshold: int }`
- `notRankedMessage: text`
- `taskCountText: text` (derived)
- `projectCountText: text` (derived)
User actions it must support:
- Tap to open value when tappable.
States it must support:
- Default.

---

## 5) `IssuesSummarySection`
Purpose: Summarizes “issues” (attention items) that block or degrade progress.
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

## 6) `AllocationAlertsSection`
Purpose: Summarizes allocation alerts (tasks excluded from My Day).
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

## 7) `CheckInSummarySection`
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

## 8) `AllocationSection` (My Day)
Purpose: Displays the allocated tasks for “today” with grouping modes.
Data it must show:
- `allocatedTasks: list<TaskListTileData>` (must support all TaskListTile fields)
- `activeFocusMode: enum{responsive, intentional, sustainable, personalized}`
- `displayMode: enum{groupedByProject, groupedByUrgency, groupedByValue, flat}`
- `groupTitles: list<text>` (used when grouped)
- `groupCounts: list<int>` (used when grouped)
User actions it must support:
- Task toggle and task tap via the task tile.
States it must support:
- Empty state when there are no allocated tasks.

---

## 9) `AgendaSection`
Purpose: Displays scheduled items grouped by date, including overdue.
Data it must show:
- `groups: list<{ date: date, semanticLabel: text, items: list<AgendaRenderableItem> }>`
- `overdueItems: list<AgendaRenderableItem>`
- `showDatePicker: bool`
- `collapsibleOverdue: bool`
- `overdueCollapsedByDefault: bool`
Where `AgendaRenderableItem` is one of:
- `TaskListTileData`
- `ProjectListTileData`
User actions it must support:
- Select date when date picker is enabled.
- Tap/toggle items via the underlying tiles.
States it must support:
- Empty state when there are no groups and no overdue items.

---

## Final Check
- Every component above lists all supported fields.
- The prompt never describes *how* to render, only *what must be present*.

---

## Appendix: Field Source Mapping (short)

Use these sources for the data fields:
- Task tile data comes from `Task` plus section/view-model context for `reasonText` and derived `deadlineStatus`.
- Project tile data comes from `Project` plus section enrichment for counts/recommendations and derived `deadlineStatus`.
- Value card data comes from `Value` plus computed `ValueStats`.
- Issues/alerts/reviews come from `AttentionItem` and section results (counts, totals, truncation).
