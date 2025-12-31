@Tags(['unit', 'mixin'])
library;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/shared/mixins/list_bloc_mixin.dart';

// Test event types
sealed class TestEvent {}

class SubscribeEvent extends TestEvent {}

class DeleteEvent extends TestEvent {
  DeleteEvent({required this.delete});
  final Future<void> Function() delete;
}

class ToggleEvent extends TestEvent {
  ToggleEvent({required this.toggle});
  final Future<void> Function() toggle;
}

// Test state types
sealed class TestState {}

class TestInitial extends TestState {}

class TestLoading extends TestState {}

class TestLoaded extends TestState {
  TestLoaded({required this.items});
  final List<String> items;

  @override
  bool operator ==(Object other) =>
      other is TestLoaded &&
      items.length == other.items.length &&
      items.every((item) => other.items.contains(item));

  @override
  int get hashCode => Object.hashAll(items);
}

class TestError extends TestState {
  TestError({required this.error});
  final Object error;

  @override
  bool operator ==(Object other) =>
      other is TestError && error.toString() == other.error.toString();

  @override
  int get hashCode => error.hashCode;
}

// Test bloc that uses ListBlocMixin
class TestListBloc extends Bloc<TestEvent, TestState>
    with ListBlocMixin<TestEvent, TestState, String> {
  TestListBloc({required Stream<List<String>> itemStream})
    : _itemStream = itemStream,
      super(TestInitial()) {
    on<SubscribeEvent>(_onSubscribe);
    on<DeleteEvent>(_onDelete);
    on<ToggleEvent>(_onToggle);
  }

  final Stream<List<String>> _itemStream;

  Future<void> _onSubscribe(
    SubscribeEvent event,
    Emitter<TestState> emit,
  ) async {
    await subscribeToStream(emit, stream: _itemStream);
  }

  Future<void> _onDelete(
    DeleteEvent event,
    Emitter<TestState> emit,
  ) async {
    await executeDelete(emit, delete: event.delete);
  }

  Future<void> _onToggle(
    ToggleEvent event,
    Emitter<TestState> emit,
  ) async {
    await executeToggle(emit, toggle: event.toggle);
  }

  @override
  TestState createErrorState(Object error) => TestError(error: error);

  @override
  TestState createLoadedState(List<String> items) => TestLoaded(items: items);

  @override
  TestState createLoadingState() => TestLoading();
}

// Test bloc that uses CachedListBlocMixin
class TestCachedListBloc extends Bloc<TestEvent, TestState>
    with CachedListBlocMixin<TestEvent, TestState, String> {
  TestCachedListBloc() : super(TestInitial());
}

void main() {
  group('ListBlocMixin', () {
    group('subscribeToStream', () {
      blocTest<TestListBloc, TestState>(
        'emits loading then loaded with items from stream',
        build: () => TestListBloc(
          itemStream: Stream.value(['item1', 'item2', 'item3']),
        ),
        act: (bloc) => bloc.add(SubscribeEvent()),
        expect: () => [
          isA<TestLoading>(),
          isA<TestLoaded>().having((s) => s.items.length, 'items.length', 3),
        ],
      );

      blocTest<TestListBloc, TestState>(
        'emits loading then loaded with empty list when stream is empty',
        build: () => TestListBloc(
          itemStream: Stream.value([]),
        ),
        act: (bloc) => bloc.add(SubscribeEvent()),
        expect: () => [
          isA<TestLoading>(),
          isA<TestLoaded>().having((s) => s.items, 'items', isEmpty),
        ],
      );

      blocTest<TestListBloc, TestState>(
        'emits error state when stream errors',
        build: () => TestListBloc(
          itemStream: Stream.error(Exception('Stream error')),
        ),
        act: (bloc) => bloc.add(SubscribeEvent()),
        expect: () => [
          isA<TestLoading>(),
          isA<TestError>(),
        ],
      );

      blocTest<TestListBloc, TestState>(
        'emits multiple loaded states when stream emits multiple times',
        build: () {
          final controller = StreamController<List<String>>();

          // We need to delay the controller operations
          Future<void>.delayed(const Duration(milliseconds: 10)).then((_) {
            controller.add(['a']);
          });
          Future<void>.delayed(const Duration(milliseconds: 20)).then((_) {
            controller.add(['a', 'b']);
          });
          Future<void>.delayed(const Duration(milliseconds: 30)).then((_) {
            controller.add(['a', 'b', 'c']);
            controller.close();
          });

          return TestListBloc(itemStream: controller.stream);
        },
        act: (bloc) => bloc.add(SubscribeEvent()),
        wait: const Duration(milliseconds: 50),
        expect: () => [
          isA<TestLoading>(),
          isA<TestLoaded>().having((s) => s.items.length, 'items.length', 1),
          isA<TestLoaded>().having((s) => s.items.length, 'items.length', 2),
          isA<TestLoaded>().having((s) => s.items.length, 'items.length', 3),
        ],
      );
    });

    group('executeDelete', () {
      blocTest<TestListBloc, TestState>(
        'does not emit when delete succeeds',
        build: () => TestListBloc(itemStream: const Stream.empty()),
        act: (bloc) => bloc.add(
          DeleteEvent(delete: () async {}),
        ),
        expect: () => <TestState>[],
      );

      blocTest<TestListBloc, TestState>(
        'emits error state when delete fails',
        build: () => TestListBloc(itemStream: const Stream.empty()),
        act: (bloc) => bloc.add(
          DeleteEvent(delete: () async => throw Exception('Delete failed')),
        ),
        expect: () => [
          isA<TestError>(),
        ],
      );
    });

    group('executeToggle', () {
      blocTest<TestListBloc, TestState>(
        'does not emit when toggle succeeds',
        build: () => TestListBloc(itemStream: const Stream.empty()),
        act: (bloc) => bloc.add(
          ToggleEvent(toggle: () async {}),
        ),
        expect: () => <TestState>[],
      );

      blocTest<TestListBloc, TestState>(
        'emits error state when toggle fails',
        build: () => TestListBloc(itemStream: const Stream.empty()),
        act: (bloc) => bloc.add(
          ToggleEvent(toggle: () async => throw Exception('Toggle failed')),
        ),
        expect: () => [
          isA<TestError>(),
        ],
      );
    });
  });

  group('CachedListBlocMixin', () {
    test('initial state has no cached items', () {
      final bloc = TestCachedListBloc();

      expect(bloc.cachedItems, isEmpty);
      expect(bloc.hasSnapshot, isFalse);

      bloc.close();
    });

    test('updateCache stores items and sets hasSnapshot', () {
      final bloc = TestCachedListBloc();

      bloc.updateCache(['item1', 'item2']);

      expect(bloc.cachedItems, ['item1', 'item2']);
      expect(bloc.hasSnapshot, isTrue);

      bloc.close();
    });

    test('clearCache resets items and hasSnapshot', () {
      final bloc = TestCachedListBloc();

      bloc.updateCache(['item1', 'item2']);
      expect(bloc.hasSnapshot, isTrue);

      bloc.clearCache();

      expect(bloc.cachedItems, isEmpty);
      expect(bloc.hasSnapshot, isFalse);

      bloc.close();
    });

    test('updateCache replaces previous items', () {
      final bloc = TestCachedListBloc();

      bloc.updateCache(['a', 'b']);
      expect(bloc.cachedItems, ['a', 'b']);

      bloc.updateCache(['x', 'y', 'z']);
      expect(bloc.cachedItems, ['x', 'y', 'z']);

      bloc.close();
    });
  });
}
