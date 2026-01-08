class RepositoryException implements Exception {
  RepositoryException(this.message, [this.cause, this.stackTrace]);
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() =>
      'RepositoryException: $message${cause != null ? ' (cause: $cause)' : ''}';
}

class RepositoryNotFoundException extends RepositoryException {
  RepositoryNotFoundException(super.message, [super.cause, super.stackTrace]);
}

class RepositoryValidationException extends RepositoryException {
  RepositoryValidationException(super.message, [super.cause, super.stackTrace]);
}
