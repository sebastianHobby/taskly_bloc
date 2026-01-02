import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/user_data_seeder_contract.dart';
import 'package:taskly_bloc/domain/interfaces/auth_repository_contract.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC that manages authentication state.
///
/// Listens to auth state changes from the repository and provides
/// actions for sign in, sign up, sign out, and password reset.
class AuthBloc extends Bloc<AuthEvent, AppAuthState> {
  AuthBloc({
    required AuthRepositoryContract authRepository,
    required UserDataSeederContract userDataSeeder,
  }) : _authRepository = authRepository,
       _userDataSeeder = userDataSeeder,
       super(const AppAuthState()) {
    talker.blocLog('Auth', 'AuthBloc CONSTRUCTOR called');
    on<AuthSubscriptionRequested>(_onSubscriptionRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    on<_AuthStateChanged>(_onAuthStateChanged);
    talker.blocLog(
      'Auth',
      'AuthBloc CONSTRUCTOR done, event handlers registered',
    );
  }

  final AuthRepositoryContract _authRepository;
  final UserDataSeederContract _userDataSeeder;
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
    talker.blocLog(
      'Auth',
      '_onSubscriptionRequested: session=${session != null ? "exists" : "null"}',
    );
    if (session != null) {
      talker.blocLog(
        'Auth',
        'Initial session found, emitting authenticated state',
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: session.user,
        ),
      );
      // Seed user data for existing session (user was already logged in)
      // This ensures system labels and screens exist
      talker.blocLog('Auth', 'Seeding user data for existing session');
      _userDataSeeder.seedAll(session.user.id).ignore();
    } else {
      talker.blocLog(
        'Auth',
        'No initial session, emitting unauthenticated state',
      );
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
    talker.blocLog(
      'Auth',
      'Auth state changed: event=${event.authState.event}',
    );
    final session = event.authState.session;
    if (session != null) {
      talker.blocLog(
        'Auth',
        'Session found in auth state change, emitting authenticated',
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: session.user,
        ),
      );
      // Seed user data after successful authentication
      // This ensures system labels and screens exist for the user
      talker.blocLog('Auth', 'Seeding user data after auth state change');
      _userDataSeeder.seedAll(session.user.id).ignore();
    } else {
      talker.blocLog(
        'Auth',
        'No session in auth state change, emitting unauthenticated',
      );
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

      // Let the auth subscription handle authenticated state emission
      // to avoid double navigation. Only handle error cases here.
      if (response.session == null) {
        talker.warning(
          '[AuthBloc] Sign in succeeded but no session returned',
        );
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            error: 'Sign in failed - no session',
          ),
        );
      }
      // Success case: onAuthStateChange will emit authenticated state
    } catch (error, stackTrace) {
      talker.handle(error, stackTrace, '[AuthBloc] Sign in failed');
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
        // Let the auth subscription handle authenticated state emission
        // to avoid double navigation
        talker.info('[AuthBloc] Sign up succeeded with session');
        // Success case: onAuthStateChange will emit authenticated state
      } else {
        // Email confirmation might be required
        talker.info(
          '[AuthBloc] Sign up succeeded but requires email confirmation',
        );
        emit(
          state.copyWith(
            status: AuthStatus.unauthenticated,
            message: 'Check your email to confirm your account',
          ),
        );
      }
    } catch (error, stackTrace) {
      talker.handle(error, stackTrace, '[AuthBloc] Sign up failed');
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
    } catch (error, stackTrace) {
      talker.handle(error, stackTrace, '[AuthBloc] Sign out failed');
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
    } catch (error, stackTrace) {
      talker.handle(error, stackTrace, '[AuthBloc] Password reset failed');
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
