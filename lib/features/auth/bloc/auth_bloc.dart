import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_bloc/domain/contracts/auth_repository_contract.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC that manages authentication state.
///
/// Listens to auth state changes from the repository and provides
/// actions for sign in, sign up, sign out, and password reset.
class AuthBloc extends Bloc<AuthEvent, AppAuthState> {
  AuthBloc({required AuthRepositoryContract authRepository})
    : _authRepository = authRepository,
      super(const AppAuthState()) {
    on<AuthSubscriptionRequested>(_onSubscriptionRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<_AuthStateChanged>(_onAuthStateChanged);
  }

  final AuthRepositoryContract _authRepository;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onSubscriptionRequested(
    AuthSubscriptionRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    await _authSubscription?.cancel();

    // Emit initial state based on current session
    final session = _authRepository.currentSession;
    if (session != null) {
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: session.user,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
        ),
      );
    }

    // Listen to auth state changes
    _authSubscription = _authRepository.watchAuthState().listen(
      (authState) {
        add(_AuthStateChanged(authState));
      },
    );
  }

  void _onAuthStateChanged(
    _AuthStateChanged event,
    Emitter<AppAuthState> emit,
  ) {
    final session = event.authState.session;
    if (session != null) {
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: session.user,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
        ),
      );
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final response = await _authRepository.signInWithPassword(
        email: event.email,
        password: event.password,
      );

      if (response.session != null) {
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: response.user,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            error: 'Sign in failed',
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final response = await _authRepository.signUp(
        email: event.email,
        password: event.password,
      );

      if (response.session != null) {
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: response.user,
          ),
        );
      } else {
        // Email confirmation might be required
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            message: 'Check your email to confirm your account',
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    try {
      await _authRepository.signOut();
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      await _authRepository.resetPasswordForEmail(event.email);
      emit(
        state.copyWith(
          status: state.status == AuthStatus.authenticated
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated,
          message: 'Password reset email sent',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: state.status == AuthStatus.authenticated
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated,
          error: error.toString(),
        ),
      );
    }
  }
}
