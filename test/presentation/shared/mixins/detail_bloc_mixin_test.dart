import 'package:bloc/bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/core/utils/app_logger.dart';
import 'package:taskly_bloc/core/utils/detail_bloc_error.dart';
import 'package:taskly_bloc/core/utils/entity_operation.dart';
import 'package:taskly_bloc/presentation/shared/mixins/detail_bloc_mixin.dart';

// Test events
abstract class TestEvent {}

class TestCreate extends TestEvent {
  TestCreate(this.data);
  final String data;
}

class TestUpdate extends TestEvent {
  TestUpdate(this.id, this.data);
  final String id;
  final String data;
}

class TestDelete extends TestEvent {
  TestDelete(this.id);
  final String id;
}

class TestLoad extends TestEvent {
  TestLoad(this.id);
  final String id;
}

// Test states
abstract class TestState {}

class TestInitial extends TestState {}

class TestLoadInProgress extends TestState {}

class TestLoadSuccess extends TestState {
  TestLoadSuccess(this.entity);
  final TestEntity entity;
}

class TestOperationSuccess extends TestState {
  TestOperationSuccess(this.operation);
  final EntityOperation operation;
}

class TestOperationFailure extends TestState {
  TestOperationFailure(this.error);
  final DetailBlocError<TestEntity> error;
}

// Test entity
class TestEntity {
  TestEntity(this.id, this.data);
  final String id;
  final String data;
}

// Test logger
class TestLogger extends AppLogger {
  TestLogger() : super('test');
}

// Test bloc with DetailBlocMixin
class TestDetailBloc extends Bloc<TestEvent, TestState>
    with DetailBlocMixin<TestEvent, TestState, TestEntity> {
  TestDetailBloc() : super(TestInitial()) {
    on<TestCreate>(_onCreate);
    on<TestUpdate>(_onUpdate);
    on<TestDelete>(_onDelete);
    on<TestLoad>(_onLoad);
  }

  final Map<String, TestEntity> _storage = {};

  @override
  AppLogger get logger => TestLogger();

  Future<void> _onCreate(TestCreate event, Emitter<TestState> emit) async {
    await executeCreateOperation(
      emit,
      operation: () async {
        final entity = TestEntity('new-id', event.data);
        _storage[entity.id] = entity;
      },
    );
  }

  Future<void> _onUpdate(TestUpdate event, Emitter<TestState> emit) async {
    await executeUpdateOperation(
      emit,
      operation: () async {
        if (!_storage.containsKey(event.id)) {
          throw Exception('Entity not found');
        }
        _storage[event.id] = TestEntity(event.id, event.data);
      },
    );
  }

  Future<void> _onDelete(TestDelete event, Emitter<TestState> emit) async {
    await executeDeleteOperation(
      emit,
      operation: () async {
        if (!_storage.containsKey(event.id)) {
          throw Exception('Entity not found');
        }
        _storage.remove(event.id);
      },
    );
  }

  Future<void> _onLoad(TestLoad event, Emitter<TestState> emit) async {
    await executeLoadOperation(
      emit,
      load: () async {
        final entity = _storage[event.id];
        if (entity == null) {
          throw Exception('Entity not found');
        }
        return entity;
      },
      onSuccess: createLoadSuccessState,
    );
  }

  @override
  TestState createLoadInProgressState() => TestLoadInProgress();

  @override
  TestState createOperationSuccessState(EntityOperation operation) =>
      TestOperationSuccess(operation);

  @override
  TestState createOperationFailureState(DetailBlocError<TestEntity> error) =>
      TestOperationFailure(error);

  @override
  TestState createLoadSuccessState(TestEntity entity) =>
      TestLoadSuccess(entity);
}

// Test bloc that throws errors
class TestErrorBloc extends Bloc<TestEvent, TestState>
    with DetailBlocMixin<TestEvent, TestState, TestEntity> {
  TestErrorBloc() : super(TestInitial()) {
    on<TestCreate>(_onCreate);
    on<TestUpdate>(_onUpdate);
    on<TestDelete>(_onDelete);
    on<TestLoad>(_onLoad);
  }

  @override
  AppLogger get logger => TestLogger();

  Future<void> _onCreate(TestCreate event, Emitter<TestState> emit) async {
    await executeCreateOperation(
      emit,
      operation: () async {
        throw Exception('Create failed');
      },
    );
  }

  Future<void> _onUpdate(TestUpdate event, Emitter<TestState> emit) async {
    await executeUpdateOperation(
      emit,
      operation: () async {
        throw Exception('Update failed');
      },
    );
  }

  Future<void> _onDelete(TestDelete event, Emitter<TestState> emit) async {
    await executeDeleteOperation(
      emit,
      operation: () async {
        throw Exception('Delete failed');
      },
    );
  }

  Future<void> _onLoad(TestLoad event, Emitter<TestState> emit) async {
    await executeLoadOperation(
      emit,
      load: () async {
        throw Exception('Load failed');
      },
      onSuccess: (entity) => createLoadSuccessState(entity),
    );
  }

  @override
  TestState createLoadInProgressState() => TestLoadInProgress();

  @override
  TestState createOperationSuccessState(EntityOperation operation) =>
      TestOperationSuccess(operation);

  @override
  TestState createOperationFailureState(DetailBlocError<TestEntity> error) =>
      TestOperationFailure(error);

  @override
  TestState createLoadSuccessState(TestEntity entity) =>
      TestLoadSuccess(entity);
}

void main() {
  group('DetailBlocMixin', () {
    group('executeCreateOperation', () {
      blocTest<TestDetailBloc, TestState>(
        'emits success state when operation succeeds',
        build: TestDetailBloc.new,
        act: (bloc) => bloc.add(TestCreate('test data')),
        expect: () => [
          predicate<TestOperationSuccess>(
            (state) => state.operation == EntityOperation.create,
          ),
        ],
      );

      blocTest<TestErrorBloc, TestState>(
        'emits failure state when operation throws',
        build: TestErrorBloc.new,
        act: (bloc) => bloc.add(TestCreate('test data')),
        expect: () => [
          predicate<TestOperationFailure>(
            (state) => state.error.error.toString().contains('Create failed'),
          ),
        ],
      );

      blocTest<TestDetailBloc, TestState>(
        'actually executes the operation',
        build: TestDetailBloc.new,
        act: (bloc) => bloc.add(TestCreate('test data')),
        verify: (bloc) {
          expect(bloc._storage.containsKey('new-id'), isTrue);
          expect(bloc._storage['new-id']?.data, equals('test data'));
        },
      );
    });

    group('executeUpdateOperation', () {
      blocTest<TestDetailBloc, TestState>(
        'emits success state when operation succeeds',
        build: () {
          final bloc = TestDetailBloc();
          bloc._storage['test-id'] = TestEntity('test-id', 'old data');
          return bloc;
        },
        act: (bloc) => bloc.add(TestUpdate('test-id', 'new data')),
        expect: () => [
          predicate<TestOperationSuccess>(
            (state) => state.operation == EntityOperation.update,
          ),
        ],
      );

      blocTest<TestErrorBloc, TestState>(
        'emits failure state when operation throws',
        build: TestErrorBloc.new,
        act: (bloc) => bloc.add(TestUpdate('test-id', 'new data')),
        expect: () => [
          predicate<TestOperationFailure>(
            (state) => state.error.error.toString().contains('Update failed'),
          ),
        ],
      );

      blocTest<TestDetailBloc, TestState>(
        'actually updates the entity',
        build: () {
          final bloc = TestDetailBloc();
          bloc._storage['test-id'] = TestEntity('test-id', 'old data');
          return bloc;
        },
        act: (bloc) => bloc.add(TestUpdate('test-id', 'new data')),
        verify: (bloc) {
          expect(bloc._storage['test-id']?.data, equals('new data'));
        },
      );
    });

    group('executeDeleteOperation', () {
      blocTest<TestDetailBloc, TestState>(
        'emits success state when operation succeeds',
        build: () {
          final bloc = TestDetailBloc();
          bloc._storage['test-id'] = TestEntity('test-id', 'test data');
          return bloc;
        },
        act: (bloc) => bloc.add(TestDelete('test-id')),
        expect: () => [
          predicate<TestOperationSuccess>(
            (state) => state.operation == EntityOperation.delete,
          ),
        ],
      );

      blocTest<TestErrorBloc, TestState>(
        'emits failure state when operation throws',
        build: TestErrorBloc.new,
        act: (bloc) => bloc.add(TestDelete('test-id')),
        expect: () => [
          predicate<TestOperationFailure>(
            (state) => state.error.error.toString().contains('Delete failed'),
          ),
        ],
      );

      blocTest<TestDetailBloc, TestState>(
        'actually deletes the entity',
        build: () {
          final bloc = TestDetailBloc();
          bloc._storage['test-id'] = TestEntity('test-id', 'test data');
          return bloc;
        },
        act: (bloc) => bloc.add(TestDelete('test-id')),
        verify: (bloc) {
          expect(bloc._storage.containsKey('test-id'), isFalse);
        },
      );
    });

    group('executeLoadOperation', () {
      blocTest<TestDetailBloc, TestState>(
        'emits loading and success states when load succeeds',
        build: () {
          final bloc = TestDetailBloc();
          bloc._storage['test-id'] = TestEntity('test-id', 'test data');
          return bloc;
        },
        act: (bloc) => bloc.add(TestLoad('test-id')),
        expect: () => [
          isA<TestLoadInProgress>(),
          predicate<TestLoadSuccess>(
            (state) =>
                state.entity.id == 'test-id' &&
                state.entity.data == 'test data',
          ),
        ],
      );

      blocTest<TestErrorBloc, TestState>(
        'emits loading and failure states when load throws',
        build: TestErrorBloc.new,
        act: (bloc) => bloc.add(TestLoad('test-id')),
        expect: () => [
          isA<TestLoadInProgress>(),
          predicate<TestOperationFailure>(
            (state) => state.error.error.toString().contains('Load failed'),
          ),
        ],
      );
    });

    group('executeOperation (generic)', () {
      test('captures and wraps exceptions in DetailBlocError', () async {
        final bloc = TestErrorBloc();
        final states = <TestState>[];

        bloc.stream.listen(states.add);

        bloc.add(TestCreate('test'));

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(
          states.any((state) => state is TestOperationFailure),
          isTrue,
        );

        final failureState = states.whereType<TestOperationFailure>().first;

        expect(failureState.error.error, isA<Exception>());
        expect(failureState.error.stackTrace, isNotNull);

        await bloc.close();
      });
    });
  });
}
