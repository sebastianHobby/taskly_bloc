import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/label.dart';

import '../../fixtures/test_data.dart';
import '../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('Label', () {
    group('construction', () {
      test('creates with required fields', () {
        final now = DateTime.now();
        final label = Label(
          id: 'label-1',
          createdAt: now,
          updatedAt: now,
          name: 'Test Label',
        );

        expect(label.id, 'label-1');
        expect(label.name, 'Test Label');
        expect(label.createdAt, now);
        expect(label.updatedAt, now);
      });

      test('creates with type as label (default)', () {
        final label = TestData.label();
        expect(label.type, LabelType.label);
      });

      test('creates with type as value', () {
        final label = TestData.label(type: LabelType.value);
        expect(label.type, LabelType.value);
      });

      test('creates with all optional fields', () {
        final now = DateTime.now();
        final label = Label(
          id: 'label-1',
          createdAt: now,
          updatedAt: now,
          name: 'Full Label',
          color: '#FF5733',
          type: LabelType.value,
          iconName: 'star',
          isSystemLabel: true,
          systemLabelType: SystemLabelType.pinned,
          lastReviewedAt: now,
        );

        expect(label.color, '#FF5733');
        expect(label.type, LabelType.value);
        expect(label.iconName, 'star');
        expect(label.isSystemLabel, true);
        expect(label.systemLabelType, SystemLabelType.pinned);
        expect(label.lastReviewedAt, now);
      });
    });

    group('LabelType', () {
      test('label type has correct value', () {
        expect(LabelType.label.name, 'label');
      });

      test('value type has correct value', () {
        expect(LabelType.value.name, 'value');
      });

      test('LabelType enum has 2 values', () {
        expect(LabelType.values, hasLength(2));
      });
    });

    group('SystemLabelType', () {
      test('pinned type exists', () {
        expect(SystemLabelType.pinned.name, 'pinned');
      });

      test('SystemLabelType enum has correct values', () {
        expect(SystemLabelType.values, contains(SystemLabelType.pinned));
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final now = DateTime(2025, 1, 15, 12);
        final label1 = Label(
          id: 'label-1',
          createdAt: now,
          updatedAt: now,
          name: 'Test',
        );
        final label2 = Label(
          id: 'label-1',
          createdAt: now,
          updatedAt: now,
          name: 'Test',
        );

        expect(label1, equals(label2));
        expect(label1.hashCode, equals(label2.hashCode));
      });

      test('not equal when type differs', () {
        final now = DateTime(2025, 1, 15, 12);
        final label1 = Label(
          id: 'label-1',
          createdAt: now,
          updatedAt: now,
          name: 'Test',
        );
        final label2 = Label(
          id: 'label-1',
          createdAt: now,
          updatedAt: now,
          name: 'Test',
          type: LabelType.value,
        );

        expect(label1, isNot(equals(label2)));
      });
    });

    group('copyWith', () {
      test('copies with new name', () {
        final label = TestData.label(name: 'Original');
        final copied = label.copyWith(name: 'Changed');

        expect(copied.name, 'Changed');
        expect(copied.id, label.id);
        expect(copied.type, label.type);
      });

      test('copies with new color', () {
        final label = TestData.label(color: '#000000');
        final copied = label.copyWith(color: '#FFFFFF');

        expect(copied.color, '#FFFFFF');
      });

      test('copies with new type', () {
        final label = TestData.label();
        final copied = label.copyWith(type: LabelType.value);

        expect(copied.type, LabelType.value);
      });

      test('preserves unchanged fields', () {
        final label = TestData.label(
          name: 'Test',
          color: '#FF0000',
          iconName: 'star',
        );
        final copied = label.copyWith(name: 'New Name');

        expect(copied.color, '#FF0000');
        expect(copied.iconName, 'star');
      });
    });

    group('lastReviewedAt', () {
      test('defaults to null', () {
        final label = TestData.label();
        expect(label.lastReviewedAt, isNull);
      });

      test('can be set', () {
        final now = DateTime.now();
        final label = Label(
          id: 'label-1',
          createdAt: now,
          updatedAt: now,
          name: 'Test',
          lastReviewedAt: now,
        );

        expect(label.lastReviewedAt, now);
      });
    });
  });
}
