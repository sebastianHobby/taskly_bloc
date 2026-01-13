# Unified Screen Model V2 — Decisions

Created at: 2026-01-12T00:00:00Z (UTC)
Last updated at: 2026-01-12T00:00:00Z (UTC)

This file records explicit plan-level decisions confirmed in chat, to keep Phases 2–5 implementation aligned.

## D-01 — Template IDs for V2 cutover
- Decision: **A** — introduce new template IDs (`*_v2`) and cut over fully.

## D-02 — Replacement for related-data sidecar (`relatedEntities`, `RelatedDataConfig`)
- Decision: **B** — remove related-data concept and replace required derived data with **typed V2 enrichment results**.

## D-03 — Where enrichment/derived data is computed
- Decision: **B** — compute in **domain/runtime** (interpreters/data services), not in UI renderers.

## D-04 — V2 layout spec scope
- Decision: **A** — ship only the layouts that match real current UX patterns:
  - `flat_list`
  - `timeline_month_sections` (Scheduled-style)
  - `hierarchy_value_project_task` (replaces `valueHierarchy`)

## D-05 — Sticky header support
- Decision: **B** — support sticky headers for **timeline** and **grouped lists**.

## D-06 — Agenda tags + `TaskTileVariant.agenda` semantics
- Decision: **B** — agenda tags are a **typed derived output** and must be available anywhere `TaskTileVariant.agenda` renders (not agenda-only).

## D-07 — Value query correctness
- Decision: **B** — fix `ValueDataConfig(query: ...)` so it is honored end-to-end as part of the V2 work.
