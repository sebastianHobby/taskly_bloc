@Tags(['widget', 'guided_tour'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/bloc/guided_tour_bloc.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/guided_tour_anchors.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/model/guided_tour_step.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/view/guided_tour_overlay.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/plan_my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/view/plan_my_day_page.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';

import '../../../helpers/test_imports.dart';

class MockGuidedTourBloc extends MockBloc<GuidedTourEvent, GuidedTourState>
    implements GuidedTourBloc {}

class MockPlanMyDayBloc extends MockBloc<PlanMyDayEvent, PlanMyDayState>
    implements PlanMyDayBloc {}

class MockMyDayGateBloc extends MockBloc<MyDayGateEvent, MyDayGateState>
    implements MyDayGateBloc {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  Future<void> pumpUntilFound(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 2),
    Duration step = const Duration(milliseconds: 50),
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < timeout) {
      await tester.pump(step);
      if (finder.evaluate().isNotEmpty) return;
    }
  }

  testWidgetsSafe('navigates to projects and shows coachmark overlay', (
    tester,
  ) async {
    final guidedTourBloc = MockGuidedTourBloc();

    final steps = [
      GuidedTourStep(
        id: 'projects_overview',
        route: '/projects',
        title: 'Projects',
        body: 'Projects intro',
        kind: GuidedTourStepKind.coachmark,
        coachmark: const GuidedTourCoachmark(
          targetId: 'projects_create_project',
          title: 'Projects',
          body: 'Projects intro',
        ),
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

    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        ShellRoute(
          builder: (_, __, child) => GuidedTourOverlayHost(child: child),
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, __) => const Scaffold(
                body: Center(
                  child: Text('Settings Screen', key: Key('settings-screen')),
                ),
              ),
            ),
            GoRoute(
              path: '/projects',
              builder: (_, __) => Scaffold(
                body: Center(
                  child: SizedBox(
                    key: const Key('projects-screen'),
                    child: ColoredBox(
                      color: Colors.transparent,
                      child: SizedBox(
                        width: 10,
                        height: 10,
                        key: GuidedTourAnchors.projectsCreateProject,
                      ),
                    ),
                  ),
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
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      stateController.emit(activeState);
    });
    await tester.pumpForStream();
    await pumpUntilFound(
      tester,
      find.byKey(const Key('guided-tour-coachmark-projects_overview')),
    );

    expect(find.byKey(const Key('projects-screen')), findsOneWidget);
    expect(
      find.byKey(const Key('guided-tour-coachmark-projects_overview')),
      findsOneWidget,
    );
  });

  testWidgetsSafe(
    'coachmark card stays on-screen when target is near bottom',
    (tester) async {
      const surfaceSize = Size(600, 420);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() async {
        tester.binding.window.devicePixelRatioTestValue = 1.0;
        await tester.binding.setSurfaceSize(null);
      });

      final guidedTourBloc = MockGuidedTourBloc();

      final steps = [
        GuidedTourStep(
          id: 'projects_overview',
          route: '/projects',
          title: 'Projects',
          body: 'Projects intro',
          kind: GuidedTourStepKind.coachmark,
          coachmark: const GuidedTourCoachmark(
            targetId: 'projects_create_project',
            title: 'Projects',
            body: 'Projects intro',
          ),
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

      when(() => guidedTourBloc.state).thenAnswer(
        (_) => stateController.value ?? initialState,
      );
      whenListen(
        guidedTourBloc,
        stateController.stream,
        initialState: initialState,
      );

      final router = GoRouter(
        initialLocation: '/projects',
        routes: [
          ShellRoute(
            builder: (_, __, child) => GuidedTourOverlayHost(child: child),
            routes: [
              GoRoute(
                path: '/projects',
                builder: (_, __) => Scaffold(
                  body: Stack(
                    children: [
                      const Center(child: Text('Projects Screen')),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            key: GuidedTourAnchors.projectsCreateProject,
                          ),
                        ),
                      ),
                    ],
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
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        stateController.emit(activeState);
      });
      await tester.pumpForStream();
      await pumpUntilFound(
        tester,
        find.byKey(const Key('guided-tour-coachmark-projects_overview')),
      );

      final cardFinder = find.byKey(
        const Key('guided-tour-coachmark-projects_overview'),
      );
      expect(cardFinder, findsOneWidget);

      final cardRect = tester.getRect(cardFinder);
      expect(cardRect.top, greaterThanOrEqualTo(0));
      expect(cardRect.bottom, lessThanOrEqualTo(surfaceSize.height));
    },
  );

  testWidgetsSafe(
    'waits for Plan My Day anchor to mount before showing coachmark',
    (tester) async {
      final guidedTourBloc = MockGuidedTourBloc();
      final planMyDayBloc = MockPlanMyDayBloc();
      final readyState = DemoDataProvider().buildPlanMyDayReady();
      final planStates = TestStreamController<PlanMyDayState>.seeded(
        readyState,
      );
      addTearDown(planStates.close);

      final steps = [
        GuidedTourStep(
          id: 'plan_my_day_triage',
          route: '/my-day',
          title: 'Start with time-sensitive',
          body: "Start with what's time-sensitive.",
          kind: GuidedTourStepKind.coachmark,
          coachmark: const GuidedTourCoachmark(
            targetId: 'plan_my_day_triage',
            title: 'Start with time-sensitive',
            body: "Start with what's time-sensitive.",
          ),
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

      when(() => guidedTourBloc.state).thenAnswer(
        (_) => stateController.value ?? initialState,
      );
      whenListen(
        guidedTourBloc,
        stateController.stream,
        initialState: initialState,
      );

      when(() => planMyDayBloc.state).thenAnswer(
        (_) => planStates.value ?? readyState,
      );
      whenListen(
        planMyDayBloc,
        planStates.stream,
        initialState: readyState,
      );

      final router = GoRouter(
        initialLocation: '/my-day',
        routes: [
          ShellRoute(
            builder: (_, __, child) => GuidedTourOverlayHost(child: child),
            routes: [
              GoRoute(
                path: '/my-day',
                builder: (_, __) => const _DelayedAnchorPage(),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<GuidedTourBloc>.value(value: guidedTourBloc),
            BlocProvider<PlanMyDayBloc>.value(value: planMyDayBloc),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        stateController.emit(activeState);
      });
      await tester.pumpForStream();

      expect(
        find.byKey(const Key('guided-tour-coachmark-plan_my_day_triage')),
        findsNothing,
      );

      await pumpUntilFound(
        tester,
        find.byKey(const Key('guided-tour-coachmark-plan_my_day_triage')),
        timeout: const Duration(seconds: 5),
        step: const Duration(milliseconds: 50),
      );

      expect(
        find.byKey(const Key('guided-tour-coachmark-plan_my_day_triage')),
        findsOneWidget,
      );
      await tester.pumpForStream();
      expect(
        find.byKey(const Key('guided-tour-coachmark-plan_my_day_triage')),
        findsOneWidget,
      );
    },
  );

  testWidgetsSafe(
    'keeps coachmark visible through Plan My Day loading churn',
    (tester) async {
      final guidedTourBloc = MockGuidedTourBloc();
      final planMyDayBloc = MockPlanMyDayBloc();
      final gateBloc = MockMyDayGateBloc();

      const gateState = MyDayGateLoaded(needsValuesSetup: false);

      final steps = [
        GuidedTourStep(
          id: 'plan_my_day_triage',
          route: '/my-day',
          title: 'Start with time-sensitive',
          body: "Start with what's time-sensitive.",
          kind: GuidedTourStepKind.coachmark,
          coachmark: const GuidedTourCoachmark(
            targetId: 'plan_my_day_triage',
            title: 'Start with time-sensitive',
            body: "Start with what's time-sensitive.",
          ),
        ),
      ];
      final initialTourState = GuidedTourState(
        steps: steps,
        active: false,
        currentIndex: 0,
        navRequestId: 0,
      );
      final activeTourState = initialTourState.copyWith(
        active: true,
        navRequestId: 1,
      );

      final tourStates = TestStreamController<GuidedTourState>.seeded(
        initialTourState,
      );
      addTearDown(tourStates.close);

      final readyState = DemoDataProvider().buildPlanMyDayReady();
      final planStates = TestStreamController<PlanMyDayState>.seeded(
        const PlanMyDayLoading(),
      );
      addTearDown(planStates.close);

      when(() => guidedTourBloc.state).thenAnswer(
        (_) => tourStates.value ?? initialTourState,
      );
      whenListen(
        guidedTourBloc,
        tourStates.stream,
        initialState: initialTourState,
      );

      when(() => planMyDayBloc.state).thenAnswer(
        (_) => planStates.value ?? const PlanMyDayLoading(),
      );
      whenListen(
        planMyDayBloc,
        planStates.stream,
        initialState: const PlanMyDayLoading(),
      );

      when(() => gateBloc.state).thenReturn(gateState);
      whenListen(
        gateBloc,
        const Stream<MyDayGateState>.empty(),
        initialState: gateState,
      );

      final router = GoRouter(
        initialLocation: '/my-day',
        routes: [
          ShellRoute(
            builder: (_, __, child) => GuidedTourOverlayHost(child: child),
            routes: [
              GoRoute(
                path: '/my-day',
                builder: (_, __) => const PlanMyDayPage(
                  onCloseRequested: _noop,
                ),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<NowService>.value(value: const _FixedNowService()),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<GuidedTourBloc>.value(value: guidedTourBloc),
              BlocProvider<PlanMyDayBloc>.value(value: planMyDayBloc),
              BlocProvider<MyDayGateBloc>.value(value: gateBloc),
            ],
            child: MaterialApp.router(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        tourStates.emit(activeTourState);
        planStates.emit(readyState);
      });
      await tester.pump();
      final anchorFinder = find.byKey(GuidedTourAnchors.planMyDayTriage);
      if (anchorFinder.evaluate().isEmpty) {
        // ignore: avoid_print
        print('Churn test: triage anchor not found');
      } else {
        // ignore: avoid_print
        print('Churn test: triage anchor found');
      }
      await pumpUntilFound(
        tester,
        find.byKey(const Key('guided-tour-coachmark-plan_my_day_triage')),
        timeout: const Duration(seconds: 2),
        step: const Duration(milliseconds: 120),
      );
      expect(
        find.byKey(const Key('guided-tour-coachmark-plan_my_day_triage')),
        findsOneWidget,
      );

      planStates.emit(const PlanMyDayLoading());
      await tester.pump();
      planStates.emit(readyState);
      await tester.pumpUntilCondition(
        () => find
            .byKey(const Key('guided-tour-coachmark-plan_my_day_triage'))
            .evaluate()
            .isNotEmpty,
      );

      expect(
        find.byKey(const Key('guided-tour-coachmark-plan_my_day_triage')),
        findsOneWidget,
      );
    },
  );

  testWidgetsSafe(
    'scrolls to coachmark target before showing routines step',
    (tester) async {
      const surfaceSize = Size(600, 420);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() async {
        tester.binding.window.devicePixelRatioTestValue = 1.0;
        await tester.binding.setSurfaceSize(null);
      });

      final guidedTourBloc = MockGuidedTourBloc();
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      final steps = [
        GuidedTourStep(
          id: 'plan_my_day_routines',
          route: '/my-day',
          title: 'Routines',
          body: 'Scheduled and flexible routines show up here.',
          kind: GuidedTourStepKind.coachmark,
          coachmark: const GuidedTourCoachmark(
            targetId: 'plan_my_day_routines_block',
            title: 'Routines',
            body: 'Scheduled and flexible routines show up here.',
          ),
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

      when(() => guidedTourBloc.state).thenAnswer(
        (_) => stateController.value ?? initialState,
      );
      whenListen(
        guidedTourBloc,
        stateController.stream,
        initialState: initialState,
      );

      final router = GoRouter(
        initialLocation: '/my-day',
        routes: [
          ShellRoute(
            builder: (_, __, child) => GuidedTourOverlayHost(child: child),
            routes: [
              GoRoute(
                path: '/my-day',
                builder: (_, __) => _ScrollableAnchorPage(
                  controller: scrollController,
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
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );

      expect(scrollController.offset, 0);
      final anchorFinder = find.byKey(GuidedTourAnchors.planMyDayRoutinesBlock);
      final initialRect = tester.getRect(anchorFinder);
      expect(initialRect.top, greaterThan(surfaceSize.height));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        stateController.emit(activeState);
      });
      await tester.pumpForStream();
      await pumpUntilFound(
        tester,
        find.byKey(const Key('guided-tour-coachmark-plan_my_day_routines')),
      );
      await tester.pumpUntilCondition(
        () => tester.getRect(anchorFinder).top < initialRect.top,
      );

      final updatedRect = tester.getRect(anchorFinder);
      expect(updatedRect.top, lessThan(initialRect.top));
      expect(
        find.byKey(const Key('guided-tour-coachmark-plan_my_day_routines')),
        findsOneWidget,
      );
    },
  );
}

class _DelayedAnchorPage extends StatefulWidget {
  const _DelayedAnchorPage();

  @override
  State<_DelayedAnchorPage> createState() => _DelayedAnchorPageState();
}

void _noop() {}

class _FixedNowService implements NowService {
  const _FixedNowService();

  @override
  DateTime nowLocal() => DateTime(2026, 1, 29, 9, 0);

  @override
  DateTime nowUtc() => DateTime.utc(2026, 1, 29, 9);
}

class _DelayedAnchorPageState extends State<_DelayedAnchorPage> {
  var _showAnchor = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _showAnchor = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _showAnchor
            ? SizedBox(
                width: 32,
                height: 32,
                key: GuidedTourAnchors.planMyDayTriage,
              )
            : const SizedBox(width: 32, height: 32),
      ),
    );
  }
}

class _ScrollableAnchorPage extends StatelessWidget {
  const _ScrollableAnchorPage({
    required this.controller,
  });

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: controller,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 900),
              Container(
                key: GuidedTourAnchors.planMyDayRoutinesBlock,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Routines'),
                    SizedBox(height: 12),
                    SizedBox(height: 240),
                  ],
                ),
              ),
              const SizedBox(height: 900),
            ],
          ),
        ),
      ),
    );
  }
}
