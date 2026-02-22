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
  print('Running pre-commit checks...\n');
  print('\nAll pre-commit checks passed!');
  return true;
}

Future<bool> prePush() async {
  print('Running pre-push checks...\n');

  if (!await _runDependencyResolutionChecks()) {
    _printFailure();
    return false;
  }

  if (!await _runFormat()) {
    _printFailure();
    return false;
  }

  if (!await _runGuardrails()) {
    _printFailure();
    return false;
  }

  if (!await _runSchemaParityCheck()) {
    _printFailure();
    return false;
  }

  if (!await _runAnalyze()) {
    _printFailure();
    return false;
  }

  if (!await _runFastTests()) {
    _printFailure();
    return false;
  }

  print('\nAll pre-push checks passed!');
  return true;
}

Future<bool> _runDependencyResolutionChecks() async {
  print('Running dependency resolution checks (flutter pub get)...');

  final checks = <({String label, String? workingDirectory})>[
    (label: 'root', workingDirectory: null),
    (label: 'packages/taskly_core', workingDirectory: 'packages/taskly_core'),
    (
      label: 'packages/taskly_domain',
      workingDirectory: 'packages/taskly_domain',
    ),
    (label: 'packages/taskly_data', workingDirectory: 'packages/taskly_data'),
    (label: 'packages/taskly_ui', workingDirectory: 'packages/taskly_ui'),
  ];

  for (final check in checks) {
    print(' - ${check.label}');
    try {
      final result = await Process.run(
        'flutter',
        ['pub', 'get'],
        runInShell: true,
        workingDirectory: check.workingDirectory,
      );

      stdout.write(result.stdout);
      stderr.write(result.stderr);

      if (result.exitCode != 0) {
        print('   flutter pub get failed for ${check.label}');
        return false;
      }
    } catch (e) {
      print('   Could not run flutter pub get for ${check.label}: $e');
      return false;
    }
  }

  return true;
}

Future<bool> _runFormat() async {
  print('Running dart format...');

  try {
    final result = await Process.run(
      'dart',
      ['format', '.'],
      runInShell: true,
    );

    stdout.write(result.stdout);
    stderr.write(result.stderr);

    return result.exitCode == 0;
  } catch (e) {
    print('   Could not run formatter: $e');
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

    return result.exitCode == 0;
  } catch (e) {
    print('   Could not run guardrails: $e');
    return false;
  }
}

Future<bool> _runAnalyze() async {
  print('Running dart analyze...');

  try {
    final result = await Process.run(
      'dart',
      ['analyze'],
      runInShell: true,
    );

    stdout.write(result.stdout);
    stderr.write(result.stderr);

    return result.exitCode == 0;
  } catch (e) {
    print('   Could not run analyzer: $e');
    return false;
  }
}

Future<bool> _runSchemaParityCheck() async {
  print('Running Supabase linked-remote schema parity check...');

  try {
    final result = await Process.run(
      'dart',
      [
        'run',
        'tool/validate_supabase_schema_alignment.dart',
        '--require-db',
        '--linked-only',
      ],
      runInShell: true,
    );

    stdout.write(result.stdout);
    stderr.write(result.stderr);

    return result.exitCode == 0;
  } catch (e) {
    print('   Could not run schema parity check: $e');
    return false;
  }
}

Future<bool> _runFastTests() async {
  print('Running tests (fast loop)...');

  try {
    final result = await Process.run(
      'flutter',
      [
        'test',
        '-x',
        'integration',
        '-x',
        'slow',
        '-x',
        'repository',
        '-x',
        'flaky',
        '-x',
        'diagnosis',
      ],
      runInShell: true,
    );

    stdout.write(result.stdout);
    stderr.write(result.stderr);

    return result.exitCode == 0;
  } catch (e) {
    print('   Could not run tests: $e');
    return false;
  }
}

void _printFailure() {
  print('\nPre-push checks failed. Fix issues before pushing.');
  print('   Use "git push --no-verify" to bypass (not recommended).');
}
