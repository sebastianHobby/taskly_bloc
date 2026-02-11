import 'dart:io';

const _ignoreComment = 'ignore-pump-and-settle';

final _pumpAndSettlePattern = RegExp(r'\bpumpAndSettle\s*\(');

Future<void> main(List<String> args) async {
  final roots = <Directory>[
    Directory('test'),
    Directory('packages'),
  ].where((dir) => dir.existsSync()).toList(growable: false);

  if (roots.isEmpty) {
    stdout.writeln('No test roots found. Skipping.');
    return;
  }

  final violations = <String>[];
  final files = <File>[];
  for (final root in roots) {
    files.addAll(
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('_test.dart')),
    );
  }

  for (final file in files) {
    final content = file.readAsStringSync();
    if (!content.contains('testWidgets')) continue;
    if (!_pumpAndSettlePattern.hasMatch(content)) continue;

    final lines = content.split('\n');
    for (final match in _pumpAndSettlePattern.allMatches(content)) {
      final lineNumber = _lineNumberForMatch(content, match.start);
      final lineIndex = lineNumber - 1;
      final line = lines[lineIndex];
      final previousLine = lineIndex > 0 ? lines[lineIndex - 1] : '';
      final ignored =
          line.contains(_ignoreComment) ||
          previousLine.contains(_ignoreComment);
      if (ignored) continue;

      violations.add(
        '${file.path}:$lineNumber: pumpAndSettle -> ${line.trim()}',
      );
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('No pumpAndSettle usage found in widget tests.');
    return;
  }

  stderr.writeln('Found pumpAndSettle usage in widget tests:');
  for (final violation in violations) {
    stderr.writeln('  $violation');
  }
  stderr.writeln('');
  stderr.writeln(
    'Prefer pumpForStream(), pumpUntilFound(), or explicit pump durations.',
  );
  stderr.writeln(
    'If a test is purely static and requires pumpAndSettle, add '
    '"// $_ignoreComment" on the same line or the line above.',
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
