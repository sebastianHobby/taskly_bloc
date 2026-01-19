#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';

/// Runs `flutter test --coverage` for `packages/taskly_domain`, filters LCOV using
/// repo tooling, prints a focused summary, and fails if coverage is below 80%.
///
/// Usage:
///   dart run tool/coverage_taskly_domain.dart
///
/// Optional args:
///   --min=80.0
///   --package=taskly_domain
Future<void> main(List<String> args) async {
  var packageName = 'taskly_domain';
  var minCoverage = 80.0;
  var skipTests = false;

  for (final arg in args) {
    if (arg.startsWith('--package=')) {
      packageName = arg.substring('--package='.length);
    } else if (arg.startsWith('--min=')) {
      minCoverage = double.parse(arg.substring('--min='.length));
    } else if (arg == '--skip-tests') {
      skipTests = true;
    }
  }

  final repoRoot = Directory.current;
  final packageDir = Directory(
    '${repoRoot.path}${Platform.pathSeparator}packages'
    '${Platform.pathSeparator}$packageName',
  );

  if (!packageDir.existsSync()) {
    stderr.writeln('Error: package directory not found: ${packageDir.path}');
    exitCode = 1;
    return;
  }

  final flutterOk = await _run(
    'flutter',
    const ['--version'],
    workingDirectory: packageDir.path,
    echo: false,
  );
  if (!flutterOk) {
    stderr.writeln('Error: flutter is not available on PATH.');
    exitCode = 1;
    return;
  }

  print('Running coverage for $packageName...');

  if (!skipTests) {
    final testsOk = await _run(
      'flutter',
      const ['test', '--coverage'],
      workingDirectory: packageDir.path,
    );
    if (!testsOk) {
      stderr.writeln('Error: flutter test failed.');
      exitCode = 1;
      return;
    }
  }

  final filterOk = await _run(
    'dart',
    const ['run', '../../tool/coverage_filter.dart'],
    workingDirectory: packageDir.path,
  );
  if (!filterOk) {
    stderr.writeln('Error: coverage_filter.dart failed.');
    exitCode = 1;
    return;
  }

  final filtered = File(
    '${packageDir.path}${Platform.pathSeparator}coverage'
    '${Platform.pathSeparator}lcov_filtered.info',
  );
  if (!filtered.existsSync()) {
    stderr.writeln('Error: filtered LCOV not found: ${filtered.path}');
    exitCode = 1;
    return;
  }

  final percent = _computeCoveragePercent(filtered);
  print(
    'taskly_domain filtered coverage: ${percent.toStringAsFixed(2)}% '
    '(min ${minCoverage.toStringAsFixed(2)}%)',
  );

  // Keep the standard repo summary output too (useful for bottom-N files).
  await _run(
    'dart',
    const [
      'run',
      '../../tool/coverage_summary.dart',
      'coverage/lcov_filtered.info',
    ],
    workingDirectory: packageDir.path,
  );

  if (percent + 1e-9 < minCoverage) {
    stderr.writeln(
      'FAIL: $packageName coverage ${percent.toStringAsFixed(2)}% '
      'is below ${minCoverage.toStringAsFixed(2)}%.',
    );
    exitCode = 2;
  }
}

bool _isInTasklyDomainLib(String filePath) {
  final normalized = filePath.replaceAll(r'\', '/');

  // Coverage can report either absolute paths or package-relative paths.
  // - Absolute: C:/.../packages/taskly_domain/lib/...
  // - Relative: lib/... (when tests are run from the package directory)
  if (normalized.startsWith('lib/')) return true;
  return normalized.contains('/packages/taskly_domain/lib/') ||
      normalized.contains('/taskly_domain/lib/');
}

/// Computes total LH/LF from an LCOV file, scoped to taskly_domain's lib.
///
/// Assumes [lcovFiltered] has already removed generated and excluded files.
double _computeCoveragePercent(File lcovFiltered) {
  String? currentFile;
  var lf = 0;
  var lh = 0;

  var totalLf = 0;
  var totalLh = 0;

  for (final line in lcovFiltered.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      lf = 0;
      lh = 0;
      continue;
    }

    if (line.startsWith('LF:')) {
      lf = int.tryParse(line.substring(3)) ?? 0;
      continue;
    }

    if (line.startsWith('LH:')) {
      lh = int.tryParse(line.substring(3)) ?? 0;
      continue;
    }

    if (line == 'end_of_record') {
      if (currentFile != null && _isInTasklyDomainLib(currentFile)) {
        totalLf += lf;
        totalLh += lh;
      }
      currentFile = null;
      lf = 0;
      lh = 0;
    }
  }

  if (totalLf == 0) return 100;
  return (totalLh / totalLf) * 100.0;
}

Future<bool> _run(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  bool echo = true,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: true,
  );

  if (echo) {
    stdout.writeln(
      r'$ '
      '$executable ${arguments.join(' ')}',
    );
  }

  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);

  final code = await process.exitCode;
  return code == 0;
}
