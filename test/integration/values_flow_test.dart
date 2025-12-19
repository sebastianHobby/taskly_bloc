import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import '../helpers/test_db.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/features/values/view/value_overview_view.dart';

// Minimal in-test fake repository to avoid external test helper dependency.
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
  Future<bool> updateValue(ValueTableCompanion updateCompanion) async {
    try {
      final id = updateCompanion.id.value as String?;
      if (id != null) {
        final idx = _last.indexWhere((v) => v.id == id);
        if (idx != -1) {
          final old = _last[idx];
          final updated = ValueTableData(
            id: id,
            createdAt: old.createdAt,
            updatedAt: updateCompanion.updatedAt.present
                ? updateCompanion.updatedAt.value
                : DateTime.now(),
            name: updateCompanion.name.present
                ? updateCompanion.name.value
                : old.name,
          );
          _last[idx] = updated;
          _controller.add(_last);
        }
      }
    } catch (_) {}
    return true;
  }

  @override
  Future<int> createValue(ValueTableCompanion createCompanion) async {
    final id = createCompanion.id.present
        ? createCompanion.id.value
        : 'gen-${DateTime.now().millisecondsSinceEpoch}';
    final now = createCompanion.createdAt.present
        ? createCompanion.createdAt.value
        : DateTime.now();
    final newValue = ValueTableData(
      id: id,
      createdAt: now,
      updatedAt: createCompanion.updatedAt.present
          ? createCompanion.updatedAt.value
          : now,
      name: createCompanion.name.present ? createCompanion.name.value : '',
    );
    _last = [..._last, newValue];
    _controller.add(_last);
    return 1;
  }

  @override
  Future<int> deleteValue(ValueTableCompanion deleteCompanion) async {
    try {
      final id = deleteCompanion.id.value as String?;
      if (id != null) {
        _last.removeWhere((v) => v.id == id);
        _controller.add(_last);
        return 1;
      }
    } catch (_) {}
    return 0;
  }
}

void main() {
  testWidgets('values flow: display, open detail and create sheets', (
    tester,
  ) async {
    final repo = FakeValueRepository();

    final sample = ValueTableData(
      id: 'v-int-1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      name: 'Integration Value',
    );

    await tester.pumpWidget(
      MaterialApp(home: ValueOverviewPage(valueRepository: repo)),
    );
    // push values after widget builds so the bloc subscription receives the value
    repo.pushValues([sample]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Value is displayed
    expect(find.text('Integration Value'), findsOneWidget);

    // Open detail sheet by tapping the value tile
    await tester.tap(find.text('Integration Value'));
    await tester.pumpAndSettle();
    expect(find.byType(FormBuilder), findsOneWidget);

    // Close sheet
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Open create sheet via FAB
    await tester.tap(find.byTooltip('Create value'));
    await tester.pumpAndSettle();
    expect(find.byType(FormBuilder), findsOneWidget);
  });

  testWidgets('create value via UI updates list', (tester) async {
    final repo = FakeValueRepository();
    await tester.pumpWidget(
      MaterialApp(home: ValueOverviewPage(valueRepository: repo)),
    );
    // ensure the bloc receives an initial loaded state
    repo.pushValues([]);
    await tester.pump();

    // Open create sheet via FAB
    await tester.tap(find.byTooltip('Create value'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Enter name and submit — locate text fields inside the FormBuilder
    final textFields = find.descendant(
      of: find.byType(FormBuilder),
      matching: find.byType(TextField),
    );
    await tester.enterText(textFields.at(0), 'New UI Value');
    await tester.tap(find.byTooltip('Create'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // The fake repo should have emitted the new value and the list should update
    await tester.pump();
    expect(find.text('New UI Value'), findsOneWidget);
  });
}
