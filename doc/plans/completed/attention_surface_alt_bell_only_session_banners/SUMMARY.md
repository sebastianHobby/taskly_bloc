# Summary — Attention surface ALT (Bell-only + session-dismiss banners)

Implementation date (UTC): 2026-01-16T02:24:35Z

## What shipped

- Removed persistent `attentionBannerV2` summary strips from system unified screens.
- Kept the global bell as the always-on attention indicator (count + severity halo).
- Added calm, on-enter banners for:
  - My Day: critical only
  - Anytime: warning + critical
  - Scheduled: none
- Banner dismiss is app-session scoped (no persistence / no `AttentionResolution` writes).

## Notes

- Analyzer is clean (`flutter analyze`).
- Tests were not run (per repo workflow; run your normal presets when ready).
