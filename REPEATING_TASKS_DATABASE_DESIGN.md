# Repeating Tasks Database Design

## Overview

A simplified design for repeating tasks with completion tracking. Uses **virtual expansion** where occurrences are derived at runtime from RRULE patterns, not stored as individual rows.

---

## Design Summary

| Aspect | Decision |
|--------|----------|
| **Expansion Model** | Virtual (runtime RRULE expansion) |
| **Single-Occurrence Exceptions** | ✅ Skip or reschedule individual occurrences |
| **Per-Occurrence Edits** | Date/time/deadline only (other fields affect all) |
| **Analytics/On-Schedule Tracking** | ✅ Full reporting with on-time tracking |
| **Delete Behavior** | CASCADE (always delete all history) |
| **Table Design** | Separate tables per entity (no polymorphism) |
| **New Tables** | 4 (`task_completion_history`, `project_completion_history`, `task_recurrence_exceptions`, `project_recurrence_exceptions`) |
| **New Columns** | 1 (`series_ended` on tasks/projects) |

### Exception Rules

| Rule | Decision |
|------|----------|
| Reschedule | Skips original date, creates new occurrence on target date |
| Delete occurrence | Records as "skip" (no undo) |
| Editable per-occurrence | Date, time, deadline only |
| Scope | Future occurrences only |
| Conflicts | Allow multiple occurrences on same day |

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            PRESENTATION LAYER                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│   │  Today View │  │ Inbox View  │  │Upcoming View│  │ History View│        │
│   └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘        │
│          │                │                │                │               │
│          ▼                ▼                ▼                ▼               │
│   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│   │  TaskBloc   │  │  InboxBloc  │  │ UpcomingBloc│  │ HistoryBloc │        │
│   └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘        │
│          │                │                │                │               │
└──────────┼────────────────┼────────────────┼────────────────┼───────────────┘
           │                │                │                │
           └────────────────┴────────┬───────┴────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                             SERVICE LAYER                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────┐       │
│   │                     OccurrenceService                           │       │
│   ├─────────────────────────────────────────────────────────────────┤       │
│   │ • Parse RRULE patterns                                          │       │
│   │ • Expand occurrences for date range                             │       │
│   │ • Merge with completion status                                  │       │
│   │ • Cache parsed RRULEs                                           │       │
│   │ • Complete / Uncomplete occurrences                             │       │
│   └──────────────────────────────┬──────────────────────────────────┘       │
│                                  │                                          │
└──────────────────────────────────┼──────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            REPOSITORY LAYER                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│      ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐       │
│      │    TaskRepo      │  │   ProjectRepo    │  │  CompletionRepo  │       │
│      └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘       │
│               │                     │                     │                 │
└───────────────┼─────────────────────┼─────────────────────┼─────────────────┘
                │                     │                     │
                └─────────────────────┴──────────┬──────────┘
                                                 │
                                                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              DATA LAYER                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────┐       │
│   │                      Drift Database (SQLite)                    │       │
│   │                                                                 │       │
│   │   ┌───────────┐  ┌───────────┐  ┌─────────────────────────┐   │       │
│   │   │   tasks   │  │ projects  │  │ task_completion_history │   │       │
│   │   └───────────┘  └───────────┘  └─────────────────────────┘   │       │
│   │   ┌─────────────────────────────┐  ┌────────────────────────┐ │       │
│   │   │ project_completion_history  │  │ *_recurrence_exceptions│ │       │
│   │   └─────────────────────────────┘  └────────────────────────┘ │       │
│   │                                                                 │       │
│   └─────────────────────────────────────────────────────────────────┘       │
│                                    │                                        │
│                                    ▼                                        │
│   ┌─────────────────────────────────────────────────────────────────┐       │
│   │                    PowerSync (Offline-First Sync)               │       │
│   └─────────────────────────────────────────────────────────────────┘       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Database Schema Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              EXISTING TABLES                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────────┐              ┌──────────────────────┐             │
│  │       tasks          │              │      projects        │             │
│  ├──────────────────────┤              ├──────────────────────┤             │
│  │ • id (PK)            │              │ • id (PK)            │             │
│  │ • name               │         ┌───▶│ • name               │             │
│  │ • description        │         │    │ • description        │             │
│  │ • completed          │         │    │ • completed          │             │
│  │ • series_ended (NEW) │         │    │ • series_ended (NEW) │             │
│  │ • start_date         │         │    │ • start_date         │             │
│  │ • deadline_date      │         │    │ • deadline_date      │             │
│  │ • repeat_ical_rrule  │         │    │ • repeat_ical_rrule  │             │
│  │ • project_id (FK)────┼─────────┘    │ • user_id            │             │
│  │ • user_id            │              │ • created_at         │             │
│  │ • created_at         │              │ • updated_at         │             │
│  │ • updated_at         │              └──────────────────────┘             │
│  └──────────────────────┘                                                   │
│            │                                                                │
│            │ 1:N (per occurrence)                                           │
│            ▼                                                                │
└────────────┼────────────────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                               NEW TABLES                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────┐       │
│  │                  task_completion_history                         │       │
│  ├──────────────────────────────────────────────────────────────────┤       │
│  │ • id (PK)              UUID, auto-generated                      │       │
│  │ • task_id (FK)         References tasks.id (CASCADE DELETE)      │       │
│  │ • occurrence_date      Date of occurrence (NULL if non-repeating)│       │
│  │ • original_occ_date    Original RRULE date (for rescheduled)     │       │
│  │ • completed_at         Timestamp when marked complete            │       │
│  │ • notes                Optional completion notes                 │       │
│  │ • user_id              Who completed it                          │       │
│  ├──────────────────────────────────────────────────────────────────┤       │
│  │ UNIQUE: (task_id, occurrence_date)                               │       │
│  │ ON DELETE: CASCADE when parent task deleted                      │       │
│  └──────────────────────────────────────────────────────────────────┘       │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────┐       │
│  │                project_completion_history                        │       │
│  ├──────────────────────────────────────────────────────────────────┤       │
│  │ • id (PK)              UUID, auto-generated                      │       │
│  │ • project_id (FK)      References projects.id (CASCADE DELETE)   │       │
│  │ • occurrence_date      Date of occurrence (NULL if non-repeating)│       │
│  │ • original_occ_date    Original RRULE date (for rescheduled)     │       │
│  │ • completed_at         Timestamp when marked complete            │       │
│  │ • notes                Optional completion notes                 │       │
│  │ • user_id              Who completed it                          │       │
│  ├──────────────────────────────────────────────────────────────────┤       │
│  │ UNIQUE: (project_id, occurrence_date)                            │       │
│  │ ON DELETE: CASCADE when parent project deleted                   │       │
│  └──────────────────────────────────────────────────────────────────┘       │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────┐       │
│  │                  task_recurrence_exceptions                      │       │
│  ├──────────────────────────────────────────────────────────────────┤       │
│  │ • id (PK)              UUID, auto-generated                      │       │
│  │ • task_id (FK)         References tasks.id (CASCADE DELETE)      │       │
│  │ • original_date        The RRULE date being modified             │       │
│  │ • exception_type       'skip' | 'reschedule'                     │       │
│  │ • new_date             Target date (NULL if skip)                │       │
│  │ • new_deadline         Override deadline (NULL = inherit)        │       │
│  │ • created_at           Timestamp                                 │       │
│  ├──────────────────────────────────────────────────────────────────┤       │
│  │ UNIQUE: (task_id, original_date)                                 │       │
│  └──────────────────────────────────────────────────────────────────┘       │
│                                                                             │
│  ┌──────────────────────────────────────────────────────────────────┐       │
│  │                project_recurrence_exceptions                     │       │
│  ├──────────────────────────────────────────────────────────────────┤       │
│  │ • id (PK)              UUID, auto-generated                      │       │
│  │ • project_id (FK)      References projects.id (CASCADE DELETE)   │       │
│  │ • original_date        The RRULE date being modified             │       │
│  │ • exception_type       'skip' | 'reschedule'                     │       │
│  │ • new_date             Target date (NULL if skip)                │       │
│  │ • new_deadline         Override deadline (NULL = inherit)        │       │
│  │ • created_at           Timestamp                                 │       │
│  ├──────────────────────────────────────────────────────────────────┤       │
│  │ UNIQUE: (project_id, original_date)                              │       │
│  └──────────────────────────────────────────────────────────────────┘       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow: Virtual Expansion

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       HOW OCCURRENCES ARE GENERATED                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  STEP 1: Fetch Base Task                                                    │
│  ┌──────────────────────────────────────────────────────────────────┐       │
│  │  Task: "Take vitamins"                                           │       │
│  │  RRULE: FREQ=DAILY                                               │       │
│  │  Start: 2025-01-01                                               │       │
│  │  series_ended: false                                             │       │
│  └──────────────────────────────────────────────────────────────────┘       │
│                                     │                                       │
│                                     ▼                                       │
│  STEP 2: Expand RRULE (for requested date range)                            │
│  ┌──────────────────────────────────────────────────────────────────┐       │
│  │  Input: startDate=Jan 1, endDate=Jan 7                           │       │
│  │  Generated: Jan 1, Jan 2, Jan 3, Jan 4, Jan 5, Jan 6, Jan 7      │       │
│  └──────────────────────────────────────────────────────────────────┘       │
│                                     │                                       │
│                                     ▼                                       │
│  STEP 3: Merge Completion Status                                            │
│  ┌──────────────────────────────────────────────────────────────────┐       │
│  │  Query: SELECT * FROM completion_history                         │       │
│  │         WHERE entity_id = ? AND occurrence_date IN (...)         │       │
│  │                                                                  │       │
│  │  Found: Jan 1 ✓, Jan 2 ✓                                         │       │
│  └──────────────────────────────────────────────────────────────────┘       │
│                                     │                                       │
│                                     ▼                                       │
│  STEP 4: Return TaskOccurrence List                                         │
│  ┌──────────────────────────────────────────────────────────────────┐       │
│  │  Jan 1 ✓ completed                                               │       │
│  │  Jan 2 ✓ completed                                               │       │
│  │  Jan 3 ○ pending                                                 │       │
│  │  Jan 4 ○ pending                                                 │       │
│  │  Jan 5 ○ pending                                                 │       │
│  │  Jan 6 ○ pending                                                 │       │
│  │  Jan 7 ○ pending                                                 │       │
│  └──────────────────────────────────────────────────────────────────┘       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Operations Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER ACTIONS                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────┐    ┌─────────────────────────────────────┐ │
│  │ COMPLETE OCCURRENCE         │    │ Database Operation                  │ │
│  │ User taps ✓ on Jan 3        │───▶│ INSERT INTO completion_history      │ │
│  │                             │    │ (entity_id, occurrence_date, ...)   │ │
│  └─────────────────────────────┘    └─────────────────────────────────────┘ │
│                                                                             │
│  ┌─────────────────────────────┐    ┌─────────────────────────────────────┐ │
│  │ UNCOMPLETE OCCURRENCE       │    │ Database Operation                  │ │
│  │ User taps ✓ again on Jan 3  │───▶│ DELETE FROM completion_history      │ │
│  │                             │    │ WHERE entity_id=? AND date=?        │ │
│  └─────────────────────────────┘    └─────────────────────────────────────┘ │
│                                                                             │
│  ┌─────────────────────────────┐    ┌─────────────────────────────────────┐ │
│  │ SKIP OCCURRENCE             │    │ Database Operation                  │ │
│  │ User deletes Jan 5          │───▶│ INSERT INTO recurrence_exceptions   │ │
│  │ (future dates only)         │    │ (original_date=Jan5, type='skip')   │ │
│  └─────────────────────────────┘    └─────────────────────────────────────┘ │
│                                                                             │
│  ┌─────────────────────────────┐    ┌─────────────────────────────────────┐ │
│  │ RESCHEDULE OCCURRENCE       │    │ Database Operation                  │ │
│  │ User moves Jan 5 → Jan 8    │───▶│ INSERT INTO recurrence_exceptions   │ │
│  │ (future dates only)         │    │ (original=Jan5, new=Jan8,           │ │
│  │                             │    │  type='reschedule')                 │ │
│  └─────────────────────────────┘    └─────────────────────────────────────┘ │
│                                                                             │
│  ┌─────────────────────────────┐    ┌─────────────────────────────────────┐ │
│  │ CHANGE OCCURRENCE DEADLINE  │    │ Database Operation                  │ │
│  │ User changes deadline for   │───▶│ UPDATE recurrence_exceptions        │ │
│  │ specific occurrence         │    │ SET new_deadline=? WHERE ...        │ │
│  │                             │    │ (or INSERT if no exception exists)  │ │
│  └─────────────────────────────┘    └─────────────────────────────────────┘ │
│                                                                             │
│  ┌─────────────────────────────┐    ┌─────────────────────────────────────┐ │
│  │ EDIT TASK (ALL OCCURRENCES) │    │ Database Operation                  │ │
│  │ Change name/description/etc │───▶│ UPDATE tasks SET ...                │ │
│  │                             │    │ (All occurrences affected)          │ │
│  └─────────────────────────────┘    └─────────────────────────────────────┘ │
│                                                                             │
│  ┌─────────────────────────────┐    ┌─────────────────────────────────────┐ │
│  │ END SERIES                  │    │ Database Operation                  │ │
│  │ Stop generating occurrences │───▶│ UPDATE tasks                        │ │
│  │                             │    │ SET series_ended = true             │ │
│  └─────────────────────────────┘    └─────────────────────────────────────┘ │
│                                                                             │
│  ┌─────────────────────────────┐    ┌─────────────────────────────────────┐ │
│  │ DELETE TASK                 │    │ Database Operation                  │ │
│  │ Remove task entirely        │───▶│ DELETE FROM tasks WHERE id = ?      │ │
│  │                             │    │ (CASCADE deletes history+exceptions)│ │
│  └─────────────────────────────┘    └─────────────────────────────────────┘ │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Requirements

| Requirement | Implementation |
|-------------|----------------|
| Repeating tasks | `repeat_ical_rrule` column with iCal RRULE |
| Complete occurrence | INSERT into `completion_history` |
| Uncomplete occurrence | DELETE from `completion_history` |
| Skip occurrence | INSERT into `recurrence_exceptions` with type='skip' |
| Reschedule occurrence | INSERT into `recurrence_exceptions` with type='reschedule' |
| Change occurrence deadline | Store in `recurrence_exceptions.new_deadline` |
| View completion history | Query `completion_history` by date range |
| End repeating series | Set `series_ended = true` on task |
| Edit task (all occurrences) | UPDATE task (name, description, labels affect all) |
| Delete task | CASCADE delete task + all history + all exceptions |
| Labels | Inherit from base task (no per-occurrence override) |

---

## Schema Definition

### Modified: tasks table

```sql
-- Add new column
ALTER TABLE tasks ADD COLUMN series_ended INTEGER NOT NULL DEFAULT 0;
```

### Modified: projects table

```sql
-- Add new column  
ALTER TABLE projects ADD COLUMN series_ended INTEGER NOT NULL DEFAULT 0;
```

### New: task_completion_history table

```sql
CREATE TABLE task_completion_history (
  id TEXT PRIMARY KEY,
  task_id TEXT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  occurrence_date TEXT,       -- NULL for non-repeating tasks
  original_occurrence_date TEXT,  -- Original RRULE date (for on-time tracking)
  completed_at TEXT NOT NULL DEFAULT (datetime('now')),
  notes TEXT,
  user_id TEXT,
  UNIQUE (task_id, occurrence_date)
);

-- Indexes for fast lookups
CREATE INDEX idx_task_completion_task 
ON task_completion_history(task_id, occurrence_date);

CREATE INDEX idx_task_completion_date 
ON task_completion_history(completed_at);

CREATE INDEX idx_task_completion_original_date 
ON task_completion_history(task_id, original_occurrence_date);
```

### New: project_completion_history table

```sql
CREATE TABLE project_completion_history (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  occurrence_date TEXT,       -- NULL for non-repeating projects
  original_occurrence_date TEXT,  -- Original RRULE date (for on-time tracking)
  completed_at TEXT NOT NULL DEFAULT (datetime('now')),
  notes TEXT,
  user_id TEXT,
  UNIQUE (project_id, occurrence_date)
);

-- Indexes for fast lookups
CREATE INDEX idx_project_completion_project 
ON project_completion_history(project_id, occurrence_date);

CREATE INDEX idx_project_completion_date 
ON project_completion_history(completed_at);

CREATE INDEX idx_project_completion_original_date 
ON project_completion_history(project_id, original_occurrence_date);
```

### New: task_recurrence_exceptions table

```sql
CREATE TABLE task_recurrence_exceptions (
  id TEXT PRIMARY KEY,
  task_id TEXT NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  original_date TEXT NOT NULL,  -- The RRULE date being modified
  exception_type TEXT NOT NULL CHECK (exception_type IN ('skip', 'reschedule')),
  new_date TEXT,                -- Target date for reschedule (NULL if skip)
  new_deadline TEXT,            -- Override deadline (NULL = inherit from task)
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE (task_id, original_date)
);

-- Index for finding exceptions by task
CREATE INDEX idx_task_exception_task 
ON task_recurrence_exceptions(task_id, original_date);

-- Index for finding rescheduled occurrences by new_date
CREATE INDEX idx_task_exception_new_date 
ON task_recurrence_exceptions(task_id, new_date)
WHERE new_date IS NOT NULL;
```

### New: project_recurrence_exceptions table

```sql
CREATE TABLE project_recurrence_exceptions (
  id TEXT PRIMARY KEY,
  project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  original_date TEXT NOT NULL,  -- The RRULE date being modified
  exception_type TEXT NOT NULL CHECK (exception_type IN ('skip', 'reschedule')),
  new_date TEXT,                -- Target date for reschedule (NULL if skip)
  new_deadline TEXT,            -- Override deadline (NULL = inherit from project)
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE (project_id, original_date)
);

-- Index for finding exceptions by project
CREATE INDEX idx_project_exception_project 
ON project_recurrence_exceptions(project_id, original_date);

-- Index for finding rescheduled occurrences by new_date
CREATE INDEX idx_project_exception_new_date 
ON project_recurrence_exceptions(project_id, new_date)
WHERE new_date IS NOT NULL;
```

### Drift Table Definitions

```dart
/// Task completion history - tracks when task occurrences are completed
class TaskCompletionHistoryTable extends Table {
  @override
  String get tableName => 'task_completion_history';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();
  TextColumn get taskId => text().named('task_id').references(Tasks, #id)();
  DateTimeColumn get occurrenceDate => dateTime().nullable().named('occurrence_date')();
  /// Original RRULE-generated date. For rescheduled tasks, this differs from
  /// occurrence_date. Used for on-time reporting.
  DateTimeColumn get originalOccurrenceDate => dateTime().nullable().named('original_occurrence_date')();
  DateTimeColumn get completedAt => dateTime().clientDefault(DateTime.now).named('completed_at')();
  TextColumn get notes => text().nullable().named('notes')();
  TextColumn get userId => text().nullable().named('user_id')();

  @override
  Set<Column> get primaryKey => {id};
  
  @override
  List<Set<Column>> get uniqueKeys => [
    {taskId, occurrenceDate},
  ];
}

/// Project completion history - tracks when project occurrences are completed
class ProjectCompletionHistoryTable extends Table {
  @override
  String get tableName => 'project_completion_history';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();
  TextColumn get projectId => text().named('project_id').references(Projects, #id)();
  DateTimeColumn get occurrenceDate => dateTime().nullable().named('occurrence_date')();
  DateTimeColumn get originalOccurrenceDate => dateTime().nullable().named('original_occurrence_date')();
  DateTimeColumn get completedAt => dateTime().clientDefault(DateTime.now).named('completed_at')();
  TextColumn get notes => text().nullable().named('notes')();
  TextColumn get userId => text().nullable().named('user_id')();

  @override
  Set<Column> get primaryKey => {id};
  
  @override
  List<Set<Column>> get uniqueKeys => [
    {projectId, occurrenceDate},
  ];
}

/// Task recurrence exceptions - skip/reschedule individual task occurrences
class TaskRecurrenceExceptionsTable extends Table {
  @override
  String get tableName => 'task_recurrence_exceptions';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();
  TextColumn get taskId => text().named('task_id').references(Tasks, #id)();
  DateTimeColumn get originalDate => dateTime().named('original_date')();
  TextColumn get exceptionType => text().named('exception_type')(); // 'skip' | 'reschedule'
  DateTimeColumn get newDate => dateTime().nullable().named('new_date')();
  DateTimeColumn get newDeadline => dateTime().nullable().named('new_deadline')();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now).named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
  
  @override
  List<Set<Column>> get uniqueKeys => [
    {taskId, originalDate},
  ];
}

/// Project recurrence exceptions - skip/reschedule individual project occurrences
class ProjectRecurrenceExceptionsTable extends Table {
  @override
  String get tableName => 'project_recurrence_exceptions';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();
  TextColumn get projectId => text().named('project_id').references(Projects, #id)();
  DateTimeColumn get originalDate => dateTime().named('original_date')();
  TextColumn get exceptionType => text().named('exception_type')(); // 'skip' | 'reschedule'
  DateTimeColumn get newDate => dateTime().nullable().named('new_date')();
  DateTimeColumn get newDeadline => dateTime().nullable().named('new_deadline')();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now).named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
  
  @override
  List<Set<Column>> get uniqueKeys => [
    {projectId, originalDate},
  ];
}
```

---

## Column Semantics

| Column | Non-Repeating Task | Repeating Task |
|--------|-------------------|----------------|
| `completed` | ✅ Task is done | ❌ Not used |
| `series_ended` | ❌ Not used | ✅ Stop generating future occurrences |
| `task_completion_history` | ✅ One record (occurrence_date = NULL) | ✅ One record per completed occurrence |

---

## Domain Models

```dart
/// A single occurrence of a task (repeating or non-repeating)
@immutable
class TaskOccurrence {
  const TaskOccurrence({
    required this.task,
    required this.occurrenceDate,
    required this.isCompleted,
    this.completedAt,
    this.isRescheduled = false,
    this.originalDate,
    this.overrideDeadline,
  });

  final Task task;
  final DateTime? occurrenceDate; // null = non-repeating
  final bool isCompleted;
  final DateTime? completedAt;
  
  /// True if this occurrence was rescheduled from another date
  final bool isRescheduled;
  
  /// Original date if rescheduled (for display purposes)
  final DateTime? originalDate;
  
  /// Override deadline for this specific occurrence (null = use task deadline)
  final DateTime? overrideDeadline;
  
  String get name => task.name;
  String? get description => task.description;
  DateTime? get deadline => overrideDeadline ?? task.deadlineDate;
  List<Label> get labels => task.labels;
  
  bool get isRepeating => occurrenceDate != null;
}

/// Exception types for recurrence modifications
enum ExceptionType { skip, reschedule }

/// Represents a modification to a single task occurrence
@immutable
class TaskRecurrenceException {
  const TaskRecurrenceException({
    required this.id,
    required this.taskId,
    required this.originalDate,
    required this.exceptionType,
    this.newDate,
    this.newDeadline,
  });

  final String id;
  final String taskId;
  final DateTime originalDate;
  final ExceptionType exceptionType;
  final DateTime? newDate;       // Only for reschedule
  final DateTime? newDeadline;   // Optional deadline override
}

/// Represents a modification to a single project occurrence
@immutable
class ProjectRecurrenceException {
  const ProjectRecurrenceException({
    required this.id,
    required this.projectId,
    required this.originalDate,
    required this.exceptionType,
    this.newDate,
    this.newDeadline,
  });

  final String id;
  final String projectId;
  final DateTime originalDate;
  final ExceptionType exceptionType;
  final DateTime? newDate;       // Only for reschedule
  final DateTime? newDeadline;   // Optional deadline override
}
```

---

## OccurrenceService

```dart
class OccurrenceService {
  final TaskRepository _taskRepo;
  final TaskCompletionHistoryRepository _completionRepo;
  final TaskRecurrenceExceptionRepository _exceptionRepo;
  
  /// Get expanded occurrences for Upcoming view
  Stream<List<TaskOccurrence>> watchOccurrences({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return Rx.combineLatest3(
      _taskRepo.watchRepeatingTasks(),
      _completionRepo.watchByDateRange(startDate, endDate),
      _exceptionRepo.watchByDateRange(startDate, endDate),
      (tasks, completions, exceptions) => 
        _expand(tasks, completions, exceptions, startDate, endDate),
    );
  }
  
  /// Get tasks for Today view (one row per task, not expanded)
  Stream<List<Task>> watchTasksForToday(DateTime today) {
    return Rx.combineLatest3(
      _taskRepo.watchAll(),
      _completionRepo.watchByDate(today),
      _exceptionRepo.watchByDate(today),
      (tasks, completions, exceptions) => 
        _filterForToday(tasks, completions, exceptions, today),
    );
  }
  
  /// Complete an occurrence
  Future<void> complete(String taskId, DateTime? occurrenceDate) async {
    await _completionRepo.create(
      entityId: taskId,
      entityType: 'task',
      occurrenceDate: occurrenceDate,
    );
    
    // For non-repeating, also set completed flag
    if (occurrenceDate == null) {
      await _taskRepo.setCompleted(taskId, true);
    }
  }
  
  /// Uncomplete an occurrence
  Future<void> uncomplete(String taskId, DateTime? occurrenceDate) async {
    await _completionRepo.delete(
      entityId: taskId,
      entityType: 'task',
      occurrenceDate: occurrenceDate,
    );
    
    if (occurrenceDate == null) {
      await _taskRepo.setCompleted(taskId, false);
    }
  }
  
  /// Skip a single occurrence (delete it from the series)
  Future<void> skipOccurrence(String taskId, DateTime occurrenceDate) async {
    // Validate: only future dates
    if (occurrenceDate.isBefore(DateTime.now())) {
      throw ArgumentError('Cannot skip past occurrences');
    }
    
    await _exceptionRepo.create(
      taskId: taskId,
      originalDate: occurrenceDate,
      exceptionType: ExceptionType.skip,
    );
  }
  
  /// Reschedule a single occurrence to a new date
  Future<void> rescheduleOccurrence(
    String taskId, 
    DateTime originalDate, 
    DateTime newDate, {
    DateTime? newDeadline,
  }) async {
    // Validate: only future dates
    if (originalDate.isBefore(DateTime.now())) {
      throw ArgumentError('Cannot reschedule past occurrences');
    }
    
    await _exceptionRepo.create(
      taskId: taskId,
      originalDate: originalDate,
      exceptionType: ExceptionType.reschedule,
      newDate: newDate,
      newDeadline: newDeadline,
    );
  }
  
  /// Change deadline for a specific occurrence
  Future<void> setOccurrenceDeadline(
    String taskId, 
    DateTime occurrenceDate, 
    DateTime? deadline,
  ) async {
    final existing = await _exceptionRepo.findByOccurrence(
      taskId: taskId, 
      originalDate: occurrenceDate,
    );
    
    if (existing != null) {
      await _exceptionRepo.update(existing.id, newDeadline: deadline);
    } else {
      // Create a "reschedule to same date" exception just to store deadline
      await _exceptionRepo.create(
        entityId: taskId,
        entityType: 'task',
        originalDate: occurrenceDate,
        exceptionType: ExceptionType.reschedule,
        newDate: occurrenceDate,  // Same date
        newDeadline: deadline,
      );
    }
  }
  
  List<TaskOccurrence> _expand(
    List<Task> tasks,
    List<TaskCompletionRecord> completions,
    List<TaskRecurrenceException> exceptions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final completionSet = completions
        .map((c) => '${c.entityId}_${c.occurrenceDate?.toIso8601String()}')
        .toSet();
    
    // Index exceptions by (entityId, originalDate)
    final skipSet = <String>{};
    final rescheduleMap = <String, RecurrenceException>{};
    
    for (final ex in exceptions) {
      final key = '${ex.entityId}_${ex.originalDate.toIso8601String()}';
      if (ex.exceptionType == ExceptionType.skip) {
        skipSet.add(key);
      } else {
        rescheduleMap[key] = ex;
      }
    }
    
    final result = <TaskOccurrence>[];
    
    for (final task in tasks) {
      if (task.seriesEnded) continue;
      
      if (task.isRepeating) {
        final dates = _expandRRule(task.repeatIcalRrule!, startDate, endDate);
        
        for (final date in dates) {
          final key = '${task.id}_${date.toIso8601String()}';
          
          // Skip if deleted
          if (skipSet.contains(key)) continue;
          
          // Check if rescheduled away
          final rescheduled = rescheduleMap[key];
          if (rescheduled != null && rescheduled.newDate != date) {
            // Original date is removed, will be added at new_date
            continue;
          }
          
          result.add(TaskOccurrence(
            task: task,
            occurrenceDate: date,
            isCompleted: completionSet.contains(key),
            overrideDeadline: rescheduled?.newDeadline,
          ));
        }
        
        // Add rescheduled occurrences that land in our date range
        for (final ex in exceptions.where((e) => 
          e.entityId == task.id && 
          e.exceptionType == ExceptionType.reschedule &&
          e.newDate != null &&
          !e.newDate!.isBefore(startDate) &&
          !e.newDate!.isAfter(endDate))) {
          
          final key = '${task.id}_${ex.newDate!.toIso8601String()}';
          result.add(TaskOccurrence(
            task: task,
            occurrenceDate: ex.newDate,
            isCompleted: completionSet.contains(key),
            isRescheduled: true,
            originalDate: ex.originalDate,
            overrideDeadline: ex.newDeadline,
          ));
        }
      } else {
        // Non-repeating task
        final key = '${task.id}_null';
        result.add(TaskOccurrence(
          task: task,
          occurrenceDate: null,
          isCompleted: task.completed || completionSet.contains(key),
        ));
      }
    }
    
    return result..sort((a, b) => 
      (a.deadline ?? DateTime(9999)).compareTo(b.deadline ?? DateTime(9999)));
  }
}
```

---

## Migration Plan

### Phase 1: Schema (~2 days)
- Add `series_ended` column to tasks and projects
- Create `completion_history` table
- Create `recurrence_exceptions` table
- Add indexes

### Phase 2: Core Logic (~1.5 weeks)
- Implement `OccurrenceService`
- Add RRULE parsing (use `rrule` package)
- Create `CompletionHistoryRepository`
- Create `RecurrenceExceptionRepository`
- Implement skip/reschedule logic

### Phase 3: UI Integration (~1 week)
- Update Upcoming view to use expanded occurrences
- Add complete/uncomplete gestures
- Add "Skip" and "Reschedule" actions for occurrences
- Add occurrence deadline override UI
- Add "End Series" action
- Add History view

**Total: ~3-4 weeks**

---

## Reporting & Analytics

### Supported Reports

| Report | Description |
|--------|-------------|
| **Completion History** | All completions for any task/project |
| **On-Time Rate** | % completed on original scheduled date |
| **Within X Days Rate** | % completed within X days of schedule |
| **Adherence/Consistency %** | Completions ÷ Expected occurrences |
| **Streak Tracking** | Consecutive periods meeting goal |

### Key Column: `original_occurrence_date`

This column enables accurate on-time tracking for rescheduled tasks:

| Scenario | occurrence_date | original_occurrence_date | Days Late |
|----------|-----------------|-------------------------|----------|
| Normal completion | Jan 15 | Jan 15 | 0 |
| Completed late | Jan 17 | Jan 15 | 2 |
| Rescheduled Jan 15→Jan 20, done Jan 20 | Jan 20 | Jan 15 | 5 |
| Rescheduled Jan 15→Jan 20, done Jan 22 | Jan 20 | Jan 15 | 7 |

### Example Queries

#### 1. Completion History for a Task
```sql
SELECT 
  occurrence_date,
  original_occurrence_date,
  completed_at,
  notes
FROM task_completion_history
WHERE task_id = ?
ORDER BY completed_at DESC;
```

#### 2. On-Time Completion Rate
```sql
SELECT 
  COUNT(*) AS total_completions,
  SUM(CASE 
    WHEN date(completed_at) = date(original_occurrence_date) THEN 1 
    ELSE 0 
  END) AS on_time,
  ROUND(100.0 * SUM(CASE 
    WHEN date(completed_at) = date(original_occurrence_date) THEN 1 
    ELSE 0 
  END) / COUNT(*), 1) AS on_time_pct
FROM task_completion_history
WHERE task_id = ?
  AND original_occurrence_date IS NOT NULL;
```

#### 3. Completed Within X Days Rate
```sql
-- Example: within 2 days
SELECT 
  COUNT(*) AS total,
  SUM(CASE 
    WHEN julianday(completed_at) - julianday(original_occurrence_date) <= 2 THEN 1 
    ELSE 0 
  END) AS within_threshold,
  ROUND(100.0 * SUM(CASE 
    WHEN julianday(completed_at) - julianday(original_occurrence_date) <= 2 THEN 1 
    ELSE 0 
  END) / COUNT(*), 1) AS within_threshold_pct
FROM task_completion_history
WHERE task_id = ?
  AND original_occurrence_date IS NOT NULL;
```

#### 4. Adherence % (Requires Dart for RRULE expansion)
```dart
Future<double> calculateAdherence(
  Task task, 
  DateTime start, 
  DateTime end,
) async {
  // Expected occurrences from RRULE
  final expectedDates = expandRRule(task.repeatIcalRrule!, start, end);
  
  // Subtract skipped occurrences
  final skips = await _exceptionRepo.getSkips(task.id, start, end);
  final expectedCount = expectedDates.length - skips.length;
  
  // Actual completions
  final completions = await _completionRepo.getByDateRange(
    task.id, start, end,
  );
  
  if (expectedCount == 0) return 100.0;
  return (completions.length / expectedCount) * 100;
}
```

#### 5. Weekly Adherence Trend
```sql
SELECT 
  strftime('%Y-%W', original_occurrence_date) AS week,
  COUNT(*) AS completions
FROM task_completion_history
WHERE task_id = ?
  AND original_occurrence_date >= date('now', '-12 weeks')
GROUP BY week
ORDER BY week;
```

#### 6. Average Days Late
```sql
SELECT 
  ROUND(AVG(julianday(completed_at) - julianday(original_occurrence_date)), 1) AS avg_days_late
FROM task_completion_history
WHERE task_id = ?
  AND original_occurrence_date IS NOT NULL
  AND julianday(completed_at) >= julianday(original_occurrence_date);
```

### Analytics Service

```dart
class AnalyticsService {
  final TaskCompletionHistoryRepository _completionRepo;
  final TaskRecurrenceExceptionRepository _exceptionRepo;

  /// Get comprehensive stats for a task
  Future<TaskStats> getTaskStats(String taskId, DateTime start, DateTime end) async {
    final completions = await _completionRepo.getByEntityAndRange(
      entityId: taskId,
      start: start,
      end: end,
    );
    
    final onTime = completions.where((c) => 
      c.originalOccurrenceDate != null &&
      _isSameDay(c.completedAt, c.originalOccurrenceDate!)
    ).length;
    
    final withinThreshold = (int days) => completions.where((c) =>
      c.originalOccurrenceDate != null &&
      c.completedAt.difference(c.originalOccurrenceDate!).inDays <= days
    ).length;
    
    return TaskStats(
      totalCompletions: completions.length,
      onTimeCount: onTime,
      onTimePercent: completions.isEmpty ? 0 : (onTime / completions.length) * 100,
      within1DayPercent: completions.isEmpty ? 0 : (withinThreshold(1) / completions.length) * 100,
      within3DaysPercent: completions.isEmpty ? 0 : (withinThreshold(3) / completions.length) * 100,
    );
  }
}

@immutable
class TaskStats {
  final int totalCompletions;
  final int onTimeCount;
  final double onTimePercent;
  final double within1DayPercent;
  final double within3DaysPercent;
  
  const TaskStats({
    required this.totalCompletions,
    required this.onTimeCount,
    required this.onTimePercent,
    required this.within1DayPercent,
    required this.within3DaysPercent,
  });
}
```

---

## What's NOT Included (Future Features)

| Feature | Effort to Add Later |
|---------|---------------------|
| Modify occurrence name/description | +3 days (add JSON overrides column) |
| Habit goals (X times per week) | +1 week (add goal columns + UI) |
| Preserve history on delete | +2 days (remove cascade, handle orphans) |
| Label snapshots | +1 day (add column) |
| Undo skip/reschedule | +2 days (soft delete exceptions) |

---

## Testing Checklist

- [ ] Non-repeating task: complete creates history record
- [ ] Non-repeating task: uncomplete removes history record
- [ ] Repeating task: complete occurrence creates dated record
- [ ] Repeating task: uncomplete removes dated record
- [ ] Repeating task: edit updates all future occurrences
- [ ] Repeating task: end series stops generation
- [ ] **Skip occurrence: creates exception, occurrence disappears**
- [ ] **Skip occurrence: past dates rejected**
- [ ] **Reschedule occurrence: old date removed, new date appears**
- [ ] **Reschedule occurrence: past dates rejected**
- [ ] **Reschedule to occupied date: both occurrences show**
- [ ] **Change occurrence deadline: overrides task deadline**
- [ ] Delete task cascades to completion_history AND recurrence_exceptions
- [ ] Today view shows one row per task
- [ ] Upcoming view shows expanded occurrences (with exceptions applied)
- [ ] History view shows all completions
- [ ] **Reporting: on-time % calculated correctly**
- [ ] **Reporting: rescheduled tasks use original_occurrence_date for lateness**
- [ ] **Reporting: adherence % matches expected vs actual**
- [ ] **Reporting: within X days threshold works**
