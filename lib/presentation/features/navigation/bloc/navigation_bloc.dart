import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
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

  final List<ScreenDefinition> screens;
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
    required List<NavigationDestinationVm> destinations,
  }) : status = NavigationStatus.ready,
       destinations = destinations,
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
    String Function(String screenId)? routeBuilder,
  }) : _screensRepository = screensRepository,
       _badgeService = badgeService,
       _iconResolver = iconResolver,
       _routeBuilder = routeBuilder ?? ((id) => '/s/$id'),
       super(const NavigationState.loading()) {
    on<NavigationStarted>(_onStarted);
    on<NavigationScreensChanged>(_onScreensChanged);
  }

  final ScreenDefinitionsRepositoryContract _screensRepository;
  final NavigationBadgeService _badgeService;
  final NavigationIconResolver _iconResolver;
  final String Function(String screenId) _routeBuilder;

  StreamSubscription<List<ScreenDefinition>>? _screensSub;

  Future<void> _onStarted(
    NavigationStarted event,
    Emitter<NavigationState> emit,
  ) async {
    await _screensSub?.cancel();
    _screensSub = _screensRepository.watchAllScreens().listen(
      (screens) => add(NavigationScreensChanged(screens)),
      onError: (Object error, StackTrace stack) {
        talker.handle(error, stack, 'Failed to watch screens');
        emit(NavigationState.failure(friendlyErrorMessage(error)));
      },
    );
  }

  void _onScreensChanged(
    NavigationScreensChanged event,
    Emitter<NavigationState> emit,
  ) {
    try {
      final destinations = event.screens.map(_mapScreen).toList();
      destinations.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      emit(NavigationState.ready(destinations: destinations));
    } catch (e, stack) {
      talker.handle(e, stack, 'Failed to process screen changes');
      emit(NavigationState.failure(friendlyErrorMessage(e)));
    }
  }

  NavigationDestinationVm _mapScreen(ScreenDefinition screen) {
    final iconSet = _iconResolver.resolve(
      screenId: screen.screenId,
      iconName: screen.iconName,
    );

    return NavigationDestinationVm(
      id: screen.id,
      screenId: screen.screenId,
      label: screen.name,
      icon: iconSet.icon,
      selectedIcon: iconSet.selectedIcon,
      route: _routeBuilder(screen.screenId),
      isSystem: screen.isSystem,
      badgeStream: _badgeService.badgeStreamFor(screen),
      sortOrder: screen.sortOrder,
    );
  }

  @override
  Future<void> close() async {
    await _screensSub?.cancel();
    return super.close();
  }
}
