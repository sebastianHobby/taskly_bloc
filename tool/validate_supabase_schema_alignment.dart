import 'dart:io';

const _powersyncSchemaPath =
    'packages/taskly_data/lib/src/infrastructure/powersync/schema.dart';
const _driftDatabasePath =
    'packages/taskly_data/lib/src/infrastructure/drift/drift_database.dart';
const _driftDatabaseGeneratedPath =
    'packages/taskly_data/lib/src/infrastructure/drift/drift_database.g.dart';
const _driftFeaturesDir =
    'packages/taskly_data/lib/src/infrastructure/drift/features';

const _ignoredColumns = <String>{'_metadata'};

Future<void> main(List<String> args) async {
  final requireDb = args.contains('--require-db');
  final linkedOnly = args.contains('--linked-only');

  final powersyncTables = _parsePowerSyncSchema(_powersyncSchemaPath);
  if (powersyncTables.isEmpty) {
    stderr.writeln(
      'No PowerSync tables found in $_powersyncSchemaPath. Cannot validate.',
    );
    exitCode = 1;
    return;
  }

  final driftTables = _parseDriftSchema(
    _driftDatabasePath,
    _driftFeaturesDir,
  );
  if (driftTables.isEmpty) {
    stderr.writeln(
      'No Drift tables found in $_driftDatabasePath / $_driftFeaturesDir.',
    );
    exitCode = 1;
    return;
  }

  final localMismatches = _compareSchemas(
    leftName: 'PowerSync schema.dart',
    left: powersyncTables,
    rightName: 'Drift schema',
    right: driftTables,
  );
  if (localMismatches.isNotEmpty) {
    stderr.writeln('Local schema mismatch detected:');
    _printMismatches(localMismatches);
    exitCode = 1;
    return;
  }

  final dumpResult = await _dumpSupabasePublicSchema(linkedOnly: linkedOnly);
  if (dumpResult == null) {
    final msg = linkedOnly
        ? 'Could not read Supabase schema via CLI (--linked).'
        : 'Could not read Supabase schema via CLI '
              '(tried remote via SUPABASE_DB_URL and --linked).';
    if (requireDb) {
      stderr.writeln(msg);
      stderr.writeln(
        'Start local Supabase (or link a project) before pushing.',
      );
      exitCode = 1;
      return;
    }
    stdout.writeln('SKIP: $msg');
    return;
  }

  final supabaseTables = _parseSupabaseDumpSql(dumpResult);
  if (supabaseTables.isEmpty) {
    stderr.writeln(
      'Supabase schema dump produced no public CREATE TABLE data.',
    );
    exitCode = 1;
    return;
  }

  final supabaseVsPowersync = _compareSchemas(
    leftName: 'Supabase public schema',
    left: supabaseTables,
    rightName: 'PowerSync schema.dart',
    right: powersyncTables,
  );

  final supabaseVsDrift = _compareSchemas(
    leftName: 'Supabase public schema',
    left: supabaseTables,
    rightName: 'Drift schema',
    right: driftTables,
  );

  final allMismatches = [...supabaseVsPowersync, ...supabaseVsDrift];
  if (allMismatches.isNotEmpty) {
    stderr.writeln('Supabase schema mismatch detected:');
    _printMismatches(allMismatches);
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Supabase schema matches PowerSync schema.dart and Drift tables '
    '(${powersyncTables.length} tables checked).',
  );
}

Map<String, Set<String>> _parsePowerSyncSchema(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return {};
  }

  final content = file.readAsStringSync();
  final tables = <String, Set<String>>{};

  final tablePattern = RegExp(
    r"Table\(\s*'([^']+)'\s*,\s*\[(.*?)\]\s*(?:,\s*([^)]*?))?\)",
    dotAll: true,
  );
  final columnPattern = RegExp(r"Column\.\w+\(\s*'([^']+)'\s*\)");

  for (final match in tablePattern.allMatches(content)) {
    final tableName = match.group(1)?.toLowerCase();
    final columnsSegment = match.group(2) ?? '';
    final optionsSegment = match.group(3) ?? '';
    if (tableName == null || tableName.isEmpty) {
      continue;
    }

    final cols = <String>{'id'};
    for (final c in columnPattern.allMatches(columnsSegment)) {
      final col = c.group(1)?.toLowerCase();
      if (col != null && col.isNotEmpty) {
        cols.add(col);
      }
    }

    if (optionsSegment.contains('trackMetadata: true')) {
      cols.add('_metadata');
    }

    tables[tableName] = _normalizedColumns(cols);
  }

  return tables;
}

Map<String, Set<String>> _parseDriftSchema(
  String driftDatabasePath,
  String driftFeaturesDir,
) {
  final generatedTables = _parseDriftGeneratedSchema(
    _driftDatabaseGeneratedPath,
  );
  if (generatedTables.isNotEmpty) {
    return generatedTables;
  }

  final tables = <String, Set<String>>{};

  final dbFile = File(driftDatabasePath);
  if (dbFile.existsSync()) {
    _parseDriftFileInto(dbFile.readAsStringSync(), tables);
  }

  final featuresDir = Directory(driftFeaturesDir);
  if (featuresDir.existsSync()) {
    for (final entity in featuresDir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.drift.dart')) {
        continue;
      }
      _parseDriftFileInto(entity.readAsStringSync(), tables);
    }
  }

  return tables.map((key, value) => MapEntry(key, _normalizedColumns(value)));
}

Map<String, Set<String>> _parseDriftGeneratedSchema(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return {};
  }

  final content = file.readAsStringSync();
  final tables = <String, Set<String>>{};

  final classPattern = RegExp(
    r'class\s+\$\w+Table\s+extends[\s\S]*?\{([\s\S]*?)(?=\nclass\s+\$\w+Table\s+extends|\nabstract class|\Z)',
    dotAll: true,
  );
  final tableNamePattern = RegExp(r"static const String \$name = '([^']+)';");
  final columnPattern = RegExp(r"GeneratedColumn(?:<[^>]*>)?\(\s*'([^']+)'");

  for (final classMatch in classPattern.allMatches(content)) {
    final block = classMatch.group(1) ?? '';
    final tableName = tableNamePattern
        .firstMatch(block)
        ?.group(1)
        ?.toLowerCase();
    if (tableName == null || tableName.isEmpty) {
      continue;
    }

    final cols = <String>{};
    for (final c in columnPattern.allMatches(block)) {
      final col = c.group(1)?.toLowerCase();
      if (col != null && col.isNotEmpty) {
        cols.add(col);
      }
    }

    tables[tableName] = _normalizedColumns(cols);
  }

  return tables;
}

void _parseDriftFileInto(String content, Map<String, Set<String>> tables) {
  final classPattern = RegExp(
    r'class\s+\w+\s+extends\s+Table\s*\{([\s\S]*?)(?=\nclass\s+\w+\s+extends\s+Table|\Z)',
    dotAll: true,
  );
  final tableNamePattern = RegExp(r"tableName\s*=>\s*'([^']+)'");
  final namedPattern = RegExp(r"named\('([^']+)'\)");

  for (final classMatch in classPattern.allMatches(content)) {
    final block = classMatch.group(1) ?? '';
    final tableName = tableNamePattern
        .firstMatch(block)
        ?.group(1)
        ?.toLowerCase();
    if (tableName == null || tableName.isEmpty) {
      continue;
    }

    final cols = <String>{};
    for (final c in namedPattern.allMatches(block)) {
      final col = c.group(1)?.toLowerCase();
      if (col != null && col.isNotEmpty) {
        cols.add(col);
      }
    }

    if (cols.isNotEmpty) {
      tables[tableName] = {...?tables[tableName], ...cols};
    }
  }
}

Future<String?> _dumpSupabasePublicSchema({required bool linkedOnly}) async {
  final tempDir = await Directory.systemTemp.createTemp(
    'taskly_supabase_schema_',
  );
  final tempFile = File('${tempDir.path}${Platform.pathSeparator}public.sql');

  try {
    final attempts = <List<String>>[
      [
        'db',
        'dump',
        '--linked',
        '--schema',
        'public',
        '--file',
        tempFile.path,
      ],
    ];

    if (!linkedOnly) {
      final dbUrl = Platform.environment['SUPABASE_DB_URL']?.trim();
      if (dbUrl != null && dbUrl.isNotEmpty) {
        attempts.add([
          'db',
          'dump',
          '--db-url',
          dbUrl,
          '--schema',
          'public',
          '--file',
          tempFile.path,
        ]);
      }
    }

    for (final args in attempts) {
      final result = await Process.run('supabase', args, runInShell: true);
      if (result.exitCode == 0 && tempFile.existsSync()) {
        return tempFile.readAsStringSync();
      }
    }

    if (!linkedOnly) {
      // Backward-compatible fallback for older local setups.
      final fallback = [
        'db',
        'dump',
        '--linked',
        '--schema',
        'public',
        '--file',
        tempFile.path,
      ];
      final result = await Process.run(
        'supabase',
        fallback,
        runInShell: true,
      );
      if (result.exitCode == 0 && tempFile.existsSync()) {
        return tempFile.readAsStringSync();
      }
    }

    return null;
  } finally {
    if (tempFile.existsSync()) {
      tempFile.deleteSync();
    }
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}

Map<String, Set<String>> _parseSupabaseDumpSql(String sql) {
  final tables = <String, Set<String>>{};

  final tablePattern = RegExp(
    r'CREATE TABLE\s+(?:IF NOT EXISTS\s+)?(?:(?:"?([A-Za-z0-9_]+)"?)\.)?"?([A-Za-z0-9_]+)"?\s*\((.*?)\);',
    caseSensitive: false,
    dotAll: true,
  );

  for (final match in tablePattern.allMatches(sql)) {
    final schemaName = (match.group(1) ?? 'public').toLowerCase();
    if (schemaName != 'public') {
      continue;
    }

    final tableName = (match.group(2) ?? '').toLowerCase();
    if (tableName.isEmpty) {
      continue;
    }

    final body = match.group(3) ?? '';
    final cols = <String>{};
    for (final rawLine in body.split('\n')) {
      final line = rawLine.trim().replaceAll(RegExp(r',$'), '');
      if (line.isEmpty) {
        continue;
      }

      final upper = line.toUpperCase();
      if (upper.startsWith('CONSTRAINT ') ||
          upper.startsWith('PRIMARY KEY') ||
          upper.startsWith('FOREIGN KEY') ||
          upper.startsWith('UNIQUE ') ||
          upper.startsWith('CHECK ') ||
          upper.startsWith('EXCLUDE ')) {
        continue;
      }

      final colMatch = RegExp(
        r'^"?([A-Za-z_][A-Za-z0-9_]*)"?\s+',
      ).firstMatch(line);
      final col = colMatch?.group(1)?.toLowerCase();
      if (col != null && col.isNotEmpty) {
        cols.add(col);
      }
    }

    tables[tableName] = _normalizedColumns(cols);
  }

  return tables;
}

Set<String> _normalizedColumns(Set<String> columns) {
  return columns
      .map((c) => c.toLowerCase())
      .where((c) => !_ignoredColumns.contains(c))
      .toSet();
}

List<String> _compareSchemas({
  required String leftName,
  required Map<String, Set<String>> left,
  required String rightName,
  required Map<String, Set<String>> right,
}) {
  final messages = <String>[];

  final leftTables = left.keys.toSet();
  final rightTables = right.keys.toSet();

  final missingInRight = leftTables.difference(rightTables).toList()..sort();
  for (final table in missingInRight) {
    messages.add(
      'Table `$table` exists in $leftName but is missing in $rightName.',
    );
  }

  final missingInLeft = rightTables.difference(leftTables).toList()..sort();
  for (final table in missingInLeft) {
    messages.add(
      'Table `$table` exists in $rightName but is missing in $leftName.',
    );
  }

  final common = leftTables.intersection(rightTables).toList()..sort();
  for (final table in common) {
    final leftCols = left[table] ?? const <String>{};
    final rightCols = right[table] ?? const <String>{};

    final missingColsInRight = leftCols.difference(rightCols).toList()..sort();
    if (missingColsInRight.isNotEmpty) {
      messages.add(
        'Table `$table`: columns in $leftName but missing in $rightName: '
        '${missingColsInRight.join(', ')}.',
      );
    }

    final missingColsInLeft = rightCols.difference(leftCols).toList()..sort();
    if (missingColsInLeft.isNotEmpty) {
      messages.add(
        'Table `$table`: columns in $rightName but missing in $leftName: '
        '${missingColsInLeft.join(', ')}.',
      );
    }
  }

  return messages;
}

void _printMismatches(List<String> mismatches) {
  for (final mismatch in mismatches) {
    stderr.writeln('  - $mismatch');
  }
}
