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

## Governance

- Shared UI behavior changes require explicit change notes in the PR.
- Shared appearance changes should flow through package-owned entrypoints:
  - `taskly_ui_theme.dart`
  - `taskly_ui_chrome.dart`
  - `taskly_ui_primitives.dart`
  - `taskly_ui_sections.dart`
