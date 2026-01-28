@Tags(['widget', 'app'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/app/bloc/initial_sync_gate_bloc.dart';
import 'package:taskly_bloc/presentation/features/app/view/initial_sync_gate_screen.dart';
import 'package:taskly_bloc/presentation/shared/widgets/app_loading_screen.dart';

class MockInitialSyncGateBloc
    extends MockBloc<InitialSyncGateEvent, InitialSyncGateState>
    implements InitialSyncGateBloc {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockInitialSyncGateBloc bloc;

  setUp(() {
    bloc = MockInitialSyncGateBloc();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidgetWithBloc<InitialSyncGateBloc>(
      bloc: bloc,
      child: const InitialSyncGateScreen(),
    );
  }

  testWidgetsSafe('shows loading screen during sync', (tester) async {
    const state = InitialSyncGateInProgress(null);
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await pumpScreen(tester);

    expect(find.byType(AppLoadingScreen), findsOneWidget);
    expect(find.text('Syncing your data'), findsOneWidget);
  });

  testWidgetsSafe('shows error state with retry button', (tester) async {
    const state = InitialSyncGateFailure('Failed');
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await pumpScreen(tester);

    expect(find.text('Failed'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
