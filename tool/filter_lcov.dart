import 'dart:io';

/// Filters an LCOV report by excluding specific source files.
///
/// Usage:
///   dart run tool/filter_lcov.dart \
///     --in coverage/lcov.info \
///     --out coverage/lcov.filtered.info \
///     --exclude lib/data/drift/drift_database.dart
void main(List<String> args) {
  final inPath = _argValue(args, '--in') ?? 'coverage/lcov.info';
  final outPath = _argValue(args, '--out') ?? 'coverage/lcov.filtered.info';
  final excludes = _argValues(args, '--exclude');

  if (excludes.isEmpty) {
    stderr.writeln('No --exclude provided. Nothing to filter.');
    exitCode = 2;
    return;
  }

  final inFile = File(inPath);
  if (!inFile.existsSync()) {
    stderr.writeln('Input file not found: $inPath');
    exitCode = 2;
    return;
  }

  final excludeSet = excludes
      .map((e) => e.replaceAll(r'\', '/'))
      .map((e) => e.startsWith('/') ? e.substring(1) : e)
      .toSet();

  final output = StringBuffer();
  final lines = inFile.readAsLinesSync();

  String? currentSf;
  final record = <String>[];

  void flushRecord() {
    if (record.isEmpty) return;

    final sf = currentSf;
    if (sf != null) {
      final normalized = sf.replaceAll(r'\', '/');
      // LCOV SF entries may be absolute paths. Exclude by suffix match.
      final shouldExclude = excludeSet.any(
        (ex) => normalized == ex || normalized.endsWith('/$ex'),
      );
      if (!shouldExclude) {
        for (final l in record) {
          output.writeln(l);
        }
      }
    }

    record.clear();
    currentSf = null;
  }

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      flushRecord();
      currentSf = line.substring(3);
      record.add(line);
      continue;
    }

    record.add(line);

    if (line.trim() == 'end_of_record') {
      flushRecord();
    }
  }

  flushRecord();

  File(outPath)
    ..createSync(recursive: true)
    ..writeAsStringSync(output.toString());

  stdout.writeln('Wrote filtered LCOV to $outPath');
}

String? _argValue(List<String> args, String name) {
  final idx = args.indexOf(name);
  if (idx == -1) return null;
  if (idx + 1 >= args.length) return null;
  return args[idx + 1];
}

List<String> _argValues(List<String> args, String name) {
  final values = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == name && i + 1 < args.length) {
      values.add(args[i + 1]);
      i++;
    }
  }
  return values;
}
