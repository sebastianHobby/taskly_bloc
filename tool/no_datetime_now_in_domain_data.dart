import 'dart:io';

/// Guardrail: forbid `DateTime.now()` in domain/data layers.
///
/// Rationale:
/// - Time usage should be centralized behind an injected clock/time service.
/// - Direct calls to `DateTime.now()` in domain/data create subtle time bugs,
///   make testing harder, and can cause day-boundary drift.
///
/// Targets:
/// - lib/domain/
/// - lib/data/
/// - packages/taskly_*/lib/
///
/// Escape hatch:
/// - Add `// ignore-datetime-now-guardrail` in a file to skip it.
Future<void> main(List<String> args) async {
  final repoRoot = Directory.current;

  final targets = <Directory>[
    Directory(_join(repoRoot.path, ['lib', 'domain'])),
    Directory(_join(repoRoot.path, ['lib', 'data'])),
    Directory(_join(repoRoot.path, ['packages'])),
  ];

  final violations = <_Violation>[];

  for (final target in targets) {
    if (!target.existsSync()) continue;

    await for (final entity in target.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      final normalizedAbsPath = _normalize(entity.path);
      if (normalizedAbsPath.contains('/build/') ||
          normalizedAbsPath.contains('/.dart_tool/') ||
          normalizedAbsPath.contains('/.git/')) {
        continue;
      }

      if (normalizedAbsPath.endsWith('.g.dart') ||
          normalizedAbsPath.endsWith('.freezed.dart')) {
        continue;
      }

      final relativePath = _toRelativePath(repoRoot.path, entity.path);
      final normalizedRelPath = _normalize(relativePath);

      if (_isAllowedDateTimeNowFile(normalizedRelPath)) {
        continue;
      }

      // Limit packages scan to packages/taskly_*/lib/
      if (normalizedRelPath.startsWith('packages/')) {
        final parts = normalizedRelPath.split('/');
        final packagesIndex = parts.indexOf('packages');
        if (packagesIndex != -1) {
          final packageName = parts.length > packagesIndex + 1
              ? parts[packagesIndex + 1]
              : '';
          final isTasklyPackage = packageName.startsWith('taskly_');
          final isUnderLib =
              parts.length > packagesIndex + 2 &&
              parts[packagesIndex + 2] == 'lib';
          if (!isTasklyPackage || !isUnderLib) {
            continue;
          }
        }
      }

      final content = await entity.readAsString();
      if (content.contains('// ignore-datetime-now-guardrail')) {
        continue;
      }

      final lines = content.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('//') || trimmed.startsWith('///')) {
          continue;
        }
        if (trimmed.startsWith('*')) {
          // Likely inside a block comment.
          continue;
        }
        if (_dateTimeNowPattern.hasMatch(line)) {
          violations.add(
            _Violation(
              path: normalizedRelPath,
              lineNumber: i + 1,
              line: line.trimRight(),
            ),
          );
        }
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('✓ No DateTime.now() usage found in domain/data.');
    return;
  }

  stderr.writeln('❌ DateTime.now() guardrail violations found:');
  stderr.writeln('   (Use an injected clock/time service instead)');
  stderr.writeln('');

  for (final v in violations) {
    stderr.writeln(' - ${v.path}:${v.lineNumber}');
    stderr.writeln('   ${v.line.trim()}');
  }

  exitCode = 1;
}

final _dateTimeNowPattern = RegExp(r'\bDateTime\.now\s*\(');

bool _isAllowedDateTimeNowFile(String normalizedRelPath) {
  // Allow boundary implementations to centralize time access.
  //
  // - Domain Clock abstraction implementation.
  if (normalizedRelPath == 'packages/taskly_domain/lib/src/time/clock.dart') {
    return true;
  }

  // - Logging timestamps are allowed.
  if (normalizedRelPath.startsWith('packages/taskly_core/lib/src/logging/')) {
    return true;
  }

  return false;
}

class _Violation {
  const _Violation({
    required this.path,
    required this.lineNumber,
    required this.line,
  });

  final String path;
  final int lineNumber;
  final String line;
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

String _join(String root, List<String> parts) {
  final normalizedRoot = root.replaceAll(r'\\', '/');
  final normalizedParts = parts.map((p) => p.replaceAll(r'\\', '/')).toList();
  return [normalizedRoot, ...normalizedParts].join('/');
}
