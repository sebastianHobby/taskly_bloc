import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/theme/app_theme.dart';
import 'package:taskly_bloc/domain/contracts/auth_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/next_action/bloc/next_actions_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/services/today_badge_service.dart';
import 'package:taskly_bloc/core/routing/router.dart';
import 'package:taskly_bloc/domain/services/notifications/pending_notifications_processor.dart';

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
        child: StreamBuilder<GlobalSettings>(
          stream: getIt<SettingsRepositoryContract>().watchGlobalSettings(),
          builder: (context, snapshot) {
            final settings = snapshot.data ?? const GlobalSettings();

            return MaterialApp.router(
              theme: AppTheme.lightTheme(seedColor: settings.colorSchemeSeed),
              darkTheme: AppTheme.darkTheme(
                seedColor: settings.colorSchemeSeed,
              ),
              themeMode: settings.themeMode,
              locale: settings.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(settings.textScaleFactor),
                  ),
                  child: _NotificationsBootstrapper(child: child!),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationsBootstrapper extends StatefulWidget {
  const _NotificationsBootstrapper({required this.child});

  final Widget child;

  @override
  State<_NotificationsBootstrapper> createState() =>
      _NotificationsBootstrapperState();
}

class _NotificationsBootstrapperState
    extends State<_NotificationsBootstrapper> {
  @override
  void initState() {
    super.initState();

    // Web is a secondary client: it should not consume/mark-delivered
    // notifications that mobile/desktop are expected to present.
    if (kIsWeb) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<PendingNotificationsProcessor>().start();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
