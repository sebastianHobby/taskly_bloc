import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/services/review_action_service.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/domain/repositories/wellbeing_repository.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/services/analytics_service.dart';

/// Mock implementations for reviews and wellbeing feature testing

class MockReviewsRepository extends Mock implements ReviewsRepository {}

class MockReviewActionService extends Mock implements ReviewActionService {}

class MockWellbeingRepository extends Mock implements WellbeingRepository {}

class MockAnalyticsService extends Mock implements AnalyticsService {}
