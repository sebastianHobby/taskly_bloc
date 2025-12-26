import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/occurrence_stream_expander_contract.dart';
import 'package:taskly_bloc/domain/contracts/occurrence_write_helper_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';

/// Shared mock implementations for repository contracts.
///
/// These mocks can be imported and used across all test files to avoid
/// duplication and ensure consistency in testing patterns.

class MockTaskRepository extends Mock implements TaskRepositoryContract {}

class MockProjectRepository extends Mock implements ProjectRepositoryContract {}

class MockLabelRepository extends Mock implements LabelRepositoryContract {}

class MockSettingsRepository extends Mock
    implements SettingsRepositoryContract {}

class MockOccurrenceStreamExpander extends Mock
    implements OccurrenceStreamExpanderContract {}

class MockOccurrenceWriteHelper extends Mock
    implements OccurrenceWriteHelperContract {}
