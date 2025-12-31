import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/theme/app_theme.dart';
import 'package:taskly_bloc/data/services/user_data_seeder.dart';
import 'package:taskly_bloc/domain/interfaces/auth_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/models/settings.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/services/today_badge_service.dart';
import 'package:taskly_bloc/core/routing/router.dart';
import 'package:taskly_bloc/domain/services/notifications/pending_notifications_processor.dart';

/// Root application widget with app-level bloc providers.
///
/// Provides:
/// - [AuthBloc]: Authentication state for the entire app
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
            lazy: false, // Force immediate creation to trigger seeding
            create: (context) {
              talker.debug('[app] Creating AuthBloc...');
              try {
                final bloc = AuthBloc(
                  authRepository: getIt<AuthRepositoryContract>(),
                  userDataSeeder: getIt<UserDataSeeder>(),
                )..add(const AuthSubscriptionRequested());
                talker.debug('[app] AuthBloc created successfully');
                return bloc;
              } catch (e, st) {
                talker.handle(e, st, '[app] AuthBloc creation FAILED');
                rethrow;
              }
            },
          ),
        ],
        child: StreamBuilder<GlobalSettings>(
          stream: getIt<SettingsRepositoryContract>().watchGlobalSettings(),
          builder: (context, snapshot) {
            final settings = snapshot.data ?? const GlobalSettings();

            return MaterialApp.router(
              theme: AppTheme.lightTheme(
                seedColor: Color(settings.colorSchemeSeedArgb),
              ),
              darkTheme: AppTheme.darkTheme(
                seedColor: Color(settings.colorSchemeSeedArgb),
              ),
              themeMode: _toFlutterThemeMode(settings.themeMode),
              locale: settings.localeCode == null
                  ? null
                  : Locale(settings.localeCode!),
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

  ThemeMode _toFlutterThemeMode(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
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
