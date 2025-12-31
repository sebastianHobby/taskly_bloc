#!/usr/bin/env dart
// ignore_for_file: avoid_print
/// i18n Automation Script
///
/// This script performs automated checks for internationalization issues:
/// 1. Verifies ARB key parity between English and Spanish files
/// 2. Detects potential hardcoded strings in Dart presentation files
/// 3. Validates ARB file JSON syntax
///
/// Usage:
///   dart run tool/i18n_check.dart [--fix]
///
/// Options:
///   --fix    Attempt to add missing keys to ARB files (placeholders only)
///
/// Exit codes:
///   0 - All checks passed
///   1 - Issues found (missing keys, hardcoded strings, or syntax errors)

import 'dart:convert';
import 'dart:io';

/// Patterns that indicate a hardcoded user-facing string
final List<RegExp> hardcodedStringPatterns = [
  // Text widget with string literal
  RegExp(r"Text\(\s*'[A-Z][^']{2,}'"),
  RegExp(r'Text\(\s*"[A-Z][^"]{2,}"'),

  // Common widget properties with string literals
  RegExp(r"labelText:\s*'[A-Z][^']{2,}'"),
  RegExp(r'labelText:\s*"[A-Z][^"]{2,}"'),
  RegExp(r"hintText:\s*'[A-Z][^']{2,}'"),
  RegExp(r'hintText:\s*"[A-Z][^"]{2,}"'),
  RegExp(r"title:\s*Text\(\s*'[A-Z][^']{2,}'"),
  RegExp(r'title:\s*Text\(\s*"[A-Z][^"]{2,}"'),

  // AppBar title
  RegExp(r"AppBar\([^)]*title:\s*Text\(\s*'[^']{2,}'"),

  // SnackBar content
  RegExp(r"SnackBar\([^)]*content:\s*Text\(\s*'[^']{2,}'"),

  // Dialog titles and content
  RegExp(r"AlertDialog\([^)]*title:\s*Text\(\s*'[^']{2,}'"),

  // Tooltip messages
  RegExp(r"tooltip:\s*'[A-Z][^']{2,}'"),
  RegExp(r'tooltip:\s*"[A-Z][^"]{2,}"'),

  // Semantic labels
  RegExp(r"semanticLabel:\s*'[A-Z][^']{2,}'"),
];

/// Patterns to exclude (not user-facing strings)
final List<RegExp> excludePatterns = [
  // Technical strings
  RegExp(r"'[a-z_]+\.[a-z_]+'"), // dot notation
  RegExp("'package:"), // package imports
  RegExp("'assets/"), // asset paths
  RegExp(r"'\d+"), // numbers
  RegExp("'[A-Z_]+_[A-Z_]+'"), // CONSTANT_CASE
  RegExp("'application/"), // mime types
  RegExp("'https?://"), // URLs
  RegExp(r"key:\s*'"), // keys
  RegExp(r"debugLabel:\s*'"), // debug labels
  RegExp(r"semanticsLabel:\s*'"), // semantics technical labels
];

class I18nCheckResult {
  I18nCheckResult({
    required this.missingInEnglish,
    required this.missingInSpanish,
    required this.hardcodedStrings,
    required this.syntaxErrors,
  });
  final List<String> missingInEnglish;
  final List<String> missingInSpanish;
  final Map<String, List<HardcodedString>> hardcodedStrings;
  final List<String> syntaxErrors;

  bool get hasIssues =>
      missingInEnglish.isNotEmpty ||
      missingInSpanish.isNotEmpty ||
      hardcodedStrings.isNotEmpty ||
      syntaxErrors.isNotEmpty;

  int get totalIssues =>
      missingInEnglish.length +
      missingInSpanish.length +
      hardcodedStrings.values.fold<int>(0, (sum, list) => sum + list.length) +
      syntaxErrors.length;
}

class HardcodedString {
  HardcodedString({
    required this.lineNumber,
    required this.line,
    required this.matchedText,
  });
  final int lineNumber;
  final String line;
  final String matchedText;
}

Future<void> main(List<String> args) async {
  final fix = args.contains('--fix');

  print('🌐 Running i18n checks...\n');

  final result = await runChecks();

  printResults(result);

  if (fix && result.missingInSpanish.isNotEmpty) {
    await addMissingKeys(result.missingInSpanish);
  }

  exit(result.hasIssues ? 1 : 0);
}

Future<I18nCheckResult> runChecks() async {
  final missingInEnglish = <String>[];
  final missingInSpanish = <String>[];
  final hardcodedStrings = <String, List<HardcodedString>>{};
  final syntaxErrors = <String>[];

  // Load ARB files
  const enArbPath = 'lib/core/l10n/arb/app_en.arb';
  const esArbPath = 'lib/core/l10n/arb/app_es.arb';

  Map<String, dynamic>? enArb;
  Map<String, dynamic>? esArb;

  try {
    final enContent = await File(enArbPath).readAsString();
    enArb = json.decode(enContent) as Map<String, dynamic>;
  } catch (e) {
    syntaxErrors.add('Error parsing $enArbPath: $e');
  }

  try {
    final esContent = await File(esArbPath).readAsString();
    esArb = json.decode(esContent) as Map<String, dynamic>;
  } catch (e) {
    syntaxErrors.add('Error parsing $esArbPath: $e');
  }

  // Check key parity
  if (enArb != null && esArb != null) {
    final enKeys = enArb.keys
        .where((k) => !k.startsWith('@') && !k.startsWith('@@'))
        .toSet();
    final esKeys = esArb.keys
        .where((k) => !k.startsWith('@') && !k.startsWith('@@'))
        .toSet();

    missingInSpanish.addAll(enKeys.difference(esKeys));
    missingInEnglish.addAll(esKeys.difference(enKeys));
  }

  // Scan for hardcoded strings in presentation layer
  final presentationDir = Directory('lib/presentation');
  if (await presentationDir.exists()) {
    await for (final entity in presentationDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final issues = await scanFileForHardcodedStrings(entity);
        if (issues.isNotEmpty) {
          hardcodedStrings[entity.path] = issues;
        }
      }
    }
  }

  return I18nCheckResult(
    missingInEnglish: missingInEnglish,
    missingInSpanish: missingInSpanish,
    hardcodedStrings: hardcodedStrings,
    syntaxErrors: syntaxErrors,
  );
}

Future<List<HardcodedString>> scanFileForHardcodedStrings(File file) async {
  final issues = <HardcodedString>[];
  final lines = await file.readAsLines();

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    // Skip comments
    if (line.trim().startsWith('//') || line.trim().startsWith('*')) {
      continue;
    }

    // Skip lines with l10n calls
    if (line.contains('l10n.') || line.contains('AppLocalizations')) {
      continue;
    }

    // Skip excluded patterns
    var shouldExclude = false;
    for (final pattern in excludePatterns) {
      if (pattern.hasMatch(line)) {
        shouldExclude = true;
        break;
      }
    }
    if (shouldExclude) continue;

    // Check for hardcoded string patterns
    for (final pattern in hardcodedStringPatterns) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        issues.add(
          HardcodedString(
            lineNumber: i + 1,
            line: line.trim(),
            matchedText: match.group(0) ?? '',
          ),
        );
        break; // Only report one issue per line
      }
    }
  }

  return issues;
}

void printResults(I18nCheckResult result) {
  if (!result.hasIssues) {
    print('✅ All i18n checks passed!\n');
    return;
  }

  print('❌ Found ${result.totalIssues} i18n issue(s):\n');

  if (result.syntaxErrors.isNotEmpty) {
    print('📛 Syntax Errors:');
    for (final error in result.syntaxErrors) {
      print('   • $error');
    }
    print('');
  }

  if (result.missingInSpanish.isNotEmpty) {
    print('🇪🇸 Missing in Spanish (${result.missingInSpanish.length}):');
    for (final key in result.missingInSpanish.take(20)) {
      print('   • $key');
    }
    if (result.missingInSpanish.length > 20) {
      print('   ... and ${result.missingInSpanish.length - 20} more');
    }
    print('');
  }

  if (result.missingInEnglish.isNotEmpty) {
    print('🇺🇸 Missing in English (${result.missingInEnglish.length}):');
    for (final key in result.missingInEnglish.take(20)) {
      print('   • $key');
    }
    if (result.missingInEnglish.length > 20) {
      print('   ... and ${result.missingInEnglish.length - 20} more');
    }
    print('');
  }

  if (result.hardcodedStrings.isNotEmpty) {
    print('📝 Potential Hardcoded Strings:');
    for (final entry in result.hardcodedStrings.entries) {
      final relativePath = entry.key.replaceAll(r'\', '/');
      print('   📄 $relativePath:');
      for (final issue in entry.value.take(5)) {
        print('      L${issue.lineNumber}: ${issue.matchedText}');
      }
      if (entry.value.length > 5) {
        print('      ... and ${entry.value.length - 5} more');
      }
    }
    print('');
  }

  print('💡 To fix missing keys, run: dart run tool/i18n_check.dart --fix\n');
}

Future<void> addMissingKeys(List<String> missingKeys) async {
  print('🔧 Adding ${missingKeys.length} missing key(s) to Spanish ARB...\n');

  const esArbPath = 'lib/core/l10n/arb/app_es.arb';
  const enArbPath = 'lib/core/l10n/arb/app_en.arb';

  final esContent = await File(esArbPath).readAsString();
  final enContent = await File(enArbPath).readAsString();

  final esArb = json.decode(esContent) as Map<String, dynamic>;
  final enArb = json.decode(enContent) as Map<String, dynamic>;

  for (final key in missingKeys) {
    // Copy from English as placeholder
    if (enArb.containsKey(key)) {
      esArb[key] = '[TODO: Translate] ${enArb[key]}';

      // Copy metadata if exists
      final metaKey = '@$key';
      if (enArb.containsKey(metaKey)) {
        esArb[metaKey] = enArb[metaKey];
      }
    }
  }

  // Write back
  final encoder = JsonEncoder.withIndent('    ');
  await File(esArbPath).writeAsString(encoder.convert(esArb));

  print(
    '✅ Added placeholder translations. Search for [TODO: Translate]'
    ' in $esArbPath\n',
  );
}
