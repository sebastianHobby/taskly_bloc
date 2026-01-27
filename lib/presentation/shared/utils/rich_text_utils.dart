import 'dart:convert';

import 'package:fleather/fleather.dart';

ParchmentDocument parseParchmentDocument(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) {
    return ParchmentDocument();
  }

  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is List) {
      return ParchmentDocument.fromJson(decoded);
    }
  } catch (_) {}

  final document = ParchmentDocument();
  document.insert(0, '$trimmed\n');
  return document;
}

String serializeParchmentDocument(ParchmentDocument document) {
  return jsonEncode(document.toJson());
}

String? richTextPreview(
  String? raw, {
  int maxChars = 160,
}) {
  final plain = parseParchmentDocument(
    raw,
  ).toPlainText().replaceAll(RegExp(r'\s+'), ' ').trim();
  if (plain.isEmpty) return null;
  if (plain.length <= maxChars) return plain;
  if (maxChars <= 3) return plain.substring(0, maxChars);
  final keep = maxChars - 3;
  return '${plain.substring(0, keep)}...';
}

bool richTextHasContent(String? raw) {
  final plain = parseParchmentDocument(raw).toPlainText().trim();
  return plain.isNotEmpty;
}
