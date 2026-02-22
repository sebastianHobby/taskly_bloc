import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_domain/journal.dart';

String? trackerIconNameFromConfig(Map<String, dynamic> config) {
  final raw = config['iconName'];
  if (raw is! String) return null;
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String defaultTrackerIconName({
  required String trackerName,
  required String valueType,
}) {
  final normalized = trackerName.toLowerCase();

  if (normalized.contains('mood')) return 'mood';
  if (normalized.contains('stress')) return 'health';
  if (normalized.contains('sleep')) return 'bedtime';
  if (normalized.contains('exercise')) return 'fitness_center';
  if (normalized.contains('water')) return 'water_drop';
  if (normalized.contains('social')) return 'group';
  if (normalized.contains('energy')) return 'bolt';
  if (normalized.contains('running')) return 'directions_run';
  if (normalized.contains('guitar')) return 'music_note';
  if (normalized.contains('reading')) return 'menu_book';
  if (normalized.contains('cooking')) return 'restaurant';
  if (normalized.contains('gaming')) return 'sports_esports';

  return switch (valueType.toLowerCase()) {
    'yes_no' => 'check',
    'choice' => 'list',
    'quantity' => 'bar_chart',
    'rating' => 'mood',
    _ => 'trackers',
  };
}

String effectiveTrackerIconName(TrackerDefinition definition) {
  return trackerIconNameFromConfig(definition.config) ??
      defaultTrackerIconName(
        trackerName: definition.name,
        valueType: definition.valueType,
      );
}

IconData trackerIconData(TrackerDefinition definition) {
  final iconName = effectiveTrackerIconName(definition);
  return getIconDataFromName(iconName) ?? Icons.track_changes_outlined;
}
