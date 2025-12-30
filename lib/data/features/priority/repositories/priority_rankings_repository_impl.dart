import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' as db;
import 'package:taskly_bloc/data/drift/features/priority_tables.drift.dart'
    as db_priority;
import 'package:taskly_bloc/domain/models/priority/priority_ranking.dart'
    as model;
import 'package:taskly_bloc/domain/repositories/priority_rankings_repository.dart';
import 'package:uuid/uuid.dart';

/// Drift implementation of priority rankings repository
class PriorityRankingsRepositoryImpl implements PriorityRankingsRepository {
  PriorityRankingsRepositoryImpl(this._db);

  final db.AppDatabase _db;
  final _uuid = const Uuid();

  @override
  Stream<List<model.PriorityRanking>> watchAllRankings() {
    return (_db.select(_db.priorityRankings)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .watch()
        .asyncMap((rankings) async {
          final result = <model.PriorityRanking>[];
          for (final ranking in rankings) {
            final items =
                await (_db.select(_db.rankedItems)
                      ..where((t) => t.rankingId.equals(ranking.id))
                      ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
                    .get();

            result.add(
              model.PriorityRanking(
                id: ranking.id,
                userId: ranking.userId ?? '',
                rankingType: _mapRankingType(ranking.rankingType),
                items: items
                    .map(
                      (item) => model.RankedItem(
                        id: item.id,
                        rankingId: item.rankingId,
                        entityId: item.entityId,
                        entityType: _mapEntityType(item.entityType),
                        weight: item.weight,
                        sortOrder: item.sortOrder,
                        userId: item.userId ?? '',
                        createdAt: item.createdAt,
                        updatedAt: item.updatedAt,
                      ),
                    )
                    .toList(),
                createdAt: ranking.createdAt,
                updatedAt: ranking.updatedAt,
              ),
            );
          }
          return result;
        });
  }

  @override
  Stream<model.PriorityRanking?> watchRanking(String id) {
    return (_db.select(_db.priorityRankings)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .asyncMap((ranking) async {
          if (ranking == null) return null;

          final items =
              await (_db.select(_db.rankedItems)
                    ..where((t) => t.rankingId.equals(ranking.id))
                    ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
                  .get();

          return model.PriorityRanking(
            id: ranking.id,
            userId: ranking.userId ?? '',
            rankingType: _mapRankingType(ranking.rankingType),
            items: items
                .map(
                  (item) => model.RankedItem(
                    id: item.id,
                    rankingId: item.rankingId,
                    entityId: item.entityId,
                    entityType: _mapEntityType(item.entityType),
                    weight: item.weight,
                    sortOrder: item.sortOrder,
                    userId: item.userId ?? '',
                    createdAt: item.createdAt,
                    updatedAt: item.updatedAt,
                  ),
                )
                .toList(),
            createdAt: ranking.createdAt,
            updatedAt: ranking.updatedAt,
          );
        });
  }

  @override
  Stream<model.PriorityRanking?> watchRankingByType(model.RankingType type) {
    return (_db.select(_db.priorityRankings)..where(
          (t) => t.rankingType.equals(_mapRankingTypeToDrift(type).name),
        ))
        .watchSingleOrNull()
        .asyncMap((ranking) async {
          if (ranking == null) return null;

          final items =
              await (_db.select(_db.rankedItems)
                    ..where((t) => t.rankingId.equals(ranking.id))
                    ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
                  .get();

          return model.PriorityRanking(
            id: ranking.id,
            userId: ranking.userId ?? '',
            rankingType: _mapRankingType(ranking.rankingType),
            items: items
                .map(
                  (item) => model.RankedItem(
                    id: item.id,
                    rankingId: item.rankingId,
                    entityId: item.entityId,
                    entityType: _mapEntityType(item.entityType),
                    weight: item.weight,
                    sortOrder: item.sortOrder,
                    userId: item.userId ?? '',
                    createdAt: item.createdAt,
                    updatedAt: item.updatedAt,
                  ),
                )
                .toList(),
            createdAt: ranking.createdAt,
            updatedAt: ranking.updatedAt,
          );
        });
  }

  @override
  Future<String> createRanking({
    required model.RankingType rankingType,
    required List<model.RankedItem> items,
  }) async {
    final rankingId = _uuid.v4();
    final now = DateTime.now();

    await _db
        .into(_db.priorityRankings)
        .insert(
          db.PriorityRankingsCompanion.insert(
            id: Value(rankingId),
            userId: const Value(''), // server-side trigger will set
            rankingType: _mapRankingTypeToDrift(rankingType),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    // Insert items
    for (var i = 0; i < items.length; i++) {
      await _db
          .into(_db.rankedItems)
          .insert(
            db.RankedItemsCompanion.insert(
              id: Value(items[i].id),
              rankingId: rankingId,
              entityId: items[i].entityId,
              entityType: _mapEntityTypeToDrift(items[i].entityType),
              weight: items[i].weight,
              sortOrder: i,
              userId: const Value(''), // server-side trigger will set
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    }

    return rankingId;
  }

  @override
  Future<void> updateRanking({
    required String id,
    required List<model.RankedItem> items,
  }) async {
    final now = DateTime.now();

    // Update ranking timestamp
    await (_db.update(
      _db.priorityRankings,
    )..where((t) => t.id.equals(id))).write(
      db.PriorityRankingsCompanion(
        updatedAt: Value(now),
      ),
    );

    // Delete existing items
    await (_db.delete(
      _db.rankedItems,
    )..where((t) => t.rankingId.equals(id))).go();

    // Insert new items
    for (var i = 0; i < items.length; i++) {
      await _db
          .into(_db.rankedItems)
          .insert(
            db.RankedItemsCompanion.insert(
              id: Value(items[i].id),
              rankingId: id,
              entityId: items[i].entityId,
              entityType: _mapEntityTypeToDrift(items[i].entityType),
              weight: items[i].weight,
              sortOrder: i,
              userId: const Value(''), // Will be set by trigger
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    }
  }

  @override
  Future<void> deleteRanking(String id) async {
    // Delete items first (if not cascaded)
    await (_db.delete(
      _db.rankedItems,
    )..where((t) => t.rankingId.equals(id))).go();

    // Delete ranking
    await (_db.delete(
      _db.priorityRankings,
    )..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> reorderItems({
    required String rankingId,
    required List<String> orderedItemIds,
  }) async {
    final now = DateTime.now();

    for (var i = 0; i < orderedItemIds.length; i++) {
      await (_db.update(_db.rankedItems)..where(
            (t) =>
                t.id.equals(orderedItemIds[i]) & t.rankingId.equals(rankingId),
          ))
          .write(
            db.RankedItemsCompanion(
              sortOrder: Value(i),
              updatedAt: Value(now),
            ),
          );
    }

    // Update ranking timestamp
    await (_db.update(
      _db.priorityRankings,
    )..where((t) => t.id.equals(rankingId))).write(
      db.PriorityRankingsCompanion(
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> updateItemWeight({
    required String itemId,
    required int weight,
  }) async {
    final now = DateTime.now();

    await (_db.update(
      _db.rankedItems,
    )..where((t) => t.id.equals(itemId))).write(
      db.RankedItemsCompanion(
        weight: Value(weight),
        updatedAt: Value(now),
      ),
    );
  }

  // Mapping helpers
  model.RankingType _mapRankingType(db_priority.RankingType type) {
    switch (type) {
      case db_priority.RankingType.value:
        return model.RankingType.value;
      case db_priority.RankingType.project:
        return model.RankingType.project;
      case db_priority.RankingType.context:
        return model.RankingType.context;
      case db_priority.RankingType.goal:
        return model.RankingType.goal;
    }
  }

  db_priority.RankingType _mapRankingTypeToDrift(model.RankingType type) {
    switch (type) {
      case model.RankingType.value:
        return db_priority.RankingType.value;
      case model.RankingType.project:
        return db_priority.RankingType.project;
      case model.RankingType.context:
        return db_priority.RankingType.context;
      case model.RankingType.goal:
        return db_priority.RankingType.goal;
    }
  }

  model.RankedEntityType _mapEntityType(db_priority.RankedEntityType type) {
    switch (type) {
      case db_priority.RankedEntityType.label:
        return model.RankedEntityType.label;
      case db_priority.RankedEntityType.project:
        return model.RankedEntityType.project;
    }
  }

  db_priority.RankedEntityType _mapEntityTypeToDrift(
    model.RankedEntityType type,
  ) {
    switch (type) {
      case model.RankedEntityType.label:
        return db_priority.RankedEntityType.label;
      case model.RankedEntityType.project:
        return db_priority.RankedEntityType.project;
    }
  }
}
