@Tags(['unit', 'values'])
library;

import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/feature_mocks.dart';
import '../../../../mocks/presentation_mocks.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/values_hero_bloc.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockAnalyticsService analyticsService;
  late MockValueRepositoryContract valueRepository;
  late MockSessionSharedDataService sharedDataService;
  late MockNowService nowService;
  late TestStreamController<List<Value>> valuesController;

  ValuesHeroBloc buildBloc() {
    return ValuesHeroBloc(
      analyticsService: analyticsService,
      valueRepository: valueRepository,
      sharedDataService: sharedDataService,
      nowService: nowService,
      defaultRangeDays: 30,
    );
  }

  setUp(() {
    analyticsService = MockAnalyticsService();
    valueRepository = MockValueRepositoryContract();
    sharedDataService = MockSessionSharedDataService();
    nowService = MockNowService();
    valuesController = TestStreamController.seeded([
      TestData.value(id: 'v1', name: 'Purpose', priority: ValuePriority.high),
    ]);

    when(() => nowService.nowLocal()).thenReturn(DateTime(2025, 1, 15));
    when(() => valueRepository.getAll()).thenAnswer(
      (_) async => valuesController.value ?? const <Value>[],
    );
    when(() => sharedDataService.watchValues()).thenAnswer(
      (_) => valuesController.stream,
    );
    when(
      () => analyticsService.getRecentCompletionsByValue(days: any()),
    ).thenAnswer((_) async => {'v1': 3});
    when(() => analyticsService.getValueActivityStats()).thenAnswer(
      (_) async => {
        'v1': const ValueActivityStats(taskCount: 1, projectCount: 2),
      },
    );

    addTearDown(valuesController.close);
  });

  blocTestSafe<ValuesHeroBloc, ValuesHeroState>(
    'loads hero items from analytics and values',
    build: buildBloc,
    act: (bloc) => bloc.add(const ValuesHeroSubscriptionRequested()),
    expect: () => [
      isA<ValuesHeroLoading>(),
      isA<ValuesHeroLoaded>().having((s) => s.items.length, 'items.length', 1),
    ],
  );

  blocTestSafe<ValuesHeroBloc, ValuesHeroState>(
    'updates when values stream changes',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const ValuesHeroSubscriptionRequested());
      valuesController.emit([
        TestData.value(id: 'v1', name: 'Purpose', priority: ValuePriority.high),
        TestData.value(
          id: 'v2',
          name: 'Growth',
          priority: ValuePriority.medium,
        ),
      ]);
    },
    expect: () => [
      isA<ValuesHeroLoading>(),
      isA<ValuesHeroLoaded>(),
      isA<ValuesHeroLoaded>().having((s) => s.items.length, 'items.length', 2),
    ],
  );

  blocTestSafe<ValuesHeroBloc, ValuesHeroState>(
    'emits error when analytics fails',
    build: () {
      when(
        () => analyticsService.getRecentCompletionsByValue(days: any()),
      ).thenThrow(StateError('boom'));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const ValuesHeroSubscriptionRequested()),
    expect: () => [
      isA<ValuesHeroLoading>(),
      isA<ValuesHeroError>().having(
        (s) => s.error.toString(),
        'error',
        contains('boom'),
      ),
    ],
  );
}
