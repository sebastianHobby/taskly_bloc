import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

@immutable
class AttentionBannerSessionState {
  const AttentionBannerSessionState({required this.dismissedScreenKeys});

  const AttentionBannerSessionState.empty() : dismissedScreenKeys = const {};

  final Set<String> dismissedScreenKeys;

  bool isDismissed(String screenKey) => dismissedScreenKeys.contains(screenKey);
}

/// App-session scoped store for banner dismissal.
///
/// This intentionally does not persist to the DB; it resets on app restart.
class AttentionBannerSessionCubit extends Cubit<AttentionBannerSessionState> {
  AttentionBannerSessionCubit()
    : super(const AttentionBannerSessionState.empty());

  void dismissForScreenKey(String screenKey) {
    if (state.dismissedScreenKeys.contains(screenKey)) return;

    emit(
      AttentionBannerSessionState(
        dismissedScreenKeys: {...state.dismissedScreenKeys, screenKey},
      ),
    );
  }
}
