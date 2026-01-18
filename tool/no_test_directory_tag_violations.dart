import 'dart:io';

/// Guardrail: enforce directory ↔ tag contract for tests (TG-005-A).
///
/// Policy (for *_test.dart files):
/// - test/core/**           -> must include tag: unit
/// - test/domain/**          -> must include tag: unit
/// - test/contracts/**       -> must include tag: unit
/// - test/presentation/**    -> must include tag: widget OR unit
/// - test/data/**            -> must include tag: repository OR integration
/// - test/integration/**     -> must include tag: integration
/// - test/integration_test/**-> must include tag: pipeline
/// - test/diagnosis/**       -> must include tag: diagnosis
///
/// Implementation: enforce a file-level annotation:
/// `@Tags(['unit'])` (or multiple tags).
///
/// Escape hatch:
/// - Add `// ignore-test-tag-guardrail` in a file to skip it.
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

    final expected = _expectedTagsForPath(relativePath);
    if (expected == null) {
      // Not part of the directory contract (or unknown folder).
      continue;
    }

    final content = await entity.readAsString();
    if (content.contains('// ignore-test-tag-guardrail')) {
      continue;
    }

    final tags = _extractFileTags(content);

    if (tags.isEmpty) {
      violations.add(
        _Violation(
          path: relativePath,
          message:
              'Missing @Tags([...]) annotation (expected one of: ${expected.join(', ')})',
        ),
      );
      continue;
    }

    final hasExpected = expected.any(tags.contains);
    if (!hasExpected) {
      violations.add(
        _Violation(
          path: relativePath,
          message:
              'Tags ${tags.toList()..sort()} do not match directory policy (expected one of: ${expected.join(', ')})',
        ),
      );
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('✓ No test directory/tag contract violations found.');
    return;
  }

  stderr.writeln('❌ Test directory/tag contract violations found:');
  stderr.writeln('');
  for (final v in violations) {
    stderr.writeln(' - ${v.path}');
    stderr.writeln('   ${v.message}');
  }

  exitCode = 1;
}

Set<String> _extractFileTags(String content) {
  final tags = <String>{};

  // Supports: @Tags(['unit', 'slow']) and @Tags(["unit"]).
  final match = _tagsAnnotationPattern.firstMatch(content);
  if (match == null) return tags;

  final insideBrackets = match.group(1) ?? '';
  for (final m in _quotedStringPattern.allMatches(insideBrackets)) {
    final tag = m.group(1);
    if (tag != null && tag.isNotEmpty) {
      tags.add(tag);
    }
  }

  return tags;
}

List<String>? _expectedTagsForPath(String normalizedRelPath) {
  if (normalizedRelPath.startsWith('test/core/')) return const ['unit'];
  if (normalizedRelPath.startsWith('test/domain/')) return const ['unit'];
  if (normalizedRelPath.startsWith('test/contracts/')) return const ['unit'];

  if (normalizedRelPath.startsWith('test/presentation/')) {
    return const ['widget', 'unit'];
  }

  if (normalizedRelPath.startsWith('test/data/')) {
    return const ['repository', 'integration'];
  }

  if (normalizedRelPath.startsWith('test/integration/')) {
    return const ['integration'];
  }

  if (normalizedRelPath.startsWith('test/integration_test/')) {
    return const ['pipeline'];
  }

  if (normalizedRelPath.startsWith('test/diagnosis/')) {
    return const ['diagnosis'];
  }

  return null;
}

final _tagsAnnotationPattern = RegExp(
  r'@Tags\(\s*\[(.*?)\]\s*\)',
  dotAll: true,
);

final _quotedStringPattern = RegExp(r"""['\"]([^'\"]+)['\"]""");

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

class _Violation {
  const _Violation({required this.path, required this.message});

  final String path;
  final String message;
}
