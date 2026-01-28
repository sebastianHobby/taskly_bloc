@Tags(['widget', 'settings'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/allocation_settings_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_appearance_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_language_region_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_my_day_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_task_suggestions_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_weekly_review_page.dart';
import 'package:taskly_domain/preferences.dart';

class MockGlobalSettingsBloc
    extends MockBloc<GlobalSettingsEvent, GlobalSettingsState>
    implements GlobalSettingsBloc {}

class MockAllocationSettingsBloc
    extends MockBloc<AllocationSettingsEvent, AllocationSettingsState>
    implements AllocationSettingsBloc {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockGlobalSettingsBloc globalBloc;
  late MockAllocationSettingsBloc allocationBloc;

  setUp(() {
    globalBloc = MockGlobalSettingsBloc();
    allocationBloc = MockAllocationSettingsBloc();
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

  testWidgetsSafe('my day settings render when loaded', (tester) async {
    const state = GlobalSettingsState(isLoading: false);
    when(() => globalBloc.state).thenReturn(state);
    whenListen(globalBloc, Stream.value(state), initialState: state);

    await tester.pumpWidgetWithBloc<GlobalSettingsBloc>(
      bloc: globalBloc,
      child: const SettingsMyDayPage(),
    );

    expect(find.text('My Day'), findsOneWidget);
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
    final state = AllocationSettingsState.loading();
    when(() => allocationBloc.state).thenReturn(state);
    whenListen(allocationBloc, Stream.value(state), initialState: state);

    await tester.pumpWidgetWithBloc<AllocationSettingsBloc>(
      bloc: allocationBloc,
      child: const SettingsTaskSuggestionsPage(),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgetsSafe('task suggestions page shows content', (tester) async {
    const state = AllocationSettingsState(
      settings: AllocationConfig(
        suggestionSignal: SuggestionSignal.valuesBased,
      ),
      isLoading: false,
    );
    when(() => allocationBloc.state).thenReturn(state);
    whenListen(allocationBloc, Stream.value(state), initialState: state);

    await tester.pumpWidgetWithBloc<AllocationSettingsBloc>(
      bloc: allocationBloc,
      child: const SettingsTaskSuggestionsPage(),
    );

    expect(find.text('Task Suggestions'), findsOneWidget);
  });
}
