import 'package:meta/meta.dart';

@immutable
final class JournalHistoryFilterPreferences {
  const JournalHistoryFilterPreferences({
    this.rangeStartIsoDayUtc,
    this.rangeEndIsoDayUtc,
    this.factorTrackerIds = const <String>[],
    this.factorGroupId,
    this.lookbackDays = 30,
    this.dayTrackerOrderIds = const <String>[],
    this.hiddenDayTrackerIds = const <String>[],
    this.hiddenSummaryTrackerIds = const <String>[],
  });

  factory JournalHistoryFilterPreferences.fromJson(Map<String, dynamic> json) {
    final rangeStartIsoDayUtc = json['rangeStartIsoDayUtc'] as String?;
    final rangeEndIsoDayUtc = json['rangeEndIsoDayUtc'] as String?;
    final factorTrackerIds =
        (json['factorTrackerIds'] as List<dynamic>?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];
    final factorGroupId = json['factorGroupId'] as String?;
    final lookbackDays = json['lookbackDays'] is int
        ? (json['lookbackDays'] as int)
        : 30;
    final dayTrackerOrderIds =
        (json['dayTrackerOrderIds'] as List<dynamic>?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];
    final hiddenDayTrackerIds =
        (json['hiddenDayTrackerIds'] as List<dynamic>?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];
    final hiddenSummaryTrackerIds =
        (json['hiddenSummaryTrackerIds'] as List<dynamic>?)
            ?.whereType<String>()
            .toList(growable: false) ??
        const <String>[];
    return JournalHistoryFilterPreferences(
      rangeStartIsoDayUtc: rangeStartIsoDayUtc,
      rangeEndIsoDayUtc: rangeEndIsoDayUtc,
      factorTrackerIds: factorTrackerIds,
      factorGroupId: factorGroupId,
      lookbackDays: lookbackDays,
      dayTrackerOrderIds: dayTrackerOrderIds,
      hiddenDayTrackerIds: hiddenDayTrackerIds,
      hiddenSummaryTrackerIds: hiddenSummaryTrackerIds,
    );
  }

  final String? rangeStartIsoDayUtc;
  final String? rangeEndIsoDayUtc;
  final List<String> factorTrackerIds;
  final String? factorGroupId;
  final int lookbackDays;
  final List<String> dayTrackerOrderIds;
  final List<String> hiddenDayTrackerIds;
  final List<String> hiddenSummaryTrackerIds;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'rangeStartIsoDayUtc': rangeStartIsoDayUtc,
    'rangeEndIsoDayUtc': rangeEndIsoDayUtc,
    'factorTrackerIds': factorTrackerIds,
    'factorGroupId': factorGroupId,
    'lookbackDays': lookbackDays,
    'dayTrackerOrderIds': dayTrackerOrderIds,
    'hiddenDayTrackerIds': hiddenDayTrackerIds,
    'hiddenSummaryTrackerIds': hiddenSummaryTrackerIds,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalHistoryFilterPreferences &&
          other.rangeStartIsoDayUtc == rangeStartIsoDayUtc &&
          other.rangeEndIsoDayUtc == rangeEndIsoDayUtc &&
          _sameList(other.factorTrackerIds, factorTrackerIds) &&
          other.factorGroupId == factorGroupId &&
          other.lookbackDays == lookbackDays &&
          _sameList(other.dayTrackerOrderIds, dayTrackerOrderIds) &&
          _sameList(other.hiddenDayTrackerIds, hiddenDayTrackerIds) &&
          _sameList(other.hiddenSummaryTrackerIds, hiddenSummaryTrackerIds);

  @override
  int get hashCode => Object.hash(
    rangeStartIsoDayUtc,
    rangeEndIsoDayUtc,
    Object.hashAll(factorTrackerIds),
    factorGroupId,
    lookbackDays,
    Object.hashAll(dayTrackerOrderIds),
    Object.hashAll(hiddenDayTrackerIds),
    Object.hashAll(hiddenSummaryTrackerIds),
  );
}

bool _sameList(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
