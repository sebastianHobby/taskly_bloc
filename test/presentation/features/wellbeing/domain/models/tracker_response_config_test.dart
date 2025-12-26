import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/models/tracker_response_config.dart';

void main() {
  group('TrackerResponseConfig', () {
    group('ChoiceConfig', () {
      test('creates choice config with options', () {
        const config = TrackerResponseConfig.choice(
          options: ['Morning', 'Afternoon', 'Evening'],
        );

        expect(config, isA<ChoiceConfig>());
        expect(config.options, equals(['Morning', 'Afternoon', 'Evening']));
        expect(config.options.length, equals(3));
      });

      test('creates choice config with single option', () {
        const config = TrackerResponseConfig.choice(options: ['Only Option']);

        expect(config.options.length, equals(1));
      });

      test('creates choice config with empty options list', () {
        const config = TrackerResponseConfig.choice(options: []);

        expect(config.options, isEmpty);
      });

      test('two choice configs with same options are equal', () {
        const config1 = TrackerResponseConfig.choice(options: ['A', 'B']);
        const config2 = TrackerResponseConfig.choice(options: ['A', 'B']);

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('preserves option order', () {
        const config = TrackerResponseConfig.choice(
          options: ['First', 'Second', 'Third'],
        );

        expect(config.options[0], equals('First'));
        expect(config.options[1], equals('Second'));
        expect(config.options[2], equals('Third'));
      });
    });

    group('ScaleConfig', () {
      test('creates scale config with defaults', () {
        const config = TrackerResponseConfig.scale();

        expect(config, isA<ScaleConfig>());
        expect(config.min, equals(1));
        expect(config.max, equals(5));
        expect(config.minLabel, isNull);
        expect(config.maxLabel, isNull);
      });

      test('creates scale config with custom min and max', () {
        const config = TrackerResponseConfig.scale(min: 0, max: 10);

        expect(config.min, equals(0));
        expect(config.max, equals(10));
      });

      test('creates scale config with labels', () {
        const config = TrackerResponseConfig.scale(
          max: 10,
          minLabel: 'Not at all',
          maxLabel: 'Extremely',
        );

        expect(config.minLabel, equals('Not at all'));
        expect(config.maxLabel, equals('Extremely'));
      });

      test('allows negative min value', () {
        const config = TrackerResponseConfig.scale(min: -5);

        expect(config.min, equals(-5));
      });

      test('two scale configs with same values are equal', () {
        const config1 = TrackerResponseConfig.scale(max: 10);
        const config2 = TrackerResponseConfig.scale(max: 10);

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('configs with different labels are not equal', () {
        const config1 = TrackerResponseConfig.scale(
          minLabel: 'Low',
          maxLabel: 'High',
        );
        const config2 = TrackerResponseConfig.scale(
          minLabel: 'Bad',
          maxLabel: 'Good',
        );

        expect(config1, isNot(equals(config2)));
      });
    });

    group('YesNoConfig', () {
      test('creates yesNo config', () {
        const config = TrackerResponseConfig.yesNo();

        expect(config, isA<YesNoConfig>());
      });

      test('two yesNo configs are equal', () {
        const config1 = TrackerResponseConfig.yesNo();
        const config2 = TrackerResponseConfig.yesNo();

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('is const constructible', () {
        const config1 = TrackerResponseConfig.yesNo();
        const config2 = TrackerResponseConfig.yesNo();

        expect(identical(config1, config2), isTrue);
      });
    });

    group('type discrimination', () {
      test('distinguishes between different config types', () {
        const choice = TrackerResponseConfig.choice(options: ['A', 'B']);
        const scale = TrackerResponseConfig.scale();
        const yesNo = TrackerResponseConfig.yesNo();

        expect(choice, isNot(equals(scale)));
        expect(choice, isNot(equals(yesNo)));
        expect(scale, isNot(equals(yesNo)));
      });

      test('supports pattern matching with when clause', () {
        const config = TrackerResponseConfig.scale(max: 10);

        final result = switch (config) {
          ChoiceConfig(:final options) => 'Choice with ${options.length}',
          ScaleConfig(:final min, :final max) => 'Scale from $min to $max',
          YesNoConfig() => 'YesNo',
        };

        expect(result, equals('Scale from 1 to 10'));
      });
    });

    group('JSON serialization', () {
      test('choice config serializes correctly', () {
        const config = TrackerResponseConfig.choice(
          options: ['A', 'B', 'C'],
        );

        final json = config.toJson();

        expect(json, containsKey('options'));
        expect(json['options'], equals(['A', 'B', 'C']));
      });

      test('scale config serializes correctly', () {
        const config = TrackerResponseConfig.scale(
          min: 0,
          max: 10,
          minLabel: 'None',
          maxLabel: 'Max',
        );

        final json = config.toJson();

        expect(json['min'], equals(0));
        expect(json['max'], equals(10));
        expect(json['minLabel'], equals('None'));
        expect(json['maxLabel'], equals('Max'));
      });

      test('yesNo config serializes correctly', () {
        const config = TrackerResponseConfig.yesNo();

        final json = config.toJson();

        expect(json, isA<Map<String, dynamic>>());
      });

      test('roundtrip serialization preserves choice config', () {
        const original = TrackerResponseConfig.choice(
          options: ['Option 1', 'Option 2'],
        );

        final json = original.toJson();
        final deserialized = TrackerResponseConfig.fromJson(json);

        expect(deserialized, equals(original));
        expect(deserialized, isA<ChoiceConfig>());
      });

      test('roundtrip serialization preserves scale config', () {
        const original = TrackerResponseConfig.scale(
          max: 7,
          minLabel: 'Low',
          maxLabel: 'High',
        );

        final json = original.toJson();
        final deserialized = TrackerResponseConfig.fromJson(json);

        expect(deserialized, equals(original));
        expect(deserialized, isA<ScaleConfig>());
      });

      test('roundtrip serialization preserves yesNo config', () {
        const original = TrackerResponseConfig.yesNo();

        final json = original.toJson();
        final deserialized = TrackerResponseConfig.fromJson(json);

        expect(deserialized, equals(original));
        expect(deserialized, isA<YesNoConfig>());
      });
    });

    group('edge cases', () {
      test('scale config with same min and max', () {
        const config = TrackerResponseConfig.scale(min: 5);

        expect(config.min, equals(config.max));
      });

      test('choice config with duplicate options', () {
        const config = TrackerResponseConfig.choice(
          options: ['A', 'A', 'B'],
        );

        expect(config.options.length, equals(3));
        expect(config.options[0], equals(config.options[1]));
      });

      test('scale config with very large range', () {
        const config = TrackerResponseConfig.scale(min: 0, max: 1000000);

        expect(config.max - config.min, equals(1000000));
      });
    });
  });
}
