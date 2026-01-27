final class ValueTagLayout {
  ValueTagLayout._();

  static String? formatLabel(String label, {required int maxChars}) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length <= maxChars) return trimmed;
    if (maxChars <= 3) return trimmed.substring(0, maxChars);
    final keep = maxChars - 3;
    return '${trimmed.substring(0, keep)}...';
  }
}
