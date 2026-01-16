import 'package:flutter/foundation.dart';

@immutable
class SystemTrackerChoiceTemplate {
  const SystemTrackerChoiceTemplate({
    required this.choiceKey,
    required this.label,
    required this.sortOrder,
  });

  final String choiceKey;
  final String label;
  final int sortOrder;
}

@immutable
class SystemTrackerTemplate {
  const SystemTrackerTemplate({
    required this.systemKey,
    required this.name,
    required this.scope,
    required this.valueType,
    required this.opKind,
    this.valueKind,
    this.description,
    this.minInt,
    this.maxInt,
    this.stepInt,
    this.isOutcome = false,
    this.defaultSortOrder = 0,
    this.defaultPinned = false,
    this.defaultQuickAdd = false,
    this.choices = const <SystemTrackerChoiceTemplate>[],
  });

  final String systemKey;
  final String name;
  final String scope;
  final String valueType;
  final String opKind;
  final String? valueKind;
  final String? description;
  final int? minInt;
  final int? maxInt;
  final int? stepInt;

  /// Whether this tracker represents a target/outcome variable.
  ///
  /// Example: Mood is an outcome, whereas Exercise is a factor.
  final bool isOutcome;

  final int defaultSortOrder;
  final bool defaultPinned;
  final bool defaultQuickAdd;

  final List<SystemTrackerChoiceTemplate> choices;
}

/// Initial system tracker set for the B1 Journal experience.
///
/// This is intentionally small and safe to seed idempotently.
class SystemTrackers {
  static const mood = SystemTrackerTemplate(
    systemKey: 'mood',
    name: 'Mood',
    description: 'How are you feeling right now?',
    scope: 'entry',
    valueType: 'rating',
    valueKind: 'rating',
    opKind: 'set',
    minInt: 1,
    maxInt: 5,
    stepInt: 1,
    isOutcome: true,
    defaultSortOrder: 0,
    defaultPinned: false,
    defaultQuickAdd: false,
  );

  static const exercise = SystemTrackerTemplate(
    systemKey: 'exercise',
    name: 'Exercise',
    scope: 'entry',
    valueType: 'yes_no',
    valueKind: 'boolean',
    opKind: 'set',
    defaultSortOrder: 10,
    defaultPinned: true,
    defaultQuickAdd: true,
  );

  static const meds = SystemTrackerTemplate(
    systemKey: 'meds',
    name: 'Meds',
    scope: 'entry',
    valueType: 'yes_no',
    valueKind: 'boolean',
    opKind: 'set',
    defaultSortOrder: 20,
    defaultPinned: true,
    defaultQuickAdd: true,
  );

  static const meditation = SystemTrackerTemplate(
    systemKey: 'meditation',
    name: 'Meditation',
    scope: 'entry',
    valueType: 'yes_no',
    valueKind: 'boolean',
    opKind: 'set',
    defaultSortOrder: 30,
    defaultPinned: false,
    defaultQuickAdd: true,
  );

  static const all = <SystemTrackerTemplate>[
    mood,
    exercise,
    meds,
    meditation,
  ];
}
