/// Generic error class for detail BLoCs
class DetailBlocError<T> {
  const DetailBlocError({
    required this.error,
    this.stackTrace,
  });

  final Object error;
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetailBlocError<T> &&
        other.error == error &&
        other.stackTrace == stackTrace;
  }

  @override
  int get hashCode => error.hashCode ^ stackTrace.hashCode;

  @override
  String toString() {
    return 'DetailBlocError<$T>{error: $error, stackTrace: $stackTrace}';
  }
}
