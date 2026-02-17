# Settings And Preferences Spec

## Scope

Defines user-configurable behavior toggles and preference propagation across features.

## Core rules

- Settings changes propagate through domain/presentation contracts, not direct widget access.
- Defaults are explicit and documented.
- Feature toggles that affect support systems map to attention/maintenance behavior consistently.

## Testing minimums

- Default values.
- Persistence + readback.
- Cross-feature effects from changed settings.
