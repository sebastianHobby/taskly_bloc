import 'package:flutter/foundation.dart';

/// Params for the Someday backlog template.
///
/// This template renders "Someday" (future focus/backlog) and is intentionally
/// config-light because filter/sort state is handled as ephemeral UI state.
@immutable
class SomedayBacklogSectionParams {
  const SomedayBacklogSectionParams();

  factory SomedayBacklogSectionParams.fromJson(Map<String, dynamic> json) {
    // Intentionally empty for now.
    return const SomedayBacklogSectionParams();
  }

  Map<String, dynamic> toJson() => const <String, dynamic>{};
}
