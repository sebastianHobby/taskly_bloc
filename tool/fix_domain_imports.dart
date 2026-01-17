import 'dart:io';

/// Fixes broken imports of the form:
///   package:taskly_domain/domain//{suffix}
/// created by an earlier incorrect PowerShell replacement.
///
/// It resolves {suffix} against actual files under
/// `packages/taskly_domain/lib/domain/` using a suffix match.
Future<void> main() async {
  final repoRoot = Directory.current.path;
  final domainRoot = Directory(
    p(repoRoot, ['packages', 'taskly_domain', 'lib', 'domain']),
  );

  if (!domainRoot.existsSync()) {
    stderr.writeln('Domain root not found: ${domainRoot.path}');
    exitCode = 2;
    return;
  }

  final domainRelPaths = <String>[];
  for (final file in domainRoot.listSync(recursive: true, followLinks: false)) {
    if (file is! File) continue;
    if (!file.path.endsWith('.dart')) continue;
    final rel = file.path
        .substring(domainRoot.path.length + 1)
        .replaceAll(r'\', '/');
    domainRelPaths.add(rel);
  }

  String? resolveSuffix(String suffix) {
    final normalized = suffix.replaceAll(r'\', '/');
    final bySuffix = domainRelPaths
        .where((p) => p.endsWith(normalized))
        .toList(growable: false);
    if (bySuffix.length == 1) return bySuffix.single;

    final fileName = normalized.split('/').last;
    final byName = domainRelPaths
        .where((p) => p.split('/').last == fileName)
        .toList(growable: false);
    if (byName.length == 1) return byName.single;

    return null;
  }

  final targets = <Directory>[
    Directory(p(repoRoot, ['lib'])),
    Directory(p(repoRoot, ['test'])),
  ];

  final importPattern = RegExp("package:taskly_domain/domain//([^'\";]+)");

  var filesTouched = 0;
  var importsFixed = 0;
  final unresolved = <String, int>{};

  for (final dir in targets) {
    if (!dir.existsSync()) continue;

    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      final original = entity.readAsStringSync();
      if (!original.contains('package:taskly_domain/domain//')) continue;

      var changed = false;
      final updated = original.replaceAllMapped(importPattern, (match) {
        final suffix = match.group(1)!;
        final resolved = resolveSuffix(suffix);
        if (resolved == null) {
          unresolved[suffix] = (unresolved[suffix] ?? 0) + 1;
          return match.group(0)!;
        }
        importsFixed++;
        changed = true;
        return 'package:taskly_domain/domain/$resolved';
      });

      if (changed) {
        entity.writeAsStringSync(updated);
        filesTouched++;
      }
    }
  }

  stdout.writeln('Fixed imports: $importsFixed');
  stdout.writeln('Touched files: $filesTouched');
  if (unresolved.isNotEmpty) {
    stdout.writeln('Unresolved suffixes (top 25):');
    final items = unresolved.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in items.take(25)) {
      stdout.writeln('  ${e.value}x  ${e.key}');
    }
  }
}

String p(String root, List<String> parts) {
  var out = root;
  for (final part in parts) {
    out = out.endsWith(Platform.pathSeparator)
        ? '$out$part'
        : '$out${Platform.pathSeparator}$part';
  }
  return out;
}
