import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/settings/value_ranking.dart';

void main() {
  group('ValueRankItem', () {
    group('constructor', () {
      test('creates with required fields', () {
        const item = ValueRankItem(labelId: 'label1', weight: 5);

        expect(item.labelId, 'label1');
        expect(item.weight, 5);
        expect(item.sortOrder, 0);
      });

      test('creates with all fields', () {
        const item = ValueRankItem(
          labelId: 'label2',
          weight: 8,
          sortOrder: 3,
        );

        expect(item.labelId, 'label2');
        expect(item.weight, 8);
        expect(item.sortOrder, 3);
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'labelId': 'testLabel',
          'weight': 7,
          'sortOrder': 2,
        };

        final item = ValueRankItem.fromJson(json);

        expect(item.labelId, 'testLabel');
        expect(item.weight, 7);
        expect(item.sortOrder, 2);
      });

      test('parses with default weight', () {
        final json = {
          'labelId': 'testLabel',
        };

        final item = ValueRankItem.fromJson(json);

        expect(item.labelId, 'testLabel');
        expect(item.weight, 5);
        expect(item.sortOrder, 0);
      });

      test('parses with null weight', () {
        final json = {
          'labelId': 'testLabel',
          'weight': null,
        };

        final item = ValueRankItem.fromJson(json);

        expect(item.weight, 5);
      });

      test('parses with null sortOrder', () {
        final json = {
          'labelId': 'testLabel',
          'weight': 3,
          'sortOrder': null,
        };

        final item = ValueRankItem.fromJson(json);

        expect(item.sortOrder, 0);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        const item = ValueRankItem(
          labelId: 'myLabel',
          weight: 9,
          sortOrder: 5,
        );

        final json = item.toJson();

        expect(json['labelId'], 'myLabel');
        expect(json['weight'], 9);
        expect(json['sortOrder'], 5);
      });

      test('round-trips through JSON', () {
        const original = ValueRankItem(
          labelId: 'roundTrip',
          weight: 6,
          sortOrder: 1,
        );

        final json = original.toJson();
        final restored = ValueRankItem.fromJson(json);

        expect(restored, original);
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        const item = ValueRankItem(labelId: 'test', weight: 5, sortOrder: 2);

        final copied = item.copyWith();

        expect(copied, item);
      });

      test('copies with labelId change', () {
        const item = ValueRankItem(labelId: 'old', weight: 5);

        final copied = item.copyWith(labelId: 'new');

        expect(copied.labelId, 'new');
        expect(copied.weight, item.weight);
        expect(copied.sortOrder, item.sortOrder);
      });

      test('copies with weight change', () {
        const item = ValueRankItem(labelId: 'test', weight: 5);

        final copied = item.copyWith(weight: 10);

        expect(copied.weight, 10);
        expect(copied.labelId, item.labelId);
      });

      test('copies with sortOrder change', () {
        const item = ValueRankItem(labelId: 'test', weight: 5, sortOrder: 0);

        final copied = item.copyWith(sortOrder: 99);

        expect(copied.sortOrder, 99);
      });
    });

    group('equality', () {
      test('equal items are equal', () {
        const item1 = ValueRankItem(labelId: 'a', weight: 5, sortOrder: 1);
        const item2 = ValueRankItem(labelId: 'a', weight: 5, sortOrder: 1);

        expect(item1, item2);
        expect(item1.hashCode, item2.hashCode);
      });

      test('different labelId are not equal', () {
        const item1 = ValueRankItem(labelId: 'a', weight: 5);
        const item2 = ValueRankItem(labelId: 'b', weight: 5);

        expect(item1, isNot(item2));
      });

      test('different weight are not equal', () {
        const item1 = ValueRankItem(labelId: 'a', weight: 5);
        const item2 = ValueRankItem(labelId: 'a', weight: 6);

        expect(item1, isNot(item2));
      });

      test('different sortOrder are not equal', () {
        const item1 = ValueRankItem(labelId: 'a', weight: 5, sortOrder: 1);
        const item2 = ValueRankItem(labelId: 'a', weight: 5, sortOrder: 2);

        expect(item1, isNot(item2));
      });

      test('identical returns true for same instance', () {
        const item = ValueRankItem(labelId: 'a', weight: 5);

        expect(item == item, true);
      });
    });
  });

  group('ValueRanking', () {
    group('constructor', () {
      test('creates with default empty items', () {
        const ranking = ValueRanking();

        expect(ranking.items, isEmpty);
      });

      test('creates with provided items', () {
        const items = [
          ValueRankItem(labelId: 'a', weight: 5),
          ValueRankItem(labelId: 'b', weight: 8),
        ];
        const ranking = ValueRanking(items: items);

        expect(ranking.items, items);
        expect(ranking.items.length, 2);
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'items': [
            {'labelId': 'label1', 'weight': 5, 'sortOrder': 0},
            {'labelId': 'label2', 'weight': 8, 'sortOrder': 1},
          ],
        };

        final ranking = ValueRanking.fromJson(json);

        expect(ranking.items.length, 2);
        expect(ranking.items[0].labelId, 'label1');
        expect(ranking.items[1].labelId, 'label2');
      });

      test('parses empty items', () {
        final json = {'items': <dynamic>[]};

        final ranking = ValueRanking.fromJson(json);

        expect(ranking.items, isEmpty);
      });

      test('parses null items as empty', () {
        final json = {'items': null};

        final ranking = ValueRanking.fromJson(json);

        expect(ranking.items, isEmpty);
      });

      test('parses missing items as empty', () {
        final ranking = ValueRanking.fromJson(const {});

        expect(ranking.items, isEmpty);
      });
    });

    group('toJson', () {
      test('serializes items', () {
        const ranking = ValueRanking(
          items: [
            ValueRankItem(labelId: 'x', weight: 3),
            ValueRankItem(labelId: 'y', weight: 7),
          ],
        );

        final json = ranking.toJson();

        expect(json['items'], isA<List>());
        expect((json['items'] as List).length, 2);
      });

      test('serializes empty items', () {
        const ranking = ValueRanking();

        final json = ranking.toJson();

        expect(json['items'], isEmpty);
      });

      test('round-trips through JSON', () {
        const original = ValueRanking(
          items: [
            ValueRankItem(labelId: 'a', weight: 2, sortOrder: 0),
            ValueRankItem(labelId: 'b', weight: 9, sortOrder: 1),
          ],
        );

        final json = original.toJson();
        final restored = ValueRanking.fromJson(json);

        expect(restored, original);
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        const ranking = ValueRanking(
          items: [ValueRankItem(labelId: 'a', weight: 5)],
        );

        final copied = ranking.copyWith();

        expect(copied, ranking);
      });

      test('copies with new items', () {
        const ranking = ValueRanking(
          items: [ValueRankItem(labelId: 'a', weight: 5)],
        );
        const newItems = [ValueRankItem(labelId: 'b', weight: 8)];

        final copied = ranking.copyWith(items: newItems);

        expect(copied.items, newItems);
      });
    });

    group('equality', () {
      test('equal rankings are equal', () {
        const ranking1 = ValueRanking(
          items: [ValueRankItem(labelId: 'a', weight: 5)],
        );
        const ranking2 = ValueRanking(
          items: [ValueRankItem(labelId: 'a', weight: 5)],
        );

        expect(ranking1, ranking2);
        expect(ranking1.hashCode, ranking2.hashCode);
      });

      test('empty rankings are equal', () {
        const ranking1 = ValueRanking();
        const ranking2 = ValueRanking();

        expect(ranking1, ranking2);
      });

      test('different items are not equal', () {
        const ranking1 = ValueRanking(
          items: [ValueRankItem(labelId: 'a', weight: 5)],
        );
        const ranking2 = ValueRanking(
          items: [ValueRankItem(labelId: 'b', weight: 5)],
        );

        expect(ranking1, isNot(ranking2));
      });

      test('different item count are not equal', () {
        const ranking1 = ValueRanking(
          items: [ValueRankItem(labelId: 'a', weight: 5)],
        );
        const ranking2 = ValueRanking(
          items: [
            ValueRankItem(labelId: 'a', weight: 5),
            ValueRankItem(labelId: 'b', weight: 8),
          ],
        );

        expect(ranking1, isNot(ranking2));
      });

      test('identical returns true for same instance', () {
        const ranking = ValueRanking();

        expect(ranking == ranking, true);
      });
    });

    group('toString', () {
      test('returns formatted string', () {
        const ranking = ValueRanking(
          items: [
            ValueRankItem(labelId: 'a', weight: 5),
            ValueRankItem(labelId: 'b', weight: 8),
          ],
        );

        expect(ranking.toString(), 'ValueRanking(2 items)');
      });

      test('returns formatted string for empty ranking', () {
        const ranking = ValueRanking();

        expect(ranking.toString(), 'ValueRanking(0 items)');
      });
    });
  });
}
