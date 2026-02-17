# Navigation + Screen Keys -- Guide

> Audience: developers
>
> Scope: navigation conventions, screen keys, and where routing is defined.
> Descriptive only; invariants live in [../INVARIANTS.md](../INVARIANTS.md).

## 1) Why this exists

Taskly uses **screen keys** as stable identifiers for system screens while
routes use readable paths. This guide keeps route construction, navigation
destinations, and screen-key persistence in one place.

Related guide:
- [SCREEN_ARCHITECTURE.md](SCREEN_ARCHITECTURE.md)

## 2) Key concepts

- **Screen key**: stable identifier like `my_day` or `projects`.
- **Route path**: user-facing path like `/my-day` or `/projects`.

Route rules are defined centrally (see `Routing` below).

## 3) Where things live

Routing conventions and path building:
- `lib/presentation/routing/routing.dart`
- `lib/presentation/routing/router.dart`

Navigation shell + destinations:
- `lib/presentation/app_shell/scaffold_with_nested_navigation.dart`
- `lib/presentation/app_shell/navigation_bar_scaffold.dart`
- `lib/presentation/app_shell/navigation_rail_scaffold.dart`
- `lib/presentation/app_shell/more_destinations_sheet.dart`
- `lib/presentation/features/navigation/services/navigation_icon_resolver.dart`

Screen-key persistence + ID generation:
- `packages/taskly_data/lib/src/infrastructure/drift/features/screen_tables.drift.dart`
- `packages/taskly_data/lib/src/id/id_generator.dart`

## 4) Adding a system screen (typical steps)

This is a descriptive checklist; follow existing patterns for your feature:

1) Add the route in `lib/presentation/routing/router.dart`.
2) Ensure the screen key appears in `Routing` conventions
   (`lib/presentation/routing/routing.dart`).
3) Add navigation labels/icons/sort order in the app shell scaffolds if the
   screen should be a destination.
4) Ensure any persisted screen preferences use the correct screen key.

## 5) Notes

- Route segments use hyphens; screen keys use underscores.
- `Routing.screenPath(...)` is the single source of truth for screen paths.
