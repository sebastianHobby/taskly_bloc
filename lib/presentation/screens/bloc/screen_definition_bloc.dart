import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/system_screen_provider.dart';

part 'screen_definition_bloc.freezed.dart';

@freezed
sealed class ScreenDefinitionEvent with _$ScreenDefinitionEvent {
  const factory ScreenDefinitionEvent.subscriptionRequested({
    required String screenKey,
  }) = _SubscriptionRequested;
}

@freezed
sealed class ScreenDefinitionState with _$ScreenDefinitionState {
  const factory ScreenDefinitionState.loading() = _Loading;

  const factory ScreenDefinitionState.loaded({
    required ScreenDefinition screen,
  }) = _Loaded;

  const factory ScreenDefinitionState.notFound() = _NotFound;

  const factory ScreenDefinitionState.error({
    required Object error,
    required StackTrace stackTrace,
  }) = _Error;
}

/// BLoC that manages loading and watching a single screen definition.
///
/// ## Race Condition Prevention
///
/// This bloc assumes that it will only be created/used AFTER the user is
/// fully authenticated and system data is available. The [AuthBloc]
/// ensures this by:
/// 1. Waiting for PowerSync sync to establish initial data
/// 2. Only emitting [AuthStatus.authenticated] after sync completes
///
/// System screens are generated from code ([SystemScreenDefinitions]) not
/// from database, so they're always immediately available without seeding.
///
/// Attention rules are seeded via [AttentionSeeder] during initial sync.
///
/// UI components should only render screens (and thus create this bloc)
/// when auth status is [AuthStatus.authenticated].
class ScreenDefinitionBloc
    extends Bloc<ScreenDefinitionEvent, ScreenDefinitionState> {
  ScreenDefinitionBloc({
    required ScreenDefinitionsRepositoryContract repository,
  }) : _repository = repository,
       _createdAt = DateTime.now(),
       super(const ScreenDefinitionState.loading()) {
    talker.blocLog('ScreenDefinitionBloc', 'CREATED at $_createdAt');
    on<_SubscriptionRequested>(
      _onSubscriptionRequested,
      transformer: restartable(),
    );
  }

  final ScreenDefinitionsRepositoryContract _repository;
  final DateTime _createdAt;
  String? _currentScreenKey;

  @override
  Future<void> close() {
    talker.blocLog(
      'ScreenDefinitionBloc',
      'CLOSING - was created at $_createdAt, screenKey=$_currentScreenKey',
    );
    return super.close();
  }

  Future<void> _onSubscriptionRequested(
    _SubscriptionRequested event,
    Emitter<ScreenDefinitionState> emit,
  ) async {
    _currentScreenKey = event.screenKey;
    talker.blocLog(
      'ScreenDefinition',
      '_onSubscriptionRequested START for screenKey="${event.screenKey}"',
    );
    emit(const ScreenDefinitionState.loading());

    // Track whether we've received a valid screen (for deletion detection)
    var receivedScreen = false;

    try {
      await emit.forEach<ScreenWithPreferences?>(
        _repository.watchScreen(event.screenKey),
        onData: (screenWithPrefs) {
          final screen = screenWithPrefs?.screen;
          talker.blocLog(
            'ScreenDefinition',
            'onData: screen=${screen == null ? "null" : "ScreenDefinition(screenKey=${screen.screenKey})"}',
          );

          if (screen != null) {
            receivedScreen = true;
            return ScreenDefinitionState.loaded(screen: screen);
          }

          // If we previously had a screen and now it's null, it was deleted
          if (receivedScreen) {
            talker.blocLog(
              'ScreenDefinition',
              'Previously had screen, now null -> notFound (deleted)',
            );
            return const ScreenDefinitionState.notFound();
          }

          // Screen doesn't exist - no grace period needed since AuthBloc
          // guarantees seeding is complete before authenticated status
          talker.blocLog('ScreenDefinition', 'Screen not found');
          return const ScreenDefinitionState.notFound();
        },
        onError: (error, stackTrace) {
          talker.handle(
            error,
            stackTrace,
            '[ScreenDefinitionBloc] Stream error',
          );
          return ScreenDefinitionState.error(
            error: error,
            stackTrace: stackTrace,
          );
        },
      );
      talker.blocLog('ScreenDefinition', 'emit.forEach completed normally');
    } catch (e, st) {
      talker.handle(
        e,
        st,
        '[ScreenDefinitionBloc] emit.forEach threw exception',
      );
      rethrow;
    } finally {
      talker.blocLog(
        'ScreenDefinition',
        '_onSubscriptionRequested END for screenKey="${event.screenKey}"',
      );
    }
  }
}
