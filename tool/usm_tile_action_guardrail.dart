import 'dart:io';

/// Lightweight guardrail to prevent tile-layer mutations/DI regressions.
///
/// Scope is intentionally narrow (entity views + tile builder code) to avoid
/// false positives.
Future<void> main(List<String> args) async {
  final repoRoot = Directory.current;

  final targets = <String>[
    'lib/presentation/entity_views',
    'lib/presentation/screens/tiles',
  ];

  final forbidden = <RegExp, String>{
    RegExp(r'getIt<\s*EntityActionService\s*>'):
        'Entity views/tiles must not resolve EntityActionService via getIt',
    RegExp(r'ScaffoldMessenger\.of\('):
        'Entity views/tiles must not show SnackBars directly',
    RegExp(r'\.showSnackBar\('):
        'Entity views/tiles must not show SnackBars directly',
    RegExp(r'showDeleteSnackBar\('):
        'Delete success SnackBars must not live in entity views/tiles',
  };

  final violations = <String>[];

  for (final relativePath in targets) {
    final dir = Directory.fromUri(repoRoot.uri.resolve(relativePath));
    if (!dir.existsSync()) continue;

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      final content = await entity.readAsString();
      for (final entry in forbidden.entries) {
        final regex = entry.key;
        final reason = entry.value;
        if (regex.hasMatch(content)) {
          violations.add('${entity.path}: $reason (pattern: ${regex.pattern})');
        }
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('OK: no tile action guardrail violations found.');
    return;
  }

  stderr.writeln('FAIL: tile action guardrail violations found:');
  for (final v in violations) {
    stderr.writeln(' - $v');
  }

  exitCode = 1;
}
