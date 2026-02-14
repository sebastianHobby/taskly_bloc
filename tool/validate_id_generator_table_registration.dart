import 'dart:io';

Future<void> main(List<String> args) async {
  const idGeneratorPath = 'packages/taskly_data/lib/src/id/id_generator.dart';
  const schemaPath =
      'packages/taskly_data/lib/src/infrastructure/powersync/schema.dart';

  final idGeneratorFile = File(idGeneratorPath);
  final schemaFile = File(schemaPath);

  if (!idGeneratorFile.existsSync()) {
    stdout.writeln('IdGenerator file not found at $idGeneratorPath. Skipping.');
    return;
  }

  if (!schemaFile.existsSync()) {
    stdout.writeln('Schema file not found at $schemaPath. Skipping.');
    return;
  }

  final idGeneratorContent = idGeneratorFile.readAsStringSync();
  final schemaContent = schemaFile.readAsStringSync();

  final schemaTables = RegExp(
    r"Table\(\s*'(\w+)'",
  ).allMatches(schemaContent).map((m) => m.group(1)!).toSet();

  final registeredTables = {
    ..._extractTables(idGeneratorContent, 'v5Tables'),
    ..._extractTables(idGeneratorContent, 'v4Tables'),
  };

  final unregisteredTables = schemaTables.difference(registeredTables);
  final orphanedTables = registeredTables.difference(schemaTables);

  if (unregisteredTables.isNotEmpty) {
    stderr.writeln('Tables in schema but NOT registered in IdGenerator:');
    for (final table in unregisteredTables.toList()..sort()) {
      stderr.writeln('  - $table');
    }
    stderr.writeln(
      'Add these to v5Tables or v4Tables in packages/taskly_data/lib/src/id/id_generator.dart',
    );
    exitCode = 1;
    return;
  }

  if (orphanedTables.isNotEmpty) {
    stdout.writeln('Tables registered in IdGenerator but NOT in schema:');
    for (final table in orphanedTables.toList()..sort()) {
      stdout.writeln('  - $table');
    }
    stdout.writeln('Consider removing these from id_generator.dart.');
  }

  stdout.writeln('All ${schemaTables.length} schema tables are registered.');
}

Set<String> _extractTables(String content, String variableName) {
  final match = RegExp(
    '$variableName\\s*=\\s*\\{([^}]+)\\}',
  ).firstMatch(content);
  if (match == null) {
    return <String>{};
  }
  return RegExp(
    r"'(\w+)'",
  ).allMatches(match.group(1)!).map((m) => m.group(1)!).toSet();
}
