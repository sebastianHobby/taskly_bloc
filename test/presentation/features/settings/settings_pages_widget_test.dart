@Tags(['widget', 'settings'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_appearance_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_language_region_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_task_suggestions_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_weekly_review_page.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/preferences.dart';

class MockGlobalSettingsBloc
    extends MockBloc<GlobalSettingsEvent, GlobalSettingsState>
    implements GlobalSettingsBloc {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockGlobalSettingsBloc globalBloc;
  late MockSettingsRepositoryContract settingsRepository;

  setUp(() {
    globalBloc = MockGlobalSettingsBloc();
    settingsRepository = MockSettingsRepositoryContract();
  });

  testWidgetsSafe('appearance page shows loading state', (tester) async {
    const state = GlobalSettingsState(isLoading: true);
    when(() => globalBloc.state).thenReturn(state);
    whenListen(globalBloc, Stream.value(state), initialState: state);

    await tester.pumpWidgetWithBloc<GlobalSettingsBloc>(
      bloc: globalBloc,
      child: const SettingsAppearancePage(),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgetsSafe('appearance page shows content when loaded', (tester) async {
    const state = GlobalSettingsState(isLoading: false);
    when(() => globalBloc.state).thenReturn(state);
    whenListen(globalBloc, Stream.value(state), initialState: state);

    await tester.pumpWidgetWithBloc<GlobalSettingsBloc>(
      bloc: globalBloc,
      child: const SettingsAppearancePage(),
    );

    expect(find.text('Theme'), findsOneWidget);
  });

  testWidgetsSafe('language and region page renders', (tester) async {
    const state = GlobalSettingsState(isLoading: false);
    when(() => globalBloc.state).thenReturn(state);
    whenListen(globalBloc, Stream.value(state), initialState: state);

    await tester.pumpWidgetWithBloc<GlobalSettingsBloc>(
      bloc: globalBloc,
      child: const SettingsLanguageRegionPage(),
    );

    expect(find.text('Language & Region'), findsOneWidget);
  });

  testWidgetsSafe('weekly review page renders', (tester) async {
    const state = GlobalSettingsState(isLoading: false);
    when(() => globalBloc.state).thenReturn(state);
    whenListen(globalBloc, Stream.value(state), initialState: state);

    await tester.pumpWidgetWithBloc<GlobalSettingsBloc>(
      bloc: globalBloc,
      child: const SettingsWeeklyReviewPage(),
    );

    expect(find.text('Weekly Review'), findsOneWidget);
  });

  testWidgetsSafe('task suggestions page shows loading', (tester) async {
    when(
      () => settingsRepository.watch(SettingsKey.allocation),
    ).thenAnswer((_) => Stream<AllocationConfig>.empty());

    await tester.pumpApp(
      RepositoryProvider<SettingsRepositoryContract>.value(
        value: settingsRepository,
        child: const SettingsTaskSuggestionsPage(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgetsSafe('task suggestions page shows content', (tester) async {
    const settings = AllocationConfig(
      suggestionSignal: SuggestionSignal.ratingsBased,
    );
    when(
      () => settingsRepository.watch(SettingsKey.allocation),
    ).thenAnswer((_) => Stream.value(settings));

    await tester.pumpApp(
      RepositoryProvider<SettingsRepositoryContract>.value(
        value: settingsRepository,
        child: const SettingsTaskSuggestionsPage(),
      ),
    );
    await tester.pumpForStream();

    expect(find.text('Task Suggestions'), findsOneWidget);
  });
}
