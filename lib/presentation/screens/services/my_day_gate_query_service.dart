import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';

import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';

final class MyDayGateQueryService {
  MyDayGateQueryService({
    required ValueRepositoryContract valueRepository,
    required SessionSharedDataService sharedDataService,
  }) : _valueRepository = valueRepository,
       _sharedDataService = sharedDataService;

  final ValueRepositoryContract _valueRepository;
  final SessionSharedDataService _sharedDataService;

  Stream<bool> watchNeedsValuesSetup() {
    final Stream<List<Value>> values$ = (() async* {
      yield await _valueRepository.getAll();
      yield* _sharedDataService.watchValues();
    })();

    return values$
        .map((values) => values.isEmpty)
        .distinct()
        .shareReplay(maxSize: 1);
  }
}
