import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/shared/mixins/list_bloc_mixin.dart';

// Test event
abstract class TestEvent {}

class TestLoad extends TestEvent {}

class TestDelete extends TestEvent {
  TestDelete(this.id);
  final String id;
}

class TestToggle extends TestEvent {
  TestToggle(this.id);
  final String id;
}

// Test state
abstract class TestState {}

class TestInitial extends TestState {}

class TestLoading extends TestState {}

class TestLoaded extends TestState {
  TestLoaded(this.items);
  final List<String> items;
}

class TestError extends TestState {
  TestError(this.error);
  final Object error;
}

// Test entity
class TestEntity {
  TestEntity(this.id, this.name);
  final String id;
  final String name;
}

// Test bloc with ListBlocMixin
class TestListBloc extends Bloc<TestEvent, TestState>
    with ListBlocMixin<TestEvent, TestState, String> {
  TestListBloc() : super(TestInitial()) {
    on<TestLoad>(_onLoad);
    on<TestDelete>(_onDelete);
    on<TestToggle>(_onToggle);
  }

  final _controller = StreamController<List<String>>();
  @override
  Stream<List<String>> get stream => _controller.stream;

  void addItems(List<String> items) {
    _controller.add(items);
  }

  @override
  void addError(Object error) {
    _controller.addError(error);
  }

  Future<void> _onLoad(TestLoad event, Emitter<TestState> emit) async {
    await subscribeToStream(
      emit,
      stream: stream,
    );
  }

  Future<void> _onDelete(TestDelete event, Emitter<TestState> emit) async {
    await executeDelete(
      emit,
      delete: () async {
        // Simulate delete
        if (event.id == 'error') {
          throw Exception('Delete failed');
        }
      },
    );
  }

  Future<void> _onToggle(TestToggle event, Emitter<TestState> emit) async {
    await executeToggle(
      emit,
      toggle: () async {
        // Simulate toggle
        if (event.id == 'error') {
          throw Exception('Toggle failed');
        }
      },
    );
  }

  @override
  TestState createLoadingState() => TestLoading();

  @override
  TestState createErrorState(Object error) => TestError(error);

  @override
  TestState createLoadedState(List<String> items) => TestLoaded(items);

  @override
  Future<void> close() {
    _controller.close();
    return super.close();
  }
}

// Test bloc with data transformation
class TestFilteringBloc extends Bloc<TestEvent, TestState>
    with ListBlocMixin<TestEvent, TestState, String> {
  TestFilteringBloc() : super(TestInitial()) {
    on<TestLoad>(_onLoad);
  }

  final _controller = StreamController<List<String>>();
  @override
  Stream<List<String>> get stream => _controller.stream;

  void addItems(List<String> items) {
    _controller.add(items);
  }

  Future<void> _onLoad(TestLoad event, Emitter<TestState> emit) async {
    await subscribeToStream(
      emit,
      stream: stream,
      onData: (items) => items.where((item) => item.startsWith('A')).toList(),
    );
  }

  @override
  TestState createLoadingState() => TestLoading();

  @override
  TestState createErrorState(Object error) => TestError(error);

  @override
  TestState createLoadedState(List<String> items) => TestLoaded(items);

  @override
  Future<void> close() {
    _controller.close();
    return super.close();
  }
}

// Test bloc with CachedListBlocMixin
class TestCachedListBloc extends Bloc<TestEvent, TestState>
    with
        ListBlocMixin<TestEvent, TestState, String>,
        CachedListBlocMixin<TestEvent, TestState, String> {
  TestCachedListBloc() : super(TestInitial());

  @override
  TestState createLoadingState() => TestLoading();

  @override
  TestState createErrorState(Object error) => TestError(error);

  @override
  TestState createLoadedState(List<String> items) {
    updateCache(items);
    return TestLoaded(items);
  }
}

void main() {
  group('ListBlocMixin', () {
    group('subscribeToStream', () {
      blocTest<TestListBloc, TestState>(
        'emits loading then loaded states when stream emits data',
        build: TestListBloc.new,
        act: (bloc) {
          bloc.add(TestLoad());
          bloc.addItems(['item1', 'item2', 'item3']);
        },
        expect: () => [
          isA<TestLoading>(),
          predicate<TestLoaded>(
            (state) =>
                state.items.length == 3 &&
                state.items[0] == 'item1' &&
                state.items[1] == 'item2' &&
                state.items[2] == 'item3',
          ),
        ],
      );

      blocTest<TestListBloc, TestState>(
        'emits loading then error states when stream emits error',
        build: TestListBloc.new,
        act: (bloc) {
          bloc.add(TestLoad());
          bloc.addError(Exception('Stream error'));
        },
        expect: () => [
          isA<TestLoading>(),
          predicate<TestError>(
            (state) => state.error.toString().contains('Stream error'),
          ),
        ],
      );

      blocTest<TestListBloc, TestState>(
        'emits multiple loaded states for multiple stream emissions',
        build: TestListBloc.new,
        act: (bloc) {
          bloc.add(TestLoad());
          bloc.addItems(['item1']);
          bloc.addItems(['item1', 'item2']);
          bloc.addItems(['item1', 'item2', 'item3']);
        },
        expect: () => [
          isA<TestLoading>(),
          predicate<TestLoaded>((state) => state.items.length == 1),
          predicate<TestLoaded>((state) => state.items.length == 2),
          predicate<TestLoaded>((state) => state.items.length == 3),
        ],
      );

      blocTest<TestFilteringBloc, TestState>(
        'applies onData transformation when provided',
        build: TestFilteringBloc.new,
        act: (bloc) {
          bloc.add(TestLoad());
          bloc.addItems(['Alice', 'Bob', 'Andy', 'Charlie']);
        },
        expect: () => [
          isA<TestLoading>(),
          predicate<TestLoaded>(
            (state) =>
                state.items.length == 2 &&
                state.items[0] == 'Alice' &&
                state.items[1] == 'Andy',
          ),
        ],
      );
    });

    group('executeDelete', () {
      blocTest<TestListBloc, TestState>(
        'completes successfully when delete succeeds',
        build: TestListBloc.new,
        act: (bloc) => bloc.add(TestDelete('item1')),
        expect: () => [],
      );

      blocTest<TestListBloc, TestState>(
        'emits error state when delete fails',
        build: TestListBloc.new,
        act: (bloc) => bloc.add(TestDelete('error')),
        expect: () => [
          predicate<TestError>(
            (state) => state.error.toString().contains('Delete failed'),
          ),
        ],
      );
    });

    group('executeToggle', () {
      blocTest<TestListBloc, TestState>(
        'completes successfully when toggle succeeds',
        build: TestListBloc.new,
        act: (bloc) => bloc.add(TestToggle('item1')),
        expect: () => [],
      );

      blocTest<TestListBloc, TestState>(
        'emits error state when toggle fails',
        build: TestListBloc.new,
        act: (bloc) => bloc.add(TestToggle('error')),
        expect: () => [
          predicate<TestError>(
            (state) => state.error.toString().contains('Toggle failed'),
          ),
        ],
      );
    });
  });

  group('CachedListBlocMixin', () {
    test('initial cache is empty', () {
      final bloc = TestCachedListBloc();

      expect(bloc.cachedItems, isEmpty);
      expect(bloc.hasSnapshot, isFalse);

      bloc.close();
    });

    test('updateCache updates cached items and snapshot flag', () {
      final bloc = TestCachedListBloc();

      bloc.updateCache(['item1', 'item2']);

      expect(bloc.cachedItems, equals(['item1', 'item2']));
      expect(bloc.hasSnapshot, isTrue);

      bloc.close();
    });

    test('clearCache clears cached items and snapshot flag', () {
      final bloc = TestCachedListBloc();

      bloc.updateCache(['item1', 'item2']);
      bloc.clearCache();

      expect(bloc.cachedItems, isEmpty);
      expect(bloc.hasSnapshot, isFalse);

      bloc.close();
    });

    test('createLoadedState automatically updates cache', () {
      final bloc = TestCachedListBloc();

      final state = bloc.createLoadedState(['item1', 'item2', 'item3']);

      expect(state, isA<TestLoaded>());
      expect(bloc.cachedItems, equals(['item1', 'item2', 'item3']));
      expect(bloc.hasSnapshot, isTrue);

      bloc.close();
    });
  });
}
