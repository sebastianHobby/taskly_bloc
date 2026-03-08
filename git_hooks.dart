import 'dart:io';

import 'package:git_hooks/git_hooks.dart';

const _schemaRelevantPathPrefixes = <String>[
  'supabase/migrations/',
  'packages/taskly_data/lib/src/infrastructure/powersync/',
  'packages/taskly_data/lib/src/infrastructure/drift/',
  'packages/taskly_data/lib/src/features/',
];

const _schemaRelevantFiles = <String>{
  'tool/validate_supabase_schema_alignment.dart',
  'doc/architecture/runbooks/SUPABASE_SCHEMA_PARITY.md',
};

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
  final schemaCheckMode = await _determineSchemaCheckMode();
  print('Schema parity mode: ${schemaCheckMode.label}');
  if (schemaCheckMode.paths.isNotEmpty) {
    print('Schema-relevant changes:');
    for (final path in schemaCheckMode.paths) {
      print(' - $path');
    }
  }
  print('');

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

  if (!await _runSchemaParityCheck(schemaCheckMode)) {
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

Future<bool> _runSchemaParityCheck(_SchemaCheckMode mode) async {
  if (mode.strictDdl) {
    print('Running Supabase linked-remote schema parity check (strict DDL)...');
  } else {
    print(
      'Running Supabase linked-remote schema parity check '
      '(lightweight; strict DDL skipped)...',
    );
  }

  try {
    final args = <String>[
      'run',
      'tool/validate_supabase_schema_alignment.dart',
      '--linked-only',
    ];
    if (mode.strictDdl) {
      args
        ..add('--require-db')
        ..add('--strict-ddl');
    }
    final result = await Process.run(
      'dart',
      args,
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

Future<_SchemaCheckMode> _determineSchemaCheckMode() async {
  final changedPaths = await _changedPathsAgainstUpstream();
  if (changedPaths == null) {
    return const _SchemaCheckMode(
      strictDdl: true,
      label: 'strict (could not determine changed paths)',
      paths: <String>[],
    );
  }

  final relevant = changedPaths
      .where(_isSchemaRelevantPath)
      .toList(growable: false);
  if (relevant.isEmpty) {
    return const _SchemaCheckMode(
      strictDdl: false,
      label: 'lightweight (no schema-relevant paths changed)',
      paths: <String>[],
    );
  }

  return _SchemaCheckMode(
    strictDdl: true,
    label: 'strict (schema-relevant paths changed)',
    paths: relevant,
  );
}

Future<List<String>?> _changedPathsAgainstUpstream() async {
  final upstream = await _resolveUpstreamRef();
  if (upstream == null) {
    return null;
  }

  try {
    final result = await Process.run(
      'git',
      ['diff', '--name-only', '$upstream...HEAD'],
      runInShell: true,
    );
    if (result.exitCode != 0) {
      stderr.write(result.stderr);
      return null;
    }

    return (result.stdout as String)
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  } catch (e) {
    print('   Could not determine changed paths from git diff: $e');
    return null;
  }
}

Future<String?> _resolveUpstreamRef() async {
  try {
    final upstreamResult = await Process.run(
      'git',
      ['rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{u}'],
      runInShell: true,
    );
    if (upstreamResult.exitCode == 0) {
      final upstream = (upstreamResult.stdout as String).trim();
      if (upstream.isNotEmpty) return upstream;
    }
  } catch (_) {
    // Fall through to origin/main fallback.
  }

  try {
    final fallbackResult = await Process.run(
      'git',
      ['rev-parse', '--verify', 'origin/main'],
      runInShell: true,
    );
    if (fallbackResult.exitCode == 0) {
      return 'origin/main';
    }
  } catch (_) {
    // Fall through to null.
  }

  print('   Could not resolve an upstream ref; running strict schema check.');
  return null;
}

bool _isSchemaRelevantPath(String path) {
  if (_schemaRelevantFiles.contains(path)) {
    return true;
  }
  return _schemaRelevantPathPrefixes.any(path.startsWith);
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

class _SchemaCheckMode {
  const _SchemaCheckMode({
    required this.strictDdl,
    required this.label,
    required this.paths,
  });

  final bool strictDdl;
  final String label;
  final List<String> paths;
}
