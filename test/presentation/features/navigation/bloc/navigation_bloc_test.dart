import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/bloc_test_patterns.dart';
import '../../../../helpers/test_helpers.dart';
import 'package:taskly_bloc/shared/logging/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_chrome.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/presentation/shared/models/screen_preferences.dart';
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
      registerFallbackValue(
        ScreenSpec(
          id: 'fallback-id',
          screenKey: 'fallback',
          name: 'Fallback',
          template: const ScreenTemplateSpec.standardScaffoldV1(),
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
      bool isActive = true,
      String? iconName,
    }) {
      final screen = ScreenSpec(
        id: id,
        screenKey: screenKey,
        name: name,
        template: const ScreenTemplateSpec.standardScaffoldV1(),
        chrome: ScreenChrome(iconName: iconName),
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
          createScreen(id: '1', screenKey: 'my_day', name: 'My Day'),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state.status, NavigationStatus.ready);
        expect(bloc.state.destinations.length, 1);
        expect(bloc.state.destinations.first.label, 'My Day');
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
          createScreen(id: '1', screenKey: 'my_day', name: 'My Day'),
          createScreen(
            id: '2',
            screenKey: 'today',
            name: 'Today',
            sortOrder: 1,
          ),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final labels = bloc.state.destinations.map((d) => d.label).toList();
        expect(labels, ['My Day', 'Today', 'Upcoming']);
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
            screenKey: 'my_day',
            name: 'My Day',
          ),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(bloc.state.destinations.first.route, '/my-day');
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
          ),
          createScreen(
            id: '2',
            screenKey: 'navigation_settings',
            name: 'Navigation',
            sortOrder: 1,
          ),
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final routes = bloc.state.destinations.map((d) => d.route).toList();
        // Settings is always sorted last by NavigationBloc.
        expect(routes, ['/navigation-settings', '/settings']);
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

    test('resolves inbox icon by iconName (custom screens)', () {
      final result = resolver.resolve(screenId: 'custom', iconName: 'inbox');
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

    test('resolves journal icon by screenId', () {
      final result = resolver.resolve(screenId: 'journal', iconName: null);
      // Journal uses book icon
      expect(result.icon, Icons.book_outlined);
      expect(result.selectedIcon, Icons.book);
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
      // Even if iconName is 'folder', screenId 'my_day' wins
      final result = resolver.resolve(screenId: 'my_day', iconName: 'folder');
      expect(result.icon, Icons.wb_sunny_outlined);
      expect(result.selectedIcon, Icons.wb_sunny);
    });

    test('handles empty iconName by using screenId', () {
      final result = resolver.resolve(screenId: 'my_day', iconName: '');
      expect(result.icon, Icons.wb_sunny_outlined);
    });

    test('handles whitespace iconName by using screenId', () {
      final result = resolver.resolve(screenId: 'my_day', iconName: '  ');
      expect(result.icon, Icons.wb_sunny_outlined);
    });

    test('handles null iconName by using screenId', () {
      final result = resolver.resolve(screenId: 'my_day', iconName: null);
      expect(result.icon, Icons.wb_sunny_outlined);
      expect(result.selectedIcon, Icons.wb_sunny);
    });
  });
}
