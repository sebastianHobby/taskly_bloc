import 'package:taskly_bloc/domain/interfaces/journal_repository_contract.dart';
import 'package:taskly_bloc/domain/queries/journal_query.dart';
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
