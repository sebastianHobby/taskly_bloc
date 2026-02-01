import 'dart:io';

const _ignoreComment = 'ignore-unseeded-subject';

final _behaviorSubjectPattern = RegExp(
  r'BehaviorSubject(?:<[^>]*>)?\s*\(\s*\)',
);
final _publishSubjectPattern = RegExp(
  r'PublishSubject(?:<[^>]*>)?\s*\(',
);

Future<void> main(List<String> args) async {
  final root = Directory('test/presentation');
  if (!root.existsSync()) {
    stdout.writeln('No test/presentation directory found. Skipping.');
    return;
  }

  final violations = <String>[];
  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('_test.dart'))
      .toList(growable: false);

  for (final file in files) {
    final content = file.readAsStringSync();
    if (!content.contains('testWidgets')) continue;

    final lines = content.split('\n');
    void recordViolations(RegExp pattern, String label) {
      for (final match in pattern.allMatches(content)) {
        final lineNumber = _lineNumberForMatch(content, match.start);
        final lineIndex = lineNumber - 1;
        final line = lines[lineIndex];
        final previousLine = lineIndex > 0 ? lines[lineIndex - 1] : '';
        final ignored =
            line.contains(_ignoreComment) ||
            previousLine.contains(_ignoreComment);
        if (ignored) continue;

        violations.add(
          '${file.path}:$lineNumber: $label -> ${line.trim()}',
        );
      }
    }

    recordViolations(_behaviorSubjectPattern, 'Unseeded BehaviorSubject');
    recordViolations(_publishSubjectPattern, 'Unseeded PublishSubject');
  }

  if (violations.isEmpty) {
    stdout.writeln('No unseeded subjects found in widget tests.');
    return;
  }

  stderr.writeln('Found unseeded subjects in widget tests:');
  for (final violation in violations) {
    stderr.writeln('  $violation');
  }
  stderr.writeln('');
  stderr.writeln(
    'Seed streams using BehaviorSubject.seeded(...) or '
    'TestStreamController.seeded(...).',
  );
  stderr.writeln(
    'If a test intentionally asserts loading, add '
    '"// $_ignoreComment" on the line.',
  );
  exitCode = 1;
}

int _lineNumberForMatch(String content, int offset) {
  var line = 1;
  for (var i = 0; i < offset && i < content.length; i += 1) {
    if (content.codeUnitAt(i) == 10) {
      line += 1;
    }
  }
  return line;
}
