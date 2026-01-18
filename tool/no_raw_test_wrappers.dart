import 'dart:io';

/// Guardrail: enforce safe wrappers for new tests (TG-002-A).
///
/// Policy (for *_test.dart files):
/// - forbid raw `testWidgets(` (use `testWidgetsSafe`)
/// - forbid raw `test(` (use `testSafe` or a wrapper built on it)
/// - forbid raw `blocTest(` / `blocTest<...>` (use `blocTestSafe`)
///
/// Escape hatch:
/// - Add `// ignore-safe-wrappers-guardrail` in a file to skip it.
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
    if (!entity.path.endsWith('_test.dart')) continue;

    final relativePath = _normalize(
      _toRelativePath(repoRoot.path, entity.path),
    );

    final content = await entity.readAsString();
    if (content.contains('// ignore-safe-wrappers-guardrail')) {
      continue;
    }

    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
      if (trimmed.startsWith('*')) continue;

      if (_rawTestWidgetsPattern.hasMatch(line) &&
          !_safeTestWidgetsPattern.hasMatch(line)) {
        violations.add(
          _Violation(
            path: relativePath,
            lineNumber: i + 1,
            message: 'Use testWidgetsSafe(...) instead of testWidgets(...)',
            line: line.trimRight(),
          ),
        );
      }

      if (_rawTestPattern.hasMatch(line) && !_safeTestPattern.hasMatch(line)) {
        violations.add(
          _Violation(
            path: relativePath,
            lineNumber: i + 1,
            message: 'Use testSafe(...) instead of test(...)',
            line: line.trimRight(),
          ),
        );
      }

      if (_rawBlocTestPattern.hasMatch(line) &&
          !_safeBlocTestPattern.hasMatch(line)) {
        violations.add(
          _Violation(
            path: relativePath,
            lineNumber: i + 1,
            message: 'Use blocTestSafe(...) instead of blocTest(...)',
            line: line.trimRight(),
          ),
        );
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('✓ No unsafe raw test wrappers found.');
    return;
  }

  stderr.writeln('❌ Unsafe raw test wrapper usage found:');
  stderr.writeln('');
  for (final v in violations) {
    stderr.writeln(' - ${v.path}:${v.lineNumber}: ${v.message}');
    stderr.writeln('   ${v.line.trim()}');
  }

  exitCode = 1;
}

final _rawTestWidgetsPattern = RegExp(r'\btestWidgets\s*\(');
final _safeTestWidgetsPattern = RegExp(r'\btestWidgetsSafe\s*\(');

final _rawTestPattern = RegExp(r'\btest\s*\(');
final _safeTestPattern = RegExp(r'\btestSafe\s*\(');

final _rawBlocTestPattern = RegExp(r'\bblocTest\s*(?:<|\()');
final _safeBlocTestPattern = RegExp(r'\bblocTestSafe\s*\(');

class _Violation {
  const _Violation({
    required this.path,
    required this.lineNumber,
    required this.message,
    required this.line,
  });

  final String path;
  final int lineNumber;
  final String message;
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
