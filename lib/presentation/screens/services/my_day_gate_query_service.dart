import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';

import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';

final class MyDayGateQueryService {
  MyDayGateQueryService({
    required ValueRepositoryContract valueRepository,
    required SessionSharedDataService sharedDataService,
    required DemoModeService demoModeService,
  }) : _valueRepository = valueRepository,
       _sharedDataService = sharedDataService,
       _demoModeService = demoModeService;

  final ValueRepositoryContract _valueRepository;
  final SessionSharedDataService _sharedDataService;
  final DemoModeService _demoModeService;

  Stream<bool> watchNeedsValuesSetup() {
    return _demoModeService.enabled.distinct().switchMap((enabled) {
      if (enabled) {
        return Stream<bool>.value(false);
      }

      final Stream<List<Value>> values$ = (() async* {
        yield await _valueRepository.getAll();
        yield* _sharedDataService.watchValues();
      })();

      return values$.map((values) => values.isEmpty).distinct();
    }).shareReplay(maxSize: 1);
  }
}
