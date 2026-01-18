# Taskly — Current Task/Project Tile Mockups

These are *wireframe mockups* of the **current** canonical entity views:

- `TaskViewVariant.list` (task list row)
- `ProjectViewVariant.list` (project list row)
- `TaskViewVariant.agendaCard` (task agenda card)
- `ProjectViewVariant.agendaCard` (project agenda card)

They reflect the implementation in:
- `lib/presentation/entity_views/task_view.dart`
- `lib/presentation/entity_views/project_view.dart`

Legend:
- `[PV]` = primary value chip (solid)
- `[SV◻]` = secondary value chip (outlined, icon-only, exactly 1)
- `[↻]` = repeating token (sync icon)
- `[|]` = priority flag (small vertical colored rectangle, only P1/P2)
- `[…]` = overflow indicator (more_horiz) shown only when status tokens exist but are demoted
- `[S]` = start-date chip
- `[D]` = deadline chip

---

## 1) Task — List Row (`TaskViewVariant.list`)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ [pinned?]                                                                    │
│  ▎  [☐]  Task title (1–2 lines, ellipsize)                           [⋮menu] │
│      [PV: icon + name]  [SV◻: icon-only]                     [|] [↻] […] [S]│
│                                                                   [D]        │
└──────────────────────────────────────────────────────────────────────────────┘
```

Notes (current behavior):
- No project pill is shown in list rows.
- `deadline` is always shown when present.
- `start date` is shown **only if startDay > today (local day)**.
- Right cluster uses `WrapAlignment.end`.
- On narrow widths, status tokens (`[|]` and `[↻]`) demote first; date chips remain.
- If status tokens exist but are hidden, show `[…]` (more-horiz) just before the date chips.

---

## 2) Project — List Row (`ProjectViewVariant.list`)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ [pinned?]                                                                    │
│  ▎  [📁]  Project title (1–2 lines, ellipsize)                       [⋮menu] │
│      [PV: icon + name]  [SV◻: icon-only]                     [|] [↻] […] [S]│
│                                                                   [D]        │
│  (optional) progress bar at bottom (when taskCount + done known)             │
└──────────────────────────────────────────────────────────────────────────────┘
```

Notes (current behavior):
- Same right-side demotion/overflow-indicator rules as task list rows.
- `start date` is shown **only if startDay > today (local day)**.
- `deadline` is always shown when present.

---

## 3) Task — Agenda Card (`TaskViewVariant.agendaCard`)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ (rounded card; optional left accent bar; optional dashed outline for ongoing) │
│ [☐]  Task title (max 2 lines)                                   [statusBadge]│
│      [PV: icon + name] [SV◻: icon-only]                    [|] [↻] […] [S]   │
│                                                                   [D]        │
│                                                                              │
│ If agendaInProgressStyle: date chips typically hidden; right shows menu + end │
│ marker:
│      [PV: icon + name] [SV◻: icon-only]          [|] [↻] […]    [⋮menu]   [⏳]
│                                                        endDay label (E.g. Mon)
└──────────────────────────────────────────────────────────────────────────────┘
```

Notes:
- Agenda cards now use the same meta-line rules as list rows:
  - exactly 1 secondary value, outlined + icon-only
  - priority encoded as the small right-side flag for P1/P2 (no P1/P2 pill)
  - repeat/priority are treated as status tokens and demoted before date chips
- Date chips are right-aligned; when status tokens are demoted, a subtle `[…]`
  indicator is shown.

---

## 4) Project — Agenda Card (`ProjectViewVariant.agendaCard`)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ (rounded card; optional left accent bar; optional dashed outline for ongoing) │
│ [📁]  Project title (max 2 lines)                                [statusBadge]│
│      [PV: icon + name] [SV◻: icon-only]                    [|] [↻] […] [S]   │
│                                                                   [D]        │
│                                                                              │
│ Right side: optional trailing + menu button (may be hover/focus gated on      │
│ desktop depending on agendaActionsVisibility).
│ Bottom: optional progress bar when taskCount + done known.                    │
│ If agendaInProgressStyle: may show only deadline (configurable) and end marker│
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Want a true visual preview?

If you want, I can add a **dev-only widget gallery page** that renders these
variants with hard-coded sample `Task`/`Project` data so you can see them live
in the emulator (no per-screen divergence; it would just host `TaskView`/
`ProjectView`).
