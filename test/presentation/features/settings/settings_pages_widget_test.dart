@Tags(['widget', 'settings'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_appearance_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_language_region_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_weekly_review_page.dart';

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
  setUp(() {
    globalBloc = MockGlobalSettingsBloc();
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
}
