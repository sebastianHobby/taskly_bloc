import 'package:freezed_annotation/freezed_annotation.dart';

part 'journal_entry.freezed.dart';
part 'journal_entry.g.dart';

@freezed
abstract class JournalEntry with _$JournalEntry {
  const factory JournalEntry({
    required String id,
    required DateTime entryDate,
    required DateTime entryTime,
    required DateTime occurredAt,
    required DateTime localDate,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? journalText,
    DateTime? deletedAt,
  }) = _JournalEntry;

  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryFromJson(json);
}
