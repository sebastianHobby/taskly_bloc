import 'package:freezed_annotation/freezed_annotation.dart';

part 'date_range.freezed.dart';
part 'date_range.g.dart';

@freezed
abstract class DateRange with _$DateRange {
  const factory DateRange({
    required DateTime start,
    required DateTime end,
  }) = _DateRange;

  const DateRange._();

  factory DateRange.fromJson(Map<String, dynamic> json) =>
      _$DateRangeFromJson(json);

  factory DateRange.last30Days({required DateTime end}) {
    return DateRange(
      start: end.subtract(const Duration(days: 30)),
      end: end,
    );
  }

  int get daysDifference => end.difference(start).inDays;

  bool contains(DateTime date) {
    return date.isAfter(start.subtract(const Duration(days: 1))) &&
        date.isBefore(end.add(const Duration(days: 1)));
  }
}
