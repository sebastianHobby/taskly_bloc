import 'dart:io';

final _linkPattern = RegExp(r'\[[^\]]+\]\(([^)]+)\)');

void main(List<String> args) {
  final root = Directory('doc/architecture');
  if (!root.existsSync()) {
    stderr.writeln('Missing doc/architecture directory.');
    exit(2);
  }

  final missing = <String>[];

  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.md')) {
      continue;
    }

    final lines = entity.readAsLinesSync();
    var inFence = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('```')) {
        inFence = !inFence;
        continue;
      }
      if (inFence) continue;

      for (final match in _linkPattern.allMatches(line)) {
        final rawLink = match.group(1);
        if (rawLink == null) continue;

        final link = rawLink.trim();
        if (link.isEmpty) continue;
        if (link.startsWith('http://') || link.startsWith('https://')) continue;
        if (link.startsWith('#')) continue;
        if (!link.contains('.md') && !link.contains('.dart')) continue;

        final cleanLink = link.split('#').first.trim();
        if (cleanLink.isEmpty) continue;

        final targetUri = entity.uri.resolve(cleanLink);
        final targetPath = targetUri.toFilePath();
        if (FileSystemEntity.typeSync(targetPath) ==
            FileSystemEntityType.notFound) {
          missing.add('${entity.path} -> $cleanLink');
        }
      }
    }
  }

  if (missing.isNotEmpty) {
    stderr.writeln('Missing doc links:');
    for (final entry in missing) {
      stderr.writeln('  $entry');
    }
    exit(1);
  }

  stdout.writeln('All architecture doc links are valid.');
}
