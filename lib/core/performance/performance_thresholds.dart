/// Thresholds for user-perceived performance events.
///
/// Keep these centralized so warnings are consistent across screens.
abstract final class PerformanceThresholds {
  // Screen-level
  static const int screenSlowMs = 1000;
  static const int screenInfoMs = 500;

  // Time to first data (TTFD)
  static const int firstDataSlowMs = 1000;
  static const int firstDataVerySlowMs = 3000;

  // Time to first paint after navigation (TTFP)
  static const int firstPaintSlowMs = 1000;
  static const int firstPaintInfoMs = 500;

  // Loading state emission (spinner)
  static const int loadingEmitInfoMs = 50;
}
