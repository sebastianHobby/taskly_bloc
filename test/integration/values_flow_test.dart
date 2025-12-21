import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/features/values/view/value_overview_view.dart';
import 'package:taskly_bloc/routing/routes.dart';

import '../helpers/pump_app.dart';

// Minimal in-test fake repository to avoid external test helper dependency.
class FakeValueRepository implements ValueRepositoryContract {
  FakeValueRepository();

  final _controller = StreamController<List<ValueModel>>.broadcast();
  List<ValueModel> _last = [];

  void pushValues(List<ValueModel> values) {
    _last = values;
    _controller.add(values);
  }

  @override
  Stream<List<ValueModel>> watchAll({bool withRelated = false}) =>
      _controller.stream;

  @override
  Future<List<ValueModel>> getAll({bool withRelated = false}) async => _last;

  @override
  Stream<ValueModel?> watch(String id, {bool withRelated = false}) =>
      _controller.stream.map((values) {
        try {
          return values.firstWhere((v) => v.id == id);
        } catch (_) {
          return null;
        }
      });

  @override
  Future<ValueModel?> get(String id, {bool withRelated = false}) async {
    try {
      return _last.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> update({required String id, required String name}) async {
    final idx = _last.indexWhere((v) => v.id == id);
    if (idx == -1) return;

    final old = _last[idx];
    _last[idx] = ValueModel(
      id: old.id,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
      name: name,
    );
    _controller.add(_last);
  }

  @override
  Future<void> create({required String name}) async {
    final now = DateTime.now();
    final id = 'gen-${now.microsecondsSinceEpoch}';
    final newValue = ValueModel(
      id: id,
      createdAt: now,
      updatedAt: now,
      name: name,
    );
    _last = [..._last, newValue];
    _controller.add(_last);
  }

  @override
  Future<void> delete(String id) async {
    _last = _last.where((v) => v.id != id).toList();
    _controller.add(_last);
  }
}

void main() {
  testWidgets('values flow: display, open detail and create sheets', (
    tester,
  ) async {
    final repo = FakeValueRepository();

    final now = DateTime.now();
    final sample = ValueModel(
      id: 'v-int-1',
      createdAt: now,
      updatedAt: now,
      name: 'Integration Value',
    );

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => ValueOverviewPage(valueRepository: repo),
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
    // push values after widget builds so the bloc subscription receives the value
    repo.pushValues([sample]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Value is displayed
    expect(find.byKey(const Key('value-v-int-1')), findsOneWidget);

    // Open detail sheet by tapping the value tile
    await tester.tap(find.byKey(const Key('value-v-int-1')));
    await tester.pumpAndSettle();
    expect(find.text('value-detail:v-int-1'), findsOneWidget);

    // Close detail page
    router.pop();
    await tester.pumpAndSettle();

    // Open create sheet via FAB
    await tester.tap(find.byTooltip('Create value'));
    await tester.pumpAndSettle();
    expect(find.byType(FormBuilder), findsOneWidget);
  });

  testWidgets('create value via UI updates list', (tester) async {
    final repo = FakeValueRepository();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => ValueOverviewPage(valueRepository: repo),
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
