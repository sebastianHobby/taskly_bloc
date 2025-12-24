import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/theme/app_theme.dart';
import 'package:taskly_bloc/data/adapters/next_actions_settings_adapter.dart';
import 'package:taskly_bloc/domain/contracts/auth_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/features/next_action/bloc/next_actions_bloc.dart';
import 'package:taskly_bloc/features/tasks/bloc/today_tasks_bloc.dart';
import 'package:taskly_bloc/features/tasks/utils/task_selector.dart';
import 'package:taskly_bloc/routing/router.dart';

/// Root application widget with app-level bloc providers.
///
/// Provides:
/// - [AuthBloc]: Authentication state for the entire app
/// - [NextActionsBloc]: Next actions data shared across features
/// - [TodayTasksBloc]: Today's tasks with badge count for navigation
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // AuthBloc: App-wide authentication state
        // Single instance eliminates redundant stream subscriptions
        // and preserves state across auth screens
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: getIt<AuthRepositoryContract>(),
          )..add(const AuthSubscriptionRequested()),
        ),
        // NextActionsBloc: App-wide next actions data
        // Single instance shared between Today page banner and
        // Next Actions full page, eliminating duplicate processing
        BlocProvider<NextActionsBloc>(
          create: (context) => NextActionsBloc(
            taskRepository: getIt<TaskRepositoryContract>(),
            settingsAdapter: getIt<NextActionsSettingsAdapter>(),
          )..add(const NextActionsSubscriptionRequested()),
        ),
        // TodayTasksBloc: App-wide today's tasks with badge count
        // Uses factory pattern for dynamic DateTime.now() evaluation
        // Shares task stream via RxDart for performance
        BlocProvider<TodayTasksBloc>(
          create: (context) => TodayTasksBloc(
            taskRepository: getIt<TaskRepositoryContract>(),
            configFactory: () => TaskSelector.today(now: DateTime.now()),
          )..add(const TodayTasksSubscriptionRequested()),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
