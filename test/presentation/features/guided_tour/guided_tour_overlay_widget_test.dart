@Tags(['widget', 'guided_tour'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/bloc/guided_tour_bloc.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/model/guided_tour_step.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/view/guided_tour_overlay.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

import '../../../helpers/test_imports.dart';

class MockGuidedTourBloc extends MockBloc<GuidedTourEvent, GuidedTourState>
    implements GuidedTourBloc {}

class MockGlobalSettingsBloc
    extends MockBloc<GlobalSettingsEvent, GlobalSettingsState>
    implements GlobalSettingsBloc {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  testWidgetsSafe('navigates to first tour step route when started', (
    tester,
  ) async {
    final guidedTourBloc = MockGuidedTourBloc();
    final settingsBloc = MockGlobalSettingsBloc();

    const settingsState = GlobalSettingsState();

    final steps = [
      GuidedTourStep(
        id: 'anytime',
        route: Routing.screenPath('someday'),
        title: 'Anytime',
        body: 'Anytime intro',
        kind: GuidedTourStepKind.card,
      ),
    ];
    final initialState = GuidedTourState(
      steps: steps,
      active: false,
      currentIndex: 0,
      navRequestId: 0,
    );
    final activeState = initialState.copyWith(active: true, navRequestId: 1);

    final stateController = TestStreamController<GuidedTourState>.seeded(
      initialState,
    );
    addTearDown(stateController.close);

    when(() => guidedTourBloc.state).thenReturn(initialState);
    whenListen(
      guidedTourBloc,
      stateController.stream,
      initialState: initialState,
    );

    when(() => settingsBloc.state).thenReturn(settingsState);
    whenListen(
      settingsBloc,
      const Stream<GlobalSettingsState>.empty(),
      initialState: settingsState,
    );

    final router = GoRouter(
      initialLocation: Routing.screenPath('settings'),
      routes: [
        ShellRoute(
          builder: (_, __, child) => GuidedTourOverlayHost(child: child),
          routes: [
            GoRoute(
              path: Routing.screenPath('settings'),
              builder: (_, __) => const Scaffold(
                body: Center(
                  child: Text('Settings Screen', key: Key('settings-screen')),
                ),
              ),
            ),
            GoRoute(
              path: Routing.screenPath('someday'),
              builder: (_, __) => const Scaffold(
                body: Center(
                  child: Text('Anytime Screen', key: Key('anytime-screen')),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<GuidedTourBloc>.value(value: guidedTourBloc),
          BlocProvider<GlobalSettingsBloc>.value(value: settingsBloc),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      stateController.emit(activeState);
    });
    await tester.pumpForStream();

    expect(find.byKey(const Key('anytime-screen')), findsOneWidget);
  });
}
