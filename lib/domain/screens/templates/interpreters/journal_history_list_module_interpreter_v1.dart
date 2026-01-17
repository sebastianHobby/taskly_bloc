import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';

final class JournalHistoryListModuleInterpreterV1 {
  JournalHistoryListModuleInterpreterV1({
    required JournalRepositoryContract repository,
  }) : _repository = repository;

  final JournalRepositoryContract _repository;

  Stream<SectionDataResult> watch() {
    return _repository
        .watchJournalEntriesByQuery(JournalQuery.recent(days: 30))
        .map(
          (entries) => SectionDataResult.journalHistoryListV1(entries: entries),
        );
  }
}
