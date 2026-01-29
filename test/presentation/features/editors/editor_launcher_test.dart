@Tags(['widget'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/taskly_domain.dart';

import '../../../helpers/test_imports.dart';
import '../../../mocks/feature_mocks.dart';
import '../../../mocks/repository_mocks.dart';

class MockNowService extends Mock implements NowService {}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testWidgetsSafe('throws when required dependencies are missing', (
    tester,
  ) async {
    final demoModeService = DemoModeService();
    final demoDataProvider = DemoDataProvider();
    addTearDown(demoModeService.dispose);
    final launcher = EditorLauncher(
      errorReporter: AppErrorReporter(
        messengerKey: GlobalKey<ScaffoldMessengerState>(),
      ),
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
      projectRepository: MockProjectRepositoryContract(),
      valueRepository: MockValueRepositoryContract(),
    );

    late BuildContext context;
    final nowService = MockNowService();
    when(
      () => nowService.nowLocal(),
    ).thenReturn(DateTime.utc(2025, 1, 15).toLocal());
    when(() => nowService.nowUtc()).thenReturn(DateTime.utc(2025, 1, 15));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppErrorReporter>.value(
            value: AppErrorReporter(
              messengerKey: GlobalKey<ScaffoldMessengerState>(),
            ),
          ),
          Provider<NowService>.value(value: nowService),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(
      () => launcher.openTaskEditor(context),
      throwsA(isA<StateError>()),
    );
    expect(
      () => launcher.openProjectEditor(context),
      throwsA(isA<StateError>()),
    );
    expect(
      () => launcher.openValueEditor(context),
      throwsA(isA<StateError>()),
    );
    expect(
      () => launcher.openRoutineEditor(context),
      throwsA(isA<StateError>()),
    );
  });

  testWidgetsSafe('opens bottom sheet on compact screens', (tester) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.devicePixelRatioTestValue = 1.0;
    binding.window.physicalSizeTestValue = const Size(500, 800);
    addTearDown(() {
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    final taskRepository = MockTaskRepositoryContract();
    final projectRepository = MockProjectRepositoryContract();
    final valueRepository = MockValueRepositoryContract();
    final allocationOrchestrator = MockAllocationOrchestrator();
    final occurrenceCommandService = MockOccurrenceCommandService();
    final taskWriteService = TaskWriteService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      allocationOrchestrator: allocationOrchestrator,
      occurrenceCommandService: occurrenceCommandService,
    );
    final nowService = MockNowService();
    final demoModeService = DemoModeService();
    final demoDataProvider = DemoDataProvider();
    addTearDown(demoModeService.dispose);

    when(
      () => nowService.nowLocal(),
    ).thenReturn(DateTime.utc(2025, 1, 15).toLocal());
    when(() => nowService.nowUtc()).thenReturn(DateTime.utc(2025, 1, 15));

    when(() => projectRepository.getAll()).thenAnswer((_) async => []);
    when(() => valueRepository.getAll()).thenAnswer((_) async => []);

    final launcher = EditorLauncher(
      errorReporter: AppErrorReporter(
        messengerKey: GlobalKey<ScaffoldMessengerState>(),
      ),
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      valueRepository: valueRepository,
      taskWriteService: taskWriteService,
    );

    late BuildContext context;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppErrorReporter>.value(
            value: AppErrorReporter(
              messengerKey: GlobalKey<ScaffoldMessengerState>(),
            ),
          ),
          Provider<NowService>.value(value: nowService),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (ctx) {
              context = ctx;
              return FilledButton(
                onPressed: () => unawaited(launcher.openTaskEditor(context)),
                child: const Text('Open Task Editor'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Task Editor'));
    await tester.pumpForStream(10);

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);

    await tester.tap(find.text('Cancel'));
    await tester.pumpForStream(10);
  });

  testWidgetsSafe('opens dialog on regular screens', (tester) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.devicePixelRatioTestValue = 1.0;
    binding.window.physicalSizeTestValue = const Size(900, 800);
    addTearDown(() {
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    final taskRepository = MockTaskRepositoryContract();
    final projectRepository = MockProjectRepositoryContract();
    final valueRepository = MockValueRepositoryContract();
    final allocationOrchestrator = MockAllocationOrchestrator();
    final occurrenceCommandService = MockOccurrenceCommandService();
    final taskWriteService = TaskWriteService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      allocationOrchestrator: allocationOrchestrator,
      occurrenceCommandService: occurrenceCommandService,
    );
    final nowService = MockNowService();
    final demoModeService = DemoModeService();
    final demoDataProvider = DemoDataProvider();
    addTearDown(demoModeService.dispose);

    when(
      () => nowService.nowLocal(),
    ).thenReturn(DateTime.utc(2025, 1, 15).toLocal());
    when(() => nowService.nowUtc()).thenReturn(DateTime.utc(2025, 1, 15));

    when(() => projectRepository.getAll()).thenAnswer((_) async => []);
    when(() => valueRepository.getAll()).thenAnswer((_) async => []);

    final launcher = EditorLauncher(
      errorReporter: AppErrorReporter(
        messengerKey: GlobalKey<ScaffoldMessengerState>(),
      ),
      demoModeService: demoModeService,
      demoDataProvider: demoDataProvider,
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      valueRepository: valueRepository,
      taskWriteService: taskWriteService,
    );

    late BuildContext context;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppErrorReporter>.value(
            value: AppErrorReporter(
              messengerKey: GlobalKey<ScaffoldMessengerState>(),
            ),
          ),
          Provider<NowService>.value(value: nowService),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (ctx) {
              context = ctx;
              return FilledButton(
                onPressed: () => unawaited(launcher.openTaskEditor(context)),
                child: const Text('Open Task Editor'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Task Editor'));
    await tester.pumpForStream(10);

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);

    await tester.tap(find.text('Cancel'));
    await tester.pumpForStream(10);
  });
}
