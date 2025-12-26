// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analytics_insight.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnalyticsInsight {

 String get id; String get userId; InsightType get insightType; String get title; String get description; DateTime get generatedAt; DateTime get periodStart; DateTime get periodEnd; Map<String, dynamic> get metadata; double? get score;// 0-100 importance score
 double? get confidence;// 0-1 statistical confidence
 bool get isPositive;
/// Create a copy of AnalyticsInsight
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalyticsInsightCopyWith<AnalyticsInsight> get copyWith => _$AnalyticsInsightCopyWithImpl<AnalyticsInsight>(this as AnalyticsInsight, _$identity);

  /// Serializes this AnalyticsInsight to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalyticsInsight&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.insightType, insightType) || other.insightType == insightType)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.score, score) || other.score == score)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.isPositive, isPositive) || other.isPositive == isPositive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,insightType,title,description,generatedAt,periodStart,periodEnd,const DeepCollectionEquality().hash(metadata),score,confidence,isPositive);

@override
String toString() {
  return 'AnalyticsInsight(id: $id, userId: $userId, insightType: $insightType, title: $title, description: $description, generatedAt: $generatedAt, periodStart: $periodStart, periodEnd: $periodEnd, metadata: $metadata, score: $score, confidence: $confidence, isPositive: $isPositive)';
}


}

/// @nodoc
abstract mixin class $AnalyticsInsightCopyWith<$Res>  {
  factory $AnalyticsInsightCopyWith(AnalyticsInsight value, $Res Function(AnalyticsInsight) _then) = _$AnalyticsInsightCopyWithImpl;
@useResult
$Res call({
 String id, String userId, InsightType insightType, String title, String description, DateTime generatedAt, DateTime periodStart, DateTime periodEnd, Map<String, dynamic> metadata, double? score, double? confidence, bool isPositive
});




}
/// @nodoc
class _$AnalyticsInsightCopyWithImpl<$Res>
    implements $AnalyticsInsightCopyWith<$Res> {
  _$AnalyticsInsightCopyWithImpl(this._self, this._then);

  final AnalyticsInsight _self;
  final $Res Function(AnalyticsInsight) _then;

/// Create a copy of AnalyticsInsight
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? insightType = null,Object? title = null,Object? description = null,Object? generatedAt = null,Object? periodStart = null,Object? periodEnd = null,Object? metadata = null,Object? score = freezed,Object? confidence = freezed,Object? isPositive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,insightType: null == insightType ? _self.insightType : insightType // ignore: cast_nullable_to_non_nullable
as InsightType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,isPositive: null == isPositive ? _self.isPositive : isPositive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalyticsInsight].
extension AnalyticsInsightPatterns on AnalyticsInsight {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalyticsInsight value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalyticsInsight() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalyticsInsight value)  $default,){
final _that = this;
switch (_that) {
case _AnalyticsInsight():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalyticsInsight value)?  $default,){
final _that = this;
switch (_that) {
case _AnalyticsInsight() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  InsightType insightType,  String title,  String description,  DateTime generatedAt,  DateTime periodStart,  DateTime periodEnd,  Map<String, dynamic> metadata,  double? score,  double? confidence,  bool isPositive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalyticsInsight() when $default != null:
return $default(_that.id,_that.userId,_that.insightType,_that.title,_that.description,_that.generatedAt,_that.periodStart,_that.periodEnd,_that.metadata,_that.score,_that.confidence,_that.isPositive);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  InsightType insightType,  String title,  String description,  DateTime generatedAt,  DateTime periodStart,  DateTime periodEnd,  Map<String, dynamic> metadata,  double? score,  double? confidence,  bool isPositive)  $default,) {final _that = this;
switch (_that) {
case _AnalyticsInsight():
return $default(_that.id,_that.userId,_that.insightType,_that.title,_that.description,_that.generatedAt,_that.periodStart,_that.periodEnd,_that.metadata,_that.score,_that.confidence,_that.isPositive);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  InsightType insightType,  String title,  String description,  DateTime generatedAt,  DateTime periodStart,  DateTime periodEnd,  Map<String, dynamic> metadata,  double? score,  double? confidence,  bool isPositive)?  $default,) {final _that = this;
switch (_that) {
case _AnalyticsInsight() when $default != null:
return $default(_that.id,_that.userId,_that.insightType,_that.title,_that.description,_that.generatedAt,_that.periodStart,_that.periodEnd,_that.metadata,_that.score,_that.confidence,_that.isPositive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnalyticsInsight implements AnalyticsInsight {
  const _AnalyticsInsight({required this.id, required this.userId, required this.insightType, required this.title, required this.description, required this.generatedAt, required this.periodStart, required this.periodEnd, final  Map<String, dynamic> metadata = const {}, this.score, this.confidence, this.isPositive = true}): _metadata = metadata;
  factory _AnalyticsInsight.fromJson(Map<String, dynamic> json) => _$AnalyticsInsightFromJson(json);

@override final  String id;
@override final  String userId;
@override final  InsightType insightType;
@override final  String title;
@override final  String description;
@override final  DateTime generatedAt;
@override final  DateTime periodStart;
@override final  DateTime periodEnd;
 final  Map<String, dynamic> _metadata;
@override@JsonKey() Map<String, dynamic> get metadata {
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metadata);
}

@override final  double? score;
// 0-100 importance score
@override final  double? confidence;
// 0-1 statistical confidence
@override@JsonKey() final  bool isPositive;

/// Create a copy of AnalyticsInsight
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalyticsInsightCopyWith<_AnalyticsInsight> get copyWith => __$AnalyticsInsightCopyWithImpl<_AnalyticsInsight>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnalyticsInsightToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalyticsInsight&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.insightType, insightType) || other.insightType == insightType)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.periodStart, periodStart) || other.periodStart == periodStart)&&(identical(other.periodEnd, periodEnd) || other.periodEnd == periodEnd)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.score, score) || other.score == score)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.isPositive, isPositive) || other.isPositive == isPositive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,insightType,title,description,generatedAt,periodStart,periodEnd,const DeepCollectionEquality().hash(_metadata),score,confidence,isPositive);

@override
String toString() {
  return 'AnalyticsInsight(id: $id, userId: $userId, insightType: $insightType, title: $title, description: $description, generatedAt: $generatedAt, periodStart: $periodStart, periodEnd: $periodEnd, metadata: $metadata, score: $score, confidence: $confidence, isPositive: $isPositive)';
}


}

/// @nodoc
abstract mixin class _$AnalyticsInsightCopyWith<$Res> implements $AnalyticsInsightCopyWith<$Res> {
  factory _$AnalyticsInsightCopyWith(_AnalyticsInsight value, $Res Function(_AnalyticsInsight) _then) = __$AnalyticsInsightCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, InsightType insightType, String title, String description, DateTime generatedAt, DateTime periodStart, DateTime periodEnd, Map<String, dynamic> metadata, double? score, double? confidence, bool isPositive
});




}
/// @nodoc
class __$AnalyticsInsightCopyWithImpl<$Res>
    implements _$AnalyticsInsightCopyWith<$Res> {
  __$AnalyticsInsightCopyWithImpl(this._self, this._then);

  final _AnalyticsInsight _self;
  final $Res Function(_AnalyticsInsight) _then;

/// Create a copy of AnalyticsInsight
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? insightType = null,Object? title = null,Object? description = null,Object? generatedAt = null,Object? periodStart = null,Object? periodEnd = null,Object? metadata = null,Object? score = freezed,Object? confidence = freezed,Object? isPositive = null,}) {
  return _then(_AnalyticsInsight(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,insightType: null == insightType ? _self.insightType : insightType // ignore: cast_nullable_to_non_nullable
as InsightType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,periodStart: null == periodStart ? _self.periodStart : periodStart // ignore: cast_nullable_to_non_nullable
as DateTime,periodEnd: null == periodEnd ? _self.periodEnd : periodEnd // ignore: cast_nullable_to_non_nullable
as DateTime,metadata: null == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,score: freezed == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,isPositive: null == isPositive ? _self.isPositive : isPositive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
