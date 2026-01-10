import 'package:flutter/foundation.dart';

/// Params for the Someday null-dates template.
///
/// This template shows all incomplete tasks and projects where both
/// `startDate` and `deadlineDate` are null.
@immutable
class SomedayNullDatesSectionParams {
  const SomedayNullDatesSectionParams();

  factory SomedayNullDatesSectionParams.fromJson() {
    // Intentionally empty for now.
    return const SomedayNullDatesSectionParams();
  }

  Map<String, dynamic> toJson() => const <String, dynamic>{};
}
