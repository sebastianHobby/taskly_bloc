import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_gate_query_service.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_session_query_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_domain/services.dart';

class MockSessionSharedDataService extends Mock
    implements SessionSharedDataService {}

class MockSessionDayKeyService extends Mock implements SessionDayKeyService {
  @override
  ValueStream<DateTime> get todayDayKeyUtc =>
      super.noSuchMethod(
            Invocation.getter(#todayDayKeyUtc),
            returnValue: BehaviorSubject<DateTime>(),
            returnValueForMissingStub: BehaviorSubject<DateTime>(),
          )
          as ValueStream<DateTime>;
}

class MockMyDaySessionQueryService extends Mock
    implements MyDaySessionQueryService {}

class MockMyDayGateQueryService extends Mock implements MyDayGateQueryService {}

class MockNowService extends Mock implements NowService {}

class MockTemporalTriggerService extends Mock
    implements TemporalTriggerService {}

class MockTaskSuggestionService extends Mock implements TaskSuggestionService {}

class MockHomeDayKeyService extends Mock implements HomeDayKeyService {}

class MockRoutineWriteService extends Mock implements RoutineWriteService {}

class MockTaskWriteService extends Mock implements TaskWriteService {}

class MockValueWriteService extends Mock implements ValueWriteService {}
