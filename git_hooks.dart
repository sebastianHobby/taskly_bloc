import 'dart:io';

import 'package:git_hooks/git_hooks.dart';

void main(List<String> arguments) {
  final params = <Git, UserBackFun>{
    Git.preCommit: preCommit,
    Git.prePush: prePush,
  };
  GitHooks.call(arguments, params);
}

Future<bool> preCommit() async {
  print('🔍 Running pre-commit checks...\n');

  print('\n✅ All pre-commit checks passed!');
  return true;
}

Future<bool> prePush() async {
  print('🚀 Running pre-push checks...\n');

  // 1. Check for unsafe testWidgets usage
  if (!await _checkUnsafeTests()) {
    _printFailure();
    return false;
  }

  // 2. Check for raw StreamController usage in tests
  if (!await _checkRawStreamController()) {
    _printFailure();
    return false;
  }

  // 3. Run flutter analyze (no warnings allowed)
  if (!await _runAnalyze()) {
    _printFailure();
    return false;
  }

  // 4. Validate IdGenerator table registration
  if (!await _validateTableRegistration()) {
    _printFailure();
    return false;
  }

  // 5. Run tests with coverage (staged gate; filtered lcov)
  if (!await _runTestsWithCoverage()) {
    _printFailure();
    return false;
  }

  print('\n✅ All pre-push checks passed!');
  return true;
}

void _printFailure() {
  print('\n❌ Pre-push checks failed. Fix issues before pushing.');
  print('   Use "git push --no-verify" to bypass (not recommended).');
}

/// Validates that all PowerSync tables are registered in IdGenerator.
///
/// Parses both files and compares table names to find missing registrations.
Future<bool> _validateTableRegistration() async {
  print('📋 Validating IdGenerator table registration...');

  try {
    // Path to IdGenerator
    const idGeneratorPath = 'lib/data/id/id_generator.dart';

    // Path to PowerSync schema
    const schemaPath = 'lib/data/infrastructure/powersync/schema.dart';

    final idGeneratorFile = File(idGeneratorPath);
    final schemaFile = File(schemaPath);

    if (!idGeneratorFile.existsSync()) {
      print('   ⚠️  IdGenerator file not found at $idGeneratorPath');
      return true; // Don't block if file doesn't exist yet
    }

    if (!schemaFile.existsSync()) {
      print('   ⚠️  Schema file not found at $schemaPath');
      return true; // Don't block if file doesn't exist yet
    }

    final idGeneratorContent = idGeneratorFile.readAsStringSync();
    final schemaContent = schemaFile.readAsStringSync();

    // Extract table names from PowerSync schema
    // Pattern: Table('table_name', [...])
    final schemaTablePattern = RegExp(r"Table\(\s*'(\w+)'");
    final schemaTables = schemaTablePattern
        .allMatches(schemaContent)
        .map((m) => m.group(1)!)
        .toSet();

    // Extract tables from v5Tables set
    // Pattern: 'table_name',
    final v5Pattern = RegExp(r'v5Tables\s*=\s*\{([^}]+)\}');
    final v5Match = v5Pattern.firstMatch(idGeneratorContent);
    final v5Tables = <String>{};
    if (v5Match != null) {
      final tablePattern = RegExp(r"'(\w+)'");
      v5Tables.addAll(
        tablePattern.allMatches(v5Match.group(1)!).map((m) => m.group(1)!),
      );
    }

    // Extract tables from v4Tables set
    final v4Pattern = RegExp(r'v4Tables\s*=\s*\{([^}]+)\}');
    final v4Match = v4Pattern.firstMatch(idGeneratorContent);
    final v4Tables = <String>{};
    if (v4Match != null) {
      final tablePattern = RegExp(r"'(\w+)'");
      v4Tables.addAll(
        tablePattern.allMatches(v4Match.group(1)!).map((m) => m.group(1)!),
      );
    }

    // Combine registered tables
    final registeredTables = {...v5Tables, ...v4Tables};

    // Find tables in schema but not registered
    final unregisteredTables = schemaTables.difference(registeredTables);

    // Find tables registered but not in schema (orphaned)
    final orphanedTables = registeredTables.difference(schemaTables);

    var hasIssues = false;

    if (unregisteredTables.isNotEmpty) {
      print('   ❌ Tables in schema but NOT registered in IdGenerator:');
      for (final table in unregisteredTables.toList()..sort()) {
        print('      - $table');
      }
      print('   Add these to v5Tables or v4Tables in id_generator.dart');
      hasIssues = true;
    }

    if (orphanedTables.isNotEmpty) {
      print('   ⚠️  Tables registered in IdGenerator but NOT in schema:');
      for (final table in orphanedTables.toList()..sort()) {
        print('      - $table');
      }
      print('   Consider removing these from id_generator.dart');
      // Warning only, don't fail
    }

    if (!hasIssues) {
      print('   ✓ All ${schemaTables.length} tables are registered.');
      print('     - v5 (deterministic): ${v5Tables.length} tables');
      print('     - v4 (random): ${v4Tables.length} tables');
    }

    return !hasIssues;
  } catch (e) {
    print('   ⚠️  Could not validate table registration: $e');
    return true; // Don't block on check failure
  }
}

Future<bool> _checkUnsafeTests() async {
  print('📋 Checking for unsafe testWidgets usage...');

  try {
    // Get staged dart test files
    final result = await Process.run(
      'git',
      ['diff', '--cached', '--name-only', '--diff-filter=ACM'],
    );

    final stagedFiles = (result.stdout as String)
        .split('\n')
        .where((f) => f.endsWith('_test.dart'))
        .toList();

    if (stagedFiles.isEmpty) {
      print('   No test files staged.');
      return true;
    }

    var hasUnsafe = false;

    for (final file in stagedFiles) {
      final fileObj = File(file);
      if (!fileObj.existsSync()) continue;

      final content = fileObj.readAsStringSync();
      final lines = content.split('\n');

      // Check 1: testWidgets + pumpAndSettle (widget tests at risk of hanging)
      final usesPumpAndSettle = content.contains('pumpAndSettle');
      if (usesPumpAndSettle) {
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          // Check for testWidgets( that is NOT testWidgetsSafe(
          if (line.contains('testWidgets(') &&
              !line.contains('testWidgetsSafe(') &&
              !line.contains('// safe:')) {
            print(
              '   ⚠️  $file:${i + 1}: Use testWidgetsSafe() instead of testWidgets()',
            );
            hasUnsafe = true;
          }
        }
      }

      // Check 2: async test() + StreamController (unit tests at risk of hanging)
      final usesStreamController = content.contains('StreamController');
      if (usesStreamController) {
        // Regex to find async tests: test('...', () async {
        final asyncTestPattern = RegExp(r"^\s*test\s*\(\s*'");
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          // Check for test( that is NOT testSafe( in files with StreamController
          if (asyncTestPattern.hasMatch(line) &&
              !line.contains('testSafe(') &&
              !line.contains('// safe:')) {
            // Look ahead to see if this test is async
            final nextLines = lines
                .skip(i)
                .take(3)
                .join('\n'); // Check next 3 lines
            if (nextLines.contains('async')) {
              print(
                '   ⚠️  $file:${i + 1}: Use testSafe() instead of test() for async tests with streams',
              );
              hasUnsafe = true;
            }
          }
        }
      }
    }

    if (hasUnsafe) {
      print('   ❌ Found unsafe test patterns.');
      print('   These combinations can hang indefinitely with BLoC streams.');
      print(
        '   Replace testWidgets() with testWidgetsSafe() from test_helpers.dart',
      );
      print(
        '   Replace test() with testSafe() for async tests using streams',
      );
      print(
        '   Or add "// safe:" comment if you\'re certain the test cannot hang.',
      );
      return false;
    }

    print('   ✓ No unsafe test patterns found.');
    return true;
  } catch (e) {
    print('   ⚠️  Could not check test files: $e');
    return true; // Don't block on check failure
  }
}

/// Checks for raw StreamController usage in bloc tests.
///
/// Raw StreamController can cause test hangs because:
/// 1. `act()` fires event AND emits data simultaneously
/// 2. Bloc's event handler subscribes to stream AFTER emit
/// 3. Data is lost - test waits forever for states that never arrive
///
/// Use TestStreamController from bloc_test_patterns.dart instead.
Future<bool> _checkRawStreamController() async {
  print('🔄 Checking for raw StreamController usage in tests...');

  try {
    // Find all test files using git ls-files for better performance
    final result = await Process.run(
      'git',
      ['ls-files', 'test/', '--', '*.dart'],
    );

    final testFiles = (result.stdout as String)
        .split('\n')
        .where((f) => f.endsWith('_test.dart'))
        .toList();

    if (testFiles.isEmpty) {
      print('   No test files found.');
      return true;
    }

    final violations = <String>[];

    // Patterns to detect raw StreamController usage
    final streamControllerPattern = RegExp(
      r'StreamController\s*<',
      caseSensitive: true,
    );

    // Allowed patterns (whitelist)
    final allowedPatterns = [
      'TestStreamController', // Our safe wrapper
      'bloc_test_patterns.dart', // The file that defines TestStreamController
      '// ignore-stream-controller', // Explicit opt-out
      'widget_test_helpers.dart', // Other test infrastructure
      'fake_repositories.dart', // Fake repos use internal streams safely
    ];

    for (final filePath in testFiles) {
      final file = File(filePath);
      if (!file.existsSync()) continue;

      final content = file.readAsStringSync();

      // Skip if file uses allowed patterns
      if (allowedPatterns.any(content.contains)) continue;

      // Check for raw StreamController
      if (streamControllerPattern.hasMatch(content)) {
        final lines = content.split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (streamControllerPattern.hasMatch(line) &&
              !line.contains('TestStreamController') &&
              !line.contains('// ignore-stream-controller')) {
            violations.add('   $filePath:${i + 1}: ${line.trim()}');
          }
        }
      }
    }

    if (violations.isNotEmpty) {
      print('   ❌ Found raw StreamController usage in test files:\n');
      violations.take(10).forEach(print);
      if (violations.length > 10) {
        print('   ... and ${violations.length - 10} more');
      }
      print('');
      print('   Raw StreamController can cause tests to hang indefinitely.');
      print(
        '   Use TestStreamController from bloc_test_patterns.dart instead:',
      );
      print('');
      print('     // Before (can hang):');
      print('     final controller = StreamController<List<Task>>();');
      print('');
      print('     // After (safe):');
      print('     final controller = TestStreamController<List<Task>>();');
      print(
        '     controller.emit([task]);  // Safe - replays to late subscribers',
      );
      print('');
      print('   Add "// ignore-stream-controller" to line if intentional.');
      return false;
    }

    print('   ✓ No raw StreamController usage found in tests.');
    return true;
  } catch (e) {
    print('   ⚠️  Could not check for raw StreamController: $e');
    return true; // Don't block on check failure
  }
}

Future<bool> _runAnalyze() async {
  print('🔬 Running flutter analyze...');

  try {
    final result = await Process.run('flutter', ['analyze'], runInShell: true);

    final stdout = (result.stdout as String).trim();
    final stderr = (result.stderr as String).trim();

    if (result.exitCode != 0) {
      print('   ❌ Analysis found issues:\n');
      if (stdout.isNotEmpty) {
        // Filter out info-level messages, keep only warnings and errors
        // Format: "  info - path:line:col - message - rule"
        final infoPattern = RegExp(r'^\s*info\s*-');
        final lines = stdout.split('\n').where((line) {
          return !infoPattern.hasMatch(line);
        }).toList();
        if (lines.isNotEmpty) {
          final indented = lines.map((l) => '   $l').join('\n');
          print(indented);
        }
      }
      if (stderr.isNotEmpty) {
        final indented = stderr.split('\n').map((l) => '   $l').join('\n');
        print(indented);
      }
      print('');
      return false;
    }

    print('   ✓ No analysis issues found.');
    return true;
  } catch (e) {
    print('   ⚠️  Could not run analyzer: $e');
    return false;
  }
}

double _coverageGatePercent() {
  // Supports staged gates so developers don't need permanent --no-verify.
  //
  // Overrides:
  // - TASKLY_COVERAGE_MIN: a direct percent (e.g. "55")
  // - TASKLY_COVERAGE_GATE: an integer stage 1..6
  //
  // Gate ramp:
  // 1: 35%
  // 2: 45%
  // 3: 55%
  // 4: 65%
  // 5: 75%
  // 6: 80%
  final direct = double.tryParse(
    Platform.environment['TASKLY_COVERAGE_MIN'] ?? '',
  );
  if (direct != null) return direct;

  const gates = <double>[35, 45, 55, 65, 75, 80];
  final stageRaw = Platform.environment['TASKLY_COVERAGE_GATE'];
  final stage = int.tryParse(stageRaw ?? '') ?? 1;
  final idx = (stage - 1).clamp(0, gates.length - 1);
  return gates[idx];
}

Future<bool> _runTestsWithCoverage() async {
  print('🧪 Running tests with coverage...');

  final minCoverage = _coverageGatePercent();

  try {
    // Run tests with coverage
    final result = await Process.run(
      'flutter',
      ['test', '--no-pub', '--coverage', '--preset=no_pipeline'],
      runInShell: true,
    );

    if (result.exitCode != 0) {
      print(result.stdout);
      print('   ❌ Tests failed.');
      return false;
    }

    print('   ✓ All tests passed.');

    // Convert coverage/lcov.info -> coverage/lcov_filtered.info (official metric)
    final coverageFile = File('coverage/lcov.info');
    if (!coverageFile.existsSync()) {
      print('   ⚠️  coverage/lcov.info not found. Skipping coverage gate.');
      return true;
    }

    final filterResult = await Process.run(
      'dart',
      ['run', 'tool/coverage_filter.dart'],
      runInShell: true,
    );

    if (filterResult.exitCode != 0) {
      print(filterResult.stdout);
      print(filterResult.stderr);
      print('   ⚠️  Coverage filter failed. Skipping coverage gate.');
      return true;
    }

    final filteredFile = File('coverage/lcov_filtered.info');
    if (!filteredFile.existsSync()) {
      print(
        '   ⚠️  coverage/lcov_filtered.info not found. Skipping coverage gate.',
      );
      return true;
    }

    final coverage = _parseLcovCoverage(filteredFile.readAsStringSync());
    print('   📊 Filtered coverage: ${coverage.toStringAsFixed(1)}%');

    if (coverage < minCoverage) {
      print(
        '   ❌ Coverage ${coverage.toStringAsFixed(1)}% is below minimum ${minCoverage.toStringAsFixed(0)}%',
      );
      return false;
    }

    print('   ✓ Coverage meets ${minCoverage.toStringAsFixed(0)}% minimum.');
    return true;
  } catch (e) {
    print('   ⚠️  Could not run tests: $e');
    return false;
  }
}

/// Patterns for generated files to exclude from coverage.
const _generatedFilePatterns = [
  '.g.dart',
  '.freezed.dart',
  '.drift.dart',
];

/// Check if a file path matches any generated file pattern.
bool _isGeneratedFile(String filePath) {
  return _generatedFilePatterns.any((pattern) => filePath.endsWith(pattern));
}

/// Parse LCOV coverage file and return overall coverage percentage.
///
/// Note: this is intended for `coverage/lcov_filtered.info`.
double _parseLcovCoverage(String lcovContent) {
  var totalLines = 0;
  var coveredLines = 0;
  var currentFile = '';
  var skipCurrentFile = false;

  for (final line in lcovContent.split('\n')) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      skipCurrentFile = _isGeneratedFile(currentFile);
    } else if (!skipCurrentFile) {
      if (line.startsWith('LF:')) {
        totalLines += int.tryParse(line.substring(3)) ?? 0;
      } else if (line.startsWith('LH:')) {
        coveredLines += int.tryParse(line.substring(3)) ?? 0;
      }
    }
  }

  if (totalLines == 0) return 100;
  return (coveredLines / totalLines) * 100;
}
