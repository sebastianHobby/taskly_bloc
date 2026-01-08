import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';

part 'screen_event.freezed.dart';

/// Events for the thin ScreenBloc.
///
/// Note: Entity actions (complete, delete, etc.) are handled directly
/// by widgets via [EntityActionService], not through the bloc.
@freezed
sealed class ScreenEvent with _$ScreenEvent {
  /// Load screen by definition and start watching for changes.
  const factory ScreenEvent.load({
    required ScreenDefinition definition,
  }) = ScreenLoadEvent;

  /// Load screen by ID (fetches definition from repository first).
  const factory ScreenEvent.loadById({
    required String screenId,
  }) = ScreenLoadByIdEvent;
}
