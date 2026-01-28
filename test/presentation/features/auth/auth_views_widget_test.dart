@Tags(['widget', 'auth'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/auth/view/forgot_password_view.dart';
import 'package:taskly_bloc/presentation/features/auth/view/sign_in_view.dart';
import 'package:taskly_bloc/presentation/features/auth/view/sign_up_view.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AppAuthState>
    implements AuthBloc {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockAuthBloc bloc;

  setUp(() {
    bloc = MockAuthBloc();
  });

  Future<void> pumpView(WidgetTester tester, Widget child) async {
    await tester.pumpWidgetWithBloc<AuthBloc>(
      bloc: bloc,
      child: child,
    );
  }

  testWidgetsSafe('sign in shows loading state', (tester) async {
    const state = AppAuthState(status: AuthStatus.loading);
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await pumpView(tester, const SignInView());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgetsSafe('sign up shows loading state', (tester) async {
    const state = AppAuthState(status: AuthStatus.loading);
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await pumpView(tester, const SignUpView());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgetsSafe('forgot password shows loading state', (tester) async {
    const state = AppAuthState(status: AuthStatus.loading);
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await pumpView(tester, const ForgotPasswordView());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgetsSafe('sign in shows error snack bar', (tester) async {
    const state = AppAuthState(
      status: AuthStatus.unauthenticated,
      error: 'Invalid credentials',
    );
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await pumpView(tester, const SignInView());
    await tester.pumpForStream();

    expect(find.text('Invalid credentials'), findsOneWidget);
  });
}
