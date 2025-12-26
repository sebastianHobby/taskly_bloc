import 'package:bloc/bloc.dart';
import 'package:taskly_bloc/core/utils/app_logger.dart';
import 'package:taskly_bloc/core/utils/detail_bloc_error.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';

/// A mixin that provides common CRUD operation patterns for detail BLoCs.
///
/// This mixin helps reduce code duplication across entity-specific detail
/// blocs by providing reusable operation handlers with consistent error
/// handling and state emission patterns.
///
/// Type parameters:
/// - [E] - The event type for the bloc
/// - [S] - The state type for the bloc
/// - [T] - The entity type being managed
///
/// Example usage:
/// ```dart
/// class MyDetailBloc extends Bloc<MyEvent, MyState>
///     with DetailBlocMixin<MyEvent, MyState, MyEntity> {
///   MyDetailBloc() : super(MyState.initial());
///
///   @override
///   S createLoadInProgressState() => MyState.loadInProgress();
///
///   @override
///   S createOperationSuccessState(EntityOperation operation) =>
///       MyState.operationSuccess(operation: operation);
///
///   @override
///   S createOperationFailureState(DetailBlocError<T> error) =>
///       MyState.operationFailure(errorDetails: error);
/// }
/// ```
mixin DetailBlocMixin<E, S, T> on Bloc<E, S> {
  /// Creates the load-in-progress state for this bloc.
  S createLoadInProgressState();

  /// Creates the operation success state for a completed operation.
  S createOperationSuccessState(EntityOperation operation);

  /// Creates the operation failure state with error details.
  S createOperationFailureState(DetailBlocError<T> error);

  /// Logger for this BLoC.
  AppLogger get logger;

  /// Executes a repository operation with consistent error handling.
  ///
  /// This helper wraps the operation in a try-catch and emits the appropriate
  /// success or failure state based on the result.
  ///
  /// Parameters:
  /// - [emit] - The emitter to use for state changes
  /// - [operation] - The type of operation being performed
  /// - [execute] - The async function that performs the actual operation
  Future<void> executeOperation(
    Emitter<S> emit,
    EntityOperation operation,
    Future<void> Function() execute,
  ) async {
    try {
      logger.debug('Executing operation: ${operation.name}');
      await execute();
      // Brief delay to allow stream updates to propagate to parent BLoCs
      // This ensures UI updates before modal closes
      await Future<void>.delayed(const Duration(milliseconds: 50));
      logger.debug('Operation successful: ${operation.name}');
      emit(createOperationSuccessState(operation));
    } catch (error, stackTrace) {
      logger.error(
        'Operation failed: ${operation.name}',
        error,
        stackTrace,
      );
      emit(
        createOperationFailureState(
          DetailBlocError<T>(error: error, stackTrace: stackTrace),
        ),
      );
    }
  }

  /// Executes a get/load operation with consistent error handling.
  ///
  /// This helper emits load-in-progress state, then executes the load function
  /// and emits either a success state (via the onSuccess callback) or a failure
  /// state if an error occurs.
  ///
  /// Parameters:
  /// - [emit] - The emitter to use for state changes
  /// - [load] - The async function that loads the entity
  /// - [onSuccess] - Callback that creates the success state from loaded data
  /// - [onNotFound] - Optional callback that creates a not-found failure state
  Future<void> executeLoadOperation<R>(
    Emitter<S> emit, {
    required Future<R?> Function() load,
    required S Function(R data) onSuccess,
    DetailBlocError<T>? Function()? onNotFound,
  }) async {
    emit(createLoadInProgressState());
    try {
      logger.debug('Loading entity...');
      final result = await load();
      if (result == null) {
        if (onNotFound != null) {
          final error = onNotFound();
          if (error != null) {
            logger.warning('Entity not found');
            emit(createOperationFailureState(error));
          }
        }
        return;
      }
      logger.debug('Entity loaded successfully');
      emit(onSuccess(result));
    } catch (error, stackTrace) {
      logger.error('Failed to load entity', error, stackTrace);
      emit(
        createOperationFailureState(
          DetailBlocError<T>(error: error, stackTrace: stackTrace),
        ),
      );
    }
  }

  /// Executes a delete operation with consistent error handling.
  Future<void> executeDeleteOperation(
    Emitter<S> emit,
    Future<void> Function() delete,
  ) async {
    await executeOperation(emit, EntityOperation.delete, delete);
  }

  /// Executes a create operation with consistent error handling.
  Future<void> executeCreateOperation(
    Emitter<S> emit,
    Future<void> Function() create,
  ) async {
    await executeOperation(emit, EntityOperation.create, create);
  }

  /// Executes an update operation with consistent error handling.
  Future<void> executeUpdateOperation(
    Emitter<S> emit,
    Future<void> Function() update,
  ) async {
    await executeOperation(emit, EntityOperation.update, update);
  }
}
