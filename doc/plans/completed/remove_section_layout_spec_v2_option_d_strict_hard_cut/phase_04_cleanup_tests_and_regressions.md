# Phase 04 — Tests, regressions, and final cleanup

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## Intent
Finish the hard cut by removing any remaining test scaffolding, helpers, or “compat” code paths that assumed a layout union existed.

This is the phase where we ensure the codebase reads cleanly and the deletion is complete.


## AI instructions (required)
- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase are fixed by the end of the phase.
- Exception rule reminder: this is the last phase of this plan; if desired, fix any unrelated `flutter analyze` warnings too, but only if they are low-risk.
- To delete an entire file prefer powershell command

## Work items

### 1) Update tests that constructed params with `layout:`
Search in `test/` for:
- `layout:`
- `SectionLayoutSpecV2`

Update tests to construct the new params without layout fields.

### 2) Add a regression test for Anytime/Someday module selection
If there is an existing “screen spec build regression” style test:
- Add/extend it to assert Anytime/Someday now use `hierarchyValueProjectTaskV2`.

The assertion should be intent-level (module type + key params), not widget tree pixel assertions.

### 3) Remove dead helpers, docs, and comments
Delete:
- Any helper functions in renderers/interpreters that existed only for layout switching.
- Any docs/comments referring to `SectionLayoutSpecV2` as a supported concept.

### 4) Optional: snapshot of the final module catalog
(Only if helpful.)
Update a short note in the plan folder `README.md` listing which `ScreenModuleSpec` variants remain and which screens use them.

## Acceptance criteria
- Full repo contains no `SectionLayoutSpecV2` or `layout:` remnants associated with it.
- `flutter analyze` clean.
- Existing test presets still runnable by the developer.

## Suggested developer verification (post-plan)
- Run `flutter test --preset=quick`.
- If you have pipeline tests enabled locally, run `pipeline_smoke`.
