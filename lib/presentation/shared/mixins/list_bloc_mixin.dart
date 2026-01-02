import 'package:bloc/bloc.dart';

/// A mixin that provides common patterns for list/overview BLoCs.
///
/// This mixin helps reduce code duplication across entity-specific list
/// blocs by providing reusable stream subscription and delete patterns.
///
/// Type parameters:
/// - [E] - The event type for the bloc
/// - [S] - The state type for the bloc
/// - [T] - The entity type being listed
///
/// Example usage:
/// ```dart
/// class MyListBloc extends Bloc<MyEvent, MyState>
///     with ListBlocMixin<MyEvent, MyState, MyEntity> {
///   MyListBloc() : super(MyState.initial());
///
///   @override
///   S createLoadingState() => MyState.loading();
///
///   @override
///   S createErrorState(Object error) => MyState.error(error: error);
///
///   @override
///   S createLoadedState(List<T> items) => MyState.loaded(items: items);
/// }
/// ```
mixin ListBlocMixin<E, S, T> on Bloc<E, S> {
  /// Creates the loading state for this bloc.
  S createLoadingState();

  /// Creates the error state with the given error and optional stack trace.
  S createErrorState(Object error, [StackTrace? stackTrace]);

  /// Creates the loaded state with the given items.
  S createLoadedState(List<T> items);

  /// Subscribes to a stream of items and handles state emission.
  ///
  /// This method implements the common pattern of:
  /// 1. Emitting a loading state
  /// 2. Subscribing to a stream using emit.forEach
  /// 3. Transforming items via onData (for filtering/sorting)
  /// 4. Emitting loaded or error states
  ///
  /// Parameters:
  /// - [emit] - The emitter to use for state changes
  /// - [stream] - The stream of items to subscribe to
  /// - [onData] - Optional transformer for the items before creating state
  Future<void> subscribeToStream(
    Emitter<S> emit, {
    required Stream<List<T>> stream,
    List<T> Function(List<T> items)? onData,
  }) async {
    emit(createLoadingState());

    await emit.forEach<List<T>>(
      stream,
      onData: (items) {
        final processedItems = onData?.call(items) ?? items;
        return createLoadedState(processedItems);
      },
      onError: createErrorState,
    );
  }

  /// Executes a delete operation with error state emission on failure.
  ///
  /// Note: Unlike detail blocs, list blocs typically don't emit success states
  /// for deletes because the stream subscription automatically updates the
  /// list when an item is deleted.
  Future<void> executeDelete(
    Emitter<S> emit, {
    required Future<void> Function() delete,
  }) async {
    try {
      await delete();
    } catch (error, stackTrace) {
      emit(createErrorState(error, stackTrace));
    }
  }

  /// Executes a toggle operation (like completion status) with error handling.
  Future<void> executeToggle(
    Emitter<S> emit, {
    required Future<void> Function() toggle,
  }) async {
    try {
      await toggle();
    } catch (error, stackTrace) {
      emit(createErrorState(error, stackTrace));
    }
  }
}

/// A mixin for list blocs that need to maintain a cached snapshot of items.
///
/// This is useful when the bloc needs to re-apply filters or sorting
/// when configuration changes without re-fetching from the repository.
mixin CachedListBlocMixin<E, S, T> on Bloc<E, S> {
  /// The cached snapshot of all items from the stream.
  List<T> _cachedItems = const [];

  /// Whether a snapshot has been received from the stream.
  bool _hasSnapshot = false;

  /// Gets the cached items.
  List<T> get cachedItems => _cachedItems;

  /// Whether a snapshot has been received.
  bool get hasSnapshot => _hasSnapshot;

  /// Updates the cached snapshot.
  void updateCache(List<T> items) {
    _cachedItems = items;
    _hasSnapshot = true;
  }

  /// Clears the cached snapshot.
  void clearCache() {
    _cachedItems = const [];
    _hasSnapshot = false;
  }
}

/// A mixin for list blocs that support sorting.
///
/// This provides a common pattern for storing and updating sort preferences.
mixin SortableListBlocMixin<E, S, T, SortType> on Bloc<E, S> {
  /// The current sort preferences.
  SortType get currentSortPreferences;

  /// Applies the current sort preferences to a list of items.
  List<T> applySorting(List<T> items);

  /// Emits a new loaded state with re-sorted items.
  ///
  /// This should be called when sort preferences change to re-emit
  /// the loaded state with the new sort order.
  void emitWithCurrentSort(Emitter<S> emit, List<T> items);
}
