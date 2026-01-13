import 'dart:async';
import 'dart:convert';
import 'dart:io';

const int _exitCodeAlreadyRunning = 42;

Future<int> main(List<String> args) async {
  final config = _RecorderConfig.parse(args);
  if (config.showHelp) {
    stdout.writeln(_RecorderConfig.usage);
    return 0;
  }

  final lock = await _maybeAcquireLock(config.lockName);
  if (lock == null && config.lockName != null) {
    stdout.writeln(
      "Test run not started: another '${config.lockName}' run is already active.",
    );
    stdout.writeln('No tests were executed.');
    return _exitCodeAlreadyRunning;
  }

  try {
    final startedAt = DateTime.now().toUtc();
    final runId = _formatRunId(startedAt);
    final outputDir = Directory(config.outputDir);
    await outputDir.create(recursive: true);

    final runDir = Directory('${outputDir.path}/$runId');
    await runDir.create(recursive: true);

    final machinePath = '${runDir.path}/machine.jsonl';
    final stderrPath = '${runDir.path}/stderr.txt';
    final summaryJsonPath = '${runDir.path}/summary.json';
    final summaryMdPath = '${runDir.path}/summary.md';

    final machineSink = File(machinePath).openWrite();
    final stderrSink = File(stderrPath).openWrite();

    final parser = _MachineParser();

    final flutterArgs = <String>[
      'test',
      '--machine',
      ..._sanitizeFlutterTestArgs(
        config.flutterArgs,
        removeMachine: true,
        removeReporter: true,
      ),
    ];
    stdout.writeln('Running: flutter ${flutterArgs.join(' ')}');
    stdout.writeln('Recording into: ${runDir.path}');

    final process = await Process.start(
      'flutter',
      flutterArgs,
      runInShell: true,
    );

    final stdoutDone = _pipeLines(
      process.stdout,
      onLine: (line) {
        machineSink.writeln(line);
        parser.tryAddLine(line);
      },
    );

    final stderrDone = _pipeLines(
      process.stderr,
      onLine: stderrSink.writeln,
    );

    final exitCode = await process.exitCode;
    await Future.wait([stdoutDone, stderrDone]);
    await machineSink.flush();
    await stderrSink.flush();
    await machineSink.close();
    await stderrSink.close();

    final finishedAt = DateTime.now().toUtc();

    final summary = parser.buildSummary(
      startedAtUtc: startedAt,
      finishedAtUtc: finishedAt,
      processExitCode: exitCode,
      flutterArgs: flutterArgs,
      runId: runId,
    );

    await File(
      summaryJsonPath,
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(summary));
    await File(summaryMdPath).writeAsString(_renderMarkdown(summary));

    final ok = (summary['success'] as bool?) ?? false;
    final failedTests =
        (summary['failures'] as List?)
            ?.whereType<Map>()
            .map((f) {
              return _FailedTestRef(
                name: f['name'] as String?,
                suitePath: f['suitePath'] as String?,
              );
            })
            .where((f) => f.name != null && f.name!.isNotEmpty)
            .toList() ??
        const <_FailedTestRef>[];

    final expandedCaptured = await _maybeCaptureExpanded(
      config: config,
      runDir: runDir,
      runWasSuccessful: ok,
      failedTests: failedTests,
    );

    if (expandedCaptured != null) {
      summary['expanded'] = <String, Object?>{
        'mode': config.expandedMode.name,
        'captured': true,
        'processExitCode': expandedCaptured.exitCode,
        'stdoutFile': expandedCaptured.stdoutFile,
        'stderrFile': expandedCaptured.stderrFile,
        'nameFilterRegex': expandedCaptured.nameFilterRegex,
        'suiteFilters': expandedCaptured.suiteFilters,
      };
      await File(
        summaryJsonPath,
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(summary));
      await File(summaryMdPath).writeAsString(_renderMarkdown(summary));
    }

    await _pruneOldRuns(outputDir, keep: config.keep);

    stdout.writeln(ok ? 'OK' : 'FAILED');
    stdout.writeln('Summary: $summaryMdPath');

    return ok ? 0 : 1;
  } finally {
    await lock?.dispose();
  }
}

Future<_LockHandle?> _maybeAcquireLock(String? lockName) async {
  if (lockName == null || lockName.trim().isEmpty) return null;

  final lockFile = await _lockFileForName(lockName.trim());
  await lockFile.parent.create(recursive: true);

  Future<bool> isRunning(int pid) async {
    if (pid <= 0) return false;

    if (Platform.isWindows) {
      final r = await Process.run(
        'tasklist',
        ['/FI', 'PID eq $pid'],
        runInShell: true,
      );
      final out = (r.stdout ?? '').toString();
      return out.contains('$pid');
    }

    final r = await Process.run('kill', ['-0', '$pid'], runInShell: true);
    return r.exitCode == 0;
  }

  if (await lockFile.exists()) {
    final existingPid = await _readPidFromLockFile(lockFile);
    if (existingPid != null && await isRunning(existingPid)) {
      return null;
    }
    try {
      await lockFile.delete();
    } catch (_) {}
  }

  try {
    await lockFile.create(exclusive: true, recursive: true);
  } on FileSystemException {
    final existingPid = await _readPidFromLockFile(lockFile);
    if (existingPid != null && await isRunning(existingPid)) {
      return null;
    }
    try {
      await lockFile.delete();
    } catch (_) {}
    await lockFile.create(exclusive: true, recursive: true);
  }

  final lockObj = <String, Object?>{
    'lockName': lockName,
    'pid': pid,
    'started': DateTime.now().toUtc().toIso8601String(),
    'command': <String>['flutter', 'test', '--machine'],
  };
  await lockFile.writeAsString(jsonEncode(lockObj));

  return _LockHandle(lockFile);
}

Future<File> _lockFileForName(String lockName) async {
  final scriptDir = File.fromUri(Platform.script).parent;
  final lockRoot = Directory('${scriptDir.path}/../build_out/task_locks');
  return File('${lockRoot.path}/$lockName.json');
}

Future<int?> _readPidFromLockFile(File lockFile) async {
  try {
    final raw = await lockFile.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is Map && decoded['pid'] is int) {
      return decoded['pid'] as int;
    }
  } catch (_) {
    // Ignore unreadable lock.
  }
  return null;
}

class _LockHandle {
  _LockHandle(this._lockFile);

  final File _lockFile;

  Future<void> dispose() async {
    try {
      if (await _lockFile.exists()) {
        await _lockFile.delete();
      }
    } catch (_) {
      // Ignore.
    }
  }
}

Future<_ExpandedCaptureResult?> _maybeCaptureExpanded({
  required _RecorderConfig config,
  required Directory runDir,
  required bool runWasSuccessful,
  required List<_FailedTestRef> failedTests,
}) async {
  final shouldCapture = switch (config.expandedMode) {
    _ExpandedMode.never => false,
    _ExpandedMode.failure => !runWasSuccessful,
    _ExpandedMode.always => true,
  };
  if (!shouldCapture) return null;

  const stdoutFile = 'expanded_stdout.txt';
  const stderrFile = 'expanded_stderr.txt';
  final stdoutSink = File('${runDir.path}/$stdoutFile').openWrite();
  final stderrSink = File('${runDir.path}/$stderrFile').openWrite();

  final failedNames =
      failedTests.map((f) => f.name).whereType<String>().toSet().toList()
        ..sort();

  final failedSuites =
      failedTests.map((f) => f.suitePath).whereType<String>().toSet().toList()
        ..sort();

  // If we have per-test failures from the machine run, rerun *only those tests*
  // to avoid re-executing successful tests.
  final nameRegex = failedNames.isEmpty
      ? null
      : _buildAnchoredNameRegex(failedNames);

  final expandedArgs = <String>[
    'test',
    '-r',
    'expanded',
    '--no-color',
    if (nameRegex != null) ...['--name', nameRegex],
    ..._sanitizeFlutterTestArgs(
      config.flutterArgs,
      removeMachine: true,
      removeReporter: true,
    ),
    if (failedSuites.isNotEmpty) ...failedSuites,
  ];

  stdout.writeln(
    'Also capturing expanded output: flutter ${expandedArgs.join(' ')}',
  );

  final process = await Process.start(
    'flutter',
    expandedArgs,
    runInShell: true,
  );

  final stdoutDone = _pipeLines(process.stdout, onLine: stdoutSink.writeln);
  final stderrDone = _pipeLines(process.stderr, onLine: stderrSink.writeln);

  final exitCode = await process.exitCode;
  await Future.wait([stdoutDone, stderrDone]);
  await stdoutSink.flush();
  await stderrSink.flush();
  await stdoutSink.close();
  await stderrSink.close();

  return _ExpandedCaptureResult(
    exitCode: exitCode,
    stdoutFile: stdoutFile,
    stderrFile: stderrFile,
    nameFilterRegex: nameRegex,
    suiteFilters: failedSuites,
  );
}

String _buildAnchoredNameRegex(List<String> testNames) {
  // `flutter test --name` is regex-based and matches substrings; anchoring makes
  // it behave like exact match on the full test name.
  final parts = testNames.map(RegExp.escape).toList();
  return '^(?:${parts.join('|')})\$';
}

List<String> _sanitizeFlutterTestArgs(
  List<String> args, {
  required bool removeMachine,
  required bool removeReporter,
}) {
  final result = <String>[];

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (removeMachine && a == '--machine') {
      continue;
    }
    if (removeReporter && (a == '-r' || a == '--reporter')) {
      // Drop the reporter flag and its value if present.
      if (i + 1 < args.length) {
        i++;
      }
      continue;
    }
    result.add(a);
  }
  return result;
}

class _ExpandedCaptureResult {
  _ExpandedCaptureResult({
    required this.exitCode,
    required this.stdoutFile,
    required this.stderrFile,
    required this.nameFilterRegex,
    required this.suiteFilters,
  });

  final int exitCode;
  final String stdoutFile;
  final String stderrFile;
  final String? nameFilterRegex;
  final List<String> suiteFilters;
}

class _FailedTestRef {
  const _FailedTestRef({required this.name, required this.suitePath});

  final String? name;
  final String? suitePath;
}

Future<void> _pruneOldRuns(Directory outputDir, {required int keep}) async {
  if (keep <= 0) return;

  final runs = outputDir
      .listSync(followLinks: false)
      .whereType<Directory>()
      .toList();

  runs.sort((a, b) => b.path.compareTo(a.path));
  final toDelete = runs.skip(keep);
  for (final dir in toDelete) {
    try {
      await dir.delete(recursive: true);
    } catch (_) {
      // Best-effort pruning.
    }
  }
}

Future<void> _pipeLines(
  Stream<List<int>> stream, {
  required void Function(String line) onLine,
}) {
  final completer = Completer<void>();
  stream
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(
        onLine,
        onDone: completer.complete,
        onError: (Object _, StackTrace __) => completer.complete(),
      );
  return completer.future;
}

String _formatRunId(DateTime utc) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${utc.year}${two(utc.month)}${two(utc.day)}_'
      '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
}

String _renderMarkdown(Map<String, Object?> summary) {
  final startedAt = summary['startedAtUtc'] as String?;
  final finishedAt = summary['finishedAtUtc'] as String?;
  final durationMs = summary['durationMs'] as int?;
  final success = summary['success'] as bool?;
  final totals = (summary['totals'] as Map?)?.cast<String, Object?>();
  final failures = (summary['failures'] as List?)?.cast<Map>();
  final slowest = (summary['slowestTests'] as List?)?.cast<Map>();
  final expanded = (summary['expanded'] as Map?)?.cast<String, Object?>();

  final b = StringBuffer();
  b.writeln('# Flutter Test Run');
  b.writeln();
  b.writeln('- success: ${success ?? false}');
  if (startedAt != null) b.writeln('- startedAtUtc: $startedAt');
  if (finishedAt != null) b.writeln('- finishedAtUtc: $finishedAt');
  if (durationMs != null) b.writeln('- durationMs: $durationMs');
  if (totals != null) {
    b.writeln(
      '- totals: passed=${totals['passed']} '
      'failed=${totals['failed']} '
      'skipped=${totals['skipped']} '
      'total=${totals['total']}',
    );
  }

  b.writeln();
  b.writeln('## Failures');
  if (failures == null || failures.isEmpty) {
    b.writeln();
    b.writeln('None.');
  } else {
    b.writeln();
    for (final f in failures) {
      b.writeln('- ${f['name']} (${f['durationMs']}ms)');
      final suitePath = f['suitePath'];
      if (suitePath != null) b.writeln('  - suite: $suitePath');
      final message = (f['message'] as String?)?.trim();
      if (message != null && message.isNotEmpty) {
        b.writeln('  - message: ${_singleLine(message)}');
      }
    }
  }

  b.writeln();
  b.writeln('## Slowest Tests');
  if (slowest == null || slowest.isEmpty) {
    b.writeln();
    b.writeln('No per-test timing data found.');
  } else {
    b.writeln();
    for (final t in slowest.take(10)) {
      b.writeln('- ${t['durationMs']}ms: ${t['name']}');
    }
  }

  if (expanded != null) {
    b.writeln();
    b.writeln('## Expanded Output');
    b.writeln();
    b.writeln('- mode: ${expanded['mode']}');
    b.writeln('- captured: ${expanded['captured']}');
    b.writeln('- processExitCode: ${expanded['processExitCode']}');
    b.writeln('- stdoutFile: ${expanded['stdoutFile']}');
    b.writeln('- stderrFile: ${expanded['stderrFile']}');
    if (expanded['nameFilterRegex'] != null) {
      b.writeln('- nameFilterRegex: ${expanded['nameFilterRegex']}');
    }
    final suiteFilters = expanded['suiteFilters'];
    if (suiteFilters is List && suiteFilters.isNotEmpty) {
      b.writeln('- suiteFilters: ${suiteFilters.length}');
    }
  }

  return b.toString();
}

String _singleLine(String input) {
  return input.replaceAll(RegExp(r'\s+'), ' ').trim();
}

class _RecorderConfig {
  _RecorderConfig({
    required this.outputDir,
    required this.keep,
    required this.expandedMode,
    required this.lockName,
    required this.flutterArgs,
    required this.showHelp,
  });

  factory _RecorderConfig.parse(List<String> args) {
    var outputDir = 'build_out/test_runs';
    var keep = 5;
    var expandedMode = _ExpandedMode.failure;
    String? lockName = 'flutter_test_record';
    var showHelp = false;

    final flutterArgs = <String>[];

    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (a == '--') {
        flutterArgs.addAll(args.skip(i + 1));
        break;
      }
      switch (a) {
        case '-h':
        case '--help':
          showHelp = true;
        case '--no-lock':
          lockName = null;
        case '--lock-name':
          if (i + 1 >= args.length) {
            throw FormatException('Missing value for --lock-name');
          }
          lockName = args[++i];
        case '--out':
          if (i + 1 >= args.length) {
            throw FormatException('Missing value for --out');
          }
          outputDir = args[++i];
        case '--keep':
          if (i + 1 >= args.length) {
            throw FormatException('Missing value for --keep');
          }
          keep = int.parse(args[++i]);
        case '--expanded':
          if (i + 1 >= args.length) {
            throw FormatException('Missing value for --expanded');
          }
          expandedMode = _ExpandedMode.parse(args[++i]);
        default:
          throw FormatException('Unknown arg: $a');
      }
    }

    return _RecorderConfig(
      outputDir: outputDir,
      keep: keep,
      expandedMode: expandedMode,
      lockName: lockName,
      flutterArgs: flutterArgs,
      showHelp: showHelp,
    );
  }

  final String outputDir;
  final int keep;
  final _ExpandedMode expandedMode;
  final String? lockName;
  final List<String> flutterArgs;
  final bool showHelp;

  static const usage = '''
Records a single `flutter test --machine` run into a timestamped folder.

Usage:
  dart run tool/test_run_recorder.dart [options] [-- <flutter test args...>]

Options:
  --out <dir>     Output root directory (default: build_out/test_runs)
  --keep <n>      Keep latest N runs (default: 5)
  --expanded <m>  Capture `-r expanded` output: never|failure|always (default: failure)
  --lock-name <n> Single-instance lock name (default: flutter_test_record)
  --no-lock       Disable single-instance locking
  -h, --help      Show help

Examples:
  dart run tool/test_run_recorder.dart
  dart run tool/test_run_recorder.dart -- --tags=unit
  dart run tool/test_run_recorder.dart --keep 10 -- --exclude-tags=integration,slow
  dart run tool/test_run_recorder.dart --expanded always -- --tags=unit
''';
}

enum _ExpandedMode {
  never,
  failure,
  always;

  static _ExpandedMode parse(String input) {
    return switch (input.trim().toLowerCase()) {
      'never' => _ExpandedMode.never,
      'failure' => _ExpandedMode.failure,
      'always' => _ExpandedMode.always,
      _ => throw FormatException(
        'Invalid --expanded value: $input (expected never|failure|always)',
      ),
    };
  }
}

class _MachineParser {
  final Map<int, String> _suitePathById = {};
  final Map<int, _TestInfo> _testById = {};
  final Map<int, List<String>> _printsByTestId = {};

  bool _doneSuccess = false;
  int? _doneTimeMs;

  void tryAddLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return;

    // When piping flutter test output through shells, you can sometimes get JSON
    // arrays mixed in (e.g. VS Code test events). Ignore those.
    if (trimmed.startsWith('[')) return;

    Map<String, Object?> event;
    try {
      event = (jsonDecode(trimmed) as Map).cast<String, Object?>();
    } catch (_) {
      return;
    }

    final type = event['type'];
    if (type is! String) return;

    switch (type) {
      case 'suite':
        final suite = event['suite'];
        if (suite is Map) {
          final id = suite['id'];
          final path = suite['path'];
          if (id is int && path is String) {
            _suitePathById[id] = path;
          }
        }

      case 'testStart':
        final test = event['test'];
        if (test is Map) {
          final id = test['id'];
          final name = test['name'];
          final suiteId = test['suiteID'];
          final time = event['time'];

          if (id is int && name is String && suiteId is int && time is int) {
            _testById[id] = _TestInfo(
              id: id,
              name: name,
              suiteId: suiteId,
              startedAtMs: time,
            );
          }
        }

      case 'testDone':
        final testId = event['testID'];
        final result = event['result'];
        final skipped = event['skipped'];
        final hidden = event['hidden'];
        final time = event['time'];

        if (testId is int && result is String && time is int) {
          final info = _testById[testId];
          if (info != null) {
            info
              ..finishedAtMs = time
              ..result = result
              ..skipped = skipped is bool ? skipped : null
              ..hidden = hidden is bool ? hidden : null;
          }
        }

      case 'print':
        final testId = event['testID'];
        final message = event['message'];
        if (testId is int && message is String) {
          final list = _printsByTestId.putIfAbsent(testId, () => []);
          list.add(message);
        }

      case 'done':
        final success = event['success'];
        final time = event['time'];
        if (success is bool) _doneSuccess = success;
        if (time is int) _doneTimeMs = time;

      case 'error':
        // Some runners emit structured errors; keep going.
        break;

      default:
        break;
    }
  }

  Map<String, Object?> buildSummary({
    required DateTime startedAtUtc,
    required DateTime finishedAtUtc,
    required int processExitCode,
    required List<String> flutterArgs,
    required String runId,
  }) {
    final tests = _testById.values.where((t) => !t.isLoadingTest).toList();

    int passed = 0;
    int failed = 0;
    int skipped = 0;

    for (final t in tests) {
      if (t.skipped ?? false) {
        skipped++;
        continue;
      }
      if (t.result == 'success') {
        passed++;
      } else if (t.result != null) {
        failed++;
      }
    }

    final total = tests.length;

    final slowest = [...tests]
      ..sort((a, b) => b.durationMs.compareTo(a.durationMs));

    final failures = tests
        .where((t) => t.result != null && t.result != 'success')
        .map((t) {
          final suitePath = _suitePathById[t.suiteId];
          final prints = _printsByTestId[t.id];

          return <String, Object?>{
            'id': t.id,
            'name': t.name,
            'suitePath': suitePath,
            'result': t.result,
            'durationMs': t.durationMs,
            'message': prints == null || prints.isEmpty
                ? null
                : prints.join('\n'),
          };
        })
        .toList();

    final durationMs = finishedAtUtc.difference(startedAtUtc).inMilliseconds;

    final success =
        processExitCode == 0 && (_doneSuccess || _doneTimeMs != null);

    return <String, Object?>{
      'runId': runId,
      'success': success,
      'processExitCode': processExitCode,
      'flutterArgs': flutterArgs,
      'startedAtUtc': startedAtUtc.toIso8601String(),
      'finishedAtUtc': finishedAtUtc.toIso8601String(),
      'durationMs': durationMs,
      'totals': <String, Object?>{
        'total': total,
        'passed': passed,
        'failed': failed,
        'skipped': skipped,
      },
      'slowestTests': slowest.take(25).map((t) {
        return <String, Object?>{
          'id': t.id,
          'name': t.name,
          'suitePath': _suitePathById[t.suiteId],
          'durationMs': t.durationMs,
          'result': t.result,
        };
      }).toList(),
      'failures': failures,
    };
  }
}

class _TestInfo {
  _TestInfo({
    required this.id,
    required this.name,
    required this.suiteId,
    required this.startedAtMs,
  });

  final int id;
  final String name;
  final int suiteId;
  final int startedAtMs;

  int? finishedAtMs;
  String? result;
  bool? skipped;
  bool? hidden;

  bool get isLoadingTest => name.startsWith('loading ');

  int get durationMs {
    final end = finishedAtMs;
    if (end == null) return 0;
    final d = end - startedAtMs;
    return d < 0 ? 0 : d;
  }
}
