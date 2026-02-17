# Auth, Onboarding, And Session Spec

## Scope

Defines auth states, onboarding progression, startup synchronization gates, and app shell entry behavior.

## Core rules

- Session state transitions are explicit and testable.
- Startup gating must not bypass required sync/ready checks.
- Navigation transitions are deterministic from state.

## Testing minimums

- Startup gate state machine.
- Auth-to-app and onboarding-to-app transitions.
- Recovery behavior for failed initial sync.
