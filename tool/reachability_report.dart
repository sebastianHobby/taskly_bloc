import 'dart:collection';
import 'dart:convert';
import 'dart:io';

/// Generates a reachability report for taskly_* packages.
///
/// What it does:
/// - Starts from app entrypoints (defaults to lib/main.dart + lib/bootstrap.dart)
/// - Recursively follows `import`, `export`, and `part` directives
/// - Resolves `package:` URIs for:
///   - package:taskly_bloc/  -> lib/
///   - package:taskly_core/  -> packages/taskly_core/lib/
///   - package:taskly_domain/-> packages/taskly_domain/lib/
///   - package:taskly_data/  -> packages/taskly_data/lib/
/// - Computes which Dart files under each taskly_* package lib/ are reachable.
///
/// Notes:
/// - This is conservative and static: it can't see reflection/dynamic loading.
/// - It treats `part` files as reachable when their library is reachable.
/// - It does not attempt to resolve arbitrary third-party packages.
Future<void> main(List<String> args) async {
  final root = Directory.current.absolute;

  // Never traverse tests by default. This keeps the report focused on what the
  // app runtime can reach.
  const excludedRootPrefixes = <String>[
    'test/',
    'integration_test/',
    'tool/',
  ];

  final entrypoints = args.isEmpty
      ? <String>['lib/main.dart', 'lib/bootstrap.dart']
      : args;

  final rootPath = root.path;
  final rootUri = root.uri;

  bool isExcludedRelativePath(String relativePath) {
    final normalized = relativePath.replaceAll(r'\', '/');
    return excludedRootPrefixes.any(
      (prefix) => normalized == prefix || normalized.startsWith(prefix),
    );
  }

  bool isExcludedFile(File file) {
    final rel = _toRel(root, file);
    return isExcludedRelativePath(rel);
  }

  final resolvedEntrypoints = <File>[];
  for (final relative in entrypoints) {
    if (isExcludedRelativePath(relative)) {
      stderr.writeln('Skipping excluded entrypoint: $relative');
      continue;
    }
    final file = File(_PathUtil.join(rootPath, relative));
    if (!await file.exists()) {
      stderr.writeln('Missing entrypoint: $relative');
      exitCode = 2;
      return;
    }
    resolvedEntrypoints.add(file);
  }

  if (resolvedEntrypoints.isEmpty) {
    stderr.writeln('No valid entrypoints (all were excluded or missing).');
    exitCode = 2;
    return;
  }

  final resolver = _Resolver(root);

  final visited = <String>{};
  final queue = Queue<File>()..addAll(resolvedEntrypoints);

  while (queue.isNotEmpty) {
    final file = queue.removeFirst();
    if (isExcludedFile(file)) continue;

    final normalized = _normalizePath(file.absolute.path);
    if (!visited.add(normalized)) continue;

    final content = await _readTextSafe(file);
    if (content == null) continue;

    final directives = _parseDirectives(content);
    for (final uri in directives) {
      final resolved = await resolver.resolve(uri, from: file);
      if (resolved == null) continue;
      if (!_isInsideRoot(resolved, rootUri)) continue;

      if (isExcludedFile(resolved)) continue;
      queue.add(resolved);
    }
  }

  final report = await _buildReport(root, visited);

  final outDir = Directory(_PathUtil.join(rootPath, 'build_out'));
  if (!await outDir.exists()) {
    await outDir.create(recursive: true);
  }

  final txtOut = File(_PathUtil.join(outDir.path, 'reachability_report.txt'));
  await txtOut.writeAsString(_renderTextReport(report), flush: true);

  final jsonOut = File(_PathUtil.join(outDir.path, 'reachability_report.json'));
  await jsonOut.writeAsString(
    const JsonEncoder.withIndent('  ').convert(report.toJson()),
    flush: true,
  );

  stdout.writeln('Wrote: ${_toRel(root, txtOut)}');
  stdout.writeln('Wrote: ${_toRel(root, jsonOut)}');
}

class _PathUtil {
  static String join(String a, String b, [String? c, String? d, String? e]) {
    final parts = <String>[a, b];
    if (c != null) parts.add(c);
    if (d != null) parts.add(d);
    if (e != null) parts.add(e);
    return parts.join(Platform.pathSeparator);
  }
}

class _Resolver {
  _Resolver(this.root);

  final Directory root;

  static const _knownPackageRoots = <String, String>{
    'taskly_bloc': 'lib',
    'taskly_core': 'packages/taskly_core/lib',
    'taskly_domain': 'packages/taskly_domain/lib',
    'taskly_data': 'packages/taskly_data/lib',
  };

  Future<File?> resolve(String uri, {required File from}) async {
    // Ignore SDK / Flutter / external packages.
    if (uri.startsWith('dart:') || uri.startsWith('flutter:')) return null;

    if (uri.startsWith('package:')) {
      final rest = uri.substring('package:'.length);
      final slashIndex = rest.indexOf('/');
      if (slashIndex <= 0) return null;

      final pkg = rest.substring(0, slashIndex);
      final pathInPkg = rest.substring(slashIndex + 1);

      final pkgRoot = _knownPackageRoots[pkg];
      if (pkgRoot == null) return null;

      final filePath = _PathUtil.join(root.path, pkgRoot, pathInPkg);
      final f = File(filePath);
      if (await f.exists()) return f;
      return null;
    }

    // Relative URI.
    final fromDir = from.parent;
    final resolved = fromDir.uri.resolve(uri);
    final f = File.fromUri(resolved);
    if (await f.exists()) return f;
    return null;
  }
}

List<String> _parseDirectives(String content) {
  final directives = <String>[];

  // Simple directive parser to avoid pulling analyzer deps.
  //
  // Requirements:
  // - Must handle multi-line directives (e.g. `import '...'
  //     as foo;`).
  // - Must handle additional clauses like `as`, `show`, `hide`, and
  //   conditional imports.
  //
  // We strip comments first and then match directives up to the terminating
  // semicolon.
  final withoutBlockComments = content.replaceAll(
    RegExp(r'/\*[\s\S]*?\*/'),
    '',
  );
  final withoutComments = withoutBlockComments.replaceAll(
    RegExp('//.*'),
    '',
  );

  final rx = RegExp(
    r'''^\s*(import|export|part)\s+(?:'([^']+)'|"([^"]+)")[^;]*;''',
    multiLine: true,
  );

  for (final match in rx.allMatches(withoutComments)) {
    final uri = match.group(2) ?? match.group(3);
    if (uri != null) directives.add(uri);
  }

  return directives;
}

Future<String?> _readTextSafe(File file) async {
  try {
    return await file.readAsString();
  } catch (_) {
    return null;
  }
}

bool _isInsideRoot(File file, Uri rootUri) {
  final fileUri = file.absolute.uri;
  return fileUri.toString().startsWith(rootUri.toString());
}

String _normalizePath(String path) => path.replaceAll(r'\', '/');

String _toRel(Directory root, File file) {
  final r = root.path.replaceAll(r'\', '/');
  final f = file.path.replaceAll(r'\', '/');
  if (f.startsWith('$r/')) return f.substring(r.length + 1);
  return f;
}

class ReachabilityReport {
  ReachabilityReport({
    required this.root,
    required this.visitedFiles,
    required this.packages,
  });

  final String root;
  final int visitedFiles;
  final List<PackageReach> packages;

  Map<String, Object?> toJson() => {
    'root': root,
    'visitedFiles': visitedFiles,
    'packages': packages.map((p) => p.toJson()).toList(),
  };
}

class PackageReach {
  PackageReach({
    required this.packageName,
    required this.totalFiles,
    required this.reachableFiles,
    required this.unreachableFiles,
    required this.unreachableGeneratedFiles,
    required this.unreachableRegularFiles,
  });

  final String packageName;
  final int totalFiles;
  final int reachableFiles;
  final List<String> unreachableFiles;
  final int unreachableGeneratedFiles;
  final int unreachableRegularFiles;

  Map<String, Object?> toJson() => {
    'packageName': packageName,
    'totalFiles': totalFiles,
    'reachableFiles': reachableFiles,
    'unreachableFiles': unreachableFiles,
    'unreachableGeneratedFiles': unreachableGeneratedFiles,
    'unreachableRegularFiles': unreachableRegularFiles,
  };
}

Future<ReachabilityReport> _buildReport(
  Directory root,
  Set<String> visitedAbsPaths,
) async {
  final rootPath = root.path;

  Future<PackageReach> package(String name) async {
    final pkgLib = Directory(_PathUtil.join(rootPath, 'packages', name, 'lib'));
    if (!await pkgLib.exists()) {
      return PackageReach(
        packageName: name,
        totalFiles: 0,
        reachableFiles: 0,
        unreachableFiles: const [],
        unreachableGeneratedFiles: 0,
        unreachableRegularFiles: 0,
      );
    }

    final all = await pkgLib
        .list(recursive: true)
        .where((e) => e is File && e.path.endsWith('.dart'))
        .cast<File>()
        .toList();

    all.sort((a, b) => a.path.compareTo(b.path));

    int reachable = 0;
    final unreachable = <String>[];
    int unreachableGenerated = 0;

    for (final f in all) {
      final abs = _normalizePath(f.absolute.path);
      final rel = _toRel(root, f);
      final isReachable = visitedAbsPaths.contains(abs);
      if (isReachable) {
        reachable++;
      } else {
        unreachable.add(rel);
        if (_looksGenerated(rel)) unreachableGenerated++;
      }
    }

    final unreachableRegular = unreachable.length - unreachableGenerated;

    return PackageReach(
      packageName: name,
      totalFiles: all.length,
      reachableFiles: reachable,
      unreachableFiles: unreachable,
      unreachableGeneratedFiles: unreachableGenerated,
      unreachableRegularFiles: unreachableRegular,
    );
  }

  final packages = <PackageReach>[
    await package('taskly_core'),
    await package('taskly_domain'),
    await package('taskly_data'),
  ];

  return ReachabilityReport(
    root: rootPath.replaceAll(r'\', '/'),
    visitedFiles: visitedAbsPaths.length,
    packages: packages,
  );
}

bool _looksGenerated(String relPath) {
  return relPath.endsWith('.g.dart') ||
      relPath.endsWith('.freezed.dart') ||
      relPath.endsWith('.drift.dart');
}

String _renderTextReport(ReachabilityReport r) {
  final b = StringBuffer();
  b.writeln('Reachability report (static imports/exports/parts)');
  b.writeln('Root: ${r.root}');
  b.writeln('Visited Dart files: ${r.visitedFiles}');
  b.writeln('');

  for (final pkg in r.packages) {
    b.writeln('=== ${pkg.packageName} ===');
    b.writeln('Total package files: ${pkg.totalFiles}');
    b.writeln('Reachable files: ${pkg.reachableFiles}');
    b.writeln(
      'Unreachable files: ${pkg.unreachableFiles.length} (generated: ${pkg.unreachableGeneratedFiles}, regular: ${pkg.unreachableRegularFiles})',
    );

    if (pkg.unreachableFiles.isNotEmpty) {
      b.writeln('Sample unreachable files (up to 40):');
      for (final u in pkg.unreachableFiles.take(40)) {
        b.writeln('  $u');
      }
    }

    b.writeln('');
  }

  b.writeln('Notes:');
  b.writeln(
    '- This follows static import/export/part only; dynamic usage is not detected.',
  );
  b.writeln(
    '- “Unreachable” here means not referenced from the chosen entrypoints via directives.',
  );

  return b.toString();
}
