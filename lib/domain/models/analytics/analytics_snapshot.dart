import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_snapshot.freezed.dart';
part 'analytics_snapshot.g.dart';

/// Historical snapshot for server-side computed data
@freezed
abstract class AnalyticsSnapshot with _$AnalyticsSnapshot {
  const factory AnalyticsSnapshot({
    required String id,
    required String entityType,
    required DateTime snapshotDate,
    required Map<String, dynamic> metrics,
    String? entityId,
  }) = _AnalyticsSnapshot;

  factory AnalyticsSnapshot.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsSnapshotFromJson(json);
}
