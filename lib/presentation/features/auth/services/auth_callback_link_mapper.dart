import 'package:taskly_bloc/presentation/routing/session_entry_policy.dart';

class AuthCallbackLinkMapper {
  const AuthCallbackLinkMapper();

  Uri? map(Uri incoming) {
    if (!_isAuthCallbackUri(incoming)) return null;

    return Uri(
      path: authCallbackPath,
      query: incoming.hasQuery ? incoming.query : null,
      fragment: incoming.fragment.isEmpty ? null : incoming.fragment,
    );
  }

  bool _isAuthCallbackUri(Uri uri) {
    if (uri.host.toLowerCase() == 'auth-callback') return true;

    final normalizedPath = _normalizePath(uri.path);
    if (_isCallbackPath(normalizedPath)) return true;

    final fragmentPath = _fragmentPath(uri.fragment);
    if (fragmentPath == null) return false;
    return _isCallbackPath(_normalizePath(fragmentPath));
  }

  bool _isCallbackPath(String path) {
    if (path.isEmpty) return false;
    return path == authCallbackPath || path.endsWith(authCallbackPath);
  }

  String _normalizePath(String rawPath) {
    if (rawPath.isEmpty) return '';
    if (rawPath == '/') return '/';
    return rawPath.replaceFirst(RegExp(r'/+$'), '');
  }

  String? _fragmentPath(String fragment) {
    final trimmed = fragment.trim();
    if (trimmed.isEmpty) return null;
    if (!trimmed.startsWith('/')) return null;
    final queryIndex = trimmed.indexOf('?');
    if (queryIndex < 0) return trimmed;
    return trimmed.substring(0, queryIndex);
  }
}
