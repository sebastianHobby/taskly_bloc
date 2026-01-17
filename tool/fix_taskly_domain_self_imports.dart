import 'dart:io';

import 'package:path/path.dart' as p;

void main() {
  final repoRoot = Directory.current;
  final domainLibRoot = p.join(
    repoRoot.path,
    'packages',
    'taskly_domain',
    'lib',
  );
  final domainFolder = Directory(p.join(domainLibRoot, 'domain'));

  if (!domainFolder.existsSync()) {
    stderr.writeln('Not found: ${domainFolder.path}');
    exitCode = 2;
    return;
  }

  final dartFiles = domainFolder
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  var changedFiles = 0;
  var changedLines = 0;

  for (final file in dartFiles) {
    final original = file.readAsStringSync();
    final updated = _rewritePackageSelfUris(
      original: original,
      filePath: file.path,
      libRoot: domainLibRoot,
    );

    if (updated != original) {
      file.writeAsStringSync(updated);
      changedFiles++;
      changedLines += _countLineDiff(original, updated);
    }
  }

  stdout.writeln(
    'Rewrote taskly_domain self URIs in $changedFiles file(s) '
    '($changedLines line(s) touched).',
  );
}

String _rewritePackageSelfUris({
  required String original,
  required String filePath,
  required String libRoot,
}) {
  final fileDir = p.dirname(filePath);
  final lines = original.split('\n');

  String rewriteLine(String line) {
    // Skip commented-out lines.
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('//')) return line;

    // Handle both import and export.
    final importIndex = line.indexOf("import '");
    final exportIndex = line.indexOf("export '");

    final keywordIndex = importIndex >= 0
        ? importIndex
        : (exportIndex >= 0 ? exportIndex : -1);
    if (keywordIndex < 0) return line;

    final firstQuote = line.indexOf("'", keywordIndex);
    if (firstQuote < 0) return line;
    final secondQuote = line.indexOf("'", firstQuote + 1);
    if (secondQuote < 0) return line;

    final uri = line.substring(firstQuote + 1, secondQuote);
    // If a URI uses Windows separators, normalize it first.
    // Backslashes in Dart string literals are escape introducers (e.g. "\t"),
    // so leaving them will produce invalid URIs.
    if (uri.contains('\\')) {
      final normalized = p.posix.normalize(uri.replaceAll('\\', '/'));
      return line.replaceRange(firstQuote + 1, secondQuote, normalized);
    }

    const prefix = 'package:taskly_domain/';
    if (!uri.startsWith(prefix)) return line;

    final suffix = uri.substring(prefix.length);
    final targetAbs = p.join(libRoot, suffix);
    final relative = p.posix.normalize(
      p.relative(targetAbs, from: fileDir).replaceAll('\\', '/'),
    );

    return line.replaceRange(firstQuote + 1, secondQuote, relative);
  }

  final rewritten = lines.map(rewriteLine).join('\n');
  return rewritten;
}

int _countLineDiff(String a, String b) {
  // Simple heuristic: count lines that changed when lengths match; else return 0.
  final aLines = a.split('\n');
  final bLines = b.split('\n');
  if (aLines.length != bLines.length) return 0;

  var diff = 0;
  for (var i = 0; i < aLines.length; i++) {
    if (aLines[i] != bLines[i]) diff++;
  }
  return diff;
}
