import 'dart:io';

/// Guardrail: fail if any architecture exception is missing an expiry
/// date or has expired.
///
/// Expected format in exception docs:
/// - "Expiry: YYYY-MM-DD"
/// - or "Expires: YYYY-MM-DD"
/// - or "expires=YYYY-MM-DD"
Future<void> main(List<String> args) async {
  final exceptionsDir = Directory(
    _join(Directory.current.path, ['doc', 'architecture', 'exceptions']),
  );

  if (!exceptionsDir.existsSync()) {
    stdout.writeln('No exceptions directory found. Skipping.');
    return;
  }

  final today = _dateOnly(DateTime.now());
  final violations = <_Violation>[];

  await for (final entity in exceptionsDir.list(followLinks: false)) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!name.startsWith('EXC-')) continue;
    if (!name.endsWith('.md')) continue;

    final content = await entity.readAsString();
    final expiry = _extractExpiry(content);
    if (expiry == null) {
      violations.add(
        _Violation(
          path: _toRelativePath(Directory.current.path, entity.path),
          reason: 'Missing expiry date (expected "Expiry: YYYY-MM-DD")',
        ),
      );
      continue;
    }

    final expiryDate = _dateOnly(expiry);
    if (expiryDate.isBefore(today)) {
      violations.add(
        _Violation(
          path: _toRelativePath(Directory.current.path, entity.path),
          reason: 'Expired on ${_formatDate(expiryDate)}',
        ),
      );
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('OK: no expired architecture exceptions.');
    return;
  }

  stderr.writeln('Expired or invalid architecture exceptions found:');
  for (final v in violations) {
    stderr.writeln(' - ${v.path}: ${v.reason}');
  }
  exitCode = 1;
}

DateTime? _extractExpiry(String content) {
  final regex = RegExp(
    r'^(expiry|expires)\s*[:=]\s*([0-9]{4}-[0-9]{2}-[0-9]{2})\s*$',
    caseSensitive: false,
    multiLine: true,
  );
  final match = regex.firstMatch(content);
  if (match == null) return null;
  final text = match.group(1);
  if (text == null) return null;
  try {
    return DateTime.parse(text);
  } catch (_) {
    return null;
  }
}

DateTime _dateOnly(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

String _formatDate(DateTime dateTime) {
  final y = dateTime.year.toString().padLeft(4, '0');
  final m = dateTime.month.toString().padLeft(2, '0');
  final d = dateTime.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _toRelativePath(String rootPath, String filePath) {
  final root = _normalize(rootPath);
  var file = _normalize(filePath);

  if (!root.endsWith('/')) {
    file = file.replaceFirst('$root/', '');
  } else {
    file = file.replaceFirst(root, '');
  }

  return file;
}

String _normalize(String path) => path.replaceAll(r'\', '/');

String _join(String root, List<String> parts) {
  final normalizedRoot = root.replaceAll(r'\', '/');
  final normalizedParts = parts.map((p) => p.replaceAll(r'\', '/')).toList();
  return [normalizedRoot, ...normalizedParts].join('/');
}

class _Violation {
  const _Violation({required this.path, required this.reason});

  final String path;
  final String reason;
}
