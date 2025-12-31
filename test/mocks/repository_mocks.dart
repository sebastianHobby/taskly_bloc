import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/occurrence_stream_expander_contract.dart';
import 'package:taskly_bloc/domain/interfaces/occurrence_write_helper_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/allocation_preferences_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/priority_rankings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';

/// Shared mock implementations for repository contracts.
///
/// These mocks can be imported and used across all test files to avoid
/// duplication and ensure consistency in testing patterns.

class MockTaskRepositoryContract extends Mock
    implements TaskRepositoryContract {}

class MockProjectRepositoryContract extends Mock
    implements ProjectRepositoryContract {}

class MockLabelRepositoryContract extends Mock
    implements LabelRepositoryContract {}

class MockSettingsRepositoryContract extends Mock
    implements SettingsRepositoryContract {}

class MockOccurrenceStreamExpanderContract extends Mock
    implements OccurrenceStreamExpanderContract {}

class MockOccurrenceWriteHelperContract extends Mock
    implements OccurrenceWriteHelperContract {}

class MockScreenDefinitionsRepositoryContract extends Mock
    implements ScreenDefinitionsRepositoryContract {}

class MockAllocationPreferencesRepositoryContract extends Mock
    implements AllocationPreferencesRepositoryContract {}

class MockPriorityRankingsRepositoryContract extends Mock
    implements PriorityRankingsRepositoryContract {}
