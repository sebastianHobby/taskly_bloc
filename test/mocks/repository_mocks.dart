import 'package:mocktail/mocktail.dart';
import 'package:taskly_data/id.dart';

/// Shared mock implementations for repository contracts.
///
/// These mocks can be imported and used across all test files to avoid
/// duplication and ensure consistency in testing patterns.

// === Core Repositories ===

import 'package:taskly_domain/taskly_domain.dart';

class MockTaskRepositoryContract extends Mock
    implements TaskRepositoryContract {}

class MockProjectRepositoryContract extends Mock
    implements ProjectRepositoryContract {}

class MockProjectAnchorStateRepositoryContract extends Mock
    implements ProjectAnchorStateRepositoryContract {}

class MockValueRepositoryContract extends Mock
    implements ValueRepositoryContract {}

class MockSettingsRepositoryContract extends Mock
    implements SettingsRepositoryContract {}

class MockRoutineRepositoryContract extends Mock
    implements RoutineRepositoryContract {}

class MockMyDayRepositoryContract extends Mock
    implements MyDayRepositoryContract {}

// === Occurrence Helpers ===

class MockOccurrenceStreamExpanderContract extends Mock
    implements OccurrenceStreamExpanderContract {}

class MockOccurrenceWriteHelperContract extends Mock
    implements OccurrenceWriteHelperContract {}

// === Notifications ===

class MockPendingNotificationsRepositoryContract extends Mock
    implements PendingNotificationsRepositoryContract {}

// === ID Generator ===

class MockIdGenerator extends Mock implements IdGenerator {}

// === Auth ===

class MockAuthRepositoryContract extends Mock
    implements AuthRepositoryContract {}
