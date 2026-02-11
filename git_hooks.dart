import 'dart:io';

import 'package:git_hooks/git_hooks.dart';

const _testLogDir = 'tool/logs';
const _testLogPrefix = 'pre-push-tests-';
const _testLogRetention = Duration(days: 7);
const _testLogMaxFiles = 20;

void main(List<String> arguments) {
  final params = <Git, UserBackFun>{
    Git.preCommit: preCommit,
    Git.prePush: prePush,
  };
  GitHooks.call(arguments, params);
}

Future<bool> preCommit() async {
  print('Running pre-commit checks...\n');

  print('\nAll pre-commit checks passed!');
  return true;
}

Future<bool> prePush() async {
  print('Running pre-push checks...\n');

  // 1. Get dependencies
  if (!await _runPubGet()) {
    _printFailure();
    return false;
  }

  // 2. Generate code
  if (!await _runBuildRunner()) {
    _printFailure();
    return false;
  }

  // 3. Run repo guardrails
  if (!await _runGuardrails()) {
    _printFailure();
    return false;
  }

  // 4. Run flutter analyze
  if (!await _runAnalyze()) {
    _printFailure();
    return false;
  }

  // 5. Check formatting
  if (!await _runFormatCheck()) {
    _printFailure();
    return false;
  }

  // 6. Check for unsafe testWidgets usage
  if (!await _checkUnsafeTestWidgets()) {
    _printFailure();
    return false;
  }

  // 7. Check for unsafe async test() with StreamController
  if (!await _checkUnsafeAsyncTestWithStreamController()) {
    _printFailure();
    return false;
  }

  // 8. Check for raw StreamController usage in tests
  if (!await _checkRawStreamControllerUsage()) {
    _printFailure();
    return false;
  }

  // 9. Validate IdGenerator table registration
  if (!await _validateTableRegistration()) {
    _printFailure();
    return false;
  }

  // 10. Run tests (no coverage gate)
  if (!await _runTests()) {
    _printFailure();
    return false;
  }

  print('\nAll pre-push checks passed!');
  return true;
}

Future<bool> _runPubGet() async {
  print('Getting dependencies...');

  try {
    final rootResult = await Process.run(
      'flutter',
      ['pub', 'get'],
      runInShell: true,
    );
    if (rootResult.exitCode != 0) {
      stdout.write(rootResult.stdout);
      stderr.write(rootResult.stderr);
      return false;
    }

    final domainResult = await Process.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: 'packages/taskly_domain',
      runInShell: true,
    );
    if (domainResult.exitCode != 0) {
      stdout.write(domainResult.stdout);
      stderr.write(domainResult.stderr);
      return false;
    }

    final dataResult = await Process.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: 'packages/taskly_data',
      runInShell: true,
    );
    if (dataResult.exitCode != 0) {
      stdout.write(dataResult.stdout);
      stderr.write(dataResult.stderr);
      return false;
    }

    print('   Dependencies resolved.');
    return true;
  } catch (e) {
    print('   Could not get dependencies: $e');
    return false;
  }
}

Future<bool> _runBuildRunner() async {
  print('Generating code...');

  Future<bool> runFor(String? workingDirectory) async {
    final result = await Process.run(
      'dart',
      ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    if (result.exitCode != 0) {
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      return false;
    }
    return true;
  }

  try {
    if (!await runFor(null)) return false;
    if (!await runFor('packages/taskly_domain')) return false;
    if (!await runFor('packages/taskly_data')) return false;

    print('   Code generation completed.');
    return true;
  } catch (e) {
    print('   Could not run build_runner: $e');
    return false;
  }
}

Future<bool> _runGuardrails() async {
  print('Running repo guardrails...');

  try {
    final result = await Process.run(
      'dart',
      ['run', 'tool/guardrails.dart'],
      runInShell: true,
    );

    stdout.write(result.stdout);
    stderr.write(result.stderr);

    if (result.exitCode != 0) {
      return false;
    }
    return true;
  } catch (e) {
    print('   Could not run guardrails: $e');
    return false;
  }
}

Future<bool> _runAnalyze() async {
  print('Running flutter analyze...');

  try {
    final result = await Process.run(
      'flutter',
      ['analyze', '--fatal-warnings', '--no-fatal-infos'],
      runInShell: true,
    );

    final stdout = (result.stdout as String).trim();
    final stderr = (result.stderr as String).trim();

    if (result.exitCode != 0) {
      print('   Analysis found issues:\n');
      if (stdout.isNotEmpty) {
        final indented = stdout.split('\n').map((l) => '   $l').join('\n');
        print(indented);
      }
      if (stderr.isNotEmpty) {
        final indented = stderr.split('\n').map((l) => '   $l').join('\n');
        print(indented);
      }
      print('');
      return false;
    }

    print('   No analysis issues found.');
    return true;
  } catch (e) {
    print('   Could not run analyzer: $e');
    return false;
  }
}

Future<bool> _runFormatCheck() async {
  print('Checking formatting...');

  try {
    final result = await Process.run(
      'dart',
      ['format', '--set-exit-if-changed', '.'],
      runInShell: true,
    );

    stdout.write(result.stdout);
    stderr.write(result.stderr);

    if (result.exitCode != 0) {
      print('   Formatting check failed.');
      return false;
    }

    print('   Formatting is up to date.');
    return true;
  } catch (e) {
    print('   Could not run format check: $e');
    return false;
  }
}

Future<bool> _checkUnsafeTestWidgets() async {
  print('Checking for unsafe testWidgets usage...');

  try {
    final testFiles = Directory('test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('_test.dart'))
        .toList(growable: false);

    if (testFiles.isEmpty) {
      print('   No test files found.');
      return true;
    }

    final violations = <String>[];

    for (final file in testFiles) {
      final content = file.readAsStringSync();
      if (!content.contains('pumpAndSettle')) continue;
      if (!content.contains('testWidgets(')) continue;
      if (content.contains('testWidgetsSafe(')) continue;
      if (content.contains('// safe:')) continue;
      violations.add(file.path);
    }

    if (violations.isNotEmpty) {
      print('   Found testWidgets() in files using pumpAndSettle():');
      for (final file in violations) {
        print('   $file');
      }
      print('');
      print('   This combination can hang indefinitely with BLoC streams.');
      print(
        '   Replace testWidgets() with testWidgetsSafe() from test_helpers.dart',
      );
      return false;
    }

    print('   No unsafe testWidgets patterns found.');
    return true;
  } catch (e) {
    print('   Could not check test files: $e');
    return false;
  }
}

Future<bool> _checkUnsafeAsyncTestWithStreamController() async {
  print('Checking for unsafe async test() with StreamController...');

  try {
    final testFiles = Directory('test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('_test.dart'))
        .toList(growable: false);

    if (testFiles.isEmpty) {
      print('   No test files found.');
      return true;
    }

    final violations = <String>[];

    for (final file in testFiles) {
      final content = file.readAsStringSync();
      if (!content.contains('StreamController')) continue;
      if (!content.contains('test(')) continue;
      if (!content.contains('async')) continue;
      if (content.contains('testSafe(')) continue;
      if (content.contains('// safe:')) continue;
      violations.add(file.path);
    }

    if (violations.isNotEmpty) {
      print('   Found async test() in files using StreamController:');
      for (final file in violations) {
        print('   $file');
      }
      print('');
      print('   This combination can hang indefinitely with BLoC streams.');
      print('   Replace test() with testSafe() for async tests using streams');
      return false;
    }

    print('   No unsafe async test patterns found.');
    return true;
  } catch (e) {
    print('   Could not check async tests with StreamController: $e');
    return false;
  }
}

Future<bool> _checkRawStreamControllerUsage() async {
  print('Checking for raw StreamController usage in tests...');

  try {
    final testFiles = Directory('test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('_test.dart'))
        .toList(growable: false);

    if (testFiles.isEmpty) {
      print('   No test files found.');
      return true;
    }

    final violations = <String>[];
    final pattern = RegExp(r'StreamController\s*<');

    for (final file in testFiles) {
      final lines = file.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!pattern.hasMatch(line)) continue;
        if (line.contains('TestStreamController')) continue;
        if (line.contains('// ignore-stream-controller')) continue;
        violations.add('${file.path}:${i + 1}: ${line.trim()}');
      }
    }

    if (violations.isNotEmpty) {
      print('   Found raw StreamController usage in test files:');
      for (final violation in violations.take(20)) {
        print('   $violation');
      }
      if (violations.length > 20) {
        print('   ... and ${violations.length - 20} more');
      }
      print('');
      print('   Raw StreamController can cause tests to hang indefinitely.');
      print(
        '   Use TestStreamController from bloc_test_patterns.dart instead.',
      );
      print('   Add "// ignore-stream-controller" to line if intentional.');
      return false;
    }

    print('   No raw StreamController usage found in tests.');
    return true;
  } catch (e) {
    print('   Could not check for raw StreamController: $e');
    return false;
  }
}

void _printFailure() {
  print('\nPre-push checks failed. Fix issues before pushing.');
  print('   Use "git push --no-verify" to bypass (not recommended).');
}

/// Validates that all PowerSync tables are registered in IdGenerator.
///
/// Parses both files and compares table names to find missing registrations.
Future<bool> _validateTableRegistration() async {
  print('Validating IdGenerator table registration...');

  try {
    // Path to IdGenerator
    const idGeneratorPath = 'packages/taskly_data/lib/src/id/id_generator.dart';

    // Path to PowerSync schema
    const schemaPath =
        'packages/taskly_data/lib/src/infrastructure/powersync/schema.dart';

    final idGeneratorFile = File(idGeneratorPath);
    final schemaFile = File(schemaPath);

    if (!idGeneratorFile.existsSync()) {
      print('   IdGenerator file not found at $idGeneratorPath');
      return true; // Don't block if file doesn't exist yet
    }

    if (!schemaFile.existsSync()) {
      print('   Schema file not found at $schemaPath');
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
      print('   Tables in schema but NOT registered in IdGenerator:');
      for (final table in unregisteredTables.toList()..sort()) {
        print('      - $table');
      }
      print(
        '   Add these to v5Tables or v4Tables in packages/taskly_data/lib/src/id/id_generator.dart',
      );
      hasIssues = true;
    }

    if (orphanedTables.isNotEmpty) {
      print('   Tables registered in IdGenerator but NOT in schema:');
      for (final table in orphanedTables.toList()..sort()) {
        print('      - $table');
      }
      print('   Consider removing these from id_generator.dart');
      // Warning only, don't fail
    }

    if (!hasIssues) {
      print('   All ${schemaTables.length} tables are registered.');
      print('     - v5 (deterministic): ${v5Tables.length} tables');
      print('     - v4 (random): ${v4Tables.length} tables');
    }

    return !hasIssues;
  } catch (e) {
    print('   Could not validate table registration: $e');
    return true; // Don't block on check failure
  }
}

Future<bool> _runTests() async {
  print('Running tests...');

  try {
    final result = await Process.run(
      'flutter',
      [
        'test',
        '--reporter',
        'expanded',
      ],
      runInShell: true,
    );

    final stdout = (result.stdout as String).trimRight();
    final stderr = (result.stderr as String).trimRight();

    if (result.exitCode != 0) {
      final logPath = _writeTestOutput(stdout, stderr);
      print('   Tests failed (exit code ${result.exitCode}).');
      print('   Full output saved to: $logPath');
      return false;
    }

    print('   All tests passed.');
    return true;
  } catch (e) {
    print('   Could not run tests: $e');
    return false;
  }
}

String _writeTestOutput(String stdout, String stderr) {
  final logsDir = Directory(_testLogDir);
  if (!logsDir.existsSync()) {
    logsDir.createSync(recursive: true);
  }
  _pruneTestLogs(logsDir);
  final timestamp = DateTime.now()
      .toIso8601String()
      .replaceAll(':', '-')
      .replaceAll('.', '-');
  final logPath = '${logsDir.path}/$_testLogPrefix$timestamp.log';
  final buffer = StringBuffer();
  buffer.writeln('Exit context: flutter test');
  buffer.writeln('--- stdout ---');
  if (stdout.isNotEmpty) {
    buffer.writeln(stdout);
  }
  buffer.writeln('--- stderr ---');
  if (stderr.isNotEmpty) {
    buffer.writeln(stderr);
  }
  File(logPath).writeAsStringSync(buffer.toString());
  return logPath;
}

void _pruneTestLogs(Directory logsDir) {
  try {
    if (!logsDir.existsSync()) return;
    final now = DateTime.now();
    final files = logsDir
        .listSync()
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.log') &&
              file.uri.pathSegments.last.startsWith(_testLogPrefix),
        )
        .toList(growable: false);

    for (final file in files) {
      final modified = file.lastModifiedSync();
      if (now.difference(modified) > _testLogRetention) {
        file.deleteSync();
      }
    }

    final remaining =
        logsDir
            .listSync()
            .whereType<File>()
            .where(
              (file) =>
                  file.path.endsWith('.log') &&
                  file.uri.pathSegments.last.startsWith(_testLogPrefix),
            )
            .toList()
          ..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );

    if (remaining.length <= _testLogMaxFiles) return;
    for (var i = _testLogMaxFiles; i < remaining.length; i++) {
      remaining[i].deleteSync();
    }
  } catch (_) {
    // Best-effort cleanup; do not block pre-push.
  }
}
