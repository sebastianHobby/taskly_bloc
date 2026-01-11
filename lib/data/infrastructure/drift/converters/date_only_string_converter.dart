import 'package:drift/drift.dart';
import 'package:taskly_bloc/domain/time/date_only.dart';

/// Converts between a Dart [DateTime] (date-only, local midnight) and a
/// Postgres-style date string (`YYYY-MM-DD`).
///
/// This is used for fields that are semantically "calendar dates" and must not
/// shift when users travel.
class DateOnlyStringConverter extends TypeConverter<DateTime, String> {
  const DateOnlyStringConverter();

  @override
  DateTime fromSql(String fromDb) {
    final parsed = tryParseDateOnly(fromDb);
    if (parsed == null) {
      throw FormatException('Invalid date-only value: $fromDb');
    }
    return parsed;
  }

  @override
  String toSql(DateTime value) => encodeDateOnly(value);
}

const dateOnlyStringConverter = DateOnlyStringConverter();

final NullAwareTypeConverter<DateTime, String> dateOnlyStringNullableConverter =
    NullAwareTypeConverter.wrap(
      dateOnlyStringConverter,
    );
