import 'package:meta/meta.dart';

@immutable
final class JournalHistoryFilterPreferences {
  const JournalHistoryFilterPreferences({
    this.rangeStartIsoDayUtc,
    this.rangeEndIsoDayUtc,
    this.factorTrackerIds = const <String>[],
    this.factorGroupId,
    this.lookbackDays = 30,
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
    return JournalHistoryFilterPreferences(
      rangeStartIsoDayUtc: rangeStartIsoDayUtc,
      rangeEndIsoDayUtc: rangeEndIsoDayUtc,
      factorTrackerIds: factorTrackerIds,
      factorGroupId: factorGroupId,
      lookbackDays: lookbackDays,
    );
  }

  final String? rangeStartIsoDayUtc;
  final String? rangeEndIsoDayUtc;
  final List<String> factorTrackerIds;
  final String? factorGroupId;
  final int lookbackDays;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'rangeStartIsoDayUtc': rangeStartIsoDayUtc,
    'rangeEndIsoDayUtc': rangeEndIsoDayUtc,
    'factorTrackerIds': factorTrackerIds,
    'factorGroupId': factorGroupId,
    'lookbackDays': lookbackDays,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalHistoryFilterPreferences &&
          other.rangeStartIsoDayUtc == rangeStartIsoDayUtc &&
          other.rangeEndIsoDayUtc == rangeEndIsoDayUtc &&
          _sameList(other.factorTrackerIds, factorTrackerIds) &&
          other.factorGroupId == factorGroupId &&
          other.lookbackDays == lookbackDays;

  @override
  int get hashCode => Object.hash(
    rangeStartIsoDayUtc,
    rangeEndIsoDayUtc,
    Object.hashAll(factorTrackerIds),
    factorGroupId,
    lookbackDays,
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
