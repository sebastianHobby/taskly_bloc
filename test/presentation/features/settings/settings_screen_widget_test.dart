@Tags(['widget', 'settings'])
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/l10n/l10n.dart';

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

    final l10n = tester.element(find.byType(SettingsScreen)).l10n;

    expect(find.text(l10n.settingsTitle), findsOneWidget);
    expect(find.text(l10n.settingsAppearanceTitle), findsOneWidget);
    expect(find.text(l10n.settingsGuidedTourTitle), findsOneWidget);
    expect(find.text(l10n.weeklyReviewTitle), findsOneWidget);
    expect(find.text(l10n.settingsLanguageRegionTitle), findsOneWidget);
    expect(find.text(l10n.settingsAccountTitle), findsOneWidget);
    if (kDebugMode) {
      expect(
        find.text(l10n.settingsDeveloperTitle, skipOffstage: false),
        findsOneWidget,
      );
    }
  });
}
