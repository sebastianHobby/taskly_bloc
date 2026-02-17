import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';

bool shouldHandleAuthSessionTransition({
  required AuthStatus previous,
  required AuthStatus current,
}) {
  final becameAuthenticated =
      previous != AuthStatus.authenticated &&
      current == AuthStatus.authenticated;
  final becameUnauthenticated =
      previous == AuthStatus.authenticated &&
      current == AuthStatus.unauthenticated;
  return becameAuthenticated || becameUnauthenticated;
}
