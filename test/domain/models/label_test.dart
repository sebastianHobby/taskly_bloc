import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/label.dart';

void main() {
  group('Label', () {
    final now = DateTime(2025, 12, 26);

    test('creates instance with required fields', () {
      final label = Label(
        id: 'label-1',
        name: 'Test Label',
        createdAt: now,
        updatedAt: now,
      );

      expect(label.id, 'label-1');
      expect(label.name, 'Test Label');
      expect(label.createdAt, now);
      expect(label.updatedAt, now);
      expect(label.color, isNull);
      expect(label.type, LabelType.label);
      expect(label.iconName, isNull);
    });

    test('creates instance with all fields', () {
      final label = Label(
        id: 'label-2',
        name: 'Important',
        createdAt: now,
        updatedAt: now,
        color: '#FF0000',
        type: LabelType.value,
        iconName: 'star',
      );

      expect(label.id, 'label-2');
      expect(label.name, 'Important');
      expect(label.createdAt, now);
      expect(label.updatedAt, now);
      expect(label.color, '#FF0000');
      expect(label.type, LabelType.value);
      expect(label.iconName, 'star');
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = Label(
          id: 'label-1',
          name: 'Test',
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(
          name: 'Updated',
          color: '#00FF00',
        );

        expect(updated.id, 'label-1');
        expect(updated.name, 'Updated');
        expect(updated.color, '#00FF00');
        expect(updated.createdAt, now);
        expect(updated.updatedAt, now);
        expect(updated.type, LabelType.label);
      });

      test(
        'creates copy without changing fields when no parameters provided',
        () {
          final original = Label(
            id: 'label-1',
            name: 'Test',
            createdAt: now,
            updatedAt: now,
            color: '#FF0000',
            type: LabelType.value,
            iconName: 'star',
          );

          final copy = original.copyWith();

          expect(copy.id, original.id);
          expect(copy.name, original.name);
          expect(copy.createdAt, original.createdAt);
          expect(copy.updatedAt, original.updatedAt);
          expect(copy.color, original.color);
          expect(copy.type, original.type);
          expect(copy.iconName, original.iconName);
        },
      );

      test('can update type', () {
        final original = Label(
          id: 'label-1',
          name: 'Test',
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(type: LabelType.value);

        expect(updated.type, LabelType.value);
      });

      test('can update iconName', () {
        final original = Label(
          id: 'label-1',
          name: 'Test',
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(iconName: 'home');

        expect(updated.iconName, 'home');
      });
    });

    group('equality', () {
      test('two labels with same values are equal', () {
        final label1 = Label(
          id: 'label-1',
          name: 'Test',
          createdAt: now,
          updatedAt: now,
          color: '#FF0000',
          type: LabelType.value,
          iconName: 'star',
        );

        final label2 = Label(
          id: 'label-1',
          name: 'Test',
          createdAt: now,
          updatedAt: now,
          color: '#FF0000',
          type: LabelType.value,
          iconName: 'star',
        );

        expect(label1, equals(label2));
        expect(label1.hashCode, equals(label2.hashCode));
      });

      test('two labels with different ids are not equal', () {
        final label1 = Label(
          id: 'label-1',
          name: 'Test',
          createdAt: now,
          updatedAt: now,
        );

        final label2 = Label(
          id: 'label-2',
          name: 'Test',
          createdAt: now,
          updatedAt: now,
        );

        expect(label1, isNot(equals(label2)));
      });

      test('two labels with different names are not equal', () {
        final label1 = Label(
          id: 'label-1',
          name: 'Test1',
          createdAt: now,
          updatedAt: now,
        );

        final label2 = Label(
          id: 'label-1',
          name: 'Test2',
          createdAt: now,
          updatedAt: now,
        );

        expect(label1, isNot(equals(label2)));
      });

      test('two labels with different colors are not equal', () {
        final label1 = Label(
          id: 'label-1',
          name: 'Test',
          createdAt: now,
          updatedAt: now,
          color: '#FF0000',
        );

        final label2 = Label(
          id: 'label-1',
          name: 'Test',
          createdAt: now,
          updatedAt: now,
          color: '#00FF00',
        );

        expect(label1, isNot(equals(label2)));
      });

      test('two labels with different types are not equal', () {
        final label1 = Label(
          id: 'label-1',
          name: 'Test',
          createdAt: now,
          updatedAt: now,
        );

        final label2 = Label(
          id: 'label-1',
          name: 'Test',
          createdAt: now,
          updatedAt: now,
          type: LabelType.value,
        );

        expect(label1, isNot(equals(label2)));
      });
    });

    test('toString returns formatted string', () {
      final label = Label(
        id: 'label-1',
        name: 'Test',
        createdAt: now,
        updatedAt: now,
        color: '#FF0000',
        type: LabelType.value,
        iconName: 'star',
      );

      final string = label.toString();

      expect(string, contains('label-1'));
      expect(string, contains('Test'));
      expect(string, contains('#FF0000'));
      expect(string, contains('LabelType.value'));
      expect(string, contains('star'));
    });
  });

  group('LabelType', () {
    test('has label type', () {
      expect(LabelType.label, isA<LabelType>());
    });

    test('has value type', () {
      expect(LabelType.value, isA<LabelType>());
    });

    test('values contain both types', () {
      expect(LabelType.values, contains(LabelType.label));
      expect(LabelType.values, contains(LabelType.value));
      expect(LabelType.values.length, 2);
    });
  });
}
