#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

class _FileCoverage {
  _FileCoverage({
    required this.path,
    required this.linesFound,
    required this.linesHit,
  });

  final String path;
  final int linesFound;
  final int linesHit;

  double get percent =>
      linesFound == 0 ? 100.0 : (linesHit / linesFound) * 100.0;
}

final _excluded = <RegExp>[
  RegExp(r'\.g\.dart$'),
  RegExp(r'\.freezed\.dart$'),
  RegExp(r'\.gen\.dart$'),
  RegExp(r'\.drift\.dart$'),
];

String _normalizePath(String raw) {
  final normalized = raw.replaceAll(r'\\', '/');

  if (normalized.startsWith('package:')) {
    final withoutScheme = normalized.substring('package:'.length);
    final firstSlash = withoutScheme.indexOf('/');
    if (firstSlash != -1) {
      final packageName = withoutScheme.substring(0, firstSlash);
      final relativeToLib = withoutScheme.substring(firstSlash + 1);
      if (packageName == 'taskly_core') {
        return 'packages/taskly_core/lib/$relativeToLib';
      }
    }
  }

  final packagesIndex = normalized.indexOf('/packages/');
  if (packagesIndex != -1) {
    return normalized.substring(packagesIndex + 1);
  }

  return normalized;
}

bool _isExcluded(String path) => _excluded.any((r) => r.hasMatch(path));

List<_FileCoverage> _parseLcov(File file) {
  final lines = file.readAsLinesSync();

  String? currentFile;
  int? lf;
  int? lh;

  final results = <_FileCoverage>[];

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = _normalizePath(line.substring(3));
      lf = null;
      lh = null;
      continue;
    }

    if (line.startsWith('LF:')) {
      lf = int.tryParse(line.substring(3));
      continue;
    }

    if (line.startsWith('LH:')) {
      lh = int.tryParse(line.substring(3));
      continue;
    }

    if (line == 'end_of_record') {
      final path = currentFile;
      if (path != null) {
        results.add(
          _FileCoverage(
            path: path,
            linesFound: lf ?? 0,
            linesHit: lh ?? 0,
          ),
        );
      }

      currentFile = null;
      lf = null;
      lh = null;
    }
  }

  return results;
}

void main(List<String> args) {
  var inputPath = 'coverage/lcov.info';
  double? minPercent;

  for (final a in args) {
    if (a.startsWith('--input=')) {
      inputPath = a.substring('--input='.length);
    } else if (a.startsWith('--min=')) {
      minPercent = double.tryParse(a.substring('--min='.length));
    } else if (!a.startsWith('--') && a.isNotEmpty) {
      // Backwards compatible: first positional arg is input path.
      inputPath = a;
    }
  }

  final file = File(inputPath);
  if (!file.existsSync()) {
    stderr.writeln('Error: $inputPath not found.');
    stderr.writeln('Run (from packages/taskly_core): flutter test --coverage');
    exitCode = 1;
    return;
  }

  final records = _parseLcov(file)
      .where((r) => r.path.startsWith('packages/taskly_core/lib/'))
      .where((r) => !_isExcluded(r.path))
      .toList();

  final totalLf = records.fold<int>(0, (sum, r) => sum + r.linesFound);
  final totalLh = records.fold<int>(0, (sum, r) => sum + r.linesHit);
  final pct = totalLf == 0 ? 100.0 : (totalLh / totalLf) * 100.0;

  print(
    'taskly_core coverage: ${pct.toStringAsFixed(2)}% (LH=$totalLh / LF=$totalLf) from $inputPath',
  );

  if (minPercent != null) {
    if (pct + 1e-9 < minPercent) {
      stderr.writeln('FAIL: expected >= ${minPercent.toStringAsFixed(2)}%');
      exitCode = 1;
    } else {
      print('OK: meets >= ${minPercent.toStringAsFixed(2)}%');
    }
  }

  // Print lowest-covered files to guide the next test additions.
  final eligible = records.where((r) => r.linesFound >= 20).toList()
    ..sort((a, b) {
      final pc = a.percent.compareTo(b.percent);
      if (pc != 0) return pc;
      return b.linesFound.compareTo(a.linesFound);
    });

  const bottomN = 10;
  if (eligible.isNotEmpty) {
    print('');
    print('Bottom $bottomN taskly_core files (LF >= 20):');
    for (final r in eligible.take(bottomN)) {
      print(
        '  ${r.percent.toStringAsFixed(2).padLeft(6)}%  (LH=${r.linesHit.toString().padLeft(4)} / LF=${r.linesFound.toString().padLeft(4)})  ${r.path}',
      );
    }
  }
}
