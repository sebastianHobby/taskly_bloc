import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/domain/contracts/auth_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/services/analytics_service.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/repositories/wellbeing_repository.dart';

/// Mock implementations for feature-level repositories and services.
///
/// These mocks complement the core settingsRepo mocks in [repository_mocks.dart]
/// and provide mocking support for analytics, wellbeing, reviews, and auth.

// === Analytics Feature ===

class MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

// === Wellbeing Feature ===

class MockWellbeingRepository extends Mock implements WellbeingRepository {}

// === Reviews Feature ===

class MockReviewsRepository extends Mock implements ReviewsRepository {}

// === Auth Feature ===

class MockAuthRepository extends Mock implements AuthRepositoryContract {}
