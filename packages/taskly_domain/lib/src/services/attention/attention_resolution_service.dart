import 'package:meta/meta.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/telemetry.dart';

/// Generates new IDs for attention resolutions.
typedef AttentionResolutionIdGenerator = String Function();

/// Domain service that applies user resolution actions to attention items.
///
/// This centralizes resolution policy (e.g. snooze duration, dismiss details)
/// while keeping UI orchestration (undo windows, selection) in presentation.
@immutable
final class AttentionResolutionService {
  const AttentionResolutionService({
    required AttentionRepositoryContract repository,
    required AttentionResolutionIdGenerator newResolutionId,
    this.defaultSnoozeDuration = const Duration(days: 1),
  }) : _repository = repository,
       _newResolutionId = newResolutionId;

  final AttentionRepositoryContract _repository;
  final AttentionResolutionIdGenerator _newResolutionId;

  /// Default snooze duration used when applying [AttentionResolutionAction.snoozed].
  final Duration defaultSnoozeDuration;

  /// Records resolutions for the provided [items].
  ///
  /// Returns the number of items that were successfully recorded. Some items
  /// may be skipped (e.g. a dismiss action without a required `state_hash`).
  Future<int> applyAction({
    required AttentionResolutionAction action,
    required List<AttentionItem> items,
    required DateTime nowUtc,
    OperationContext? context,
    Duration? snoozeDuration,
  }) async {
    if (items.isEmpty) return 0;

    final effectiveSnoozeDuration = snoozeDuration ?? defaultSnoozeDuration;
    var recordedCount = 0;

    for (final item in items) {
      final details = _actionDetails(
        item: item,
        action: action,
        nowUtc: nowUtc,
        snoozeDuration: effectiveSnoozeDuration,
      );

      // If dismiss isn't possible, skip rather than failing the batch.
      if (action == AttentionResolutionAction.dismissed && details == null) {
        continue;
      }

      final resolution = AttentionResolution(
        id: _newResolutionId(),
        ruleId: item.ruleId,
        entityId: item.entityId,
        entityType: item.entityType,
        resolvedAt: nowUtc,
        createdAt: nowUtc,
        resolutionAction: action,
        actionDetails: details,
      );

      await _repository.recordResolution(resolution, context: context);
      recordedCount++;
    }

    return recordedCount;
  }

  Map<String, dynamic>? _actionDetails({
    required AttentionItem item,
    required AttentionResolutionAction action,
    required DateTime nowUtc,
    required Duration snoozeDuration,
  }) {
    return switch (action) {
      AttentionResolutionAction.snoozed => <String, dynamic>{
        'snooze_until': nowUtc.add(snoozeDuration).toIso8601String(),
      },
      AttentionResolutionAction.dismissed => _dismissDetails(item),
      AttentionResolutionAction.reviewed ||
      AttentionResolutionAction.skipped => null,
    };
  }

  Map<String, dynamic>? _dismissDetails(AttentionItem item) {
    final raw = item.metadata?['state_hash'];
    if (raw is! String || raw.isEmpty) return null;
    return <String, dynamic>{'state_hash': raw};
  }
}
