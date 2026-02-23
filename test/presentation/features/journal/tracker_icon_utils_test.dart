@Tags(['unit', 'journal'])
library;

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/journal/utils/tracker_icon_utils.dart';
import 'package:taskly_domain/journal.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe(
    'trackerIconNameFromConfig trims and handles missing values',
    () async {
      expect(trackerIconNameFromConfig(const <String, dynamic>{}), isNull);
      expect(
        trackerIconNameFromConfig(const <String, dynamic>{
          'iconName': '  bolt ',
        }),
        'bolt',
      );
      expect(
        trackerIconNameFromConfig(const <String, dynamic>{'iconName': '   '}),
        isNull,
      );
    },
  );

  testSafe(
    'default icon name resolves by tracker name and value type',
    () async {
      expect(
        defaultTrackerIconName(
          trackerName: 'Water intake',
          valueType: 'quantity',
        ),
        'water_drop',
      );
      expect(
        defaultTrackerIconName(trackerName: 'Unknown', valueType: 'yes_no'),
        'check',
      );
    },
  );

  testSafe('effectiveTrackerIconName prefers explicit config', () async {
    final definition = TrackerDefinition(
      id: 't-1',
      name: 'Mood',
      scope: 'entry',
      valueType: 'rating',
      config: const <String, dynamic>{'iconName': 'bolt'},
      createdAt: DateTime.utc(2025, 1, 1),
      updatedAt: DateTime.utc(2025, 1, 1),
    );

    expect(effectiveTrackerIconName(definition), 'bolt');
  });

  testSafe(
    'trackerIconData falls back to generic icon for unknown names',
    () async {
      final definition = TrackerDefinition(
        id: 't-1',
        name: 'Custom',
        scope: 'entry',
        valueType: 'rating',
        config: const <String, dynamic>{'iconName': 'missing_icon'},
        createdAt: DateTime.utc(2025, 1, 1),
        updatedAt: DateTime.utc(2025, 1, 1),
      );

      expect(trackerIconData(definition), isNotNull);
    },
  );
}
