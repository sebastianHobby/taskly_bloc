@Tags(['widget', 'values'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/value_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/values/view/value_detail_view.dart';
import 'package:taskly_bloc/presentation/features/values/widgets/value_form.dart';
import 'package:taskly_domain/core.dart';

class MockValueDetailBloc extends MockBloc<ValueDetailEvent, ValueDetailState>
    implements ValueDetailBloc {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockValueDetailBloc bloc;

  setUp(() {
    bloc = MockValueDetailBloc();
  });

  Future<void> pumpView(
    WidgetTester tester, {
    required Widget child,
  }) async {
    await tester.pumpWidgetWithBloc<ValueDetailBloc>(
      bloc: bloc,
      child: child,
    );
  }

  testWidgetsSafe('shows loading indicator while loading', (tester) async {
    const state = ValueDetailState.loadInProgress();
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await pumpView(tester, child: const ValueDetailSheetView());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgetsSafe('renders value form for edit flow', (tester) async {
    final value = TestData.value(name: 'Focus');
    final state = ValueDetailState.loadSuccess(value: value);
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await pumpView(
      tester,
      child: const ValueDetailSheetView(valueId: 'value-1'),
    );

    expect(find.byType(ValueForm), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
  });

  testWidgetsSafe('shows fallback error text for invalid state', (
    tester,
  ) async {
    const state = ValueDetailState.initial();
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await pumpView(
      tester,
      child: const ValueDetailSheetView(valueId: 'value-1'),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
  });
}
