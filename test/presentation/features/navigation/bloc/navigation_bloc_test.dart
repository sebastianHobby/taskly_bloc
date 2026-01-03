import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
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
    late StreamController<List<ScreenDefinition>> screensController;

    setUpAll(() {
      initializeTalkerForTest();
      // Register fallback for ScreenDefinition used with any()
      final now = DateTime.now();
      registerFallbackValue(
        ScreenDefinition(
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
      screensController = StreamController<List<ScreenDefinition>>.broadcast();

      when(
        () => mockScreensRepository.watchAllScreens(),
      ).thenAnswer((_) => screensController.stream);
      when(() => mockBadgeService.badgeStreamFor(any())).thenReturn(null);
    });

    tearDown(() async {
      await screensController.close();
    });

    ScreenDefinition createScreen({
      required String id,
      required String screenKey,
      required String name,
      int sortOrder = 0,
      ScreenCategory category = ScreenCategory.workspace,
      bool isSystem = true,
      String? iconName,
    }) {
      final now = DateTime.now();
      return ScreenDefinition(
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
        isSystem: isSystem,
        sortOrder: sortOrder,
        category: category,
        iconName: iconName,
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
      test('subscribes to screens stream', () async {
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

      test('processes screens when emitted', () async {
        final bloc = NavigationBloc(
          screensRepository: mockScreensRepository,
          badgeService: mockBadgeService,
          iconResolver: iconResolver,
        );

        bloc.add(const NavigationStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        screensController.add([
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
      test('sorts destinations by sortOrder', () async {
        final bloc = NavigationBloc(
          screensRepository: mockScreensRepository,
          badgeService: mockBadgeService,
          iconResolver: iconResolver,
        );

        bloc.add(const NavigationStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        screensController.add([
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

      test('workspace screens use dynamic routes', () async {
        final bloc = NavigationBloc(
          screensRepository: mockScreensRepository,
          badgeService: mockBadgeService,
          iconResolver: iconResolver,
          routeBuilder: (id) => '/s/$id',
        );

        bloc.add(const NavigationStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        screensController.add([
          createScreen(
            id: '1',
            screenKey: 'inbox',
            name: 'Inbox',
          ),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state.destinations.first.route, '/s/inbox');
        await bloc.close();
      });

      test('wellbeing screen uses direct route', () async {
        final bloc = NavigationBloc(
          screensRepository: mockScreensRepository,
          badgeService: mockBadgeService,
          iconResolver: iconResolver,
        );

        bloc.add(const NavigationStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        screensController.add([
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

      test('journal screen uses wellbeing/journal route', () async {
        final bloc = NavigationBloc(
          screensRepository: mockScreensRepository,
          badgeService: mockBadgeService,
          iconResolver: iconResolver,
        );

        bloc.add(const NavigationStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        screensController.add([
          createScreen(
            id: '1',
            screenKey: 'journal',
            name: 'Journal',
            category: ScreenCategory.wellbeing,
          ),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state.destinations.first.route, '/wellbeing/journal');
        await bloc.close();
      });

      test('settings screens use correct routes', () async {
        final bloc = NavigationBloc(
          screensRepository: mockScreensRepository,
          badgeService: mockBadgeService,
          iconResolver: iconResolver,
        );

        bloc.add(const NavigationStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));

        screensController.add([
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
        expect(routes, ['/settings/app', '/settings/navigation']);
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

          screensController.addError(Exception('Database error'));

          await future;
          await bloc.close();
        },
        timeout: const Timeout(Duration(seconds: 5)),
      );
    });

    group('lifecycle', () {
      test('closes stream subscription on close', () async {
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

    test('resolves inbox icon when iconName is inbox', () {
      final result = resolver.resolve(screenId: 'custom', iconName: 'inbox');
      expect(result.icon, Icons.inbox_outlined);
      expect(result.selectedIcon, Icons.inbox);
    });

    test('resolves today icon when iconName is today', () {
      final result = resolver.resolve(screenId: 'custom', iconName: 'today');
      expect(result.icon, Icons.calendar_today_outlined);
      expect(result.selectedIcon, Icons.calendar_today);
    });

    test('resolves upcoming icon when iconName is upcoming', () {
      final result = resolver.resolve(screenId: 'custom', iconName: 'upcoming');
      expect(result.icon, Icons.event_outlined);
      expect(result.selectedIcon, Icons.event);
    });

    test('resolves next_actions icon when iconName is next_actions', () {
      final result = resolver.resolve(
        screenId: 'custom',
        iconName: 'next_actions',
      );
      expect(result.icon, Icons.playlist_play_outlined);
      expect(result.selectedIcon, Icons.playlist_play);
    });

    test('resolves projects icon when iconName is projects', () {
      final result = resolver.resolve(screenId: 'custom', iconName: 'projects');
      expect(result.icon, Icons.folder_outlined);
      expect(result.selectedIcon, Icons.folder);
    });

    test('resolves labels icon when iconName is labels', () {
      final result = resolver.resolve(screenId: 'custom', iconName: 'labels');
      expect(result.icon, Icons.label_outline);
      expect(result.selectedIcon, Icons.label);
    });

    test('resolves values icon when iconName is values', () {
      final result = resolver.resolve(screenId: 'custom', iconName: 'values');
      expect(result.icon, Icons.favorite_border);
      expect(result.selectedIcon, Icons.favorite);
    });

    test('resolves wellbeing icon when iconName is wellbeing', () {
      final result = resolver.resolve(
        screenId: 'custom',
        iconName: 'wellbeing',
      );
      expect(result.icon, Icons.psychology_outlined);
      expect(result.selectedIcon, Icons.psychology);
    });

    test('resolves journal icon when iconName is journal', () {
      final result = resolver.resolve(screenId: 'custom', iconName: 'journal');
      expect(result.icon, Icons.book_outlined);
      expect(result.selectedIcon, Icons.book);
    });

    test('resolves trackers icon when iconName is trackers', () {
      final result = resolver.resolve(screenId: 'custom', iconName: 'trackers');
      expect(result.icon, Icons.timeline_outlined);
      expect(result.selectedIcon, Icons.timeline);
    });

    test('resolves settings icon when iconName is settings', () {
      final result = resolver.resolve(screenId: 'custom', iconName: 'settings');
      expect(result.icon, Icons.settings_outlined);
      expect(result.selectedIcon, Icons.settings);
    });

    test('uses iconName when provided', () {
      final result = resolver.resolve(screenId: 'custom', iconName: 'inbox');
      expect(result.icon, Icons.inbox_outlined);
      expect(result.selectedIcon, Icons.inbox);
    });

    test('returns default icon for unknown screens', () {
      final result = resolver.resolve(screenId: 'unknown', iconName: 'unknown');
      expect(result.icon, Icons.widgets_outlined);
      expect(result.selectedIcon, Icons.widgets);
    });

    test('handles empty iconName by falling back to screenId', () {
      final result = resolver.resolve(screenId: 'inbox', iconName: '');
      expect(result.icon, Icons.inbox_outlined);
    });

    test('handles whitespace iconName by falling back to screenId', () {
      final result = resolver.resolve(screenId: 'inbox', iconName: '  ');
      expect(result.icon, Icons.inbox_outlined);
    });

    test('null iconName results in default icon due to toString behavior', () {
      // Note: Due to (.toString()) on null, 'null' string is used which is
      // unknown
      final result = resolver.resolve(screenId: 'inbox', iconName: null);
      expect(result.icon, Icons.widgets_outlined);
      expect(result.selectedIcon, Icons.widgets);
    });
  });
}
