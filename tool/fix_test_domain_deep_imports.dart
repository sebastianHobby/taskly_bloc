import 'dart:io';

import 'package:path/path.dart' as p;

void main() {
  final repoRoot = Directory.current;
  final testRoots = <Directory>[
    Directory(p.join(repoRoot.path, 'test')),
  ];

  final existingRoots = testRoots.where((d) => d.existsSync()).toList();
  if (existingRoots.isEmpty) {
    stderr.writeln('No test/ folder found under ${repoRoot.path}');
    exitCode = 2;
    return;
  }

  final dartFiles = <File>[];
  for (final root in existingRoots) {
    dartFiles.addAll(
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')),
    );
  }

  var changedFiles = 0;
  var filesNeedingManualReview = 0;

  for (final file in dartFiles) {
    final original = file.readAsStringSync();

    // Only touch files that actually have deep imports.
    if (!original.contains('package:taskly_domain/domain/')) continue;

    final updated = _rewriteTestFile(original);

    if (updated == null) {
      filesNeedingManualReview++;
      continue;
    }

    if (updated != original) {
      file.writeAsStringSync(updated);
      changedFiles++;
    }
  }

  stdout.writeln(
    'Updated $changedFiles test file(s). '
    'Manual review needed for $filesNeedingManualReview file(s).',
  );
}

String? _rewriteTestFile(String original) {
  final lines = original.split('\n');

  bool isDeepDomainImportStartLine(String line) {
    final trimmed = line.trimLeft();
    return trimmed.startsWith("import 'package:taskly_domain/domain/") ||
        trimmed.startsWith('import "package:taskly_domain/domain/');
  }

  bool isOldInternalDomainBarrel(String line) {
    final trimmed = line.trim();
    return trimmed == "import 'package:taskly_domain/domain/domain.dart';" ||
        trimmed == 'import "package:taskly_domain/domain/domain.dart";';
  }

  bool isNewDirectiveStart(String line) {
    final trimmed = line.trimLeft();
    return trimmed.startsWith('import ') || trimmed.startsWith('export ');
  }

  final containsTasklyDomainPublicImport = lines.any(
    (l) =>
        l.contains("import 'package:taskly_domain/taskly_domain.dart';") ||
        l.contains('import "package:taskly_domain/taskly_domain.dart";'),
  );

  final kept = <String>[];
  var removedAny = false;

  var skippingMultilineDirective = false;

  for (final line in lines) {
    // Skip commented-out lines.
    if (line.trimLeft().startsWith('//')) {
      kept.add(line);
      continue;
    }

    if (skippingMultilineDirective) {
      // If we encounter another directive start, assume the previous one was
      // malformed and stop skipping so we don't delete unrelated imports.
      if (isNewDirectiveStart(line)) {
        skippingMultilineDirective = false;
        // fall through to process this line normally
      } else {
        removedAny = true;
        // End of a multi-line directive is the first line that has ';'.
        if (line.contains(';')) {
          skippingMultilineDirective = false;
        }
        continue;
      }
    }

    if (isOldInternalDomainBarrel(line) || isDeepDomainImportStartLine(line)) {
      removedAny = true;
      // If this line ends the directive, drop only this line. Otherwise, drop
      // subsequent continuation lines until we hit ';' or a new directive.
      if (!line.contains(';')) {
        skippingMultilineDirective = true;
      }
      continue;
    }

    kept.add(line);
  }

  if (!removedAny) return original;

  // Insert a single public import (unless it already exists).
  if (!containsTasklyDomainPublicImport) {
    final insertionIndex = _findImportInsertionIndex(kept);
    kept.insert(
      insertionIndex,
      "import 'package:taskly_domain/taskly_domain.dart';",
    );
  }

  // Remove duplicate public imports if any.
  final deduped = <String>[];
  var sawPublic = false;
  for (final line in kept) {
    if (line.trim() == "import 'package:taskly_domain/taskly_domain.dart';") {
      if (sawPublic) continue;
      sawPublic = true;
    }
    // Repair any orphaned continuation lines like `show Foo;` left behind by
    // a previous bad rewrite.
    final trimmed = line.trimLeft();
    if ((trimmed.startsWith('show ') || trimmed.startsWith('hide ')) &&
        deduped.isNotEmpty &&
        deduped.last.trimRight().endsWith(';')) {
      continue;
    }

    deduped.add(line);
  }

  return deduped.join('\n');
}

int _findImportInsertionIndex(List<String> lines) {
  // After library directives, comments, and other imports at the top.
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.startsWith('import ')) continue;
    if (line.startsWith('export ')) continue;
    if (line.startsWith('library')) continue;
    if (line.startsWith('part ')) continue;
    if (line.startsWith('//') || line.startsWith('/*') || line.isEmpty)
      continue;

    // Insert right before the first non-directive/non-comment code line.
    return i;
  }

  return lines.length;
}
