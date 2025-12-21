import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/values/widgets/values_list.dart';
import 'package:taskly_bloc/routing/routes.dart';
import '../helpers/pump_app.dart';

class FakeValueRepository implements ValueRepositoryContract {
  FakeValueRepository({required List<ValueModel> initialValues})
    : _values = [...initialValues];

  final _controller = StreamController<List<ValueModel>>.broadcast();
  List<ValueModel> _values;
  Exception? updateException;

  void _emit() => _controller.add(_values);

  @override
  Stream<List<ValueModel>> watchAll({bool withRelated = false}) {
    return _controller.stream;
  }

  @override
  Future<List<ValueModel>> getAll({bool withRelated = false}) async {
    return _values;
  }

  @override
  Stream<ValueModel?> watch(String id, {bool withRelated = false}) {
    return watchAll(withRelated: withRelated).map(
      (values) => values.where((v) => v.id == id).firstOrNull,
    );
  }

  @override
  Future<ValueModel?> get(String id, {bool withRelated = false}) async {
    return _values.where((v) => v.id == id).firstOrNull;
  }

  @override
  Future<void> create({required String name}) async {
    final now = DateTime.now();
    _values = [
      ..._values,
      ValueModel(
        id: 'fake-${_values.length + 1}',
        createdAt: now,
        updatedAt: now,
        name: name,
      ),
    ];
    _emit();
  }

  @override
  Future<void> update({required String id, required String name}) async {
    final exception = updateException;
    if (exception != null) throw exception;

    final now = DateTime.now();
    _values = _values
        .map(
          (v) => v.id == id
              ? ValueModel(
                  id: v.id,
                  createdAt: v.createdAt,
                  updatedAt: now,
                  name: name,
                )
              : v,
        )
        .toList();
    _emit();
  }

  @override
  Future<void> delete(String id) async {
    _values = _values.where((v) => v.id != id).toList();
    _emit();
  }
}

void main() {
  testWidgets('tapping value navigates to value detail route', (tester) async {
    final sample = ValueModel(
      id: 'v1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: 'Value 1',
    );
    final repo = FakeValueRepository(initialValues: [sample]);

    final isSheetOpen = ValueNotifier<bool>(false);
    final sheetOpenValues = <bool>[];
    isSheetOpen.addListener(() => sheetOpenValues.add(isSheetOpen.value));

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: ValuesListView(
              values: [sample],
              valueRepository: repo,
              isSheetOpen: isSheetOpen,
            ),
          ),
        ),
        GoRoute(
          name: AppRouteName.valueDetail,
          path: '/values/:valueId',
          builder: (context, state) {
            final valueId = state.pathParameters['valueId']!;
            return Scaffold(body: Text('value-detail:$valueId'));
          },
        ),
      ],
    );

    await pumpLocalizedRouterApp(tester, router: router);

    await tester.tap(find.byKey(const Key('value-v1')));
    await tester.pumpAndSettle();
    expect(find.text('value-detail:v1'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();

    expect(sheetOpenValues, containsAllInOrder([true, false]));
  });
}
