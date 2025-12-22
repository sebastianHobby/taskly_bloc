int compareAsciiLowerCase(String a, String b) {
  return a.toLowerCase().compareTo(b.toLowerCase());
}

int compareNullableDate(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}
