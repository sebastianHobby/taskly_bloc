#!/usr/bin/env dart

// ignore_for_file: avoid_print
/// Filters lcov.info to exclude files that shouldn't count toward coverage targets.
///
/// Usage: dart run tool/coverage_filter.dart
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

void main() {
  final inputFile = File('coverage/lcov.info');
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

      if (currentFile != null && !_isExcluded(currentFile)) {
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

  final outputFile = File('coverage/lcov_filtered.info');
  outputFile.writeAsStringSync(output.toString());

  print('Coverage filter complete:');
  print('  Included: $includedCount files');
  print('  Excluded: $excludedCount files');
  print('  Output: coverage/lcov_filtered.info');
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
