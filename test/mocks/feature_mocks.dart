import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/interfaces/auth_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/analytics_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/journal_repository_contract.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';

/// Mock implementations for feature-level repositories and services.
///
/// These mocks complement the core settingsRepo mocks in [repository_mocks.dart]
/// and provide mocking support for analytics, journal, reviews, and auth.

// === Analytics Feature ===

class MockAnalyticsRepositoryContract extends Mock
    implements AnalyticsRepositoryContract {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

// === Journal Feature ===

class MockJournalRepositoryContract extends Mock
    implements JournalRepositoryContract {}

// === Auth Feature ===

class MockAuthRepositoryContract extends Mock
    implements AuthRepositoryContract {}
