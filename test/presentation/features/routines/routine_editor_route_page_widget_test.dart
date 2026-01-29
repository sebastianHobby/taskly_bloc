@Tags(['widget', 'routines'])
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_imports.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/routines/view/routine_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/routines/widgets/routine_form.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';

class MockRoutineRepository extends Mock implements RoutineRepositoryContract {}

class MockValueRepository extends Mock implements ValueRepositoryContract {}

class MockRoutineWriteService extends Mock implements RoutineWriteService {}

class MockErrorReporter extends Mock implements AppErrorReporter {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockRoutineRepository routineRepository;
  late MockValueRepository valueRepository;
  late MockRoutineWriteService routineWriteService;
  late MockErrorReporter errorReporter;

  setUp(() {
    routineRepository = MockRoutineRepository();
    valueRepository = MockValueRepository();
    routineWriteService = MockRoutineWriteService();
    errorReporter = MockErrorReporter();

    when(() => valueRepository.getAll()).thenAnswer((_) async => <Value>[]);
  });

  Future<void> pumpRoute(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/routine/new',
          builder: (context, state) => const RoutineEditorRoutePage(
            routineId: null,
          ),
        ),
      ],
      initialLocation: '/routine/new',
    );

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<RoutineRepositoryContract>.value(
            value: routineRepository,
          ),
          RepositoryProvider<ValueRepositoryContract>.value(
            value: valueRepository,
          ),
          RepositoryProvider<RoutineWriteService>.value(
            value: routineWriteService,
          ),
          RepositoryProvider<AppErrorReporter>.value(value: errorReporter),
        ],
        child: MaterialApp.router(
          theme: AppTheme.lightTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
  }

  testWidgetsSafe('renders routine editor full page for deep link', (
    tester,
  ) async {
    await pumpRoute(tester);
    await tester.pumpForStream();

    expect(find.byType(RoutineForm), findsOneWidget);
  });
}
