import 'dart:io';

/// Guardrail: forbid `DateTime.now()` in the presentation layer.
///
/// Rationale:
/// - Presentation time usage should be centralized behind [NowService] so
///   widgets/BLoCs do not directly depend on system time.
/// - Direct calls make testing harder and create subtle day-boundary bugs.
///
/// Target:
/// - lib/presentation/
///
/// Escape hatch:
/// - Add `// ignore-datetime-now-guardrail` in a file to skip it.
Future<void> main(List<String> args) async {
  final repoRoot = Directory.current;

  final target = Directory(_join(repoRoot.path, ['lib', 'presentation']));
  if (!target.existsSync()) {
    stdout.writeln('✓ No presentation folder found; skipping.');
    return;
  }

  final violations = <_Violation>[];

  await for (final entity in target.list(recursive: true, followLinks: false)) {
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

  if (violations.isEmpty) {
    stdout.writeln('✓ No DateTime.now() usage found in presentation.');
    return;
  }

  stderr.writeln('❌ DateTime.now() guardrail violations found:');
  stderr.writeln('   (Use NowService instead)');
  stderr.writeln('');

  for (final v in violations) {
    stderr.writeln(' - ${v.path}:${v.lineNumber}');
    stderr.writeln('   ${v.line.trim()}');
  }

  exitCode = 1;
}

final _dateTimeNowPattern = RegExp(r'\bDateTime\.now\s*\(');

bool _isAllowedDateTimeNowFile(String normalizedRelPath) {
  // Allow the presentation boundary implementation to centralize time access.
  if (normalizedRelPath ==
      'lib/presentation/shared/services/time/now_service.dart') {
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
  final normalizedRoot = root.replaceAll(r'\', '/');
  final normalizedParts = parts.map((p) => p.replaceAll(r'\', '/')).toList();
  return [normalizedRoot, ...normalizedParts].join('/');
}
