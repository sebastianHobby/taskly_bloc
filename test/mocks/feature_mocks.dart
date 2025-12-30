import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/contracts/auth_repository_contract.dart';
import 'package:taskly_bloc/domain/repositories/analytics_repository.dart';
import 'package:taskly_bloc/domain/repositories/wellbeing_repository.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';

/// Mock implementations for feature-level repositories and services.
///
/// These mocks complement the core settingsRepo mocks in [repository_mocks.dart]
/// and provide mocking support for analytics, wellbeing, reviews, and auth.

// === Analytics Feature ===

class MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

// === Wellbeing Feature ===

class MockWellbeingRepository extends Mock implements WellbeingRepository {}

// === Auth Feature ===

class MockAuthRepository extends Mock implements AuthRepositoryContract {}
