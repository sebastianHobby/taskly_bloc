import 'dart:io';

/// Backwards-compatible wrapper.
///
/// Prefer running `dart run tool/no_local_package_src_deep_imports.dart`.
Future<void> main(List<String> args) async {
  final result = await Process.run(
    'dart',
    ['run', 'tool/no_local_package_src_deep_imports.dart'],
    runInShell: true,
  );

  stdout.write(result.stdout);
  stderr.write(result.stderr);
  exitCode = result.exitCode;
}
