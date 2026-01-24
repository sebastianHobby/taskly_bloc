#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

class _FileCoverage {
  _FileCoverage(this.path);

  final String path;
  final Map<int, int> lineHits = <int, int>{};

  void addHit(int line, int count) {
    lineHits[line] = (lineHits[line] ?? 0) + count;
  }
}

class _Args {
  const _Args({
    required this.inputs,
    required this.output,
  });

  final List<String> inputs;
  final String output;
}

_Args _parseArgs(List<String> args) {
  final inputs = <String>[];
  var output = 'coverage/lcov_merged.info';

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--input' && i + 1 < args.length) {
      inputs.add(args[++i]);
      continue;
    }
    if (a == '--inputs' && i + 1 < args.length) {
      final raw = args[++i];
      inputs.addAll(
        raw.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty),
      );
      continue;
    }
    if (a == '--output' && i + 1 < args.length) {
      output = args[++i];
      continue;
    }
  }

  if (inputs.isEmpty) {
    inputs.add('coverage/lcov.info');
  }

  return _Args(inputs: inputs, output: output);
}

void main(List<String> args) {
  final parsed = _parseArgs(args);

  final files = <_FileCoverage>{};
  final missingInputs = <String>[];

  for (final input in parsed.inputs) {
    final file = File(input);
    if (!file.existsSync()) {
      missingInputs.add(input);
      continue;
    }

    String? currentFile;
    for (final line in file.readAsLinesSync()) {
      if (line.startsWith('SF:')) {
        currentFile = line.substring(3);
        files.putIfAbsent(currentFile, () => _FileCoverage(currentFile));
        continue;
      }

      if (line.startsWith('DA:')) {
        final payload = line.substring(3);
        final parts = payload.split(',');
        if (parts.length >= 2 && currentFile != null) {
          final lineNo = int.tryParse(parts[0]);
          final count = int.tryParse(parts[1]);
          if (lineNo != null && count != null) {
            files[currentFile]!.addHit(lineNo, count);
          }
        }
        continue;
      }
    }
  }

  if (missingInputs.isNotEmpty) {
    print('Warning: missing coverage inputs:');
    for (final input in missingInputs) {
      print('  - $input');
    }
  }

  final outputFile = File(parsed.output);
  outputFile.parent.createSync(recursive: true);

  final buffer = StringBuffer();
  final keys = files.keys.toList()..sort();

  for (final path in keys) {
    final record = files[path]!;
    buffer.writeln('SF:$path');

    final lineNumbers = record.lineHits.keys.toList()..sort();
    var lh = 0;
    for (final lineNo in lineNumbers) {
      final hits = record.lineHits[lineNo]!;
      if (hits > 0) {
        lh++;
      }
      buffer.writeln('DA:$lineNo,$hits');
    }

    final lf = lineNumbers.length;
    buffer.writeln('LF:$lf');
    buffer.writeln('LH:$lh');
    buffer.writeln('end_of_record');
  }

  outputFile.writeAsStringSync(buffer.toString());
  print('Merged coverage: ${parsed.output}');
  print('  Inputs: ${parsed.inputs.length}');
  print('  Files: ${files.length}');
}
