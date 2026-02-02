@Tags(['widget', 'settings'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/bloc/guided_tour_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_screen.dart';

class MockGuidedTourBloc extends MockBloc<GuidedTourEvent, GuidedTourState>
    implements GuidedTourBloc {}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late MockGuidedTourBloc guidedTourBloc;

  setUp(() {
    guidedTourBloc = MockGuidedTourBloc();
  });

  testWidgetsSafe('settings screen renders navigation items', (tester) async {
    final state = GuidedTourState.initial();
    when(() => guidedTourBloc.state).thenReturn(state);
    whenListen(guidedTourBloc, Stream.value(state), initialState: state);

    await tester.pumpWidgetWithBlocs(
      providers: [
        BlocProvider<GuidedTourBloc>.value(value: guidedTourBloc),
      ],
      child: const SettingsScreen(),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Task Suggestions'), findsOneWidget);
    expect(find.text('Weekly Review'), findsOneWidget);
    expect(find.text('Language & Region'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    if (kDebugMode) {
      expect(find.text('Developer', skipOffstage: false), findsOneWidget);
    }
  });
}
