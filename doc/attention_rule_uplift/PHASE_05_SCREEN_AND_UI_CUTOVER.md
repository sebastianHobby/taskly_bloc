# Phase 05 — Screen/template/UI cutover (big-bang)

## Outcome

- All attention UI surfaces read from the new engine:
  - issues summary
  - allocation alerts
  - check-in summary
- No legacy evaluator path remains.
- No interpreter contains bespoke invalidation/refetch code.

## Scope

- Update all section interpreters that currently call legacy evaluation code.
- Update settings pages (rule toggles) to use the new repository/engine APIs.

## Constraints

- Do not update or run tests.
- Keep compilation and run `flutter analyze` at the end.
- Big-bang: once cutover happens, delete all legacy code replaced by the new engine.

## Steps

1) Update section interpreters to use `AttentionEngineContract`

- Issues summary:
  - Replace legacy “fetch once” or legacy evaluator calls.
  - Use `engine.watch(query)` and map into `SectionDataResult`.

- Allocation alerts:
  - Replace legacy evaluator calls.
  - Use `engine.watch(query)` with appropriate domain/category filters.

- Check-in summary:
  - Replace legacy refetch/invalidation wiring.
  - Use the engine stream.

2) Update presentation pieces if needed

- Ensure existing renderers remain unchanged where possible.
- Only adjust view-model mapping if the output shape changes.

3) Delete legacy attention runtime

Delete everything that is no longer referenced after the cutover, for example:

- Legacy evaluator(s) and any evaluator helpers only used by them.
- Legacy attention domain models that were superseded by `lib/domain/attention/`.
- Legacy repository contracts/implementations replaced by the new ones.
- Any section-level invalidation/refetch utilities replaced by engine-level invalidation.

Important: do not keep adapter layers. If something is still needed, it’s not deleted.

4) Compile + analyze checkpoint

- Run: `flutter analyze`

Optional (if you changed generated Drift code):
- `dart run build_runner build --delete-conflicting-outputs`

## Exit criteria

- All attention sections are powered by the engine.
- No legacy attention evaluator path remains in the codebase.
- `flutter analyze` passes.
