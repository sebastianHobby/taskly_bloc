import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/auth.dart';
import 'package:taskly_domain/errors.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:uuid/uuid.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC that manages authentication state.
///
/// Listens to auth state changes from the repository and provides
/// actions for sign in, sign up, sign out, and password reset.
class AuthBloc extends Bloc<AuthEvent, AppAuthState> {
  AuthBloc({
    required AuthRepositoryContract authRepository,
    required AppErrorReporter errorReporter,
  }) : _authRepository = authRepository,
       _errorReporter = errorReporter,
       super(const AppAuthState()) {
    talker.blocLog('Auth', 'AuthBloc CONSTRUCTOR called');
    on<AuthSubscriptionRequested>(
      _onSubscriptionRequested,
      transformer: restartable(),
    );
    on<AuthSignInRequested>(_onSignInRequested, transformer: restartable());
    on<AuthSignUpRequested>(_onSignUpRequested, transformer: restartable());
    on<AuthSignOutRequested>(_onSignOutRequested, transformer: droppable());
    on<AuthPasswordResetRequested>(
      _onPasswordResetRequested,
      transformer: restartable(),
    );
    talker.blocLog(
      'Auth',
      'AuthBloc CONSTRUCTOR done, event handlers registered',
    );
  }

  final AuthRepositoryContract _authRepository;
  final AppErrorReporter _errorReporter;

  OperationContext _newContext({
    required String screen,
    required String intent,
    required String operation,
  }) {
    return OperationContext(
      correlationId: const Uuid().v4(),
      feature: 'auth',
      screen: screen,
      intent: intent,
      operation: operation,
    );
  }

  Future<void> _onSubscriptionRequested(
    AuthSubscriptionRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    // Check for existing session
    final session = _authRepository.currentSession;
    talker.blocLog(
      'Auth',
      '_onSubscriptionRequested: session=${session != null ? "exists" : "null"}',
    );

    if (session != null) {
      talker.blocLog('Auth', 'Initial session found, emitting authenticated');
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: session.user,
          error: null,
          message: null,
          pendingEmailConfirmation: null,
        ),
      );
    } else {
      talker.blocLog(
        'Auth',
        'No initial session, emitting unauthenticated state',
      );
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }

    await emit.forEach<AuthStateChange>(
      _authRepository.watchAuthState(),
      onData: (authState) {
        talker.blocLog(
          'Auth',
          'Auth state changed: event=${authState.event}',
        );
        final nextSession = authState.session;
        if (nextSession != null) {
          if (state.status == AuthStatus.authenticated &&
              state.user?.id == nextSession.user.id) {
            talker.blocLog('Auth', 'Already authenticated, skipping re-auth');
            return state;
          }
          talker.blocLog('Auth', 'Session found, emitting authenticated');
          return state.copyWith(
            status: AuthStatus.authenticated,
            user: nextSession.user,
            error: null,
            message: null,
            pendingEmailConfirmation: null,
          );
        }
        talker.blocLog(
          'Auth',
          'No session in auth state change, emitting unauthenticated',
        );
        return state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          error: null,
          message: null,
        );
      },
      onError: (error, stackTrace) {
        talker.handle(error, stackTrace, '[AuthBloc] auth stream failed');
        return state.copyWith(
          status: AuthStatus.unauthenticated,
          error: 'Auth stream failed',
        );
      },
    );
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        error: null,
        message: null,
        pendingEmailConfirmation: null,
      ),
    );

    final ctx = _newContext(
      screen: 'sign_in',
      intent: 'sign_in_requested',
      operation: 'auth.sign_in',
    );

    try {
      final response = await _authRepository.signInWithPassword(
        context: ctx,
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
            pendingEmailConfirmation: null,
          ),
        );
      }
      // Success case: onAuthStateChange will emit authenticated state
    } catch (error, stackTrace) {
      talker.handle(error, stackTrace, '[AuthBloc] Sign in failed');

      if (error is AppFailure && error.reportAsUnexpected) {
        _errorReporter.reportUnexpected(
          error,
          stackTrace,
          context: ctx,
          message: 'Auth sign-in failed (unexpected failure)',
        );
      } else if (error is! AppFailure) {
        _errorReporter.reportUnexpected(
          error,
          stackTrace,
          context: ctx,
          message: 'Auth sign-in failed (unmapped exception)',
        );
      }

      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          error: error is AppFailure ? error.uiMessage() : 'Sign in failed',
          pendingEmailConfirmation: null,
        ),
      );
    }
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        error: null,
        message: null,
        pendingEmailConfirmation: null,
      ),
    );

    final ctx = _newContext(
      screen: 'sign_up',
      intent: 'sign_up_requested',
      operation: 'auth.sign_up',
    );

    try {
      final response = await _authRepository.signUp(
        context: ctx,
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
            pendingEmailConfirmation: event.email,
          ),
        );
      }
    } catch (error, stackTrace) {
      talker.handle(error, stackTrace, '[AuthBloc] Sign up failed');

      if (error is AppFailure && error.reportAsUnexpected) {
        _errorReporter.reportUnexpected(
          error,
          stackTrace,
          context: ctx,
          message: 'Auth sign-up failed (unexpected failure)',
        );
      } else if (error is! AppFailure) {
        _errorReporter.reportUnexpected(
          error,
          stackTrace,
          context: ctx,
          message: 'Auth sign-up failed (unmapped exception)',
        );
      }

      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          error: error is AppFailure ? error.uiMessage() : 'Sign up failed',
          pendingEmailConfirmation: null,
        ),
      );
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    final ctx = _newContext(
      screen: 'settings',
      intent: 'sign_out_requested',
      operation: 'auth.sign_out',
    );

    try {
      await _authRepository.signOut(context: ctx);
      emit(
        state.copyWith(
          status: AuthStatus.unauthenticated,
          pendingEmailConfirmation: null,
        ),
      );
    } catch (error, stackTrace) {
      talker.handle(error, stackTrace, '[AuthBloc] Sign out failed');

      if (error is AppFailure && error.reportAsUnexpected) {
        _errorReporter.reportUnexpected(
          error,
          stackTrace,
          context: ctx,
          message: 'Auth sign-out failed (unexpected failure)',
        );
      } else if (error is! AppFailure) {
        _errorReporter.reportUnexpected(
          error,
          stackTrace,
          context: ctx,
          message: 'Auth sign-out failed (unmapped exception)',
        );
      }

      emit(
        state.copyWith(
          error: error is AppFailure ? error.uiMessage() : 'Sign out failed',
        ),
      );
    }
  }

  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AppAuthState> emit,
  ) async {
    // Capture original status before changing to loading
    final wasAuthenticated = state.status == AuthStatus.authenticated;
    emit(
      state.copyWith(
        status: AuthStatus.loading,
        error: null,
        message: null,
        pendingEmailConfirmation: null,
      ),
    );

    final ctx = _newContext(
      screen: wasAuthenticated ? 'settings' : 'forgot_password',
      intent: 'password_reset_requested',
      operation: 'auth.password_reset',
    );

    try {
      await _authRepository.resetPasswordForEmail(
        event.email,
        context: ctx,
      );
      emit(
        state.copyWith(
          status: wasAuthenticated
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated,
          message: 'Password reset email sent',
          pendingEmailConfirmation: null,
        ),
      );
    } catch (error, stackTrace) {
      talker.handle(error, stackTrace, '[AuthBloc] Password reset failed');

      if (error is AppFailure && error.reportAsUnexpected) {
        _errorReporter.reportUnexpected(
          error,
          stackTrace,
          context: ctx,
          message: 'Auth password reset failed (unexpected failure)',
        );
      } else if (error is! AppFailure) {
        _errorReporter.reportUnexpected(
          error,
          stackTrace,
          context: ctx,
          message: 'Auth password reset failed (unmapped exception)',
        );
      }

      emit(
        state.copyWith(
          status: wasAuthenticated
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated,
          error: error is AppFailure
              ? error.uiMessage()
              : 'Password reset failed',
          pendingEmailConfirmation: null,
        ),
      );
    }
  }
}
