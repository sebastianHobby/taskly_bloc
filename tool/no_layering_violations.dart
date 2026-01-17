import 'dart:io';

/// Guardrail: enforce layering via imports.
///
/// Rules (normative):
/// - Presentation must not import Data.
/// - Domain/Data must not import Presentation.
///
/// Targets:
/// - lib/
/// - packages/taskly_*/lib/
///
/// Escape hatch:
/// - Add `// ignore-layering-guardrail` in a file to skip it.
Future<void> main(List<String> args) async {
  final repoRoot = Directory.current;

  final targets = <Directory>[
    Directory(_join(repoRoot.path, ['lib'])),
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

      final normalizedPath = _normalize(entity.path);
      if (normalizedPath.contains('/build/') ||
          normalizedPath.contains('/.dart_tool/') ||
          normalizedPath.contains('/.git/')) {
        continue;
      }
      if (normalizedPath.endsWith('.g.dart') ||
          normalizedPath.endsWith('.freezed.dart')) {
        continue;
      }

      // Limit packages scan to packages/taskly_*/lib/
      if (normalizedPath.contains('/packages/')) {
        final parts = normalizedPath.split('/');
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
      if (content.contains('// ignore-layering-guardrail')) {
        continue;
      }

      final relativePath = _toRelativePath(repoRoot.path, entity.path);
      final layer = _classifyLayer(relativePath);
      if (layer == null) continue;

      final lines = content.split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final match = _importLine.firstMatch(line);
        if (match == null) continue;

        final uri = match.group(2) ?? '';
        final importedLayer = _classifyImportedLayer(uri);
        if (importedLayer == null) continue;

        if (layer == _Layer.presentation && importedLayer == _Layer.data) {
          violations.add(
            _Violation(
              path: relativePath,
              lineNumber: i + 1,
              line: line.trimRight(),
              reason: 'presentation must not import data',
            ),
          );
        }

        if ((layer == _Layer.domain || layer == _Layer.data) &&
            importedLayer == _Layer.presentation) {
          violations.add(
            _Violation(
              path: relativePath,
              lineNumber: i + 1,
              line: line.trimRight(),
              reason: '${layer.name} must not import presentation',
            ),
          );
        }
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('✓ No layering import violations found.');
    return;
  }

  stderr.writeln('❌ Layering guardrail violations found:');
  stderr.writeln('   (presentation ↛ data, domain/data ↛ presentation)');
  stderr.writeln('');

  for (final v in violations) {
    stderr.writeln(' - ${v.path}:${v.lineNumber}');
    stderr.writeln('   ${v.reason}');
    stderr.writeln('   ${v.line.trim()}');
  }

  exitCode = 1;
}

// Match a single-line Dart import and capture its URI.
// Examples:
//   import 'package:taskly_bloc/presentation/foo.dart';
//   import "../data/bar.dart" as bar;
final RegExp _importLine = RegExp(
  r'''^\s*import\s+(["'])([^"']+)\1''',
);

enum _Layer {
  presentation,
  domain,
  data;

  String get name => toString().split('.').last;
}

_Layer? _classifyLayer(String relativePath) {
  final p = _normalize(relativePath);

  if (p.startsWith('lib/presentation/')) return _Layer.presentation;
  if (p.startsWith('lib/domain/')) return _Layer.domain;
  if (p.startsWith('lib/data/')) return _Layer.data;

  // Packages can contain domain/data; keep it conservative and only classify
  // obvious cases.
  if (p.startsWith('packages/') && p.contains('/lib/')) {
    if (p.contains('/presentation/')) return _Layer.presentation;
    if (p.contains('/domain/')) return _Layer.domain;
    if (p.contains('/data/')) return _Layer.data;
  }

  return null;
}

_Layer? _classifyImportedLayer(String uri) {
  final u = uri.trim();

  // Relative imports.
  if (!u.startsWith('package:')) {
    final normalized = _normalize(u);
    if (normalized.contains('/presentation/')) return _Layer.presentation;
    if (normalized.contains('/domain/')) return _Layer.domain;
    if (normalized.contains('/data/')) return _Layer.data;
    return null;
  }

  // package imports.
  // App package name is `taskly_bloc`.
  const appPackage = 'package:taskly_bloc/';
  if (u.startsWith(appPackage)) {
    final rest = u.substring(appPackage.length);
    if (rest.startsWith('presentation/')) return _Layer.presentation;
    if (rest.startsWith('domain/')) return _Layer.domain;
    if (rest.startsWith('data/')) return _Layer.data;
    return null;
  }

  // Enforce against `taskly_*` packages too.
  if (u.startsWith('package:taskly_')) {
    // Only classify if path contains explicit layer folder names.
    if (u.contains('/presentation/')) return _Layer.presentation;
    if (u.contains('/domain/')) return _Layer.domain;
    if (u.contains('/data/')) return _Layer.data;
  }

  return null;
}

class _Violation {
  const _Violation({
    required this.path,
    required this.lineNumber,
    required this.line,
    required this.reason,
  });

  final String path;
  final int lineNumber;
  final String line;
  final String reason;
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
