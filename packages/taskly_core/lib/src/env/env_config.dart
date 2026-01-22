import 'package:meta/meta.dart';

/// Build-time environment configuration for the Taskly client app.
///
/// Note: These values are not secrets in a client application.
/// They should be treated as build-time configuration (different per
/// entrypoint/environment) and protected server-side via auth + RLS.
@immutable
class EnvConfig {
  const EnvConfig({
    required this.name,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.powersyncUrl,
  });

  /// Human-readable environment name (e.g. "local", "prod").
  final String name;

  final String supabaseUrl;
  final String supabasePublishableKey;
  final String powersyncUrl;
}
