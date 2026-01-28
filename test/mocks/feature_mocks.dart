import 'package:mocktail/mocktail.dart';
import 'package:taskly_domain/taskly_domain.dart';

/// Mock implementations for feature-level repositories and services.
///
/// These mocks complement the core settingsRepo mocks in [repository_mocks.dart]
/// and provide mocking support for analytics, journal, reviews, and auth.

// === Analytics Feature ===

class MockAnalyticsRepositoryContract extends Mock
    implements AnalyticsRepositoryContract {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

// === Actions/Orchestrators ===

class MockAllocationOrchestrator extends Mock
    implements AllocationOrchestrator {}

class MockOccurrenceCommandService extends Mock
    implements OccurrenceCommandService {}

// === Journal Feature ===

class MockJournalRepositoryContract extends Mock
    implements JournalRepositoryContract {}

// === Auth Feature ===

class MockAuthRepositoryContract extends Mock
    implements AuthRepositoryContract {}
