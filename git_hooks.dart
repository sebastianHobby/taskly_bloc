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

  if (!await _runGuardrails()) {
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
