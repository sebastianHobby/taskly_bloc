features/wellbeing/domain/models/void void mood_rating.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/models/tracker_response.dart';

part 'journal_entry.freezed.dart';
part 'journal_entry.g.dart';

@freezed
abstract class JournalEntry with _$JournalEntry {
  const factory JournalEntry({
    required String id,
    required DateTime entryDate,
    required DateTime entryTime,
    required DateTime createdAt,
    required DateTime updatedAt,
    MoodRating? moodRating,
    String? journalText,
    @Default([]) List<TrackerResponse> trackerResponses,
  }) = _JournalEntry;

  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryFromJson(json);
}
