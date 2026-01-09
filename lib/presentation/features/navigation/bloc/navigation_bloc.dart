import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:meta/meta.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/system_screen_provider.dart';
import 'package:taskly_bloc/presentation/features/navigation/models/navigation_destination.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_badge_service.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';

@immutable
abstract class NavigationEvent {
  const NavigationEvent();
}

class NavigationStarted extends NavigationEvent {
  const NavigationStarted();
}

class NavigationScreensChanged extends NavigationEvent {
  const NavigationScreensChanged(this.screens);

  final List<ScreenWithPreferences> screens;
}

class NavigationFailed extends NavigationEvent {
  const NavigationFailed(this.error);

  final Object error;
}

enum NavigationStatus { loading, ready, failure }

class NavigationState {
  const NavigationState({
    required this.status,
    required this.destinations,
    this.error,
  });

  const NavigationState.loading()
    : status = NavigationStatus.loading,
      destinations = const [],
      error = null;

  const NavigationState.ready({
    required this.destinations,
  }) : status = NavigationStatus.ready,
       error = null;

  const NavigationState.failure(String message)
    : status = NavigationStatus.failure,
      destinations = const [],
      error = message;

  final NavigationStatus status;
  final List<NavigationDestinationVm> destinations;
  final String? error;
}

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc({
    required ScreenDefinitionsRepositoryContract screensRepository,
    required NavigationBadgeService badgeService,
    required NavigationIconResolver iconResolver,
  }) : _screensRepository = screensRepository,
       _badgeService = badgeService,
       _iconResolver = iconResolver,
       super(const NavigationState.loading()) {
    on<NavigationStarted>(_onStarted, transformer: droppable());
    on<NavigationScreensChanged>(_onScreensChanged, transformer: sequential());
    on<NavigationFailed>(_onFailed, transformer: sequential());
  }

  final ScreenDefinitionsRepositoryContract _screensRepository;
  final NavigationBadgeService _badgeService;
  final NavigationIconResolver _iconResolver;

  StreamSubscription<List<ScreenWithPreferences>>? _screensSub;

  Future<void> _onStarted(
    NavigationStarted event,
    Emitter<NavigationState> emit,
  ) async {
    await _screensSub?.cancel();
    _screensSub = _screensRepository.watchAllScreens().listen(
      (screens) => add(NavigationScreensChanged(screens)),
      onError: (Object error, StackTrace stack) {
        talker.handle(error, stack, 'Failed to watch screens');
        if (!isClosed) add(NavigationFailed(error));
      },
    );
  }

  void _onFailed(
    NavigationFailed event,
    Emitter<NavigationState> emit,
  ) {
    emit(NavigationState.failure(friendlyErrorMessage(event.error)));
  }

  void _onScreensChanged(
    NavigationScreensChanged event,
    Emitter<NavigationState> emit,
  ) {
    try {
      talker.blocLog(
        'NavigationBloc',
        'Received ${event.screens.length} screens from repository',
      );
      for (final screen in event.screens) {
        talker.blocLog(
          'NavigationBloc',
          '  - ${screen.screen.screenKey}: ${screen.screen.name} '
              '(sortOrder: ${screen.effectiveSortOrder})',
        );
      }

      final destinations = event.screens.map(_mapScreen).toList();
      destinations.sort((a, b) {
        final aIsSettings = a.screenId == 'settings';
        final bIsSettings = b.screenId == 'settings';
        if (aIsSettings != bIsSettings) {
          return aIsSettings ? 1 : -1;
        }

        final bySortOrder = a.sortOrder.compareTo(b.sortOrder);
        if (bySortOrder != 0) return bySortOrder;

        // Deterministic ordering when sort orders are equal.
        return a.label.compareTo(b.label);
      });
      emit(NavigationState.ready(destinations: destinations));
    } catch (e, stack) {
      talker.handle(e, stack, 'Failed to process screen changes');
      emit(NavigationState.failure(friendlyErrorMessage(e)));
    }
  }

  NavigationDestinationVm _mapScreen(ScreenWithPreferences screenWithPrefs) {
    final screen = screenWithPrefs.screen;
    final iconSet = _iconResolver.resolve(
      screenId: screen.screenKey,
      iconName: screen.chrome.iconName,
    );

    return NavigationDestinationVm(
      id: screen.id,
      screenId: screen.screenKey,
      label: screen.name,
      icon: iconSet.icon,
      selectedIcon: iconSet.selectedIcon,
      route: Routing.screenPath(screen.screenKey),
      screenSource: screen.screenSource,
      badgeStream: _badgeService.badgeStreamFor(screen),
      sortOrder: screenWithPrefs.effectiveSortOrder,
    );
  }

  @override
  Future<void> close() async {
    await _screensSub?.cancel();
    return super.close();
  }
}
