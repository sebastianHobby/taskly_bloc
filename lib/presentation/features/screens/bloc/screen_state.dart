import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data.dart';

part 'screen_state.freezed.dart';

/// State for the thin ScreenBloc.
@freezed
sealed class ScreenState with _$ScreenState {
  /// Initial state before loading.
  const factory ScreenState.initial() = ScreenInitialState;

  /// Loading state while fetching screen data.
  const factory ScreenState.loading({
    ScreenDefinition? definition,
  }) = ScreenLoadingState;

  /// Loaded state with screen data from interpreter.
  const factory ScreenState.loaded({
    required ScreenData data,
    @Default(false) bool isRefreshing,
  }) = ScreenLoadedState;

  /// Error state.
  const factory ScreenState.error({
    required String message,
    ScreenDefinition? definition,
    Object? error,
    StackTrace? stackTrace,
  }) = ScreenErrorState;
}
