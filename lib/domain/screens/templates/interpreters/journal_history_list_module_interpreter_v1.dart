import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';

final class JournalHistoryListModuleInterpreterV1 {
  JournalHistoryListModuleInterpreterV1({
    required JournalRepositoryContract repository,
    required HomeDayKeyService dayKeyService,
  }) : _repository = repository,
       _dayKeyService = dayKeyService;

  final JournalRepositoryContract _repository;
  final HomeDayKeyService _dayKeyService;

  Stream<SectionDataResult> watch() {
    final todayDayKeyUtc = _dayKeyService.todayDayKeyUtc();
    return _repository
        .watchJournalEntriesByQuery(
          JournalQuery.recent(days: 30, todayDayKeyUtc: todayDayKeyUtc),
        )
        .map(
          (entries) => SectionDataResult.journalHistoryListV1(entries: entries),
        );
  }
}
