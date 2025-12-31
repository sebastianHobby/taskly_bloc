import 'package:taskly_bloc/domain/models/priority/priority_ranking.dart';

/// Repository contract for managing priority rankings
abstract class PriorityRankingsRepositoryContract {
  /// Get all priority rankings for the current user
  Stream<List<PriorityRanking>> watchAllRankings();

  /// Get a specific ranking by ID
  Stream<PriorityRanking?> watchRanking(String id);

  /// Get ranking by type
  Stream<PriorityRanking?> watchRankingByType(RankingType type);

  /// Create a new priority ranking
  Future<String> createRanking({
    required RankingType rankingType,
    required List<RankedItem> items,
  });

  /// Update an existing ranking
  Future<void> updateRanking({
    required String id,
    required List<RankedItem> items,
  });

  /// Delete a ranking
  Future<void> deleteRanking(String id);

  /// Reorder items within a ranking
  Future<void> reorderItems({
    required String rankingId,
    required List<String> orderedItemIds,
  });

  /// Update the weight of a specific item
  Future<void> updateItemWeight({
    required String itemId,
    required int weight,
  });
}
