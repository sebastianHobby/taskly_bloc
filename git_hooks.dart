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

  var allPassed = true;

  // 1. Check for unsafe testWidgets usage
  allPassed = await _checkUnsafeTests() && allPassed;

  // 2. Run dart analyze (no warnings allowed)
  allPassed = await _runAnalyze() && allPassed;

  // 3. Run dart format check
  allPassed = await _runFormatCheck() && allPassed;

  if (allPassed) {
    print('\n✅ All pre-commit checks passed!');
  } else {
    print('\n❌ Pre-commit checks failed. Fix issues before committing.');
    print('   Use "git commit --no-verify" to bypass (not recommended).');
  }

  return allPassed;
}

Future<bool> prePush() async {
  print('🚀 Running pre-push checks...\n');

  var allPassed = true;

  // 1. Validate IdGenerator table registration
  allPassed = await _validateTableRegistration() && allPassed;

  // 2. Run tests with coverage (80% minimum)
  allPassed = await _runTestsWithCoverage() && allPassed;

  if (allPassed) {
    print('\n✅ All pre-push checks passed!');
  } else {
    print('\n❌ Pre-push checks failed. Fix issues before pushing.');
    print('   Use "git push --no-verify" to bypass (not recommended).');
  }

  return allPassed;
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
    const schemaPath = 'lib/data/powersync/schema.dart';

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

Future<bool> _runAnalyze() async {
  print('🔬 Running dart analyze...');

  try {
    final result = await Process.run(
      'dart',
      ['analyze', '--fatal-warnings'],
      runInShell: true,
    );

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

Future<bool> _runFormatCheck() async {
  print('🎨 Auto-formatting staged dart files...');

  try {
    // Get staged dart files
    final gitResult = await Process.run(
      'git',
      ['diff', '--cached', '--name-only', '--diff-filter=ACM'],
    );

    final stagedFiles = (gitResult.stdout as String)
        .split('\n')
        .where((f) => f.endsWith('.dart') && File(f).existsSync())
        .toList();

    if (stagedFiles.isEmpty) {
      print('   No Dart files staged.');
      return true;
    }

    // Auto-format the staged files
    final formatResult = await Process.run(
      'dart',
      ['format', ...stagedFiles],
      runInShell: true,
    );

    if (formatResult.exitCode != 0) {
      print('   ❌ Failed to format files.');
      print(formatResult.stderr);
      return false;
    }

    // Re-stage the formatted files
    final stageResult = await Process.run(
      'git',
      ['add', ...stagedFiles],
    );

    if (stageResult.exitCode != 0) {
      print('   ❌ Failed to re-stage formatted files.');
      print(stageResult.stderr);
      return false;
    }

    print('   ✓ Formatted and re-staged ${stagedFiles.length} files.');
    return true;
  } catch (e) {
    print('   ⚠️  Could not format files: $e');
    return true; // Don't block on check failure
  }
}

Future<bool> _runTestsWithCoverage() async {
  print('🧪 Running tests with coverage...');

  const minCoverage = 80.0;

  try {
    // Run tests with coverage
    final result = await Process.run(
      'flutter',
      ['test', '--no-pub', '--coverage'],
      runInShell: true,
    );

    if (result.exitCode != 0) {
      print(result.stdout);
      print('   ❌ Tests failed.');
      return false;
    }

    print('   ✓ All tests passed.');

    // Parse coverage from lcov.info
    final coverageFile = File('coverage/lcov.info');
    if (!coverageFile.existsSync()) {
      print('   ⚠️  No coverage file found. Skipping coverage check.');
      return true;
    }

    final coverage = _parseLcovCoverage(coverageFile.readAsStringSync());
    print('   📊 Code coverage: ${coverage.toStringAsFixed(1)}%');

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
/// Excludes generated files (*.g.dart, *.freezed.dart, *.drift.dart).
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
