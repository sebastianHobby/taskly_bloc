import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/wellbeing/model/mood_rating.dart';
import 'package:taskly_bloc/domain/wellbeing/model/tracker_response.dart';

part 'journal_entry.freezed.dart';
part 'journal_entry.g.dart';

@freezed
abstract class JournalEntry with _$JournalEntry {
  @JsonSerializable(explicitToJson: true)
  const factory JournalEntry({
    required String id,
    required DateTime entryDate,
    required DateTime entryTime,
    required DateTime createdAt,
    required DateTime updatedAt,
    MoodRating? moodRating,
    String? journalText,
    @Default([]) List<TrackerResponse> perEntryTrackerResponses,
  }) = _JournalEntry;

  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryFromJson(json);
}
