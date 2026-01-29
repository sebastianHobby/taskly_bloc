import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/services.dart';

class MockNowService extends Mock implements NowService {}

class MockTemporalTriggerService extends Mock
    implements TemporalTriggerService {}

class MockHomeDayKeyService extends Mock implements HomeDayKeyService {}
