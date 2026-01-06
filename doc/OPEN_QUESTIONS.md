# Taskly Open Questions & Pending Issues

> Deferred decisions and future considerations not yet addressed in requirements.

---

## Resolved Items

### Statistics Screen → Merged into Insights

**Status:** ✅ Resolved

**Decision:** Statistics functionality merged into "Insights" screen. Single screen with scrolling sections covering Value Balance, Task Completion, Wellbeing Patterns, and Achievements. See SCREEN_REQUIREMENTS.md for full definition.

---

### Value Inheritance → Removed (Pre-populate Model)

**Status:** ✅ Resolved

**Decision:** Value inheritance is removed entirely. Tasks do NOT inherit values from their parent project at runtime.

**New Model:**
- When creating a task within a project, the UI pre-populates the project's values into the form
- User can modify values before saving
- Once saved, task values are independent of the project
- Allocation uses `task.values` directly (no `getEffectiveValues()`)

**Rationale:**
- Simplifies mental model: "task has values" vs "task has values plus maybe inherited values"
- What-you-see-is-what-you-get: values shown = values used for allocation
- Eliminates broken implementation where `task.project.values` was often empty
- Allows intentional divergence (task in Career project tagged with Health value)

**Migration:** All existing data will be deleted. No migration required.

See BACKEND_MIGRATION_PLAN.md Change 10 for implementation details.

---

## Design Nudges (Awaiting Detailed UX)

### Review Run Step UI

**Status:** ✅ Resolved

**Decision:** Single-page stacked sections design. All due reviews displayed on one scrollable page with expandable sections. Each section has "Mark Complete" button. 4 review types: Progress, Wellbeing Insights, Balance, Pinned Tasks Check. (Values Alignment merged into Balance.)

**Access Pattern:**
- Review banner appears on My Day when any review is due
- Tapping banner opens Review screen as modal/sheet
- User reviews content, optionally adds reflection notes, marks complete

---

## Deferred Decisions

### 1. Deletion vs Archive Behavior

**Question:** When user deletes a task/project/value, should it be:
- A) Hard delete (permanent)
- B) Soft delete with archive/restore capability
- C) Varies by entity type

**Impact:** Database schema, UI for restore, storage considerations

---

### 2. Offline Behavior Scope

**Question:** What functionality is available when offline?
- A) Full CRUD with sync on reconnect
- B) Read-only with queued writes
- C) Explicit offline mode

**Current State:** PowerSync provides offline-first capability, but UI behavior not specified.

---

### 3. Notifications & Reminders

**Question:** Should Taskly include push notifications?
- A) Yes - for deadlines, reviews due, alerts
- B) No - app is passive, user checks when ready
- C) Optional - user configures in settings

**Impact:** Platform permissions, notification service, settings UI

---

### 4. Data Export

**Question:** Should users be able to export their data?
- Format options: JSON, CSV, PDF reports
- Scope: All data vs selective export

---

### 5. Multi-device Sync Indicators

**Question:** Should UI show sync status?
- Last synced timestamp
- Pending changes indicator
- Conflict resolution UI

---

## Future Feature Candidates

### Subtasks

**Status:** Deferred to v2

**Context:** Nested checklist items within a task. Considered for MVP but deferred due to complexity.

**Rationale for Deferral:**
- Adds significant complexity: nested entities, progress calculations, UI nesting
- Projects already provide task grouping functionality
- Tasks can remain atomic in v1; subtasks add organizational depth in v2

**Potential Scope:**
- Nested checklist items within a task
- Subtask completion contributes to parent task progress
- Subtasks inherit parent task's values/project/dates (or explicit override)
- Drag-and-drop reordering within task

---

### Global Search

**Status:** Deferred to v2

**Context:** Search capability across tasks, projects, values, and journal entries is desirable but not required for MVP.

**Potential Scope:**
- Global search bar accessible from navigation
- Search across: task names, project names, value names, descriptions, journal content
- Filter search results by entity type
- Recent searches history

---

### Calendar Sync

**Status:** Deferred to v2

**Context:** Integration with Google Calendar and Apple Calendar.

**Scope:**
- Two-way sync of tasks with deadlines
- Import calendar events as tasks
- Export tasks to calendar

**Rationale for Deferral:**
- Significant scope: OAuth, platform APIs, conflict handling
- Not essential for core value-aligned task management

---

### Density Toggle

**Status:** Deferred to v2

**Context:** User-configurable display density (Compact / Comfortable / Standard).

**Decision:** Use platform-appropriate defaults for MVP. Density toggle is nice-to-have.

---

### Rich Text / Markdown

**Status:** Deferred to v2

**Context:** Rich text formatting in task/project/journal descriptions.

**Decision:** Plain text only for MVP. Markdown support can be added in v2.

---

### Bulk Actions

**Status:** Deferred to future enhancement

**Context:** Multi-select and bulk operations would improve efficiency for power users.

**Potential Operations:**
- Select multiple tasks → Mark complete, Delete, Change value, Change priority
- Select multiple projects → Delete, Change value
- Select multiple journal entries → Delete

**UX Considerations:**
- Long-press to enter selection mode
- Floating action bar with bulk operation buttons
- "Select all" / "Deselect all" controls

---

### Collaboration
- Shared projects
- Delegated tasks
- Team values

### Integrations
- Calendar sync (Google, Apple)
- Task import (Todoist, Things, etc.)
- Webhook/API access

### Advanced Analytics
- AI-powered insights
- Predictive task duration
- Optimal scheduling suggestions

---

## Removed Features

### Gamification System

**Status:** ❌ Removed from scope

**Original Concept:** Streaks, achievements, badges, and gamification elements.

**Decision:** Removed entirely. Taskly focuses on intrinsic motivation through value alignment, not extrinsic gamification.

**Rationale:**
- Gamification conflicts with the core philosophy of sustainable, values-driven productivity
- Points/streaks can create unhealthy pressure and guilt
- Focus on meaningful progress reflection rather than arbitrary metrics
- Aligns with Intentional and Sustainable Focus Modes

---

## Notes

Items move from this document to SCREEN_REQUIREMENTS.md or BACKEND_MIGRATION_PLAN.md when decisions are made and requirements are defined.
