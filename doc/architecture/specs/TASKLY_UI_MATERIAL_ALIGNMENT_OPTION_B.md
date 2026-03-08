# Taskly UI Material Alignment Option B

## Purpose

Defines the active UI-system alignment rules for Taskly's private design system
package in `packages/taskly_ui`.

## Core rules

- `packages/taskly_ui` is Taskly-only and owns shared theming and render-only
  UI surfaces.
- Shared UI remains render-only (no BLoC, DI, repos, analytics, or routing).
- Theme tokens and semantic theme extensions in `taskly_ui` are the source of
  truth for shared appearance.
- App surfaces consume shared entities/sections rather than duplicating
  screen-local variants.
- Behavior differences should use style presets rather than ad-hoc component flags.
- First-level and second-level screens should share the same page-surface and
  page-header language unless a feature spec explicitly calls for a distinct
  treatment.
- Shared cards and empty states should use package-owned semantic variants
  rather than raw Material defaults.
- Typography hierarchy should be expressed through theme roles and shared chrome
  primitives, not screen-local font tuning.
- Motion should be shared and theme-driven for page entry, section reveal, and
  sheet transitions rather than ad-hoc per-screen animation constants.

## Governance

- Shared UI behavior changes require explicit change notes in the PR.
- Shared appearance changes should flow through package-owned entrypoints:
  - `taskly_ui_theme.dart`
  - `taskly_ui_chrome.dart`
  - `taskly_ui_primitives.dart`
  - `taskly_ui_sections.dart`
