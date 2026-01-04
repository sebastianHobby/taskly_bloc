import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/bloc_test_patterns.dart';
import '../../../../helpers/test_helpers.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/system_screen_provider.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/screen_source.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/settings/screen_preferences.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/presentation/features/navigation/bloc/navigation_bloc.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_badge_service.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';

class MockScreenDefinitionsRepositoryContract extends Mock
    implements ScreenDefinitionsRepositoryContract {}

class MockNavigationBadgeService extends Mock
    implements NavigationBadgeService {}

void main() {
  group('NavigationBloc', () {
    late MockScreenDefinitionsRepositoryContract mockScreensRepository;
    late MockNavigationBadgeService mockBadgeService;
    late NavigationIconResolver iconResolver;
    late TestStreamController<List<ScreenWithPreferences>> screensController;

    setUpAll(() {
      initializeTalkerForTest();
      // Register fallback for ScreenDefinition used with any()
      final now = DateTime.now();
      registerFallbackValue(
        DataDrivenScreenDefinition(
          id: 'fallback-id',
          screenKey: 'fallback',
          name: 'Fallback',
          screenType: ScreenType.list,
          sections: [
            Section.data(
              config: DataConfig.task(query: TaskQuery.all()),
            ),
          ],
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    setUp(() {
      mockScreensRepository = MockScreenDefinitionsRepositoryContract();
      mockBadgeService = MockNavigationBadgeService();
      iconResolver = const NavigationIconResolver();
      screensController = TestStreamController<List<ScreenWithPreferences>>();

      when(
        () => mockScreensRepository.watchAllScreens(),
      ).thenAnswer((_) => screensController.stream);
      when(() => mockBadgeService.badgeStreamFor(any())).thenReturn(null);
    });

    tearDown(() async {
      await screensController.close();
    });

    ScreenWithPreferences createScreen({
      required String id,
      required String screenKey,
      required String name,
      int sortOrder = 0,
      ScreenCategory category = ScreenCategory.workspace,
      ScreenSource screenSource = ScreenSource.systemTemplate,
      bool isActive = true,
      String? iconName,
    }) {
      final now = DateTime.now();
      final screen = DataDrivenScreenDefinition(
        id: id,
        screenKey: screenKey,
        name: name,
        screenType: ScreenType.list,
        sections: [
          Section.data(
            config: DataConfig.task(query: TaskQuery.all()),
          ),
        ],
        createdAt: now,
        updatedAt: now,
        screenSource: screenSource,
        category: category,
        iconName: iconName,
      );
      return ScreenWithPreferences(
        screen: screen,
        preferences: ScreenPreferences(
          sortOrder: sortOrder,
          isActive: isActive,
        ),
      );
    }

    group('initial state', () {
      test('is loading', () {
        final bloc = NavigationBloc(
          screensRepository: mockScreensRepository,
          badgeService: mockBadgeService,
          iconResolver: iconResolver,
        );

        expect(bloc.state.status, NavigationStatus.loading);
        expect(bloc.state.destinations, isEmpty);
        expect(bloc.state.error, isNull);
      });
    });

    group('NavigationStarted', () {
      testSafe('subscribes to screens stream', () async {
        final bloc = NavigationBloc(
          screensRepository: mockScreensRepository,
          badgeService: mockBadgeService,
          iconResolver: iconResolver,
        );

        bloc.add(const NavigationStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        verify(() => mockScreensRepository.watchAllScreens()).called(1);
        await bloc.close();
      });

      testSafe('processes screens when emitted', () async {
        final bloc = NavigationBloc(
          screensRepository: mockScreensRepository,
          badgeService: mockBadgeService,
          iconResolver: iconResolver,
        );

        bloc.add(const NavigationStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        screensController.emit([
          createScreen(id: '1', screenKey: 'inbox', name: 'Inbox'),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state.status, NavigationStatus.ready);
        expect(bloc.state.destinations.length, 1);
        expect(bloc.state.destinations.first.label, 'Inbox');
        await bloc.close();
      });
    });

    group('screen mapping', () {
      testSafe('sorts destinations by sortOrder', () async {
        final bloc = NavigationBloc(
          screensRepository: mockScreensRepository,
          badgeService: mockBadgeService,
          iconResolver: iconResolver,
        );

        bloc.add(const NavigationStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        screensController.emit([
          createScreen(
            id: '3',
            screenKey: 'upcoming',
            name: 'Upcoming',
            sortOrder: 2,
          ),
          createScreen(id: '1', screenKey: 'inbox', name: 'Inbox'),
          createScreen(
            id: '2',
            screenKey: 'today',
            name: 'Today',
            sortOrder: 1,
          ),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final labels = bloc.state.destinations.map((d) => d.label).toList();
        expect(labels, ['Inbox', 'Today', 'Upcoming']);
        await bloc.close();
      });

      testSafe('workspace screens use convention-based routes', () async {
        final bloc = NavigationBloc(
          screensRepository: mockScreensRepository,
          badgeService: mockBadgeService,
          iconResolver: iconResolver,
        );

        bloc.add(const NavigationStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        screensController.emit([
          createScreen(
            id: '1',
            screenKey: 'inbox',
            name: 'Inbox',
          ),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state.destinations.first.route, '/inbox');
        await bloc.close();
      });

      testSafe('wellbeing screen uses direct route', () async {
        final bloc = NavigationBloc(
          screensRepository: mockScreensRepository,
          badgeService: mockBadgeService,
          iconResolver: iconResolver,
        );

        bloc.add(const NavigationStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        screensController.emit([
          createScreen(
            id: '1',
            screenKey: 'wellbeing',
            name: 'Wellbeing',
            category: ScreenCategory.wellbeing,
          ),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state.destinations.first.route, '/wellbeing');
        await bloc.close();
      });

      testSafe('journal screen uses convention-based route', () async {
        final bloc = NavigationBloc(
          screensRepository: mockScreensRepository,
          badgeService: mockBadgeService,
          iconResolver: iconResolver,
        );

        bloc.add(const NavigationStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        screensController.emit([
          createScreen(
            id: '1',
            screenKey: 'journal',
            name: 'Journal',
            category: ScreenCategory.wellbeing,
          ),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state.destinations.first.route, '/journal');
        await bloc.close();
      });

      testSafe('settings screens use convention-based routes', () async {
        final bloc = NavigationBloc(
          screensRepository: mockScreensRepository,
          badgeService: mockBadgeService,
          iconResolver: iconResolver,
        );

        bloc.add(const NavigationStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        screensController.emit([
          createScreen(
            id: '1',
            screenKey: 'settings',
            name: 'Settings',
            category: ScreenCategory.settings,
          ),
          createScreen(
            id: '2',
            screenKey: 'navigation_settings',
            name: 'Navigation',
            sortOrder: 1,
            category: ScreenCategory.settings,
          ),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final routes = bloc.state.destinations.map((d) => d.route).toList();
        expect(routes, ['/settings', '/navigation-settings']);
        await bloc.close();
      });
    });

    group('error handling', () {
      test(
        'emits failure state on stream error',
        () async {
          final bloc = NavigationBloc(
            screensRepository: mockScreensRepository,
            badgeService: mockBadgeService,
            iconResolver: iconResolver,
          );

          // Set up expectation before triggering events
          final future = expectLater(
            bloc.stream,
            emitsThrough(
              isA<NavigationState>()
                  .having((s) => s.status, 'status', NavigationStatus.failure)
                  .having((s) => s.error, 'error', isNotNull),
            ),
          );

          bloc.add(const NavigationStarted());
          await Future<void>.delayed(const Duration(milliseconds: 50));

          screensController.emitError(Exception('Database error'));

          await future;
          await bloc.close();
        },
        timeout: const Timeout(Duration(seconds: 5)),
      );
    });

    group('lifecycle', () {
      testSafe('closes stream subscription on close', () async {
        final bloc = NavigationBloc(
          screensRepository: mockScreensRepository,
          badgeService: mockBadgeService,
          iconResolver: iconResolver,
        );

        bloc.add(const NavigationStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(screensController.hasListener, isTrue);

        await bloc.close();
      });
    });
  });

  group('NavigationIconResolver', () {
    late NavigationIconResolver resolver;

    setUp(() {
      resolver = const NavigationIconResolver();
    });

    // ─────────────────────────────────────────────────────────────────
    // System screens (resolved by screenId - the single source of truth)
    // ─────────────────────────────────────────────────────────────────

    test('resolves inbox icon by screenId', () {
      final result = resolver.resolve(screenId: 'inbox', iconName: null);
      expect(result.icon, Icons.inbox_outlined);
      expect(result.selectedIcon, Icons.inbox);
    });

    test('resolves today icon by screenId (legacy, maps to my_day icon)', () {
      final result = resolver.resolve(screenId: 'today', iconName: null);
      // Legacy 'today' now maps to my_day icon (wb_sunny)
      expect(result.icon, Icons.wb_sunny_outlined);
      expect(result.selectedIcon, Icons.wb_sunny);
    });

    test('resolves upcoming icon by screenId', () {
      final result = resolver.resolve(screenId: 'upcoming', iconName: null);
      expect(result.icon, Icons.event_outlined);
      expect(result.selectedIcon, Icons.event);
    });

    test('resolves planned icon by screenId', () {
      final result = resolver.resolve(screenId: 'planned', iconName: null);
      expect(result.icon, Icons.event_outlined);
      expect(result.selectedIcon, Icons.event);
    });

    test('resolves logbook icon by screenId', () {
      final result = resolver.resolve(screenId: 'logbook', iconName: null);
      expect(result.icon, Icons.done_all_outlined);
      expect(result.selectedIcon, Icons.done_all);
    });

    test('resolves next_actions icon by screenId (legacy, maps to my_day)', () {
      final result = resolver.resolve(screenId: 'next_actions', iconName: null);
      // Legacy 'next_actions' now maps to my_day icon (wb_sunny)
      expect(result.icon, Icons.wb_sunny_outlined);
      expect(result.selectedIcon, Icons.wb_sunny);
    });

    test('resolves projects icon by screenId', () {
      final result = resolver.resolve(screenId: 'projects', iconName: null);
      expect(result.icon, Icons.folder_outlined);
      expect(result.selectedIcon, Icons.folder);
    });

    test('resolves labels icon by screenId', () {
      final result = resolver.resolve(screenId: 'labels', iconName: null);
      expect(result.icon, Icons.label_outline);
      expect(result.selectedIcon, Icons.label);
    });

    test('resolves values icon by screenId', () {
      final result = resolver.resolve(screenId: 'values', iconName: null);
      expect(result.icon, Icons.star_outline);
      expect(result.selectedIcon, Icons.star);
    });

    test('resolves wellbeing icon by screenId', () {
      final result = resolver.resolve(screenId: 'wellbeing', iconName: null);
      expect(result.icon, Icons.self_improvement_outlined);
      expect(result.selectedIcon, Icons.self_improvement);
    });

    test('resolves journal icon by screenId', () {
      final result = resolver.resolve(screenId: 'journal', iconName: null);
      // Journal uses book icon
      expect(result.icon, Icons.book_outlined);
      expect(result.selectedIcon, Icons.book);
    });

    test('resolves workflows icon by screenId', () {
      final result = resolver.resolve(screenId: 'workflows', iconName: null);
      expect(result.icon, Icons.account_tree_outlined);
      expect(result.selectedIcon, Icons.account_tree);
    });

    test('resolves screen_management icon by screenId', () {
      final result = resolver.resolve(
        screenId: 'screen_management',
        iconName: null,
      );
      expect(result.icon, Icons.dashboard_customize_outlined);
      expect(result.selectedIcon, Icons.dashboard_customize);
    });

    test('resolves settings icon by screenId', () {
      final result = resolver.resolve(screenId: 'settings', iconName: null);
      expect(result.icon, Icons.settings_outlined);
      expect(result.selectedIcon, Icons.settings);
    });

    // ─────────────────────────────────────────────────────────────────
    // Custom screens (fall back to iconName when screenId unknown)
    // ─────────────────────────────────────────────────────────────────

    test('uses iconName when screenId is unknown', () {
      final result = resolver.resolve(screenId: 'custom', iconName: 'star');
      expect(result.icon, Icons.star_outline);
      expect(result.selectedIcon, Icons.star);
    });

    test('resolves folder iconName for custom screen', () {
      final result = resolver.resolve(screenId: 'custom', iconName: 'folder');
      expect(result.icon, Icons.folder_outlined);
      expect(result.selectedIcon, Icons.folder);
    });

    test('resolves label iconName for custom screen', () {
      final result = resolver.resolve(screenId: 'custom', iconName: 'label');
      expect(result.icon, Icons.label_outline);
      expect(result.selectedIcon, Icons.label);
    });

    test('returns default icon for unknown screenId and iconName', () {
      final result = resolver.resolve(screenId: 'unknown', iconName: 'unknown');
      expect(result.icon, Icons.widgets_outlined);
      expect(result.selectedIcon, Icons.widgets);
    });

    // ─────────────────────────────────────────────────────────────────
    // Priority: screenId takes precedence over iconName
    // ─────────────────────────────────────────────────────────────────

    test('screenId takes priority over iconName for system screens', () {
      // Even if iconName is 'folder', screenId 'inbox' wins
      final result = resolver.resolve(screenId: 'inbox', iconName: 'folder');
      expect(result.icon, Icons.inbox_outlined);
      expect(result.selectedIcon, Icons.inbox);
    });

    test('handles empty iconName by using screenId', () {
      final result = resolver.resolve(screenId: 'inbox', iconName: '');
      expect(result.icon, Icons.inbox_outlined);
    });

    test('handles whitespace iconName by using screenId', () {
      final result = resolver.resolve(screenId: 'inbox', iconName: '  ');
      expect(result.icon, Icons.inbox_outlined);
    });

    test('handles null iconName by using screenId', () {
      final result = resolver.resolve(screenId: 'inbox', iconName: null);
      expect(result.icon, Icons.inbox_outlined);
      expect(result.selectedIcon, Icons.inbox);
    });
  });
}
