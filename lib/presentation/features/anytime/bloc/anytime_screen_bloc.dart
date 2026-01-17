import 'package:bloc/bloc.dart';

sealed class AnytimeScreenEvent {
  const AnytimeScreenEvent();
}

final class AnytimeFocusOnlyToggled extends AnytimeScreenEvent {
  const AnytimeFocusOnlyToggled();
}

final class AnytimeFocusOnlySet extends AnytimeScreenEvent {
  const AnytimeFocusOnlySet(this.enabled);

  final bool enabled;
}

sealed class AnytimeScreenState {
  const AnytimeScreenState({required this.focusOnly});

  final bool focusOnly;
}

final class AnytimeScreenReady extends AnytimeScreenState {
  const AnytimeScreenReady({required super.focusOnly});
}

class AnytimeScreenBloc extends Bloc<AnytimeScreenEvent, AnytimeScreenState> {
  AnytimeScreenBloc() : super(const AnytimeScreenReady(focusOnly: false)) {
    on<AnytimeFocusOnlyToggled>((event, emit) {
      emit(AnytimeScreenReady(focusOnly: !state.focusOnly));
    });
    on<AnytimeFocusOnlySet>((event, emit) {
      emit(AnytimeScreenReady(focusOnly: event.enabled));
    });
  }
}
