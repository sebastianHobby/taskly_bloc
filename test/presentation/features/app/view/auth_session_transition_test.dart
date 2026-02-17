@Tags(['unit', 'app'])
library;

import '../../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/app/view/auth_session_transition.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';

void main() {
  testSafe('handles unauthenticated -> authenticated transition', () async {
    final shouldHandle = shouldHandleAuthSessionTransition(
      previous: AuthStatus.unauthenticated,
      current: AuthStatus.authenticated,
    );

    expect(shouldHandle, isTrue);
  });

  testSafe('handles authenticated -> unauthenticated transition', () async {
    final shouldHandle = shouldHandleAuthSessionTransition(
      previous: AuthStatus.authenticated,
      current: AuthStatus.unauthenticated,
    );

    expect(shouldHandle, isTrue);
  });

  testSafe('ignores authenticated -> loading transition', () async {
    final shouldHandle = shouldHandleAuthSessionTransition(
      previous: AuthStatus.authenticated,
      current: AuthStatus.loading,
    );

    expect(shouldHandle, isFalse);
  });

  testSafe('handles loading -> authenticated transition', () async {
    final shouldHandle = shouldHandleAuthSessionTransition(
      previous: AuthStatus.loading,
      current: AuthStatus.authenticated,
    );

    expect(shouldHandle, isTrue);
  });
}
