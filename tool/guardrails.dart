import 'dart:io';

/// Central runner for Dart-based repo guardrails.
///
/// This keeps CI wiring simple and makes it easy to add/remove guardrails in one
/// place.
Future<void> main(List<String> args) async {
  final guardrails = <_Guardrail>[
    const _Guardrail(
      name: 'Block deep imports into local package src/',
      script: 'tool/no_local_package_src_deep_imports.dart',
    ),
    const _Guardrail(
      name: 'Block Drift UPSERT usage on PowerSync tables',
      script: 'tool/no_powersync_local_upserts.dart',
    ),
    const _Guardrail(
      name: 'Block DateTime.now() in domain/data',
      script: 'tool/no_datetime_now_in_domain_data.dart',
    ),
    const _Guardrail(
      name: 'Enforce layering via imports',
      script: 'tool/no_layering_violations.dart',
    ),
  ];

  for (final guardrail in guardrails) {
    stdout.writeln('== ${guardrail.name} ==');
    final result = await Process.run(
      'dart',
      ['run', guardrail.script],
      runInShell: true,
    );

    stdout.write(result.stdout);
    stderr.write(result.stderr);

    if (result.exitCode != 0) {
      stderr.writeln('FAIL: ${guardrail.name}');
      exitCode = result.exitCode;
      return;
    }
  }

  stdout.writeln('✓ All guardrails passed.');
}

class _Guardrail {
  const _Guardrail({required this.name, required this.script});

  final String name;
  final String script;
}
