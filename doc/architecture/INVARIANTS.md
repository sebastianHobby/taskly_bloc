# Architecture Invariants (Normative)

> Audience: developers + architects
>
> Scope: the non-negotiable rules we follow to keep Taskly clean, robust, and
> maintainable.
>
> These are **invariants** (rules), not feature requirements.

This is the **single source of truth** for normative architecture and testing
rules in this repo.

All other documents under `doc/architecture/` are **descriptive guides** and
must not introduce new "must/shall" rules.

## 0) How to use this document

- When adding new code, keep changes compliant with these invariants.
- When refactoring existing areas, move them toward these invariants.
- If an invariant blocks progress, treat it as an explicit decision: document
  why, scope the exception narrowly, and plan removal.

See the descriptive overview for the mental model:
- [ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md)

## 0.1 Vocabulary and boundary ownership (strict)

Taskly's architecture stays maintainable when each layer owns a specific kind
of logic.

Normative definitions:

- **Business semantics**: rules that define product meaning and must remain
  consistent across screens (for example recurrence targeting semantics,
  canonical filtering/sorting rules, validation, write orchestration).
- **Presentation policy**: how the app *feels* and renders state on a specific
  screen (loading/retry UX, debouncing, pagination mechanics, sectioning,
  optimistic UI flags, mapping domain entities into widget-ready models).
- **Pure UI**: render-only widgets and small UI helpers (data in / events out).

Ownership table:

| Concern | Lives in | Notes |
|---|---|---|
| Business semantics | Domain | Must not depend on Flutter UI or persistence frameworks. |
| Writes (user intents -> mutations) | Domain (use-cases / write facades) | Presentation interprets the user intent and passes `OperationContext`. |
| Reactive composition for a screen | Presentation (BLoC + optional query services) | Domain provides facts/streams; presentation decides combination + screen state machine. |
| Formatting/localization/accessibility strings | Presentation / UI | Domain must not produce localized strings or UI copy. |
| Widgets, styling, reusable entities/sections | `packages/taskly_ui` | Pure UI only; no BLoCs, DI, repositories, or routing. |

### 0.1.1 Domain outputs must be view-neutral (strict)

Domain APIs must not expose screen-specific models or UI-ready DTOs.

Normative rules:

- Domain must not return models named after screens/routes (for example
  `AnytimeScreenModel`, `MyDayViewModel`, `TaskTileModel`).
- Domain must not return localized strings, UI copy, or accessibility labels.
- Domain may expose view-neutral facts (booleans/flags), identifiers, domain
  entities, and pure functions/selectors that are stable across screens.

Rationale:

- Keeps Domain reusable and stable.
- Keeps UX iteration cheap (screen model changes remain in presentation).

## 0.2 Layer index (where the rules fit)

This section is a navigation aid. The normative text lives in the linked
sections.

### 0.2.1 Presentation layer (widgets/screens/BLoCs)

- Presentation must not depend on Data: [1.1](#11-dependency-direction-strict)
- Presentation boundary (BLoC-only): [2](#2-presentation-boundary-bloc-only)
- Reactive subscription lifecycle rules: [3.1](#31-reactive-subscription-lifecycle-strict)

### 0.2.2 Domain layer (business semantics/use-cases/contracts)

- Dependency direction + domain purity: [1.1](#11-dependency-direction-strict),
  [1.4](#14-domain-purity-strict-pragmatic)
- Domain outputs are view-neutral: [0.1.1](#011-domain-outputs-must-be-view-neutral-strict)
- Recurrence occurrence targeting is a domain concern: [4.3](#43-recurrence-command-boundary-strict)
- Occurrence-aware read orchestration is a domain concern: [4.4](#44-recurrence-read-boundary-strict)

### 0.2.3 Data + sync layer (repositories/persistence/sync)

- Package API boundaries (no `src/` deep imports): [1.3](#13-package-public-api-boundary-strict)
- PowerSync/SQLite view write constraints show up in feature contracts (see
  recurrence contract and sync deep-dive):
  - [specs/RECURRENCE_SYNC_CONTRACT.md](specs/RECURRENCE_SYNC_CONTRACT.md)
  - [deep_dives/POWERSYNC_SUPABASE.md](deep_dives/POWERSYNC_SUPABASE.md)

### 0.2.4 Testing (repo-wide)

- Test invariants and directory/tag contract: [3.3](#33-testing-invariants-repo-wide-strict)

## 1) Layering and dependency direction

### 1.1 Dependency direction (strict)

- **Presentation may depend on Domain.**
- **Data may depend on Domain** (to implement repository contracts and shared
  domain policies).
- **Domain must not depend on Presentation or Data.**
- **Presentation must not depend on Data.**

Put differently:

- allowed: `presentation -> domain`, `data -> domain`
- forbidden: `domain -> data`, `domain -> presentation`, `presentation -> data`,
  `data -> presentation`

Rationale:

- Domain stays pure and stable while implementation details evolve.
- Data implements Domain-owned contracts.

Guardrail:

- Central runner: [tool/guardrails.dart](../../tool/guardrails.dart)
- Layering check: [tool/no_layering_violations.dart](../../tool/no_layering_violations.dart)
  - Escape hatch (use sparingly): `// ignore-layering-guardrail`

Note: the current layering guardrail enforces `presentation -> data` and
`domain/data -> presentation`. The `domain -> data` rule is still normative even
when it is not yet mechanically enforced.

### 1.2 `shared/` and `core/` placement

- `shared/` is for broadly reusable building blocks that are not screen/UI
  specific.
- `shared/` must not depend on `presentation/`.
- `core/` is for cross-cutting infrastructure (DI wiring, platform integration,
  logging, etc.).

### 1.3 Package public API boundary (strict)

Dart package convention is a visibility boundary:

- `lib/` is public API.
- `lib/src/` is implementation detail.

Normative rules:

- Code outside a package must not import or export `package:<pkg>/src/...`.
- Each package must expose a clean public surface via `lib/` entrypoints
  (typically a barrel like `package:<pkg>/<pkg>.dart` or feature barrels).
- If another package needs something that currently lives under `lib/src/`, do
  not deep-import it.
  - Prefer promoting the symbol into the package's public API (`lib/`), or
  introducing an explicit shared abstraction in an appropriate shared package.
  - If a narrow exception is unavoidable, document it and keep it temporary.

Guardrail:

- Script: [tool/no_local_package_src_deep_imports.dart](../../tool/no_local_package_src_deep_imports.dart)
  - Fails on `import`/`export` of `package:<local>/src/...` from outside that
    local package.

### 1.3.1 Repository contract ownership (strict)

All repository contracts live in Domain. The Data layer implements those
contracts but must not introduce new domain-like contracts.

Normative rules:

- Define repository interfaces in Domain packages.
- Data implements Domain-owned interfaces; it does not define new public
  repository interfaces.
- If Data needs a new abstraction, it must be introduced in Domain first.

Rationale:

- Prevents "shadow contracts" that fork business semantics.
- Keeps dependencies flowing in one direction (presentation -> domain, data -> domain).

### 1.4 Domain purity (strict, pragmatic)

Domain code must remain *platform-agnostic* and UI-agnostic.

Normative rules:

- Domain must not import Flutter UI framework libraries:
  - forbidden: `package:flutter/material.dart`, `package:flutter/widgets.dart`,
    `dart:ui`, any plugin packages (`package:shared_preferences/...`, etc.)
- Domain must not depend on database, network, or serialization frameworks:
  - forbidden: Drift table/query APIs, Supabase clients, PostgREST payload
    models, JSON codecs that are tied to persistence (those belong in Data)
- Domain must not define or return presentation-layer models or UI strings.
  - forbidden: screen view models, tile/section models, localized text, UI copy,
    accessibility labels, or formatting helpers that embed presentation policy
    (those belong in Presentation or `taskly_ui`).
- Domain may depend on:
  - Dart SDK libraries (e.g., `dart:core`, `dart:async`, `dart:math`)
  - pure-Dart utility packages (e.g., `package:meta`, `package:collection`)
  - other domain packages within this repo (e.g., `taskly_domain` public API)

Pragmatic exception policy:

- If a domain file must import a Flutter SDK library for a narrowly-scoped
  reason, it must be limited to **`package:flutter/foundation.dart` only**
  (no widgets/rendering)

Rationale:

- Keeps Domain testable and reusable.
- Prevents `BuildContext` and widget lifecycle from leaking into business rules.

### 1.5 Dependency injection boundary (strict)

- Do not use service locators (for example `getIt`) in widgets or BLoCs.
- Service locator usage is allowed only in composition roots:
  - DI setup (for example `lib/core/di/...`)
  - app bootstrap
  - route/screen wiring

Everything else must use constructor injection.

### 1.6 Dependency injection in tests (strict)

Tests may construct and inject doubles in composition roots only (test setups,
DI builders, or test harnesses). Widgets and BLoCs must still receive
dependencies via constructors; they must not resolve dependencies themselves.

Normative rules:

- Widgets/BLoCs must not use service locators in tests.
- Test-only service locators are allowed only in test composition roots.
- When a test needs a fake/replacement, inject it through the same constructor
  path used in production.

Rationale:

- Keeps DI behavior consistent between tests and app runtime.
- Prevents "test-only wiring" from leaking into UI or BLoC code.

## 2) Presentation boundary (BLoC-only)

- Widgets/pages must not call repositories/services directly.
- Widgets/pages must not subscribe to domain/data streams directly.
- BLoCs own subscriptions and expose widget-ready state.

Allowed exceptions (narrow): ephemeral UI-only state (controllers, focus nodes,
animations, scroll controllers) that does not represent domain/data state.

### 2.0 Guardrail escape hatch policy (strict)

If you use an `ignore-*-guardrail` escape hatch, it must reference a tracked
exception document under:

- [doc/architecture/exceptions/](exceptions/)

Required format (example):

- `// ignore-layering-guardrail (see doc/architecture/exceptions/EXC-YYYYMMDD-short-title.md; owner=<name>; expires=YYYY-MM-DD)`

### 2.0.1 Presentation query services for repeatable screen logic (recommended)

Repeatable, screen-shaped reactive composition may live in small
presentation-layer helpers (for example `*QueryService`, `*ScreenModelBuilder`).

Normative rules:

- These helpers live in the presentation layer (typically under
  `lib/presentation/...`).
- They may depend on Domain and repository contracts.
- They must not import Flutter widget libraries.
- They must not perform writes or app routing.
- They should prefer producing **one derived stream** per screen that is bound
  in the BLoC with `emit.forEach` / `emit.onEach`.

Rationale:

- Keeps BLoCs thin without pushing screen concerns into Domain.
- Encourages deterministic, cancellation-safe subscription patterns.

### 2.0.2 Session stream cache boundary (strict)

Shared, session-hot data streams (values list, inbox counts, incomplete project
lists, etc.) are owned by **presentation-level session services** and must not
be fetched directly by widgets or ad-hoc screen code.

Normative rules:

- Session-scoped shared streams must be created via the **session stream cache
  manager** (presentation layer).
- Widgets must not use `StreamBuilder` with repository streams.
- BLoCs should prefer consuming session-shared streams via a presentation
  service (e.g., `SessionSharedDataService`) when the data is cross-screen.
- Session streams should pause on background unless explicitly exempted.

Rationale:

- Prevents duplicated subscriptions and inconsistent caching.
- Keeps lifecycle/pause behavior consistent across screens.

### 2.1 UI invariants (strict)

Taskly UI must be consistent, theme-driven, and reusable across screens.

Normative rules:

- **Tokens are SSOT** for spacing, radii, elevation, motion, and tap-target
  sizing. Avoid hard-coded layout constants in shared UI; if a token does not
  exist, a small component-local constant is allowed but must be promoted to a
  token once reused or reviewed.
- **Typography is SSOT** via `ThemeData.textTheme` (or a thin semantic wrapper
  derived from it). UI must not set ad-hoc `fontSize` or `letterSpacing` in
  widgets.
- **Colors are theme-driven**: use `ThemeData.colorScheme` and `TasklyTokens`
  semantic colors only. Do not hardcode colors in widgets.
- **Tap targets** must be >= 40dp. `MaterialTapTargetSize.shrinkWrap` is not
  allowed in shared UI.
- **Entity rows are canonical**: Task/Project/Value/Routine rows must render
  through the feed schema + renderer with styles/presets. Screen-local entity
  widgets are not allowed.
- **4-tier ownership**: primitives/entities/sections live in `taskly_ui`;
  screens/templates live in app presentation. App screens may only compose
  shared UI, not define new primitives/entities/sections.
- **Pure UI boundary**: `taskly_ui` is render-only (no BLoC/DI/services,
  routing, or analytics). Data in / events out only.
- **Public API hygiene**: no deep imports from `package:taskly_ui/src/...`.
- **Catalog visibility**: all entity row styles/presets appear in
  `TasklyTileCatalog`.
- **Text scaling**: UI must respect system text scaling (no forced scaling).

### 2.1.1 Form UI boundary (strict)

- Form logic (state/validation/submit) lives in presentation.
- Form UI wrappers may live in `taskly_ui` as thin adapters only.
- Domain validators are pure functions; UI maps errors to localized strings.

### 2.1.2 Input commit boundary (strict)

Widgets own draft UI state; writes are committed explicitly or debounced.

Normative rules:

- Widgets may own draft UI state (FormBuilder state, controllers, slider
  positions, temporary selections).
- Widgets must **not** trigger repository/service writes on every
  `onChanged`/tick.
- Writes must occur only on:
  - explicit commit events (Save / Next / Done / Submit / Complete), or
  - a debounced idle window (e.g., 300–500ms) for text inputs.
- BLoC write events must represent explicit user intent and should be
  serialized (see reactive lifecycle rules).

Rationale:

- Prevents write storms and race conditions on PowerSync-backed tables.
- Keeps intent boundaries explicit and UX predictable.

### 2.1.3 Input event shaping (strict)

High-frequency UI inputs must be shaped before becoming writes.

Normative rules:

- Text inputs: debounce before commit or commit on explicit submit.
- Sliders: commit on `onChangeEnd` or explicit CTA.
- Rapid toggles: use `droppable()` or `sequential()` for commit events.

Allowed:

- Frequent draft updates in widget/BLoC state.

Forbidden:

- Writes per keystroke or per slider tick.

### 2.2 `taskly_ui` shared surface governance (strict)

Changes to `packages/taskly_ui` are governed by shared-surface rules.

See also: [guides/TASKLY_UI_GOVERNANCE.md](guides/TASKLY_UI_GOVERNANCE.md)

Definitions:

- **Shared surface change**: any change that modifies what a consuming screen
  can import/call/configure, or any change that alters default visuals,
  interaction behavior, accessibility semantics, or user-visible strings.
- **Internal-only change**: refactors/bugfixes/performance work that do not
  change the public API, default visuals, or interaction contracts.

#### Shared UI change notification (strict)

If a change to `taskly_ui` impacts other screens, the user must be informed of
the impacts before implementation.

Minimum expectation:

- Impact analysis: list affected call sites and any required wiring or
  migration steps.

#### Fast path allowed (no approval required)

The following may proceed without explicit user approval:

- Internal refactors that do not change the public surface.
- Bugfixes that restore intended behavior without changing defaults.
- Performance improvements with no user-visible behavior changes.

#### Configuration hygiene (required)

When changing or refactoring `taskly_ui` entities/sections:

- Remove unused options, dead plumbing, and unused callback wiring.
- Avoid "option creep": do not add new configuration flags to cover one-off
  screen needs; prefer creating a new, well-named variant model when required.

## 2.6 Routing and side-effects boundary (strict)

User-visible side-effects (navigation, dialogs, snackbars, toasts) must be
triggered from the presentation layer, not Domain/Data, and must be mediated
by BLoC state/effects rather than direct widget or service calls.

Normative rules:

- Domain/Data must never call routing or show UI side-effects.
- Widgets should not perform routing or snackbars directly in response to
  repository/domain streams.
- BLoCs may emit state/effects that the screen interprets into navigation or
  transient UI (snackbars, dialogs).
- Shared UI (`taskly_ui`) must remain side-effect free.

Rationale:

- Centralizes side-effects so lifecycle and retry logic are predictable.
- Keeps UI logic consistent and testable at the screen boundary.

## 3) State management standard

- Application state is **BLoC-only**.
- Do not introduce new Cubits for domain/app state.
- Keep navigation/snackbar/dialog side-effects driven by presentation patterns
  that do not leak domain/data dependencies.

### 3.1 Reactive subscription lifecycle (strict)

Reactive streams used to derive UI state must be bound to BLoC event-handler
lifecycle.

Normative rules:

- Do not call `emit(...)` from any asynchronous callback that may outlive the
  current event handler.
  - Examples: stream `.listen(...)` callbacks, `future.then(...)`, timers.
- For stream-backed screens, bind streams using `await emit.forEach(...)` or
  `await emit.onEach(...)`.
- If an upstream stream is consumed by multiple downstream subscriptions, it
  must be broadcast/shared (for example via RxDart `share`/`shareReplay`) so it
  is safe to listen to more than once.
- After any `await` point, do not emit unless the handler is still active.
  - Check `if (emit.isDone) return;` before emitting.

Rationale:

- Prevents "emit was called after an event handler completed normally" crashes.
- Makes cancellation/retry deterministic.

### 3.1.1 Stream fan-out and contract rules (strict)

These rules exist to prevent multi-listen runtime crashes and subtle lifecycle
bugs caused by caching or reusing single-subscription streams.

Normative rules:

- **Event bus streams must be broadcast (`*.events`).**
  - Any `*.events` stream exposed by services/coordinators (lifecycle, temporal
    triggers, sync anomalies, etc.) must be broadcast **by construction**
    (typically `StreamController.broadcast()` or an RxDart broadcast primitive).
- **Single-subscription streams must be per-call.**
  - If an API returns a single-subscription stream, it must return a fresh
    stream instance on each call.
  - Do not cache a single-subscription stream instance and return it to
    multiple consumers.
- **No caching of raw streams unless shared.**
  - If you cache streams (query caches, screen query services, etc.), the
    cached value must be a broadcast/shared stream (or you cache results, not
    the stream).
- **Prefer one subscription per screen at the BLoC boundary.**
  - Prefer a single derived upstream stream driving BLoC state (query-service
    style) to avoid accidental re-listens during `switchMap`/refresh cycles.
  - If a screen uses multiple subscriptions, the implementation must be
    cancellation-safe and deterministic.
- **Explicitly declare stream contracts.**
  - For any public stream, document:
    - whether it is broadcast,
    - whether it replays (none / last / N), and
    - whether it is cold or hot.

### 3.2 Test hang safety for reactive code (strict for new tests)

New tests must avoid patterns that can hang indefinitely when streams and BLoCs
are involved.

Normative rules:

- Prefer safe wrappers instead of raw `test(...)` and `testWidgets(...)`:
  - Widget tests: `testWidgetsSafe` (see [test/helpers/test_helpers.dart](../../test/helpers/test_helpers.dart))
  - Unit tests: `testSafe` (see [test/helpers/test_helpers.dart](../../test/helpers/test_helpers.dart))
  - Bloc tests: `blocTestSafe` (see [test/helpers/bloc_test_patterns.dart](../../test/helpers/bloc_test_patterns.dart))
- Avoid raw `StreamController` in tests for BLoC inputs/outputs when late
  subscriptions are possible.
  - Prefer `TestStreamController` (see [test/helpers/bloc_test_patterns.dart](../../test/helpers/bloc_test_patterns.dart))

Guardrails:

- Script (repo-wide): [tool/no_raw_test_wrappers.dart](../../tool/no_raw_test_wrappers.dart)
- Pre-push (staged-file focused): implemented in [git_hooks.dart](../../git_hooks.dart)

### 3.3 Testing invariants (repo-wide) (strict)

These invariants are in addition to any layer-specific rules above (for
example, presentation boundary rules also apply in widget tests).

#### TG-001-A -- Hermetic-by-default for unit/widget tests

Tests tagged `unit` or `widget` must be hermetic. They must not:

- require network access
- touch a real Supabase/PowerSync stack
- require non-temp filesystem state
- depend on wall-clock time (`DateTime.now()`)

If the behavior requires real persistence/network, it must be tested under an
explicit tag such as `integration`, `repository`, or `pipeline`.

#### TG-002-A -- Mandatory safe wrappers for new tests

New tests must use the repo's safe wrappers instead of raw `test()` /
`testWidgets()` / `blocTest()`.

#### TG-003-A -- No leaked resources after a test

Every resource created in a test must be cleaned up deterministically.

Examples (non-exhaustive):

- stream controllers / stream subscriptions
- timers
- BLoCs
- database handles

Cleanup must be registered immediately using `addTearDown(...)` (or test helper
APIs built on top of it).

#### TG-004-A -- Presentation boundary holds in tests

Widget tests must not call repositories/services directly and must not
subscribe to domain/data streams from widget code.

In widget tests, repositories are mocked/faked behind the BLoC and the widget
renders BLoC state.

#### TG-005-A -- Tagging is directory-driven and enforceable

Test type is determined by directory and must align with tags and presets.

If a test does not fit the directory contract, move it or change its tag.

#### TG-006-A -- OperationContext propagation is verified for write flows

Any test that validates a user-initiated write path must assert:

- the `OperationContext` is created at the presentation boundary (typically the
  BLoC handler interpreting user intent), and
- the same context (correlation id) is passed through domain/data write APIs.

#### TG-007-A -- No `src/` deep imports in tests across packages

Tests outside a package must not import `package:<local_package>/src/...`.

Tests may import only public APIs (`package:<pkg>/<pkg>.dart` or other `lib/`
entrypoints).

#### TG-008-A -- Flakiness policy: quarantine over retries

Flaky tests must be quarantined and kept out of default presets.

- Use an explicit tag (`flaky`) and exclude it from `fast/quick`.
- Do not enable global retries by default to mask nondeterminism.

#### TG-009-A -- Performance budgets are manually enforced per preset

Tests that meaningfully slow the developer loop must be tagged `slow` and
excluded from the fast presets.

Use timing artifacts (for example `test/last_run.json`) to identify regressions.

#### TG-010-A -- Coverage alignment with testing standards

Coverage must stay aligned with the repo’s testing standards and should trend
upward in touched areas.

Normative rules:

- New or changed behavior must add tests at the appropriate layer
  (unit/widget for pure logic and UI wiring, repository/integration for
  persistence and multi-component flows, pipeline for sync stack behavior).
- Filtered coverage must not regress for packages touched by the change.
- If a package is materially below its coverage goals, changes touching that
  package must include tests that increase coverage or an explicit exception.
  Exceptions must follow the documented exception process.

Operational guidance (non-normative):

- Use `tool/coverage_filter.dart` and `tool/coverage_summary.dart` to track
  per-package coverage.

### 3.4 Testing taxonomy (directory contract) (strict)

| Directory | Primary tags | IO policy | Typical scope |
| --- | --- | --- | --- |
| `test/core/**` | `unit` | hermetic | cross-cutting pure logic |
| `test/domain/**` | `unit` | hermetic | domain rules, reducers, mapping |
| `test/presentation/**` | `widget` (or `unit` for pure BLoC/state) | hermetic | widget composition + BLoC wiring |
| `test/data/**` | `repository` / `integration` | local DB only | repository behavior against real DB |
| `test/integration/**` | `integration` | local DB only | multi-component flows without network |
| `test/integration_test/**` | `pipeline` | local stack only | local Supabase/PowerSync pipeline |
| `test/contracts/**` | `unit` | hermetic | shared expectations across impls |
| `test/diagnosis/**` | `diagnosis` (optional) | varies | repros/investigations (not default) |

## 4) Write boundary and atomicity

### 4.1 Single write boundary per feature

- All domain writes must go through a small set of explicit **use-cases** (or an
  equivalent feature write facade) rather than ad-hoc writes from screens.

### 4.1.1 Nullable identifiers are canonicalized (strict)

Some domain relationships are optional (for example: a task may have no
project).

Normative rules:

- The canonical persisted representation for "no related entity" is **SQL
  `NULL`**.
- Do not store sentinel values such as empty strings (`''`) or whitespace for
  optional IDs.
- All write boundaries (domain commands/use-cases and data repositories) must
  defensively **normalize** optional IDs so that `''`/whitespace becomes
  `null`.

Rationale:

- Query semantics depend on correct nullability (for example, Inbox-style
  queries often use `IS NULL`).
- UI normalization is not sufficient: other write paths (import, migrations,
  background jobs, future features) must not be able to introduce non-null
  sentinels that silently break filters.

### 4.3 Recurrence command boundary (strict)

Recurring entities (tasks/projects with RRULEs) have *virtual occurrences*.
Selecting which occurrence a user intent should target is a **domain concern**.

Normative rules:

- Presentation must not "guess" recurrence occurrence keys (dates) when
  performing a write.
  - If a screen already has explicit occurrence data (for example, Scheduled
    agenda rows), it may pass those occurrence keys through.
  - If a screen does **not** have occurrence keys (for example, Anytime feeds
    that list base entities), it must call a domain command service that
    resolves the target occurrence before writing.
- Default completion semantics for recurring entities are:
  - **Complete** = complete the **next uncompleted** occurrence relative to the
    current home day key.
  - **Complete series** = an explicit separate action that ends the series.
- All recurrence writes must still flow through the existing recurrence write
  surface (repositories/write-helper) so the storage + sync contract is
  enforced in one place.

Rationale:

- Keeps product semantics consistent across screens.
- Prevents subtle bugs from duplicating occurrence-selection logic in UI.
- Preserves the offline-first recurrence storage contract.

### 4.4 Recurrence read boundary (strict)

Recurring entities (tasks/projects with RRULEs) have *virtual occurrences*.
Any read that depends on occurrence-aware semantics (previewing or expanding
occurrences, or filtering by occurrence dates) is a **domain concern**.

Normative rules:

- Occurrence-aware read orchestration must live in `taskly_domain`.
  - Use `OccurrenceReadService` for:
    - "Anytime-style" next-occurrence preview decoration.
    - "Scheduled-style" window expansion with two-phase filtering.
- Callers (presentation, analytics, other services) must not set
  `occurrenceExpansion` / `occurrencePreview` on `TaskQuery`/`ProjectQuery`.
  Those flags are legacy and are not an approved integration surface.
- Data repository implementations must not interpret query-level occurrence
  flags.
  - If occurrence flags are present, repositories should fail fast (so we do
    not silently fork semantics across layers).
- Scheduled/range reads that filter by date must apply the date semantics
  against occurrence-aware dates via Domain's two-phase approach:
  - SQL candidate set (date predicates removed)
  - post-expansion filter evaluation on occurrence dates

Rationale:

- Keeps recurrence semantics stable across screens and non-UI callers.
- Prevents subtle mismatches where SQL date predicates disagree with occurrence
  dates after RRULE expansion.
- Enforces the layering rule: Data provides persistence; Domain owns product
  semantics.

### 4.2 Transactionality

- If a write touches multiple tables, it must be **atomic** using a database
  transaction.
- Never rely on "eventual consistency inside the local DB" for a single user
  action.

## 5) Offline-first + PowerSync constraints

### 5.1 Local source of truth

- Local SQLite (PowerSync-backed) is the primary source of truth for UI.

### 5.2 SQLite views: no local UPSERT against PowerSync tables

PowerSync applies schema using SQLite views. SQLite cannot UPSERT views.

- Do not use Drift UPSERT helpers against tables that are part of the PowerSync
  schema.
- Prefer update-then-insert or insert-or-ignore patterns.

See: [deep_dives/POWERSYNC_SUPABASE.md](deep_dives/POWERSYNC_SUPABASE.md)

Guardrail: the repo includes a lightweight check to prevent accidental usage.

- Script: [tool/no_powersync_local_upserts.dart](../../tool/no_powersync_local_upserts.dart)
  - Scans `packages/taskly_data/lib/` for common Drift UPSERT patterns
    (`insertOnConflictUpdate`, `insertAllOnConflictUpdate`,
    `insertOrReplace`, `InsertMode.insertOrReplace`).
  - Escape hatch (use sparingly): add `// ignore-powersync-upsert-guardrail` in
    a file to skip it.
- CI: enforced in GitHub Actions analyze job:
  - [.github/workflows/main.yaml](../../.github/workflows/main.yaml)
    (step: "Run repo guardrails")

### 5.3 PowerSync schema tables must be registered for ID generation (strict)

When PowerSync-backed tables are created/changed, ensure ID generation and
deterministic write behavior stays consistent.

Normative rules:

- All tables declared in the PowerSync schema must be registered in the ID
  generator configuration.
- When adding a new PowerSync table, update the schema and the ID generator in
  the same change.

Guardrail:

- Pre-push validation: implemented in [git_hooks.dart](../../git_hooks.dart)
  (compares `packages/taskly_data/lib/src/infrastructure/powersync/schema.dart`
  against `packages/taskly_data/lib/src/id/id_generator.dart`)

### 5.4 `user_id` is server-owned (strict)

- `user_id` is derived from the authenticated Supabase JWT on the server.
- App writes must **not** set or override `user_id` in local insert/update
  payloads.
- The client treats `user_id` as read-only data that may appear after sync.

## 6) Sync conflicts/anomalies policy

Conflicts are treated as correctness bugs, not "merge inputs".

- The system must not silently overwrite on deterministic-ID conflicts.
- **Release behavior**: log a SEVERE/ERROR event with enough context to debug
  (entity type/id, occurrence keys, operation, stack trace).
- **Debug behavior**: after logging, throw an error to fail fast.

This policy is intentionally logging-first (not persisted), per current decision.

## 7) Time model and clocks

- Domain/data must not call `DateTime.now()` directly.
- Presentation must not call `DateTime.now()` directly.
- Time must come from an injected time/clock service.
- Day-key and date-only conversions must be centralized (no ad-hoc conversions
  inside screens).

Guardrail:

- Script: [tool/no_datetime_now_in_domain_data.dart](../../tool/no_datetime_now_in_domain_data.dart)
  - Escape hatch (use sparingly): `// ignore-datetime-now-guardrail`

- Script: [tool/no_datetime_now_in_presentation.dart](../../tool/no_datetime_now_in_presentation.dart)
  - Centralize presentation time access in:
    `lib/presentation/shared/services/time/now_service.dart`
  - Escape hatch (use sparingly): `// ignore-datetime-now-guardrail`

Recurrence + date-only semantics are further specified in:
- [specs/RECURRENCE_SYNC_CONTRACT.md](specs/RECURRENCE_SYNC_CONTRACT.md)

## 8) Error handling across boundaries

- Domain-facing APIs should not leak raw exceptions as a control flow
  mechanism.
- Prefer typed failures (a `Result`/sealed failure model) so BLoCs can render
  deterministic error states.
- Reactive streams used for UI must not permanently terminate the UI due to a
  transient failure; map failures into state and provide explicit retry.

### 8.0 Error mapping contract (strict)

Errors must cross boundaries as typed failures rather than raw exceptions.

Normative rules:

- Domain-facing APIs return typed failures (e.g., Result/Either/AppFailure).
- Data must map low-level exceptions into domain failures before returning.
- Presentation must not depend on raw exception types from Data/Domain.
- Reactive streams used by UI must map failures into state and remain alive
  (no permanent termination on transient errors).

Rationale:

- Prevents flaky UI caused by uncaught exceptions.
- Makes error handling predictable and testable across layers.

### 8.1 OperationContext for write correlation (strict)

All **user-initiated mutations** must be correlated end-to-end with an
`OperationContext`.

Normative rules:

- Presentation creates a **non-null** `OperationContext` **at the boundary of
  the user intent** (typically in the BLoC event handler) for every
  user-initiated mutation and passes it down through domain write APIs into
  repository mutations.
- Any domain/data API that performs a mutation **must accept** an optional
  `OperationContext? context` parameter and **must forward it** when delegating
  to deeper layers.
- Public write surfaces intended for user actions (domain use-cases / feature
  write facades) must treat a missing context as a bug. If a system/internal
  write legitimately has no user intent, it must be explicitly documented as
  such at the call site.
- Data-layer write implementations must include the `OperationContext` fields
  (at minimum `correlationId`, `feature`, `screen`, `intent`, `operation`, and
  entity identifiers when present) in structured logs.
- When mapping errors to user-facing failures (e.g., `AppFailure`), prefer a
  consistent mapping that preserves the `correlationId` so failures and logs can
  be joined.

Rationale:

- Enables correlated structured logging across UI -> domain -> data.
- Makes failure mapping deterministic and debuggable without relying on ad-hoc
  log messages.

Implementation note (non-normative): presentation uses a factory helper to
generate `OperationContext` with a UUID v4 correlation id.

## 9) Documentation invariants

- Documents under `doc/architecture/` describe the **future-state** architecture.
- Historical/archived notes (when present) are **non-normative** and must not
  be treated as required reading for new work.





