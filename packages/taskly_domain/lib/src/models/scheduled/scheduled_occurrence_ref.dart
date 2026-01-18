import 'package:taskly_domain/analytics.dart';

import 'package:taskly_domain/src/models/scheduled/scheduled_date_tag.dart';

/// Stable identity for a scheduled occurrence row.
///
/// This aligns with the MVP occurrence identity policy:
/// `(entityType, entityId, localDay, tag)`.
final class ScheduledOccurrenceRef {
  const ScheduledOccurrenceRef({
    required this.entityType,
    required this.entityId,
    required this.localDay,
    required this.tag,
  });

  final EntityType entityType;
  final String entityId;

  /// Home-day key (UTC midnight) that this occurrence is displayed on.
  final DateTime localDay;

  final ScheduledDateTag tag;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduledOccurrenceRef &&
        other.entityType == entityType &&
        other.entityId == entityId &&
        other.localDay == localDay &&
        other.tag == tag;
  }

  @override
  int get hashCode => Object.hash(entityType, entityId, localDay, tag);

  @override
  String toString() {
    return 'ScheduledOccurrenceRef('
        'entityType: ${entityType.name}, '
        'entityId: $entityId, '
        'localDay: $localDay, '
        'tag: ${tag.name}'
        ')';
  }
}
