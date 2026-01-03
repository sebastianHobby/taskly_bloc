import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/queries/label_predicate.dart';

void main() {
  group('LabelPredicate', () {
    group('fromJson', () {
      test('creates LabelTypePredicate from type json', () {
        final json = {'type': 'type', 'labelType': 'value'};
        final predicate = LabelPredicate.fromJson(json);

        expect(predicate, isA<LabelTypePredicate>());
        expect((predicate as LabelTypePredicate).labelType, LabelType.value);
      });

      test('creates LabelNamePredicate from name json', () {
        final json = {
          'type': 'name',
          'value': 'test',
          'operator': 'contains',
        };
        final predicate = LabelPredicate.fromJson(json);

        expect(predicate, isA<LabelNamePredicate>());
        final namePred = predicate as LabelNamePredicate;
        expect(namePred.value, 'test');
        expect(namePred.operator, StringOperator.contains);
      });

      test('creates LabelColorPredicate from color json', () {
        final json = {'type': 'color', 'colorHex': '#FF0000'};
        final predicate = LabelPredicate.fromJson(json);

        expect(predicate, isA<LabelColorPredicate>());
        expect((predicate as LabelColorPredicate).colorHex, '#FF0000');
      });

      test('creates LabelIdPredicate from id json', () {
        final json = {'type': 'id', 'labelId': 'label-123'};
        final predicate = LabelPredicate.fromJson(json);

        expect(predicate, isA<LabelIdPredicate>());
        expect((predicate as LabelIdPredicate).labelId, 'label-123');
      });

      test('creates LabelIdsPredicate from ids json', () {
        final json = {
          'type': 'ids',
          'labelIds': ['label-1', 'label-2'],
        };
        final predicate = LabelPredicate.fromJson(json);

        expect(predicate, isA<LabelIdsPredicate>());
        expect(
          (predicate as LabelIdsPredicate).labelIds,
          ['label-1', 'label-2'],
        );
      });

      test('throws ArgumentError for unknown type', () {
        final json = {'type': 'unknown'};

        expect(
          () => LabelPredicate.fromJson(json),
          throwsArgumentError,
        );
      });
    });
  });

  group('LabelTypePredicate', () {
    group('construction', () {
      test('creates with required labelType', () {
        const predicate = LabelTypePredicate(labelType: LabelType.label);

        expect(predicate.labelType, LabelType.label);
      });
    });

    group('fromJson', () {
      test('creates from json with labelType', () {
        final json = {'type': 'type', 'labelType': 'value'};
        final predicate = LabelTypePredicate.fromJson(json);

        expect(predicate.labelType, LabelType.value);
      });

      test('defaults to label when labelType is null', () {
        final json = <String, dynamic>{'type': 'type'};
        final predicate = LabelTypePredicate.fromJson(json);

        expect(predicate.labelType, LabelType.label);
      });
    });

    group('toJson', () {
      test('serializes to json correctly', () {
        const predicate = LabelTypePredicate(labelType: LabelType.value);
        final json = predicate.toJson();

        expect(json['type'], 'type');
        expect(json['labelType'], 'value');
      });
    });

    group('equality', () {
      test('equal when labelType matches', () {
        const pred1 = LabelTypePredicate(labelType: LabelType.label);
        const pred2 = LabelTypePredicate(labelType: LabelType.label);

        expect(pred1, equals(pred2));
        expect(pred1.hashCode, pred2.hashCode);
      });

      test('not equal when labelType differs', () {
        const pred1 = LabelTypePredicate(labelType: LabelType.label);
        const pred2 = LabelTypePredicate(labelType: LabelType.value);

        expect(pred1, isNot(equals(pred2)));
      });
    });
  });

  group('LabelNamePredicate', () {
    group('construction', () {
      test('creates with value and default operator', () {
        const predicate = LabelNamePredicate(value: 'test');

        expect(predicate.value, 'test');
        expect(predicate.operator, StringOperator.contains);
      });

      test('creates with custom operator', () {
        const predicate = LabelNamePredicate(
          value: 'test',
          operator: StringOperator.startsWith,
        );

        expect(predicate.operator, StringOperator.startsWith);
      });
    });

    group('fromJson', () {
      test('creates from json with all fields', () {
        final json = {
          'type': 'name',
          'value': 'search',
          'operator': 'equals',
        };
        final predicate = LabelNamePredicate.fromJson(json);

        expect(predicate.value, 'search');
        expect(predicate.operator, StringOperator.equals);
      });

      test('defaults to empty value when null', () {
        final json = <String, dynamic>{'type': 'name', 'operator': 'contains'};
        final predicate = LabelNamePredicate.fromJson(json);

        expect(predicate.value, '');
      });

      test('defaults to contains operator when null', () {
        final json = <String, dynamic>{'type': 'name', 'value': 'test'};
        final predicate = LabelNamePredicate.fromJson(json);

        expect(predicate.operator, StringOperator.contains);
      });
    });

    group('toJson', () {
      test('serializes to json correctly', () {
        const predicate = LabelNamePredicate(
          value: 'test',
          operator: StringOperator.startsWith,
        );
        final json = predicate.toJson();

        expect(json['type'], 'name');
        expect(json['value'], 'test');
        expect(json['operator'], 'startsWith');
      });
    });

    group('equality', () {
      test('equal when value and operator match', () {
        const pred1 = LabelNamePredicate(
          value: 'test',
          operator: StringOperator.equals,
        );
        const pred2 = LabelNamePredicate(
          value: 'test',
          operator: StringOperator.equals,
        );

        expect(pred1, equals(pred2));
        expect(pred1.hashCode, pred2.hashCode);
      });

      test('not equal when value differs', () {
        const pred1 = LabelNamePredicate(value: 'test1');
        const pred2 = LabelNamePredicate(value: 'test2');

        expect(pred1, isNot(equals(pred2)));
      });

      test('not equal when operator differs', () {
        const pred1 = LabelNamePredicate(
          value: 'test',
          operator: StringOperator.equals,
        );
        const pred2 = LabelNamePredicate(
          value: 'test',
          operator: StringOperator.contains,
        );

        expect(pred1, isNot(equals(pred2)));
      });
    });
  });

  group('LabelColorPredicate', () {
    group('construction', () {
      test('creates with colorHex', () {
        const predicate = LabelColorPredicate(colorHex: '#FF0000');

        expect(predicate.colorHex, '#FF0000');
      });
    });

    group('fromJson', () {
      test('creates from json with colorHex', () {
        final json = {'type': 'color', 'colorHex': '#00FF00'};
        final predicate = LabelColorPredicate.fromJson(json);

        expect(predicate.colorHex, '#00FF00');
      });

      test('defaults to empty string when colorHex is null', () {
        final json = <String, dynamic>{'type': 'color'};
        final predicate = LabelColorPredicate.fromJson(json);

        expect(predicate.colorHex, '');
      });
    });

    group('toJson', () {
      test('serializes to json correctly', () {
        const predicate = LabelColorPredicate(colorHex: '#0000FF');
        final json = predicate.toJson();

        expect(json['type'], 'color');
        expect(json['colorHex'], '#0000FF');
      });
    });

    group('equality', () {
      test('equal when colorHex matches', () {
        const pred1 = LabelColorPredicate(colorHex: '#FF0000');
        const pred2 = LabelColorPredicate(colorHex: '#FF0000');

        expect(pred1, equals(pred2));
        expect(pred1.hashCode, pred2.hashCode);
      });

      test('not equal when colorHex differs', () {
        const pred1 = LabelColorPredicate(colorHex: '#FF0000');
        const pred2 = LabelColorPredicate(colorHex: '#00FF00');

        expect(pred1, isNot(equals(pred2)));
      });
    });
  });

  group('LabelIdPredicate', () {
    group('construction', () {
      test('creates with labelId', () {
        const predicate = LabelIdPredicate(labelId: 'label-123');

        expect(predicate.labelId, 'label-123');
      });
    });

    group('fromJson', () {
      test('creates from json with labelId', () {
        final json = {'type': 'id', 'labelId': 'label-456'};
        final predicate = LabelIdPredicate.fromJson(json);

        expect(predicate.labelId, 'label-456');
      });

      test('defaults to empty string when labelId is null', () {
        final json = <String, dynamic>{'type': 'id'};
        final predicate = LabelIdPredicate.fromJson(json);

        expect(predicate.labelId, '');
      });
    });

    group('toJson', () {
      test('serializes to json correctly', () {
        const predicate = LabelIdPredicate(labelId: 'label-789');
        final json = predicate.toJson();

        expect(json['type'], 'id');
        expect(json['labelId'], 'label-789');
      });
    });

    group('equality', () {
      test('equal when labelId matches', () {
        const pred1 = LabelIdPredicate(labelId: 'label-123');
        const pred2 = LabelIdPredicate(labelId: 'label-123');

        expect(pred1, equals(pred2));
        expect(pred1.hashCode, pred2.hashCode);
      });

      test('not equal when labelId differs', () {
        const pred1 = LabelIdPredicate(labelId: 'label-123');
        const pred2 = LabelIdPredicate(labelId: 'label-456');

        expect(pred1, isNot(equals(pred2)));
      });
    });
  });

  group('LabelIdsPredicate', () {
    group('construction', () {
      test('creates with labelIds list', () {
        const predicate = LabelIdsPredicate(
          labelIds: ['label-1', 'label-2'],
        );

        expect(predicate.labelIds, ['label-1', 'label-2']);
      });
    });

    group('fromJson', () {
      test('creates from json with labelIds', () {
        final json = {
          'type': 'ids',
          'labelIds': ['a', 'b', 'c'],
        };
        final predicate = LabelIdsPredicate.fromJson(json);

        expect(predicate.labelIds, ['a', 'b', 'c']);
      });

      test('defaults to empty list when labelIds is null', () {
        final json = <String, dynamic>{'type': 'ids'};
        final predicate = LabelIdsPredicate.fromJson(json);

        expect(predicate.labelIds, isEmpty);
      });

      test('filters out non-string values', () {
        final json = {
          'type': 'ids',
          'labelIds': ['valid', 123, 'also-valid', null],
        };
        final predicate = LabelIdsPredicate.fromJson(json);

        expect(predicate.labelIds, ['valid', 'also-valid']);
      });
    });

    group('toJson', () {
      test('serializes to json correctly', () {
        const predicate = LabelIdsPredicate(
          labelIds: ['x', 'y', 'z'],
        );
        final json = predicate.toJson();

        expect(json['type'], 'ids');
        expect(json['labelIds'], ['x', 'y', 'z']);
      });
    });

    group('equality', () {
      test('equal when labelIds match in order', () {
        const pred1 = LabelIdsPredicate(labelIds: ['a', 'b']);
        const pred2 = LabelIdsPredicate(labelIds: ['a', 'b']);

        expect(pred1, equals(pred2));
        expect(pred1.hashCode, pred2.hashCode);
      });

      test('not equal when labelIds differ in content', () {
        const pred1 = LabelIdsPredicate(labelIds: ['a', 'b']);
        const pred2 = LabelIdsPredicate(labelIds: ['a', 'c']);

        expect(pred1, isNot(equals(pred2)));
      });

      test('not equal when labelIds differ in length', () {
        const pred1 = LabelIdsPredicate(labelIds: ['a', 'b']);
        const pred2 = LabelIdsPredicate(labelIds: ['a', 'b', 'c']);

        expect(pred1, isNot(equals(pred2)));
      });

      test('not equal when labelIds differ in order', () {
        const pred1 = LabelIdsPredicate(labelIds: ['a', 'b']);
        const pred2 = LabelIdsPredicate(labelIds: ['b', 'a']);

        expect(pred1, isNot(equals(pred2)));
      });
    });
  });

  group('StringOperator', () {
    test('contains all expected values', () {
      expect(StringOperator.values, contains(StringOperator.equals));
      expect(StringOperator.values, contains(StringOperator.contains));
      expect(StringOperator.values, contains(StringOperator.startsWith));
      expect(StringOperator.values, contains(StringOperator.endsWith));
      expect(StringOperator.values, contains(StringOperator.isNull));
      expect(StringOperator.values, contains(StringOperator.isNotNull));
    });
  });
}
