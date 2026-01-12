import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/interfaces/auth_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/occurrence_stream_expander_contract.dart';
import 'package:taskly_bloc/domain/interfaces/occurrence_write_helper_contract.dart';
import 'package:taskly_bloc/domain/interfaces/pending_notifications_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';

/// Shared mock implementations for repository contracts.
///
/// These mocks can be imported and used across all test files to avoid
/// duplication and ensure consistency in testing patterns.

// === Core Repositories ===

class MockTaskRepositoryContract extends Mock
    implements TaskRepositoryContract {}

class MockProjectRepositoryContract extends Mock
    implements ProjectRepositoryContract {}

class MockValueRepositoryContract extends Mock
    implements ValueRepositoryContract {}

class MockSettingsRepositoryContract extends Mock
    implements SettingsRepositoryContract {}

// === Occurrence Helpers ===

class MockOccurrenceStreamExpanderContract extends Mock
    implements OccurrenceStreamExpanderContract {}

class MockOccurrenceWriteHelperContract extends Mock
    implements OccurrenceWriteHelperContract {}

// === Screens & Workflows ===

class MockScreenDefinitionsRepositoryContract extends Mock
    implements ScreenDefinitionsRepositoryContract {}

// === Notifications ===

class MockPendingNotificationsRepositoryContract extends Mock
    implements PendingNotificationsRepositoryContract {}

// === ID Generator ===

class MockIdGenerator extends Mock implements IdGenerator {}

// === Auth ===

class MockAuthRepositoryContract extends Mock
    implements AuthRepositoryContract {}
