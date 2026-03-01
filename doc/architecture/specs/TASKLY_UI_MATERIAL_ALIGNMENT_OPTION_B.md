# Taskly UI Material Alignment Option B

## Purpose

Defines the active UI-system alignment rules for shared UI in `packages/taskly_ui`.

## Core rules

- Shared UI remains pure UI (no BLoC, DI, repos, or routing).
- Theme tokens are source of truth for spacing, radius, typography, and colors.
- App surfaces consume shared entities/sections rather than duplicating screen-local variants.
- Behavior differences should use style presets rather than ad-hoc component flags.

## Governance

- Shared UI behavior changes require explicit change notes in the PR.
