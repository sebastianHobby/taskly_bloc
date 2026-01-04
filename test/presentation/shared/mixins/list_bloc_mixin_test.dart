import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/shared/mixins/list_bloc_mixin.dart';

import '../../../helpers/bloc_test_patterns.dart';

// Test event
abstract class TestEvent {}

class LoadItemsEvent extends TestEvent {}

class DeleteItemEvent extends TestEvent {
  DeleteItemEvent(this.id);
  final String id;
}

class ToggleItemEvent extends TestEvent {
  ToggleItemEvent(this.id);
  final String id;
}

// Test state
abstract class TestState {}

class InitialState extends TestState {}

class LoadingState extends TestState {}

class LoadedState extends TestState {
  LoadedState(this.items);
  final List<String> items;

  @override
  bool operator ==(Object other) =>
      other is LoadedState && _listEquals(items, other.items);

  @override
  int get hashCode => items.hashCode;
}

class ErrorState extends TestState {
  ErrorState(this.error, [this.stackTrace]);
  final Object error;
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) =>
      other is ErrorState && error.toString() == other.error.toString();

  @override
  int get hashCode => error.hashCode;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// Test Bloc using the mixin
class TestListBloc extends Bloc<TestEvent, TestState>
    with ListBlocMixin<TestEvent, TestState, String> {
  TestListBloc({
    this.itemStream,
    this.deleteCallback,
    this.toggleCallback,
  }) : super(InitialState()) {
    on<LoadItemsEvent>(_onLoad);
    on<DeleteItemEvent>(_onDelete);
    on<ToggleItemEvent>(_onToggle);
  }

  final Stream<List<String>>? itemStream;
  final Future<void> Function(String id)? deleteCallback;
  final Future<void> Function(String id)? toggleCallback;

  @override
  TestState createLoadingState() => LoadingState();

  @override
  TestState createErrorState(Object error, [StackTrace? stackTrace]) =>
      ErrorState(error, stackTrace);

  @override
  TestState createLoadedState(List<String> items) => LoadedState(items);

  Future<void> _onLoad(LoadItemsEvent event, Emitter<TestState> emit) async {
    if (itemStream != null) {
      await subscribeToStream(emit, stream: itemStream!);
    }
  }

  Future<void> _onDelete(DeleteItemEvent event, Emitter<TestState> emit) async {
    if (deleteCallback != null) {
      await executeDelete(emit, delete: () => deleteCallback!(event.id));
    }
  }

  Future<void> _onToggle(ToggleItemEvent event, Emitter<TestState> emit) async {
    if (toggleCallback != null) {
      await executeToggle(emit, toggle: () => toggleCallback!(event.id));
    }
  }
}

// Test Bloc with CachedListBlocMixin
class TestCachedBloc extends Bloc<TestEvent, TestState>
    with CachedListBlocMixin<TestEvent, TestState, String> {
  TestCachedBloc() : super(InitialState());
}

void main() {
  group('ListBlocMixin', () {
    group('subscribeToStream', () {
      blocTest<TestListBloc, TestState>(
        'emits loading then loaded when stream emits items',
        build: () {
          final controller = TestStreamController<List<String>>();
          final bloc = TestListBloc(itemStream: controller.stream);
          // Emit items after bloc is built
          Future.microtask(() {
            controller.emit(['item1', 'item2']);
          });
          return bloc;
        },
        act: (bloc) => bloc.add(LoadItemsEvent()),
        expect: () => [
          isA<LoadingState>(),
          isA<LoadedState>().having(
            (s) => s.items,
            'items',
            ['item1', 'item2'],
          ),
        ],
      );

      blocTest<TestListBloc, TestState>(
        'emits loading then loaded with empty list when stream emits empty',
        build: () {
          final controller = TestStreamController<List<String>>();
          final bloc = TestListBloc(itemStream: controller.stream);
          Future.microtask(() {
            controller.emit([]);
          });
          return bloc;
        },
        act: (bloc) => bloc.add(LoadItemsEvent()),
        expect: () => [
          isA<LoadingState>(),
          isA<LoadedState>().having((s) => s.items, 'items', isEmpty),
        ],
      );

      blocTest<TestListBloc, TestState>(
        'emits error when stream errors',
        build: () {
          final controller = TestStreamController<List<String>>();
          final bloc = TestListBloc(itemStream: controller.stream);
          Future.microtask(() {
            controller.emitError(Exception('Stream error'));
          });
          return bloc;
        },
        act: (bloc) => bloc.add(LoadItemsEvent()),
        expect: () => [
          isA<LoadingState>(),
          isA<ErrorState>(),
        ],
      );

      blocTest<TestListBloc, TestState>(
        'emits multiple loaded states when stream emits multiple times',
        build: () {
          final controller = TestStreamController<List<String>>();
          final bloc = TestListBloc(itemStream: controller.stream);
          unawaited(
            Future.microtask(() async {
              controller.emit(['a']);
              await Future<void>.delayed(const Duration(milliseconds: 10));
              controller.emit(['a', 'b']);
            }),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(LoadItemsEvent()),
        wait: const Duration(milliseconds: 50),
        expect: () => [
          isA<LoadingState>(),
          isA<LoadedState>().having((s) => s.items, 'items', ['a']),
          isA<LoadedState>().having((s) => s.items, 'items', ['a', 'b']),
        ],
      );
    });

    group('executeDelete', () {
      blocTest<TestListBloc, TestState>(
        'does not emit on successful delete',
        build: () => TestListBloc(
          deleteCallback: (_) async {},
        ),
        act: (bloc) => bloc.add(DeleteItemEvent('1')),
        expect: () => <TestState>[],
      );

      blocTest<TestListBloc, TestState>(
        'emits error on delete failure',
        build: () => TestListBloc(
          deleteCallback: (_) async {
            throw Exception('Delete failed');
          },
        ),
        act: (bloc) => bloc.add(DeleteItemEvent('1')),
        expect: () => [isA<ErrorState>()],
      );
    });

    group('executeToggle', () {
      blocTest<TestListBloc, TestState>(
        'does not emit on successful toggle',
        build: () => TestListBloc(
          toggleCallback: (_) async {},
        ),
        act: (bloc) => bloc.add(ToggleItemEvent('1')),
        expect: () => <TestState>[],
      );

      blocTest<TestListBloc, TestState>(
        'emits error on toggle failure',
        build: () => TestListBloc(
          toggleCallback: (_) async {
            throw Exception('Toggle failed');
          },
        ),
        act: (bloc) => bloc.add(ToggleItemEvent('1')),
        expect: () => [isA<ErrorState>()],
      );
    });
  });

  group('CachedListBlocMixin', () {
    test('initial state has empty cache', () {
      final bloc = TestCachedBloc();
      expect(bloc.cachedItems, isEmpty);
      expect(bloc.hasSnapshot, false);
      bloc.close();
    });

    test('updateCache stores items and sets hasSnapshot', () {
      final bloc = TestCachedBloc();
      bloc.updateCache(['a', 'b', 'c']);

      expect(bloc.cachedItems, ['a', 'b', 'c']);
      expect(bloc.hasSnapshot, true);
      bloc.close();
    });

    test('clearCache resets to empty state', () {
      final bloc = TestCachedBloc();
      bloc.updateCache(['x', 'y']);
      expect(bloc.hasSnapshot, true);

      bloc.clearCache();

      expect(bloc.cachedItems, isEmpty);
      expect(bloc.hasSnapshot, false);
      bloc.close();
    });

    test('multiple updateCache calls replace previous cache', () {
      final bloc = TestCachedBloc();
      bloc.updateCache(['first']);
      bloc.updateCache(['second', 'third']);

      expect(bloc.cachedItems, ['second', 'third']);
      bloc.close();
    });
  });
}
