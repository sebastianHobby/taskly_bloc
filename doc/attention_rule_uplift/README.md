# Attention Rule Uplift — Execution Plan (Big-Bang Cutovers)

> Audience: developers + architects
>
> Goal: migrate the attention system to the new schema + runtime state model and the new domain architecture.
>
> Non-negotiables (from requirements):
> - Each phase must keep the app compiling and must run `flutter analyze`.
> - Do not update or run tests until the final phase.
> - Big-bang cutovers: when a new path replaces an old one, the legacy code is deleted in the same phase.
> - No backward-compatible “dual-path” runtime behavior in any phase.

## What “big-bang per phase” means

- Before a phase starts, the current code remains the single active path.
- During a phase, we implement the replacement and switch all call sites.
- By the end of the phase:
  - the new path is the only path,
  - the legacy code that was replaced is deleted (not left around “just in case”).

Functionality is allowed to temporarily regress between phases, but compilation and `flutter analyze` are required.

## Phases

- Phase 01 — Schema + PowerSync alignment
- Phase 02 — New domain API and model (attention “bounded context”)
- Phase 03 — Data layer + persistence rewrite (rules/resolutions/runtime-state)
- Phase 04 — Engine runtime + triggers/scheduling wiring
- Phase 05 — Screen/template/UI cutover (Issues / Allocation Alerts / Check-in)
- Phase 06 — Final cleanup: delete remaining legacy, add/adjust tests, update docs

Open each phase file and execute it top-to-bottom.
