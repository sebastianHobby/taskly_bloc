import 'package:flutter/foundation.dart';

@immutable
sealed class AnytimeScope {
  const AnytimeScope();

  const factory AnytimeScope.project({required String projectId}) =
      AnytimeProjectScope;
  const factory AnytimeScope.value({required String valueId}) =
      AnytimeValueScope;

  String get id;
}

@immutable
final class AnytimeProjectScope implements AnytimeScope {
  const AnytimeProjectScope({required this.projectId});

  final String projectId;

  @override
  String get id => projectId;
}

@immutable
final class AnytimeValueScope implements AnytimeScope {
  const AnytimeValueScope({required this.valueId});

  final String valueId;

  @override
  String get id => valueId;
}
