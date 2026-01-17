import 'dart:io';

/// Guardrail: prevent Drift UPSERT helpers that generate `ON CONFLICT` SQL.
///
/// Rationale:
/// - PowerSync applies schema using SQLite views.
/// - SQLite does not allow `INSERT ... ON CONFLICT DO UPDATE` against views.
///
/// This script fails CI if it finds common Drift UPSERT patterns in areas where
/// PowerSync-replicated tables are typically written.
///
/// Escape hatch:
/// - Add `// ignore-powersync-upsert-guardrail` in a file to skip it.
Future<void> main(List<String> args) async {
  final repoRoot = Directory.current;

  final targets = <String>[
    'lib/data',
    'packages/taskly_data/lib',
  ];

  final forbidden = <RegExp, String>{
    RegExp(r'\binsertOnConflictUpdate\s*\('):
        'Drift UPSERT helper is not allowed for PowerSync views',
    RegExp(r'\binsertAllOnConflictUpdate\s*\('):
        'Drift batch UPSERT helper is not allowed for PowerSync views',
    RegExp(
      r'\bInsertMode\.insertOrReplace\b',
    ): 'Insert-or-replace can emit conflict SQL; not allowed for PowerSync views',
    RegExp(
      r'\binsertOrReplace\s*\(',
    ): 'Insert-or-replace can emit conflict SQL; not allowed for PowerSync views',
  };

  final violations = <_Violation>[];

  for (final relativePath in targets) {
    final dir = Directory.fromUri(repoRoot.uri.resolve(relativePath));
    if (!dir.existsSync()) continue;

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      final normalizedPath = _normalize(entity.path);
      if (normalizedPath.endsWith('.g.dart') ||
          normalizedPath.endsWith('.freezed.dart')) {
        continue;
      }

      final content = await entity.readAsString();
      if (content.contains('// ignore-powersync-upsert-guardrail')) {
        continue;
      }

      final lines = content.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        for (final entry in forbidden.entries) {
          if (entry.key.hasMatch(line)) {
            violations.add(
              _Violation(
                path: _toRelativePath(repoRoot.path, entity.path),
                lineNumber: i + 1,
                line: line.trimRight(),
                reason: entry.value,
                pattern: entry.key.pattern,
              ),
            );
          }
        }
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('✓ No PowerSync-local UPSERT violations found.');
    return;
  }

  stderr.writeln('❌ PowerSync-local UPSERT guardrail violations found:');
  stderr.writeln(
    '   (Avoid Drift UPSERT helpers that generate ON CONFLICT SQL for PowerSync views)',
  );
  stderr.writeln('');

  for (final v in violations) {
    stderr.writeln(' - ${v.path}:${v.lineNumber}');
    stderr.writeln('   ${v.reason}');
    stderr.writeln('   pattern: ${v.pattern}');
    stderr.writeln('   ${v.line}');
  }

  exitCode = 1;
}

class _Violation {
  const _Violation({
    required this.path,
    required this.lineNumber,
    required this.line,
    required this.reason,
    required this.pattern,
  });

  final String path;
  final int lineNumber;
  final String line;
  final String reason;
  final String pattern;
}

String _normalize(String path) => path.replaceAll(r'\', '/');

String _toRelativePath(String rootPath, String filePath) {
  final root = _normalize(rootPath);
  var file = _normalize(filePath);

  if (!root.endsWith('/')) {
    file = file.replaceFirst('$root/', '');
  } else {
    file = file.replaceFirst(root, '');
  }

  return file;
}
