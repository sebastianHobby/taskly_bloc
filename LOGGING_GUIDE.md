# Logging Guide

## Overview

The application uses a centralized logging system (`AppLogger`) that provides structured, filterable logging with proper severity levels. This guide explains best practices for using the logging system effectively.

## Quick Start

```dart
import 'package:taskly_bloc/core/utils/app_logger.dart';

// Create a logger for your feature/component
final logger = AppLogger.forBloc('MyBloc');
// or
final logger = AppLogger.forRepository('MyRepository');
// or
final logger = AppLogger.forService('MyService');
// or
final logger = AppLogger('custom.namespace');

// Log messages at different severity levels
logger.debug('Debugging information');
logger.info('General information');
logger.warning('Warning message', error, stackTrace);
logger.error('Error occurred', error, stackTrace);
logger.critical('Critical error', error, stackTrace);
```

## Log Levels

### Severity Hierarchy

1. **TRACE** (Finest) - Most detailed debugging information
2. **DEBUG** (Fine) - General debugging during development
3. **INFO** - General informational messages about app state
4. **WARNING** - Potentially problematic situations
5. **ERROR** (Severe) - Error conditions affecting functionality
6. **CRITICAL** (Shout) - Severe errors causing instability

### When to Use Each Level

#### TRACE
Use for very detailed debugging information that's typically only needed during deep investigation:
```dart
logger.trace('Processing item $index of $total');
logger.trace('Cache hit for key: $key');
```

#### DEBUG
Use for general debugging information during development:
```dart
logger.debug('Executing operation: ${operation.name}');
logger.debug('User navigated to screen: $screenName');
logger.debug('Loading entity...');
```

#### INFO
Use for important application state changes and flow information:
```dart
logger.info('User logged in successfully');
logger.info('Sync completed: $itemsCount items synchronized');
logger.info('Initializing dependencies...');
```

#### WARNING
Use for situations that are unusual but recoverable:
```dart
logger.warning('API rate limit approaching', error, stackTrace);
logger.warning('Failed to parse cached data, using defaults');
logger.caughtException('JSON parsing', error, stackTrace);
```

#### ERROR
Use for errors that affect functionality but allow the app to continue:
```dart
logger.error('Failed to load tasks', error, stackTrace);
logger.operationFailed('update task', reason: 'Network timeout', error: error);
logger.unexpectedException('database query', error, stackTrace);
```

#### CRITICAL
Use for severe errors that may cause app instability or data loss:
```dart
logger.critical('Database corruption detected', error, stackTrace);
logger.critical('Uncaught platform error', error, stackTrace);
```

## Best Practices

### 1. Use Named Loggers

Always create a logger with a descriptive namespace to make filtering easier:

```dart
// Good
class TaskRepository {
  final _logger = AppLogger.forRepository('Task');
  
  Future<void> save(Task task) async {
    try {
      _logger.debug('Saving task: ${task.id}');
      await _database.save(task);
      _logger.info('Task saved successfully: ${task.id}');
    } catch (e, stack) {
      _logger.error('Failed to save task: ${task.id}', e, stack);
      rethrow;
    }
  }
}

// Also good
final logger = AppLogger('feature.tasks.selector');
```

### 2. Log Before and After Operations

Log the start and completion of important operations:

```dart
Future<void> _onUpdate(UpdateEvent event, Emitter emit) async {
  logger.debug('Executing operation: update');
  try {
    await repository.update(event.data);
    logger.debug('Operation successful: update');
    emit(SuccessState());
  } catch (error, stackTrace) {
    logger.error('Operation failed: update', error, stackTrace);
    emit(ErrorState(error));
  }
}
```

### 3. Include Context in Error Messages

Provide enough context to understand what was happening when the error occurred:

```dart
// Bad
logger.error('Failed', error, stackTrace);

// Good
logger.error('Failed to load task with ID: ${taskId}', error, stackTrace);

// Better
logger.operationFailed(
  'load task',
  reason: 'Task ID: $taskId',
  error: error,
  stackTrace: stackTrace,
);
```

### 4. Use Helper Methods for Common Patterns

The `AppLogger` class provides specialized methods for common scenarios:

```dart
// For caught exceptions you expected
logger.caughtException('color parsing', error, stackTrace);

// For unexpected exceptions
logger.unexpectedException('database query', error, stackTrace);

// For operation failures
logger.operationFailed('sync tasks', reason: 'Network timeout');

// For API errors
logger.apiError('/tasks', 404, error: error, stackTrace: stackTrace);

// For database errors
logger.databaseError('insert task', error: error, stackTrace: stackTrace);
```

### 5. Don't Log Sensitive Information

Never log passwords, tokens, or personally identifiable information:

```dart
// Bad
logger.debug('User credentials: $email, $password');

// Good
logger.debug('User authentication attempt for: ${email.substring(0, 3)}***');
```

### 6. Use Appropriate Granularity

Match the logging level to the deployment environment:

```dart
// In bootstrap.dart
AppLogger.initialize(
  minimumLevel: kDebugMode ? LogLevel.debug : LogLevel.info,
);
```

## Logger Factory Methods

### `AppLogger.forBloc(String blocName)`
For BLoC classes:
```dart
class TaskListBloc extends Bloc<TaskListEvent, TaskListState> {
  final _logger = AppLogger.forBloc('TaskList');
}
```

### `AppLogger.forRepository(String repositoryName)`
For repository classes:
```dart
class TaskRepository {
  final _logger = AppLogger.forRepository('Task');
}
```

### `AppLogger.forService(String serviceName)`
For service classes:
```dart
class SyncService {
  final _logger = AppLogger.forService('Sync');
}
```

### `AppLogger.forFeature(String featureName)`
For feature-specific utilities:
```dart
final logger = AppLogger.forFeature('next_actions');
```

## Filtering Logs

### In DevTools

Logs are automatically sent to Dart DevTools where you can:
- Filter by severity level
- Filter by logger name
- Search log messages
- View full stack traces

### In Console Output

Logs are formatted with:
- Timestamp
- Severity level (padded for alignment)
- Logger namespace
- Message
- Error details (if present)
- Stack trace (first 8 lines, if present)

Example output:
```
[10:23:45.123] [ERROR  ] [bloc.TaskDetail] Operation failed: update
  Error: StateError: Task not found
  Stack trace:
    #0      TaskRepository.update (task_repository.dart:42)
    #1      TaskDetailBloc._onUpdate (task_detail_bloc.dart:89)
    ...
```

## Migration from Old Logging

### Replace `dart:developer` log calls

```dart
// Old
import 'dart:developer';
log('Message', name: 'MyClass', error: error, stackTrace: stackTrace);

// New
import 'package:taskly_bloc/core/utils/app_logger.dart';
final logger = AppLogger('myclass');
logger.error('Message', error, stackTrace);
```

### Replace `print` statements

```dart
// Old
print('User logged in');

// New
logger.info('User logged in');
```

### Replace silent error catching

```dart
// Bad - errors disappear
try {
  riskyOperation();
} catch (_) {
  // Silent fail
}

// Good - errors are logged
try {
  riskyOperation();
} catch (e, stack) {
  logger.warning('Risky operation failed, using fallback', e, stack);
  useFallback();
}
```

## Performance Considerations

1. **Conditional Trace Logging**: Wrap very frequent trace logs in debug mode checks:
   ```dart
   if (kDebugMode) {
     logger.trace('Processing item $index');
   }
   ```

2. **Lazy Message Evaluation**: Expensive log messages are only evaluated if the level is enabled:
   ```dart
   // This is fine - the string interpolation only happens if debug is enabled
   logger.debug('Complex data: ${expensiveOperation()}');
   ```

3. **Stack Trace Truncation**: Stack traces are automatically truncated to the first 8 lines to reduce console clutter while maintaining useful context.

## Testing Considerations

In tests, you can:

1. **Mock the logger** for testing log output
2. **Suppress logs** by setting the minimum level to `LogLevel.off`
3. **Verify logs** by capturing log records

```dart
test('logs error when operation fails', () {
  // Setup test to capture log records
  // Verify appropriate log calls were made
});
```

## Common Patterns

### BLoC Error Handling

```dart
Future<void> _onEvent(MyEvent event, Emitter<MyState> emit) async {
  try {
    logger.debug('Handling event: ${event.runtimeType}');
    // ... operation
    logger.debug('Event handled successfully');
  } catch (error, stackTrace) {
    logger.error(
      'Failed to handle event: ${event.runtimeType}',
      error,
      stackTrace,
    );
    emit(ErrorState(error));
  }
}
```

### Repository Operations

```dart
Future<Task?> get(String id) async {
  try {
    logger.debug('Fetching task: $id');
    final task = await _database.getTask(id);
    if (task == null) {
      logger.warning('Task not found: $id');
    } else {
      logger.debug('Task fetched successfully: $id');
    }
    return task;
  } catch (error, stackTrace) {
    logger.databaseError('fetch task', error: error, stackTrace: stackTrace);
    rethrow;
  }
}
```

### Network Operations

```dart
Future<List<Task>> fetchFromApi() async {
  try {
    logger.info('Fetching tasks from API');
    final response = await _client.get('/tasks');
    
    if (response.statusCode == 200) {
      logger.info('Tasks fetched successfully: ${response.data.length} items');
      return parseTasks(response.data);
    } else {
      logger.apiError('/tasks', response.statusCode);
      throw ApiException(response.statusCode);
    }
  } catch (error, stackTrace) {
    logger.error('API request failed', error, stackTrace);
    rethrow;
  }
}
```

## Troubleshooting

### Logs Not Appearing

1. Check minimum log level in `bootstrap.dart`
2. Ensure `AppLogger.initialize()` is called before logging
3. Verify logger namespace is not filtered in DevTools

### Too Many Logs

1. Increase minimum log level for production
2. Use conditional trace logging
3. Filter by namespace in DevTools

### Missing Context

1. Include operation name in messages
2. Add relevant IDs and parameters
3. Use helper methods that provide structure

## Summary

- Use `AppLogger` for all logging throughout the application
- Choose appropriate severity levels based on the situation
- Provide context in error messages
- Use factory methods for consistent naming
- Never log sensitive information
- Log both success and failure paths for important operations
