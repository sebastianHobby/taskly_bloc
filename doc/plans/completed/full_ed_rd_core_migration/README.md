# full_ed_rd_core_migration (WIP)

Created at: 2026-01-14 (UTC)
Last updated at: 2026-01-14 (UTC)

This folder contains the persisted work-in-progress plan for aligning **core
entities** (task/project/value) to the ED/RD architecture.

## Phase files
- Phase 00: Baseline + invariants — `phase_00_baseline_and_invariants.md`
- Phase 01: Routing (NAV-01 + redirects + route-backed editors) — `phase_01_routing_nav01_and_route_backed_editors.md`
- Phase 02: Domain field keys (A3 + L2) + UI adoption — `phase_02_domain_field_keys_and_ui_adoption.md`
- Phase 03: Draft → Command pipeline — `phase_03_draft_to_command_pipeline.md`
- Phase 04: Domain-first validation mapping — `phase_04_domain_first_validation_mapping.md`
- Phase 05: Verification + docs — `phase_05_verification_and_docs.md`

## Key locked decisions (summary)
- Task canonical edit route is `/task/:id/edit`; `/task/:id` redirects.
- Edit routes are route-backed pages that open modal editors.
- Dismiss is pop-or-`/my-day` fallback.
- Draft → Command → handler; domain-first field-addressable validation.
- Field keys are sealed typed objects stored in domain (pragmatic choice to
  avoid string duplication).
