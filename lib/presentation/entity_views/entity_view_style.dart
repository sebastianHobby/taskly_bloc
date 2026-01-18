/// Shared style enums for entity-level views.
///
/// These replace USM-specific style types and keep view configuration local
/// to the presentation layer.
library;

enum AgendaMetaDensity {
  /// Show the full meta line (legacy behavior).
  full,

  /// Show a calmer, minimal meta line.
  minimal,

  /// Show minimal meta by default, with an affordance to expand.
  minimalExpandable,
}

/// How to encode entity priority in the UI.

enum AgendaPriorityEncoding {
  /// Show an explicit P# pill in the meta line.
  explicitPill,

  /// Show a subtle dot glyph near the title.
  subtleDot,

  /// Encode priority via slightly stronger title typography.
  subtleTitleWeight,

  /// Do not show priority in the default row presentation.
  none,
}

/// Controls how row actions are surfaced on agenda tiles.

enum AgendaActionsVisibility {
  /// Always show the overflow menu button.
  always,

  /// Only show actions on hover/focus (desktop), while remaining visible on touch.
  hoverOrFocus,
}
