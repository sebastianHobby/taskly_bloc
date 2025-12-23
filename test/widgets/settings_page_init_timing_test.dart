// Test that simulates the exact UI flow with potential timing issues

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/domain/settings.dart';
import 'package:taskly_bloc/features/settings/bloc/settings_bloc.dart';

void main() {
  group('Settings page initialization timing', () {
    late AppDatabase database;
    late SettingsRepository settingsRepository;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      settingsRepository = SettingsRepository(driftDb: database);
      // Pre-save some settings with includeInboxTasks = true
      await settingsRepository.save(
        const AppSettings(
          nextActions: NextActionsSettings(
            includeInboxTasks: true,
            tasksPerProject: 5,
          ),
        ),
      );
    });

    tearDown(() async {
      await database.close();
    });

    testWidgets('settings page reads current bloc state correctly', (
      tester,
    ) async {
      // Create the bloc as the router would
      final bloc = SettingsBloc(settingsRepository: settingsRepository);
      bloc.add(const SettingsSubscriptionRequested());

      // Wait for bloc to load - this simulates the time between
      // app start and user navigation to settings page
      await bloc.stream.firstWhere((s) => s.status == SettingsStatus.loaded);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const _TestSettingsPage(),
          ),
        ),
      );

      // Verify the page read the correct settings
      final state = tester.state<_TestSettingsPageState>(
        find.byType(_TestSettingsPage),
      );

      expect(
        state.includeInbox,
        isTrue,
        reason: 'Page should read includeInboxTasks=true from bloc',
      );
      expect(
        state.tasksPerProject,
        equals(5),
        reason: 'Page should read tasksPerProject=5 from bloc',
      );

      await bloc.close();
    });

    testWidgets('settings page with delayed bloc load falls back to defaults', (
      tester,
    ) async {
      // Create the bloc but DON'T dispatch subscription yet
      final bloc = SettingsBloc(settingsRepository: settingsRepository);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const _TestSettingsPage(),
          ),
        ),
      );

      // Verify the page fell back to defaults because bloc wasn't loaded
      final state = tester.state<_TestSettingsPageState>(
        find.byType(_TestSettingsPage),
      );

      expect(
        state.includeInbox,
        isFalse,
        reason: 'Page should fall back to default includeInboxTasks=false',
      );

      // Now dispatch subscription
      bloc.add(const SettingsSubscriptionRequested());
      await bloc.stream.firstWhere((s) => s.status == SettingsStatus.loaded);

      // The page state is still showing defaults because initState already ran!
      // This would be the bug if the bloc wasn't loaded when the page opened
      expect(
        state.includeInbox,
        isFalse,
        reason: 'initState already ran with defaults - state is stale',
      );

      await bloc.close();
    });
  });
}

class _TestSettingsPage extends StatefulWidget {
  const _TestSettingsPage();

  @override
  State<_TestSettingsPage> createState() => _TestSettingsPageState();
}

class _TestSettingsPageState extends State<_TestSettingsPage> {
  late bool includeInbox;
  late int tasksPerProject;

  @override
  void initState() {
    super.initState();
    final settings =
        context.read<SettingsBloc>().state.settings?.nextActions ??
        NextActionsSettings.withDefaults();
    includeInbox = settings.includeInboxTasks;
    tasksPerProject = settings.tasksPerProject;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('Include Inbox: $includeInbox'),
          Text('Tasks Per Project: $tasksPerProject'),
        ],
      ),
    );
  }
}
