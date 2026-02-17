String? hashIdentifierForTelemetry(String? value) {
  if (value == null) return null;
  final normalized = value.trim();
  if (normalized.isEmpty) return null;

  // Lightweight, non-reversible hash for log correlation without raw IDs.
  var hash = 0x811c9dc5;
  for (final unit in normalized.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
