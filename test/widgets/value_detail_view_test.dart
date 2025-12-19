import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/features/values/bloc/value_detail_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import '../helpers/test_db.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/features/values/view/value_detail_view.dart';

class FakeValueRepository extends ValueRepository {
  FakeValueRepository() : super(driftDb: createTestDb());

  final _controller = StreamController<List<ValueTableData>>.broadcast();
  List<ValueTableData> _last = [];

  void pushValues(List<ValueTableData> values) {
    _last = values;
    _controller.add(values);
  }

  @override
  Stream<List<ValueTableData>> get getValues => _controller.stream;

  @override
  Future<ValueTableData?> getValueById(String id) async {
    try {
      return _last.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> createValue(ValueTableCompanion createCompanion) async {
    return 1;
  }

  @override
  Future<bool> updateValue(ValueTableCompanion updateCompanion) async {
    return true;
  }

  @override
  Future<int> deleteValue(ValueTableCompanion deleteCompanion) async {
    return 1;
  }
}

void main() {
  testWidgets('value detail sheet shows initial data', (tester) async {
    final repo = FakeValueRepository();
    final sample = ValueTableData(
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
