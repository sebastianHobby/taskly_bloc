import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_preference.dart';
import 'package:taskly_bloc/domain/models/priority/priority_ranking.dart';
import 'package:taskly_bloc/domain/interfaces/allocation_preferences_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/priority_rankings_repository_contract.dart';
import 'package:uuid/uuid.dart';

/// Seeds default allocation preferences and value rankings.
///
/// This ensures users have sensible defaults when first using the
/// allocation system. Creates:
/// - Default allocation preferences (proportional strategy, 10 tasks/day)
/// - Value ranking from existing value labels (if any)
class AllocationDataSeeder {
  AllocationDataSeeder({
    required AllocationPreferencesRepositoryContract preferencesRepository,
    required PriorityRankingsRepositoryContract rankingsRepository,
    required LabelRepositoryContract labelRepository,
  }) : _preferencesRepository = preferencesRepository,
       _rankingsRepository = rankingsRepository,
       _labelRepository = labelRepository;

  final AllocationPreferencesRepositoryContract _preferencesRepository;
  final PriorityRankingsRepositoryContract _rankingsRepository;
  final LabelRepositoryContract _labelRepository;

  /// Seeds default allocation data if none exists.
  ///
  /// Idempotent - safe to call multiple times. Only creates data
  /// if preferences don't already exist.
  Future<void> seedDefaults() async {
    talker.serviceLog('AllocationDataSeeder', 'seedDefaults() START');

    try {
      // Check if preferences already exist
      final existingPrefs = await _preferencesRepository.getPreferences();

      if (existingPrefs == null) {
        talker.serviceLog(
          'AllocationDataSeeder',
          'No preferences found, creating defaults...',
        );

        // Create default preferences
        await _preferencesRepository.savePreferences(
          strategyType: AllocationStrategyType.proportional,
          urgencyInfluence: 0.4,
          minimumTasksPerCategory: 1,
          topNCategories: 3,
          dailyTaskLimit: 10,
          showExcludedUrgentWarning: true,
          urgencyThresholdDays: 3,
        );

        talker.serviceLog(
          'AllocationDataSeeder',
          'Default preferences created successfully',
        );
      } else {
        talker.serviceLog(
          'AllocationDataSeeder',
          'Preferences already exist, skipping',
        );
      }

      // Check if value ranking exists
      final existingRanking = await _rankingsRepository
          .watchRankingByType(RankingType.value)
          .first;

      if (existingRanking == null) {
        talker.serviceLog(
          'AllocationDataSeeder',
          'No value ranking found, checking for value labels...',
        );

        // Get existing value labels to seed initial ranking
        final valueLabels = await _labelRepository.getAllByType(
          LabelType.value,
        );

        if (valueLabels.isNotEmpty) {
          // Create ranking with equal weights
          final now = DateTime.now();
          const uuid = Uuid();
          final rankedItems = valueLabels.asMap().entries.map((entry) {
            return RankedItem(
              id: uuid.v4(),
              rankingId: '', // Will be set by repository
              entityId: entry.value.id,
              entityType: RankedEntityType.label,
              weight: 10, // Equal weight for all initially
              sortOrder: entry.key,
              userId: '', // Will be set by repository
              createdAt: now,
              updatedAt: now,
            );
          }).toList();

          await _rankingsRepository.createRanking(
            rankingType: RankingType.value,
            items: rankedItems,
          );

          talker.serviceLog(
            'AllocationDataSeeder',
            'Value ranking created with ${valueLabels.length} labels',
          );
        } else {
          talker.serviceLog(
            'AllocationDataSeeder',
            'No value labels exist yet, skipping ranking creation',
          );
        }
      } else {
        talker.serviceLog(
          'AllocationDataSeeder',
          'Value ranking already exists with ${existingRanking.items.length} items',
        );
      }

      talker.serviceLog(
        'AllocationDataSeeder',
        'seedDefaults() completed successfully',
      );
    } catch (error, stackTrace) {
      talker.handle(
        error,
        stackTrace,
        '[AllocationDataSeeder] Failed to seed allocation data',
      );
      // Don't rethrow - seeding failures shouldn't crash the app
    }
  }
}
