import 'dart:io';

Future<void> main() async {
  final workspaceRoot = Directory.current;

  final replacements = <String, String>{
    // taskly_data now uses a curated public API and hides implementation under lib/src.
    // This replacement is intentionally broad; follow up by choosing the correct
    // public entrypoint (e.g. taskly_data.dart, data_stack.dart, db.dart, sync.dart).
    'package:taskly_bloc/data/': 'package:taskly_data/',
    // Note: taskly_core now uses curated top-level entrypoints (env.dart, logging.dart).
    // This replacement is intentionally coarse; follow up by choosing the correct entrypoint.
    'package:taskly_bloc/core/': 'package:taskly_core/',
  };

  final targets = <Directory>[
    Directory.fromUri(workspaceRoot.uri.resolve('packages/taskly_data/lib/')),
    Directory.fromUri(workspaceRoot.uri.resolve('packages/taskly_domain/lib/')),
  ];

  var changedFiles = 0;
  var changedImports = 0;

  for (final dir in targets) {
    if (!dir.existsSync()) {
      stderr.writeln('Skip missing: ${dir.path}');
      continue;
    }

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      final original = await entity.readAsString();
      var updated = original;

      for (final entry in replacements.entries) {
        final before = updated;
        updated = updated.replaceAll(entry.key, entry.value);
        if (updated != before) {
          changedImports += _countOccurrences(before, entry.key);
        }
      }

      if (updated != original) {
        await entity.writeAsString(updated);
        changedFiles++;
      }
    }
  }

  stdout.writeln(
    'Updated $changedFiles files; rewrote ~$changedImports imports.',
  );
}

int _countOccurrences(String text, String needle) {
  var count = 0;
  var index = 0;
  while (true) {
    index = text.indexOf(needle, index);
    if (index == -1) return count;
    count++;
    index += needle.length;
  }
}
