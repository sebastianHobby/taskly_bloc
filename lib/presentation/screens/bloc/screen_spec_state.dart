import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data.dart';

@immutable
sealed class ScreenSpecState {
  const ScreenSpecState();
}

final class ScreenSpecInitialState extends ScreenSpecState {
  const ScreenSpecInitialState();
}

final class ScreenSpecLoadingState extends ScreenSpecState {
  const ScreenSpecLoadingState({required this.spec});

  final ScreenSpec spec;
}

final class ScreenSpecLoadedState extends ScreenSpecState {
  const ScreenSpecLoadedState({required this.data});

  final ScreenSpecData data;
}

final class ScreenSpecErrorState extends ScreenSpecState {
  const ScreenSpecErrorState({required this.message, required this.spec});

  final String message;
  final ScreenSpec spec;
}
