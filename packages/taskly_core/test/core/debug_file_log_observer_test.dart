import 'dart:io';

import '../helpers/test_imports.dart';

import 'package:talker_flutter/talker_flutter.dart';
import 'package:taskly_core/logging.dart';

void main() {
  group('DebugFileLogObserver', () {
    testSafe('writes errors to a log file (hermetic temp dir)', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'taskly_core_logs_',
      );
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      final observer = DebugFileLogObserver(
        supportDirectoryProvider: () async => tempDir,
      );
      await observer.ensureInitializedForTest();

      final t = Talker(observer: observer);
      t.handle(StateError('boom'), StackTrace.empty, 'Oops');

      final path = observer.logFilePath;
      expect(path, isNotNull);
      final file = File(path!);

      expect(await file.exists(), isTrue);
      final content = await file.readAsString();
      expect(content, contains('Oops'));
      expect(content, contains('Bad state: boom'));
    });

    testSafe('writes exceptions to a log file', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'taskly_core_logs_',
      );
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      final observer = DebugFileLogObserver(
        supportDirectoryProvider: () async => tempDir,
      );
      await observer.ensureInitializedForTest();

      observer.onException(
        TalkerException(
          Exception('boom'),
          message: 'Oops',
          stackTrace: StackTrace.empty,
        ),
      );

      final file = File(observer.logFilePath!);
      final content = await file.readAsString();
      expect(content, contains('EXCEPTION'));
      expect(content, contains('Oops'));
    });

    testSafe('init truncates an existing oversized log file', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'taskly_core_logs_',
      );
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      final existing = File('${tempDir.path}/debug_errors.log');
      await existing.writeAsString('B' * 1000);

      final observer = DebugFileLogObserver(
        maxFileBytes: 100,
        supportDirectoryProvider: () async => tempDir,
      );
      await observer.ensureInitializedForTest();

      final rotated0 = File('${existing.path}.0');
      expect(await rotated0.exists(), isFalse);

      final content = await existing.readAsString();
      expect(content, isNot(contains('B')));
      expect(content, contains('cleared'));
    });

    testSafe('init failure causes subsequent writes to be no-ops', () async {
      final observer = DebugFileLogObserver(
        supportDirectoryProvider: () async => throw StateError('no dir'),
      );
      await observer.ensureInitializedForTest();

      observer.onError(
        TalkerError(StateError('boom'), message: 'Oops', stackTrace: null),
      );
      await observer.clearLog();

      expect(observer.logFilePath, isNull);
    });

    testSafe('prunes dedupe map when it grows beyond limit', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'taskly_core_logs_',
      );
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      final observer = DebugFileLogObserver(
        dedupeWindow: const Duration(hours: 1),
        supportDirectoryProvider: () async => tempDir,
      );
      await observer.ensureInitializedForTest();

      // Force many unique dedupe keys.
      for (var i = 0; i < 510; i++) {
        observer.onLog(TalkerData('m$i', title: 'WARNING'));
      }

      final file = File(observer.logFilePath!);
      expect(await file.exists(), isTrue);
    });

    testSafe('dedupes identical entries within window', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'taskly_core_logs_',
      );
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      final observer = DebugFileLogObserver(
        dedupeWindow: const Duration(hours: 1),
        supportDirectoryProvider: () async => tempDir,
      );
      await observer.ensureInitializedForTest();

      final t = Talker(observer: observer);
      t.handle(StateError('boom'), StackTrace.empty, 'Oops');
      t.handle(StateError('boom'), StackTrace.empty, 'Oops');

      final file = File(observer.logFilePath!);
      final content = await file.readAsString();

      // Second entry should be suppressed (no suppression line yet).
      expect(RegExp('Oops').allMatches(content).length, 1);
    });

    testSafe('rotates when file grows past max size', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'taskly_core_logs_',
      );
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      final observer = DebugFileLogObserver(
        supportDirectoryProvider: () async => tempDir,
      );
      await observer.ensureInitializedForTest();

      final t = Talker(observer: observer);
      final big = 'A' * 600;
      t.handle(StateError('boom'), StackTrace.empty, big);
      t.handle(StateError('boom2'), StackTrace.empty, big);

      final current = File(observer.logFilePath!);
      expect(await current.exists(), isTrue);

      final rotated0 = File('${current.path}.0');
      expect(await rotated0.exists(), isFalse);
    });

    testSafe('clearLog rewrites the file with a header', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'taskly_core_logs_',
      );
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      final observer = DebugFileLogObserver(
        supportDirectoryProvider: () async => tempDir,
      );
      await observer.ensureInitializedForTest();

      final t = Talker(observer: observer);
      t.handle(StateError('boom'), StackTrace.empty, 'Oops');

      await observer.clearLog();

      final file = File(observer.logFilePath!);
      final content = await file.readAsString();
      expect(content, contains('cleared'));
    });

    testSafe('onLog writes only included titles', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'taskly_core_logs_',
      );
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      final observer = DebugFileLogObserver(
        includedTitles: const {'WARNING'},
        supportDirectoryProvider: () async => tempDir,
      );
      await observer.ensureInitializedForTest();

      observer.onLog(TalkerData('hello', title: 'INFO'));
      observer.onLog(TalkerData('warn', title: 'WARNING'));

      final file = File(observer.logFilePath!);
      final content = await file.readAsString();

      expect(content, isNot(contains('hello')));
      expect(content, contains('warn'));
    });

    testSafe('truncates stack traces written to file', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'taskly_core_logs_',
      );
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      final observer = DebugFileLogObserver(
        maxStackTraceLines: 1,
        supportDirectoryProvider: () async => tempDir,
      );
      await observer.ensureInitializedForTest();

      final st = StackTrace.fromString('l1\nl2\nl3\nl4\nl5');
      observer.onError(
        TalkerError(StateError('boom'), message: 'Oops', stackTrace: st),
      );

      final file = File(observer.logFilePath!);
      final content = await file.readAsString();
      expect(content, contains('StackTrace:'));
      expect(content, contains('more lines'));
    });

    testSafe(
      'writes a suppression line when duplicates were suppressed',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'taskly_core_logs_',
        );
        addTearDown(() async {
          await tempDir.delete(recursive: true);
        });

        final observer = DebugFileLogObserver(
          dedupeWindow: const Duration(milliseconds: 50),
          supportDirectoryProvider: () async => tempDir,
        );
        await observer.ensureInitializedForTest();

        final t = Talker(observer: observer);
        t.handle(StateError('boom'), StackTrace.empty, 'Oops');
        t.handle(StateError('boom'), StackTrace.empty, 'Oops');

        // Ensure we cross the dedupe window.
        await Future<void>.delayed(const Duration(milliseconds: 75));
        t.handle(StateError('boom'), StackTrace.empty, 'Oops');

        final file = File(observer.logFilePath!);
        final content = await file.readAsString();
        expect(content, contains('Suppressed'));
      },
    );

    testSafe('omits stack traces when maxStackTraceLines <= 0', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'taskly_core_logs_',
      );
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      final observer = DebugFileLogObserver(
        maxStackTraceLines: 0,
        supportDirectoryProvider: () async => tempDir,
      );
      await observer.ensureInitializedForTest();

      final st = StackTrace.fromString('l1\nl2\nl3');
      observer.onError(
        TalkerError(StateError('boom'), message: 'Oops', stackTrace: st),
      );

      final file = File(observer.logFilePath!);
      final content = await file.readAsString();
      expect(content, contains('<omitted>'));
    });

    testSafe('large writes do not create rotated backup files', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'taskly_core_logs_',
      );
      addTearDown(() async {
        await tempDir.delete(recursive: true);
      });

      final observer = DebugFileLogObserver(
        supportDirectoryProvider: () async => tempDir,
      );
      await observer.ensureInitializedForTest();

      final t = Talker(observer: observer);
      final big = 'A' * 600;
      t.handle(StateError('boom'), StackTrace.empty, big);
      t.handle(StateError('boom2'), StackTrace.empty, big);

      final current = File(observer.logFilePath!);
      expect(await current.exists(), isTrue);

      // With backups disabled, rotation should not leave a .0 file.
      final rotated0 = File('${current.path}.0');
      expect(await rotated0.exists(), isFalse);
    });
  });
}
