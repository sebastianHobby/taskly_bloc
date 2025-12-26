import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/theme/app_theme.dart';
import 'package:taskly_bloc/domain/contracts/auth_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/next_action/bloc/next_actions_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/services/today_badge_service.dart';
import 'package:taskly_bloc/core/routing/router.dart';

/// Root application widget with app-level bloc providers.
///
/// Provides:
/// - [AuthBloc]: Authentication state for the entire app
/// - [NextActionsBloc]: Next actions data shared across features
/// - [TodayBadgeService]: Today's incomplete task count for navigation badge
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // TodayBadgeService: Lightweight service for navigation badge count
        // Replaces heavier TodayTasksBloc - only provides count stream
        Provider<TodayBadgeService>(
          create: (_) => TodayBadgeService(
            taskRepository: getIt<TaskRepositoryContract>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
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
              settingsRepository: getIt<SettingsRepositoryContract>(),
            )..add(const NextActionsSubscriptionRequested()),
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
      ),
    );
  }
}
