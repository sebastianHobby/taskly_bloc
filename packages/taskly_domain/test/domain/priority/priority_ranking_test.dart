@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/priority/model/priority_ranking.dart';

void main() {
  testSafe('PriorityRanking JSON roundtrip', () async {
    final ranking = PriorityRanking(
      id: 'r1',
      userId: 'u1',
      rankingType: RankingType.value,
      items: [
        RankedItem(
          id: 'i1',
          rankingId: 'r1',
          entityId: 'v1',
          entityType: RankedEntityType.label,
          weight: 5,
          sortOrder: 1,
          userId: 'u1',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      ],
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
    );

    final decoded = PriorityRanking.fromJson(ranking.toJson());
    expect(decoded, equals(ranking));
  });

  testSafe('RankedItem JSON roundtrip', () async {
    final item = RankedItem(
      id: 'i1',
      rankingId: 'r1',
      entityId: 'p1',
      entityType: RankedEntityType.project,
      weight: 7,
      sortOrder: 2,
      userId: 'u1',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
    );

    final decoded = RankedItem.fromJson(item.toJson());
    expect(decoded, equals(item));
  });
}
