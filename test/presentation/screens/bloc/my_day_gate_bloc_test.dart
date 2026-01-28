@Tags(['unit'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/presentation_mocks.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late MockMyDayGateQueryService queryService;
  late BehaviorSubject<bool> subject;

  setUp(() {
    queryService = MockMyDayGateQueryService();
    subject = BehaviorSubject<bool>();
    when(() => queryService.watchNeedsValuesSetup()).thenAnswer(
      (_) => subject.stream,
    );
    addTearDown(subject.close);
  });

  blocTestSafe<MyDayGateBloc, MyDayGateState>(
    'emits loaded state when prerequisites stream emits',
    build: () => MyDayGateBloc(queryService: queryService),
    act: (_) => subject.add(true),
    expect: () => [const MyDayGateLoaded(needsValuesSetup: true)],
  );

  blocTestSafe<MyDayGateBloc, MyDayGateState>(
    'retry emits loading then loaded',
    build: () => MyDayGateBloc(queryService: queryService),
    act: (bloc) async {
      subject.add(false);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const MyDayGateRetryRequested());
      subject.add(true);
    },
    expect: () => [
      const MyDayGateLoaded(needsValuesSetup: false),
      const MyDayGateLoading(),
      const MyDayGateLoaded(needsValuesSetup: true),
    ],
  );
}
