/// Chip-centric Taskly UI public API.
///
/// This is intentionally separate from feed tiles so screens that only need
/// entity tiles don't implicitly depend on chip widget implementations.
library;

// Data model only. Chip widgets are intentionally not part of the public API.
export 'src/primitives/value_chip.dart' show ValueChipData;
