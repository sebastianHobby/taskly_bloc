import 'dart:io';

/// Fails if any file outside `packages/taskly_domain/` imports or exports
/// `package:taskly_domain/src/...`.
///
/// Rationale: `lib/src` is a package-internal convention. External packages
/// should only depend on the public entrypoints under `package:taskly_domain/`.
Future<void> main(List<String> args) async {
  const needle = 'package:taskly_domain/src/';

  final repoRoot = Directory.current;

  final scanRoots = <String>[
    'lib',
    'packages',
    'test',
    'integration_test',
  ];

  final violations = <_Violation>[];

  for (final root in scanRoots) {
    final dir = Directory(_join(repoRoot.path, root));
    if (!dir.existsSync()) continue;

    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      final normalized = _normalize(entity.path);

      // Allow internal imports within the domain package itself.
      if (normalized.contains('/packages/taskly_domain/')) {
        continue;
      }

      // Skip generated outputs (usually excluded, but be safe).
      if (normalized.endsWith('.g.dart') ||
          normalized.endsWith('.freezed.dart')) {
        continue;
      }

      final content = entity.readAsStringSync();
      if (!content.contains(needle)) continue;

      final lines = content.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains(needle)) {
          violations.add(
            _Violation(
              path: _toRelativePath(repoRoot.path, entity.path),
              lineNumber: i + 1,
              line: line.trimRight(),
            ),
          );
        }
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('✓ No external taskly_domain src deep imports found.');
    return;
  }

  stderr.writeln(
    '❌ Found external imports/exports of taskly_domain internals:',
  );
  stderr.writeln(
    '   (Do not use package:taskly_domain/src/ from outside packages/taskly_domain)',
  );
  stderr.writeln('');

  for (final v in violations) {
    stderr.writeln(' - ${v.path}:${v.lineNumber}');
    stderr.writeln('   ${v.line}');
  }

  stderr.writeln('');
  stderr.writeln('Fix: import from the public API instead, e.g.');
  stderr.writeln(' - package:taskly_domain/taskly_domain.dart');
  stderr.writeln(
    ' - package:taskly_domain/<feature>.dart (allocation.dart, queries.dart, etc)',
  );

  exitCode = 1;
}

String _normalize(String path) => path.replaceAll(r'\', '/');

String _join(String a, String b) {
  if (a.endsWith(Platform.pathSeparator)) return '$a$b';
  return '$a${Platform.pathSeparator}$b';
}

String _toRelativePath(String root, String fullPath) {
  final rootNorm = _normalize(root);
  final fullNorm = _normalize(fullPath);

  if (fullNorm.startsWith(rootNorm)) {
    var rel = fullNorm.substring(rootNorm.length);
    if (rel.startsWith('/')) rel = rel.substring(1);
    return rel;
  }

  return fullNorm;
}

class _Violation {
  _Violation({
    required this.path,
    required this.lineNumber,
    required this.line,
  });

  final String path;
  final int lineNumber;
  final String line;
}
