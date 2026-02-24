class AuthCallbackUriPayload {
  const AuthCallbackUriPayload({
    required this.error,
    required this.errorDescription,
    required this.type,
  });

  final String? error;
  final String? errorDescription;
  final String? type;

  bool get hasError => (error ?? '').trim().isNotEmpty;
  bool get isRecoveryFlow => type?.trim().toLowerCase() == 'recovery';
}

class AuthCallbackUriParser {
  const AuthCallbackUriParser();

  AuthCallbackUriPayload parse(Uri uri) {
    final query = uri.queryParameters;
    final fragment = _fragmentQueryParameters(uri.fragment);

    final error = _firstNonBlank(
      query['error'],
      fragment['error'],
    );
    final errorDescription = _firstNonBlank(
      query['error_description'],
      fragment['error_description'],
      query['message'],
      fragment['message'],
    );
    final type = _firstNonBlank(
      query['type'],
      fragment['type'],
    );

    return AuthCallbackUriPayload(
      error: error,
      errorDescription: errorDescription,
      type: type,
    );
  }

  Map<String, String> _fragmentQueryParameters(String fragment) {
    final trimmed = fragment.trim();
    if (trimmed.isEmpty) return const <String, String>{};

    final fragmentQuery = _extractFragmentQuery(trimmed);
    if (fragmentQuery.isEmpty || !fragmentQuery.contains('=')) {
      return const <String, String>{};
    }

    return Uri.splitQueryString(fragmentQuery);
  }

  String _extractFragmentQuery(String fragment) {
    if (fragment.startsWith('/')) {
      final index = fragment.indexOf('?');
      if (index < 0 || index + 1 >= fragment.length) return '';
      return fragment.substring(index + 1);
    }
    return fragment;
  }

  String? _firstNonBlank(String? a, [String? b, String? c, String? d]) {
    for (final value in <String?>[a, b, c, d]) {
      if (value == null) continue;
      final normalized = value.trim();
      if (normalized.isNotEmpty) return normalized;
    }
    return null;
  }
}
