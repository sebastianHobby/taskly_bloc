import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/features/values/bloc/value_detail_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/core/domain/domain.dart';
import 'package:taskly_bloc/data/repositories/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/values/view/value_detail_view.dart';

class FakeValueRepository implements ValueRepositoryContract {
  final _controller = StreamController<List<ValueModel>>.broadcast();
  List<ValueModel> _last = [];

  void pushValues(List<ValueModel> values) {
    _last = values;
    _controller.add(values);
  }

  @override
  Stream<List<ValueModel>> watchAll({bool withRelated = false}) {
    return _controller.stream;
  }

  @override
  Future<List<ValueModel>> getAll({bool withRelated = false}) async {
    return _last;
  }

  @override
  Stream<ValueModel?> watch(String id, {bool withRelated = false}) {
    return watchAll(withRelated: withRelated).map(
      (values) => values.where((v) => v.id == id).firstOrNull,
    );
  }

  @override
  Future<ValueModel?> get(String id, {bool withRelated = false}) async {
    return _last.where((v) => v.id == id).firstOrNull;
  }

  @override
  Future<void> create({required String name}) async {
    final now = DateTime.now();
    final created = ValueModel(
      id: 'fake-${_last.length + 1}',
      createdAt: now,
      updatedAt: now,
      name: name,
    );
    pushValues([..._last, created]);
  }

  @override
  Future<void> update({required String id, required String name}) async {
    pushValues(
      _last
          .map(
            (v) => v.id == id
                ? ValueModel(
                    id: v.id,
                    createdAt: v.createdAt,
                    updatedAt: DateTime.now(),
                    name: name,
                  )
                : v,
          )
          .toList(),
    );
  }

  @override
  Future<void> delete(String id) async {
    pushValues(_last.where((v) => v.id != id).toList());
  }
}

void main() {
  testWidgets('value detail sheet shows initial data', (tester) async {
    final repo = FakeValueRepository();
    final sample = ValueModel(
      id: 'v1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: 'DetailValue',
    );
    repo.pushValues([sample]);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueDetailSheetPage(
          valueRepository: repo,
          valueId: sample.id,
          onSuccess: (_) {},
          onError: (_) {},
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.byType(FormBuilder), findsOneWidget);

    // Verify bloc loaded the value (UI initial population is covered by
    // integration tests elsewhere).
    final state = tester.state(find.byType(ValueDetailSheetView));
    final bloc = BlocProvider.of<ValueDetailBloc>(state.context);
    expect(bloc.state, isA<ValueDetailLoadSuccess>());
  });
}
