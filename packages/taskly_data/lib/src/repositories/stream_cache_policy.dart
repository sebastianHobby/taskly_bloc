/// Default cache policy for repository watch queries.
///
/// We avoid caching date-filtered queries by default to prevent unbounded
/// cache growth and to keep day-key semantics centralized.
bool shouldCacheByDefault({required bool hasDateFilter}) {
  return !hasDateFilter;
}
