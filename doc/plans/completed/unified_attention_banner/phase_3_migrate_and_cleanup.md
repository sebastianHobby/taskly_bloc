# Plan: Unified Attention Banner + Action/Review Cutover (Phase 3 — UI + Migration + Cleanup)

Created at: 2026-01-14T00:00:00Z
Last updated at: 2026-01-14T14:00:00Z

## Goal
Ship the unified attention banner end-to-end using the Tier 2 rule model
(`bucket + evaluator + evaluatorParams`) and remove legacy attention surfaces
and legacy data model concepts.

This is the **last phase**, so it also fixes any remaining `flutter analyze`
warnings/errors (even if unrelated).

## Confirmed taxonomy + copy
- Top-level taxonomy is **Action** and **Review** only.
- Do not surface `intent` or `category`.

Copy (tune during implementation if needed):
- Header label: `Attention`
- Bucket labels: `Action`, `Review`
- Overflow CTA labels:
  - `Take action (N)`
  - `Start reviews (M)`

## UI scope (system screens)
Adopt unified banner on:
- `my_day`
- `someday`
- `scheduled`
- `projects`
- `values`

For these screens:
- Remove legacy sections:
  - `checkInSummary`
  - `issuesSummary`
  - `allocationAlerts`
- Add the new banner section (v1).

Notes:
- My Day must still surface both buckets:
  - Action (issues + allocation + coaching)
  - Review (review-session due items)

## Banner UX (confirmed)
- Collapsed: counts-only preview.
- Expand behavior:
  - Default `expandMaxItems=5` (keep configurable for future).
  - If `totalCount <= expandMaxItems`, show an inline expandable list.
  - If `totalCount > expandMaxItems`, show overflow CTA(s).

Constraints:
- UI must not depend on `AttentionItem.metadata`.
- UI must not re-join rules; banner section VM includes bucket attribution,
  counts, and a stable sort key.

Ordering:
- severity desc
- due date asc (when available)
- created/updated asc (when available)

## Overflow destination (make it real)
Screen key stays `review_inbox`, but UI title becomes `Attention`.

Requirements:
- Shows the same scoped set as the banner that navigated there.
- Deep-linkable (args encoded in route).
- Groups by bucket (Action, Review).
- Supports per-item actions based on `AttentionItem.availableActions`.

## Navigation args + deep links
Define a versioned args payload (e.g. `AttentionInboxArgsV1`) that supports:
- `buckets`: optional set of `action|review` (default: both)
- `expandMaxItems`: optional (for consistent behavior)

Avoid encoding legacy fields (`domain`, `category`).

## Implementation checklist
1) Banner section renderer
- Render counts by bucket.
- Render expandable list grouped by bucket.

2) Overflow inbox
- Implement list grouped by bucket.
- Actions:
  - prefer `reviewed` when present
  - also expose `dismissed` and `snoozed`

3) Update system screen specs
- Replace old sections with banner.
- Ensure no remaining navigation points to removed routes.

## Concrete file targets (Phase 3)
- New unified banner module (add + wire):
  - Module spec + template id:
    - `lib/domain/screens/language/models/screen_spec.dart`
      - Add `ScreenModuleSpec.attentionBannerV1(...)`
      - Add a corresponding `SectionTemplateId` entry
  - Runtime result + wiring:
    - `lib/domain/screens/runtime/section_data_result.dart`
      - Add a `SectionDataResult.attentionBannerV1(...)` variant
    - `lib/domain/screens/runtime/section_data_service.dart`
      - Route the new module spec to the new interpreter
  - Params model:
    - Add `lib/domain/screens/templates/params/attention_banner_section_params.dart`
  - Interpreter:
    - Add `lib/domain/screens/templates/interpreters/attention_banner_section_interpreter.dart`
    - Wire into `lib/domain/screens/templates/interpreters/section_template_interpreter.dart`
  - Renderer:
    - Add `lib/presentation/screens/templates/renderers/attention_banner_section_renderer.dart`
    - Wire into `lib/presentation/widgets/section_widget.dart`

- Overflow screen template (replace placeholder):
  - `lib/presentation/screens/templates/screen_template_widget.dart`
    - Replace the `reviewInbox: () => _PlaceholderTemplate(...)` path.

- Legacy sections to delete after banner adoption:
  - `lib/domain/screens/templates/interpreters/check_in_summary_section_interpreter.dart`
  - `lib/domain/screens/templates/interpreters/issues_summary_section_interpreter.dart`
  - `lib/domain/screens/templates/interpreters/allocation_alerts_section_interpreter.dart`

- Legacy section renderers to delete after banner adoption:
  - `lib/presentation/screens/templates/renderers/check_in_summary_section_renderer.dart`
  - `lib/presentation/screens/templates/renderers/issues_summary_section_renderer.dart`
  - `lib/presentation/screens/templates/renderers/allocation_alerts_section_renderer.dart`
  - And remove their imports/usages from `lib/presentation/widgets/section_widget.dart`

- System screen specs to update:
  - `lib/domain/screens/catalog/system_screens/system_screen_specs.dart`

- Existing attention support widgets (likely replaced/trimmed):
  - `lib/presentation/screens/templates/renderers/attention_support_section_widgets.dart`

- Attention rules settings UI (must stop grouping by legacy `AttentionRuleType`):
  - `lib/presentation/features/attention/view/attention_rules_settings_page.dart`
    - Group/toggle by `bucket` (Action/Review) or by evaluator.

- Focus Setup mismatch (required to resolve)
Today Focus Setup only persists review-session rules, but the UI historically
tried to surface coaching. Under Action/Review, keep Focus Setup scoped to
`bucket=review` rules only.

  - `lib/presentation/features/focus_setup/bloc/focus_setup_bloc.dart`
    - Only load/persist `bucket=review` rules.
  - `lib/presentation/features/focus_setup/view/focus_setup_wizard_page.dart`
    - Remove/avoid rendering coaching/action rules here.

- Overflow destination:
  - Keep screen key `review_inbox`, UI title `Attention`.
  - Implement the list UI on the `review_inbox` template path.

## Migration + cleanup (Tier 2 hard cutover)
Because "assume all user data migrated" was confirmed, prefer a hard cutover.

Note: Supabase migration is already complete, so this phase is responsible for
making sure the Flutter client (Drift + domain + engine + UI) is fully aligned
and no legacy column references remain.

1) Remove legacy schema concepts
- Remove `category`, `rule_type`, `trigger_type`, `trigger_config`,
  `entity_selector` from:
  - drift schema
  - domain model
  - seeders
  - any JSON/DTO mappings

2) Remove legacy code
- Remove any legacy switch/case evaluation logic in engine.
- Remove any leftover UI/filtering that references domain/category.

3) Remove legacy banner modules
- Hard delete legacy modules:
  - specs, params, interpreters, renderers
  - `SectionDataResult` variants
  - `SectionTemplateId` entries

4) Codegen
- Run build runner if required.

5) PowerSync sanity check
- No sync rules change required if the sync rules use `SELECT *`, but verify
  the replicated schema matches the new `attention_rules` columns and that the
  client does not assume dropped columns exist.

## Acceptance criteria
- System screens render using the unified banner with Action/Review grouping.
- Overflow `review_inbox` is a real `Attention` UI and deep-linkable.
- No references remain to legacy columns or legacy banner modules.
- `flutter analyze` is clean at end of phase (fix *any* analyze error/warning in this last phase).
- Run tests once at the end (via the recorded runner task).

## AI instructions
- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- In this **last phase**, fix **any** `flutter analyze` error or warning.
- Run tests **once** at the end using the VS Code task `flutter_test_record`.
