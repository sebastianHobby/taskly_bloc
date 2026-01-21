# Completion Summary — Anytime Screen + Remove Projects List Destination

Implementation date (UTC): 2026-01-14T23:28:10.5730906Z

## What shipped

- Removed the Projects list as a top-level destination (legacy `/projects` now redirects to Anytime).
- Created the Anytime system screen (renamed from Someday concept) with:
  - Mixed tasks + projects list
  - Description line: "Your actionable backlog. Use filters to hide 'start later' items."
- Added the "Include future starts" toggle in the section filter bar.
- Added focus cues ("In Focus") in list rendering.
- Updated architecture docs index to include `doc/product/SCREEN_PURPOSE_CONCEPTS.md`.
- `flutter analyze` is clean.

## Known issues / follow-ups

- The project list template (`project_list_v2`) remains in the codebase because it is still referenced; removing it safely would require proving it’s unused everywhere.
- Tests were not run as part of this completion; run `flutter test --preset=quick` if you want a fast validation pass.
