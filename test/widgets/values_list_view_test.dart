import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/values/view/value_detail_view.dart';
import 'package:taskly_bloc/features/values/widgets/values_list.dart';
import 'package:taskly_bloc/test/helpers/pump_app.dart';

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
  testWidgets(
    'tapping value opens sheet and shows success snackbar on update',
    (tester) async {
      final sample = ValueModel(
        id: 'v1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        name: 'Value 1',
      );
      final repo = FakeValueRepository(initialValues: [sample]);

      await pumpLocalizedApp(
        tester,
        home: Scaffold(
          body: ValuesListView(
            values: [sample],
            valueRepository: repo,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('value-v1')));
      await tester.pumpAndSettle();

      expect(find.byType(ValueDetailSheetPage), findsOneWidget);

      await tester.tap(find.byTooltip('Update'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Value updated successfully.'), findsOneWidget);

      tester
          .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
          .hideCurrentSnackBar();
      await tester.pumpAndSettle();

      expect(find.byType(ValueDetailSheetPage), findsNothing);
    },
  );

  testWidgets('shows error snackbar when update fails', (tester) async {
    final sample = ValueModel(
      id: 'v1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: 'Value 1',
    );
    final repo = FakeValueRepository(initialValues: [sample])
      ..updateException = Exception('bad');

    await pumpLocalizedApp(
      tester,
      home: Scaffold(
        body: ValuesListView(
          values: [sample],
          valueRepository: repo,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('value-v1')));
    await tester.pumpAndSettle();

    expect(find.byType(ValueDetailSheetPage), findsOneWidget);

    await tester.tap(find.byTooltip('Update'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Something went wrong. Please try again.'),
      findsAtLeast(1),
    );
    expect(find.byType(ValueDetailSheetPage), findsOneWidget);

    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();
  });
}
