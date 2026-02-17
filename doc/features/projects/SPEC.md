# Projects Spec

## Scope

Defines project lifecycle, project-detail behavior, project-scoped task/routine creation, and project value context.

## Core rules

- Project detail is the canonical project execution surface.
- Task and routine creation from project detail inherit project context.
- Project lists and detail views remain BLoC-driven.

## Testing minimums

- Project-scoped creation defaults.
- Project filtering/sorting stability.
- Cross-screen consistency of project metadata.
