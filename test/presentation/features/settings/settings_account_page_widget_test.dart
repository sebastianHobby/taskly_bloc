@Tags(['widget', 'settings'])
library;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_account_page.dart';
import 'package:taskly_domain/auth.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AppAuthState>
    implements AuthBloc {}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  late MockAuthBloc authBloc;

  setUp(() {
    authBloc = MockAuthBloc();
  });

  testWidgetsSafe('settings account shows user info and sign out', (
    tester,
  ) async {
    const user = AuthUser(
      id: 'user-1',
      email: 'alex@example.com',
      metadata: {'display_name': 'Alex Johnson'},
    );
    const state = AppAuthState(
      status: AuthStatus.authenticated,
      user: user,
    );

    when(() => authBloc.state).thenReturn(state);
    whenListen(authBloc, Stream.value(state), initialState: state);

    await tester.pumpWidgetWithBlocs(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
      ],
      child: const SettingsAccountPage(),
    );

    final l10n = tester.element(find.byType(SettingsAccountPage)).l10n;
    expect(find.text('Alex Johnson'), findsOneWidget);
    expect(find.text('alex@example.com'), findsOneWidget);
    expect(find.text(l10n.signOutLabel), findsOneWidget);
  });
}
