#!/usr/bin/env dart

// ignore_for_file: avoid_print
/// Filters lcov.info to exclude files that shouldn't count toward coverage targets.
///
/// Usage:
/// - dart run tool/coverage_filter.dart
/// - dart run tool/coverage_filter.dart --package taskly_data
///
/// This script reads coverage/lcov.info, removes excluded files, and writes
/// to coverage/lcov_filtered.info for reporting.
library;

import 'dart:io';

/// Files excluded from coverage requirements.
///
/// These fall into categories:
///
/// ## 1. Generated Files (already excluded by pattern)
/// - `*.g.dart` - JSON serialization (json_serializable)
/// - `*.freezed.dart` - Immutable classes (freezed)
///
/// ## 2. Localization Files
/// - `lib/l10n/` - Auto-generated and manually-written l10n
/// - Testing localization provides low value; the strings are verified
///   by the translation process and runtime usage.
///
/// ## 3. Configuration/Constants Files
/// - These are declarative data with no logic to test.
///
/// ## 4. Infrastructure Files
/// - Supabase/PowerSync integrations are tested via integration tests,
///   not unit tests, and require real database connections.
///
/// ## 5. *_config.dart Files
/// - **DisplayConfig**: Declarative screen display settings (sort, group, filter)
/// - **TriggerConfig**: Workflow trigger definitions (schedule, manual)
/// - **ScheduleViewConfig**: UI configuration for schedule views
/// - **TrackerResponseConfig**: Journal tracker field definitions
/// - These are pure data structures with no business logic - just
///   enums, freezed classes, and factory constructors. Testing them
///   would only verify that freezed generates correct code.

final excludedPatterns = [
  // Generated files
  RegExp(r'\.g\.dart$'),
  RegExp(r'\.freezed\.dart$'),
  RegExp(r'\.gen\.dart$'),
  RegExp(r'\.drift\.dart$'),

  // Localization
  RegExp(r'lib[/\\]core[/\\]l10n[/\\]'),
  RegExp(r'lib[/\\]l10n[/\\]'),

  // Database/sync infrastructure
  RegExp('supabase'),
  RegExp('powersync'),

  // Configuration files (declarative, no logic)
  RegExp(r'_config\.dart$'),

  // Theme/routing (UI configuration)
  RegExp(r'app_theme\.dart$'),
  RegExp(r'routes\.dart$'),

  // Constants (declarative)
  RegExp(r'constants\.dart$'),

  // Environment (build-time values)
  RegExp(r'env\.dart$'),

  // Logging infrastructure (side-effect only)
  RegExp(r'talker_service\.dart$'),
];

void main(List<String> args) {
  final parsed = _parseArgs(args);

  final inputFile = File(parsed.inputPath);
  if (!inputFile.existsSync()) {
    print(
      'Error: coverage/lcov.info not found. Run `flutter test --coverage` first.',
    );
    exit(1);
  }

  final lines = inputFile.readAsLinesSync();
  final output = StringBuffer();

  String? currentFile;
  final buffer = StringBuffer();
  var excludedCount = 0;
  var includedCount = 0;

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      buffer.clear();
      buffer.writeln(line);
    } else if (line == 'end_of_record') {
      buffer.writeln(line);

      final filePath = currentFile;
      final isInPackage =
          parsed.packageName == null ||
          (filePath != null && _isInPackage(filePath, parsed.packageName!));

      if (filePath != null && isInPackage && !_isExcluded(filePath)) {
        output.write(buffer);
        includedCount++;
      } else {
        excludedCount++;
      }

      currentFile = null;
    } else {
      buffer.writeln(line);
    }
  }

  final outputFile = File(parsed.outputPath);
  outputFile.writeAsStringSync(output.toString());

  print('Coverage filter complete:');
  if (parsed.packageName != null) {
    print('  Package: ${parsed.packageName}');
  }
  print('  Included: $includedCount files');
  print('  Excluded: $excludedCount files');
  print('  Output: ${parsed.outputPath}');
  print('');
  print('To generate HTML report:');
  print('  genhtml coverage/lcov_filtered.info -o coverage/html');
}

bool _isExcluded(String filePath) {
  for (final pattern in excludedPatterns) {
    if (pattern.hasMatch(filePath)) {
      return true;
    }
  }
  return false;
}

bool _isInPackage(String filePath, String packageName) {
  final normalized = filePath.replaceAll(r'\', '/');
  if (packageName == 'taskly_bloc') {
    return normalized.contains('/lib/');
  }

  return normalized.contains('/packages/$packageName/lib/');
}

class _Args {
  const _Args({
    required this.inputPath,
    required this.outputPath,
    required this.packageName,
  });

  final String inputPath;
  final String outputPath;
  final String? packageName;
}

_Args _parseArgs(List<String> args) {
  String inputPath = 'coverage/lcov.info';
  String outputPath = 'coverage/lcov_filtered.info';
  String? packageName;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--package' && i + 1 < args.length) {
      packageName = args[++i];
      continue;
    }
    if (a == '--input' && i + 1 < args.length) {
      inputPath = args[++i];
      continue;
    }
    if (a == '--output' && i + 1 < args.length) {
      outputPath = args[++i];
      continue;
    }
  }

  return _Args(
    inputPath: inputPath,
    outputPath: outputPath,
    packageName: packageName,
  );
}
