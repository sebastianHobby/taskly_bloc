# 08 — Infra Updates + New Builders (Use Consistently)

## Objective

Reduce duplication and enforce config-driven test construction by adding a small set of **test-only builders** that match the unified-screen architecture.

This is the only planned infra expansion, and it must integrate with existing safe helpers.

## Proposed new helper module

Create a new file:
- `test/helpers/unified_screen_builders.dart`

### Contents (exact API proposal)

#### A) ScreenDefinition builders

- `ScreenDefinition buildScreen({
    required String screenKey,
    String? id,
    String? name,
    List<SectionRef> sections = const [],
    ScreenChrome chrome = ScreenChrome.empty,
    ScreenSource screenSource = ScreenSource.userDefined,
    DateTime? now,
  })`

Rules:
- default `id` to `screenKey` unless overridden
- default timestamps to a shared fixed time (or `now ?? DateTime(2024)`)

#### B) SectionRef helpers

- `SectionRef sectionRef(
    String templateId, {
    Map<String, dynamic>? params,
    SectionOverrides? overrides,
  })`

Common helpers:
- `SectionRef taskListRef(TaskQuery query, {String? title})`
- `SectionRef projectListRef(ProjectQuery query, {String? title})`
- `SectionRef allocationRef(AllocationSectionParams params, {String? title})`

#### C) ScreenItem helpers

- `ScreenItem taskItem([Task? task])`
- `ScreenItem projectItem([Project? project])`
- `ScreenItem valueItem([Value? value])`

All default to `TestData.task()/project()/value()`.

#### D) SectionDataResult helpers (optional)

- `SectionDataResult dataResult({List<ScreenItem> items = const [], Map<String, List<Object>> related = const {}})`

Keep these minimal; the main goal is reducing boilerplate.

## Update existing fallback registrations

If mocktail fallback registration is currently scattered, consolidate:
- Extend `test/helpers/fallback_values.dart` (if that’s the project convention) to include:
  - `ScreenDefinition`, `SectionRef`, and any params types frequently passed through mocktail `any()`.

## Enforce usage

After builders exist:
- Replace ad-hoc constructors in:
  - `test/fixtures/test_data.dart`
  - navigation tests
  - screen bloc integration tests

Do not create multiple different builder styles.

## Compatibility with safe helpers

- Builders must not introduce long-lived streams.
- For tests that require streams, continue to use:
  - `TestStreamController` (bloc patterns)
  - `testIntegration` context streams (integration helpers)

## Exit criteria

- New helpers exist and are used in at least:
  - one section data result test
  - one navigation-related test
  - screen bloc integration test

- Test construction becomes mostly "1–2 lines" per screen/section setup.
