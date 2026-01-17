/// Presentation-facing helper for "today" semantics.
///
/// Delegates to [HomeDayKeyService] but always provides an explicit `nowUtc`
/// from [NowService] so call sites don't need to use `DateTime.now()`.
library;

import 'package:taskly_domain/services.dart';

import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';

class HomeDayService {
  HomeDayService({
    required HomeDayKeyService dayKeyService,
    required NowService nowService,
  }) : _dayKeyService = dayKeyService,
       _nowService = nowService;

  final HomeDayKeyService _dayKeyService;
  final NowService _nowService;

  DateTime todayDayKeyUtc() {
    return _dayKeyService.todayDayKeyUtc(nowUtc: _nowService.nowUtc());
  }

  DateTime nextHomeDayBoundaryUtc() {
    return _dayKeyService.nextHomeDayBoundaryUtc(nowUtc: _nowService.nowUtc());
  }
}
