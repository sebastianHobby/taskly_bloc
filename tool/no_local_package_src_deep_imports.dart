import 'dart:convert';
import 'dart:io';

/// Fails if any file imports or exports `package:<local>/src/...` where `<local>`
/// is a package under `packages/`, and the importing file is outside that
/// package.
///
/// This enforces Dart's conventional visibility boundary:
/// - `lib/` is public API
/// - `lib/src/` is implementation detail
///
/// Allowlist (optional)
///
/// Create `tool/no_local_package_src_deep_imports.allowlist.json`:
///
/// ```json
/// {
///   "rules": [
///     {
///       "importerPrefix": "packages/taskly_data/",
///       "targetPrefix": "package:taskly_domain/src/some_internal_bridge/"
///     }
///   ]
/// }
/// ```
///
/// A match is allowed when:
/// - the file's repo-relative path starts with `importerPrefix`, AND
/// - the import/export line contains `targetPrefix`.
Future<void> main(List<String> args) async {
  final repoRoot = Directory.current;

  final localPackages = _discoverLocalPackages(repoRoot);
  if (localPackages.isEmpty) {
    stdout.writeln('✓ No local packages under packages/ found.');
    return;
  }

  final allowlist = _loadAllowlist(repoRoot);

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

      if (normalized.endsWith('.g.dart') ||
          normalized.endsWith('.freezed.dart')) {
        continue;
      }

      final content = entity.readAsStringSync();
      if (!content.contains('package:')) continue;

      final relPath = _toRelativePath(repoRoot.path, entity.path);
      final lines = content.split('\n');

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];

        // Only care about import/export directives.
        if (!_looksLikeImportOrExport(line)) continue;

        final targetPackage = _extractLocalSrcTargetPackage(
          line: line,
          localPackages: localPackages,
        );
        if (targetPackage == null) continue;

        final targetPackageDirPrefix = 'packages/$targetPackage/';

        // Allowed: importing from within the same package.
        if (_normalize(relPath).startsWith(targetPackageDirPrefix)) {
          continue;
        }

        // Allowed: explicit allowlist exceptions.
        if (allowlist.allows(importerPath: relPath, directiveLine: line)) {
          continue;
        }

        violations.add(
          _Violation(
            path: relPath,
            lineNumber: i + 1,
            line: line.trimRight(),
            targetPackage: targetPackage,
          ),
        );
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('✓ No local package src deep imports found.');
    return;
  }

  stderr.writeln(
    '❌ Found deep imports into local package internals (lib/src):',
  );
  stderr.writeln(
    '   (Do not use package:<local>/src/... from outside that package)',
  );
  stderr.writeln('');

  for (final v in violations) {
    stderr.writeln(' - ${v.path}:${v.lineNumber} (-> ${v.targetPackage})');
    stderr.writeln('   ${v.line}');
  }

  stderr.writeln('');
  stderr.writeln(
    'Fix: import from the public API of that package instead, e.g.',
  );
  stderr.writeln(
    ' - package:${violations.first.targetPackage}/${violations.first.targetPackage}.dart',
  );
  stderr.writeln(
    ' - or another public entrypoint under lib/ (feature barrels)',
  );

  exitCode = 1;
}

Map<String, String> _discoverLocalPackages(Directory repoRoot) {
  final packagesDir = Directory(_join(repoRoot.path, 'packages'));
  if (!packagesDir.existsSync()) return <String, String>{};

  final result = <String, String>{};

  for (final entity in packagesDir.listSync(followLinks: false)) {
    if (entity is! Directory) continue;

    final pubspec = File(_join(entity.path, 'pubspec.yaml'));
    if (!pubspec.existsSync()) continue;

    final name = _readPubspecName(pubspec);
    if (name == null || name.isEmpty) continue;

    result[name] = _normalize(_toRelativePath(repoRoot.path, entity.path));
  }

  return result;
}

String? _readPubspecName(File pubspecFile) {
  try {
    final content = pubspecFile.readAsStringSync();
    final match = RegExp(
      r'^name:\s*([^\s#]+)\s*$',
      multiLine: true,
    ).firstMatch(content);
    return match?.group(1);
  } catch (_) {
    return null;
  }
}

String? _extractLocalSrcTargetPackage({
  required String line,
  required Map<String, String> localPackages,
}) {
  for (final packageName in localPackages.keys) {
    final needle = 'package:$packageName/src/';
    if (line.contains(needle)) {
      return packageName;
    }
  }
  return null;
}

bool _looksLikeImportOrExport(String line) {
  final trimmed = line.trimLeft();
  return trimmed.startsWith('import ') || trimmed.startsWith('export ');
}

_Allowlist _loadAllowlist(Directory repoRoot) {
  final allowlistFile = File(
    _join(
      repoRoot.path,
      'tool/no_local_package_src_deep_imports.allowlist.json',
    ),
  );

  if (!allowlistFile.existsSync()) {
    return const _Allowlist(rules: <_AllowRule>[]);
  }

  try {
    final json = jsonDecode(allowlistFile.readAsStringSync());
    if (json is! Map<String, Object?>) {
      return const _Allowlist(rules: <_AllowRule>[]);
    }

    final rulesJson = json['rules'];
    if (rulesJson is! List<Object?>) {
      return const _Allowlist(rules: <_AllowRule>[]);
    }

    final rules = <_AllowRule>[];
    for (final entry in rulesJson) {
      if (entry is! Map<String, Object?>) continue;
      final importerPrefix = entry['importerPrefix'];
      final targetPrefix = entry['targetPrefix'];
      if (importerPrefix is! String || targetPrefix is! String) continue;
      if (importerPrefix.isEmpty || targetPrefix.isEmpty) continue;

      rules.add(
        _AllowRule(
          importerPrefix: _normalize(importerPrefix),
          targetPrefix: targetPrefix,
        ),
      );
    }

    return _Allowlist(rules: rules);
  } catch (_) {
    return const _Allowlist(rules: <_AllowRule>[]);
  }
}

class _Allowlist {
  const _Allowlist({required this.rules});

  final List<_AllowRule> rules;

  bool allows({required String importerPath, required String directiveLine}) {
    final normalizedImporterPath = _normalize(importerPath);

    for (final rule in rules) {
      if (!normalizedImporterPath.startsWith(rule.importerPrefix)) continue;
      if (!directiveLine.contains(rule.targetPrefix)) continue;
      return true;
    }

    return false;
  }
}

class _AllowRule {
  _AllowRule({required this.importerPrefix, required this.targetPrefix});

  final String importerPrefix;
  final String targetPrefix;
}

class _Violation {
  _Violation({
    required this.path,
    required this.lineNumber,
    required this.line,
    required this.targetPackage,
  });

  final String path;
  final int lineNumber;
  final String line;
  final String targetPackage;
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
