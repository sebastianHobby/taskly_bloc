import 'package:taskly_bloc/bootstrap.dart';
import 'package:taskly_bloc/bootstrap/local_dev_host.dart';
import 'package:taskly_bloc/presentation/features/app/app.dart';
import 'package:taskly_core/env.dart';

Future<void> main() async {
  final host = localDevHost();

  Env.config = EnvConfig(
    name: 'local',
    supabaseUrl: 'http://$host:54321',
    supabasePublishableKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
    powersyncUrl: 'http://$host:8080',
    authWebRedirectUrl: 'http://$host:3000/auth/callback',
    authAppRedirectUrl: 'taskly://auth-callback',
    appVersion: String.fromEnvironment('APP_VERSION', defaultValue: 'local'),
    buildSha: String.fromEnvironment('BUILD_SHA', defaultValue: 'local'),
  );

  await bootstrap(() => const App());
}
