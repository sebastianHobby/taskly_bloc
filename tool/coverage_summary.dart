#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

class FileCoverage {
  FileCoverage({
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

String _normalizePath(String raw) {
  final normalized = raw.replaceAll(r'\', '/');

  if (normalized.startsWith('package:')) {
    final withoutScheme = normalized.substring('package:'.length);
    final firstSlash = withoutScheme.indexOf('/');
    if (firstSlash != -1) {
      final packageName = withoutScheme.substring(0, firstSlash);
      final relativeToLib = withoutScheme.substring(firstSlash + 1);

      if (packageName == 'taskly_bloc') {
        return 'lib/$relativeToLib';
      }

      if (packageName.startsWith('taskly_')) {
        return 'packages/$packageName/lib/$relativeToLib';
      }
    }
  }

  // Prefer keeping local package paths intact so coverage can be grouped.
  // Example: /.../packages/taskly_domain/lib/foo.dart -> packages/taskly_domain/lib/foo.dart
  final packagesIndex = normalized.indexOf('/packages/');
  if (packagesIndex != -1) {
    return normalized.substring(packagesIndex + 1);
  }

  final libIndex = normalized.indexOf('/lib/');
  if (libIndex != -1) return normalized.substring(libIndex + 1);

  // Fallback: try to shorten absolute paths by finding "lib/".
  final altIndex = normalized.indexOf('lib/');
  if (altIndex != -1) return normalized.substring(altIndex);

  return normalized;
}

String _groupFor(String normalizedPath) {
  if (normalizedPath.startsWith('packages/taskly_core/lib/')) {
    return 'pkg/taskly_core';
  }
  if (normalizedPath.startsWith('packages/taskly_domain/lib/')) {
    return 'pkg/taskly_domain';
  }
  if (normalizedPath.startsWith('packages/taskly_data/lib/')) {
    return 'pkg/taskly_data';
  }
  if (normalizedPath.startsWith('packages/taskly_ui/lib/')) {
    return 'pkg/taskly_ui';
  }

  if (normalizedPath.startsWith('lib/domain/')) return 'domain';
  if (normalizedPath.startsWith('lib/data/')) return 'data';
  if (normalizedPath.startsWith('lib/presentation/')) return 'presentation';
  if (normalizedPath.startsWith('lib/core/')) return 'core';
  if (normalizedPath.startsWith('lib/shared/')) return 'shared';
  if (normalizedPath.startsWith('lib/')) return 'lib/other';
  return 'other';
}

List<FileCoverage> _parseLcov(File file) {
  final lines = file.readAsLinesSync();

  String? currentFile;
  int? lf;
  int? lh;

  final results = <FileCoverage>[];

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
          FileCoverage(
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
  final inputPath = args.isNotEmpty
      ? args.first
      : 'coverage/lcov_filtered.info';

  final file = File(inputPath);
  if (!file.existsSync()) {
    stderr.writeln('Error: $inputPath not found.');
    stderr.writeln('Run: flutter test --coverage');
    stderr.writeln('Then: dart run tool/coverage_filter.dart');
    exitCode = 1;
    return;
  }

  final records = _parseLcov(file);

  final totalLf = records.fold<int>(0, (sum, r) => sum + r.linesFound);
  final totalLh = records.fold<int>(0, (sum, r) => sum + r.linesHit);
  final totalPct = totalLf == 0 ? 100.0 : (totalLh / totalLf) * 100.0;

  print(
    'Filtered coverage (official): ${totalPct.toStringAsFixed(2)}% (LH=$totalLh / LF=$totalLf)',
  );

  final byGroup = <String, List<FileCoverage>>{};
  for (final r in records) {
    byGroup.putIfAbsent(_groupFor(r.path), () => <FileCoverage>[]).add(r);
  }

  final groupKeys = byGroup.keys.toList()..sort();
  for (final group in groupKeys) {
    final groupRecords = byGroup[group]!;
    final lf = groupRecords.fold<int>(0, (sum, r) => sum + r.linesFound);
    final lh = groupRecords.fold<int>(0, (sum, r) => sum + r.linesHit);
    final pct = lf == 0 ? 100.0 : (lh / lf) * 100.0;
    print('  - $group: ${pct.toStringAsFixed(2)}% (LH=$lh / LF=$lf)');
  }

  const bottomN = 20;
  const minLines = 30;

  final eligible = records.where((r) => r.linesFound >= minLines).toList()
    ..sort((a, b) {
      final pc = a.percent.compareTo(b.percent);
      if (pc != 0) return pc;
      return b.linesFound.compareTo(a.linesFound);
    });

  print('');
  print('Bottom $bottomN files by coverage (LF >= $minLines):');

  for (final r in eligible.take(bottomN)) {
    print(
      '  ${r.percent.toStringAsFixed(2).padLeft(6)}%  (LH=${r.linesHit.toString().padLeft(4)} / LF=${r.linesFound.toString().padLeft(4)})  ${r.path}',
    );
  }

  // Additional view: prioritize large files that are still low coverage.
  const lowCoverageThreshold = 30.0;
  const largeMinLines = 150;
  const largestN = 20;

  final lowAndLarge =
      records
          .where(
            (r) =>
                r.linesFound >= largeMinLines &&
                r.percent < lowCoverageThreshold,
          )
          .toList()
        ..sort((a, b) {
          final lf = b.linesFound.compareTo(a.linesFound);
          if (lf != 0) return lf;
          return a.percent.compareTo(b.percent);
        });

  print('');
  print(
    'Largest $largestN files under ${lowCoverageThreshold.toStringAsFixed(0)}% coverage (LF >= $largeMinLines):',
  );

  if (lowAndLarge.isEmpty) {
    print('  (none)');
    return;
  }

  for (final r in lowAndLarge.take(largestN)) {
    print(
      '  ${r.percent.toStringAsFixed(2).padLeft(6)}%  (LH=${r.linesHit.toString().padLeft(4)} / LF=${r.linesFound.toString().padLeft(4)})  ${r.path}',
    );
  }
}
