import 'package:flutter/foundation.dart';

/// Configuration for computing a single “next” virtual occurrence per entity.
///
/// This is used by non-date feeds (like Anytime) that want to render a single
/// representative occurrence for repeating entities without expanding them into
/// multiple rows.
@immutable
class OccurrencePreview {
  const OccurrencePreview({
    required this.asOfDayKey,
    required this.pastDays,
    required this.futureDays,
  });

  factory OccurrencePreview.fromJson(Map<String, dynamic> json) {
    return OccurrencePreview(
      asOfDayKey: DateTime.parse(json['asOfDayKey'] as String),
      pastDays: json['pastDays'] as int? ?? 365,
      futureDays: json['futureDays'] as int? ?? 730,
    );
  }

  /// Home-day key (UTC midnight) used as the “now” anchor.
  final DateTime asOfDayKey;

  /// How far back to expand occurrences when searching for overdue instances.
  final int pastDays;

  /// How far forward to expand occurrences when searching for upcoming instances.
  final int futureDays;

  OccurrencePreview copyWith({
    DateTime? asOfDayKey,
    int? pastDays,
    int? futureDays,
  }) {
    return OccurrencePreview(
      asOfDayKey: asOfDayKey ?? this.asOfDayKey,
      pastDays: pastDays ?? this.pastDays,
      futureDays: futureDays ?? this.futureDays,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OccurrencePreview &&
        other.asOfDayKey == asOfDayKey &&
        other.pastDays == pastDays &&
        other.futureDays == futureDays;
  }

  @override
  int get hashCode => Object.hash(asOfDayKey, pastDays, futureDays);

  @override
  String toString() {
    return 'OccurrencePreview(asOfDayKey: $asOfDayKey, '
        'pastDays: $pastDays, futureDays: $futureDays)';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'asOfDayKey': asOfDayKey.toIso8601String(),
    'pastDays': pastDays,
    'futureDays': futureDays,
  };
}
