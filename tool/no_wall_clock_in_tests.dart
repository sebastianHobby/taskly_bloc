import 'dart:io';

/// Guardrail: forbid `DateTime.now()` in tests (TG-001-A).
///
/// Rationale:
/// - Unit/widget tests must be hermetic and must not depend on wall-clock time.
/// - Time should be deterministic via injected clocks (e.g. TestClock) or
///   fixed reference dates.
///
/// Targets:
/// - test/** (all Dart files)
///
/// Allowed directories:
/// - test/integration_test/** (pipeline/local-stack; still recommended to be
///   deterministic, but not enforced here)
/// - test/diagnosis/** (ad-hoc debugging repros)
///
/// Escape hatch:
/// - Add `// ignore-wall-clock-guardrail` in a file to skip it.
Future<void> main(List<String> args) async {
  final repoRoot = Directory.current;
  final testDir = Directory(_join(repoRoot.path, ['test']));

  if (!testDir.existsSync()) {
    stdout.writeln('✓ No test/ directory found.');
    return;
  }

  final violations = <_Violation>[];

  await for (final entity in testDir.list(
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

    final relativePath = _toRelativePath(repoRoot.path, entity.path);
    final normalizedRelPath = _normalize(relativePath);

    if (normalizedRelPath.startsWith('test/integration_test/')) {
      continue;
    }
    if (normalizedRelPath.startsWith('test/diagnosis/')) {
      continue;
    }

    final content = await entity.readAsString();
    if (content.contains('// ignore-wall-clock-guardrail')) {
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
    stdout.writeln('✓ No DateTime.now() usage found in tests.');
    return;
  }

  stderr.writeln('❌ Wall-clock time guardrail violations found in tests:');
  stderr.writeln(
    '   (Use TestConstants.referenceDate / TestClock / injected time)',
  );
  stderr.writeln('');

  for (final v in violations) {
    stderr.writeln(' - ${v.path}:${v.lineNumber}');
    stderr.writeln('   ${v.line.trim()}');
  }

  exitCode = 1;
}

final _dateTimeNowPattern = RegExp(r'\bDateTime\.now\s*\(');

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

String _normalize(String path) => path.replaceAll(r'\\', '/');

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
