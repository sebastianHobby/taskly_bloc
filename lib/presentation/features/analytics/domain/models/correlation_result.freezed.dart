// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'correlation_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CorrelationResult {

 String get sourceLabel; String get targetLabel; double get coefficient; CorrelationStrength get strength; String? get sourceId; String? get targetId; String? get sourceType; String? get targetType; int? get sampleSize; String? get insight; double? get valueWithSource; double? get valueWithoutSource; double? get differencePercent; StatisticalSignificance? get statisticalSignificance; PerformanceMetrics? get performanceMetrics;
/// Create a copy of CorrelationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CorrelationResultCopyWith<CorrelationResult> get copyWith => _$CorrelationResultCopyWithImpl<CorrelationResult>(this as CorrelationResult, _$identity);

  /// Serializes this CorrelationResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CorrelationResult&&(identical(other.sourceLabel, sourceLabel) || other.sourceLabel == sourceLabel)&&(identical(other.targetLabel, targetLabel) || other.targetLabel == targetLabel)&&(identical(other.coefficient, coefficient) || other.coefficient == coefficient)&&(identical(other.strength, strength) || other.strength == strength)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.sampleSize, sampleSize) || other.sampleSize == sampleSize)&&(identical(other.insight, insight) || other.insight == insight)&&(identical(other.valueWithSource, valueWithSource) || other.valueWithSource == valueWithSource)&&(identical(other.valueWithoutSource, valueWithoutSource) || other.valueWithoutSource == valueWithoutSource)&&(identical(other.differencePercent, differencePercent) || other.differencePercent == differencePercent)&&(identical(other.statisticalSignificance, statisticalSignificance) || other.statisticalSignificance == statisticalSignificance)&&(identical(other.performanceMetrics, performanceMetrics) || other.performanceMetrics == performanceMetrics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sourceLabel,targetLabel,coefficient,strength,sourceId,targetId,sourceType,targetType,sampleSize,insight,valueWithSource,valueWithoutSource,differencePercent,statisticalSignificance,performanceMetrics);

@override
String toString() {
  return 'CorrelationResult(sourceLabel: $sourceLabel, targetLabel: $targetLabel, coefficient: $coefficient, strength: $strength, sourceId: $sourceId, targetId: $targetId, sourceType: $sourceType, targetType: $targetType, sampleSize: $sampleSize, insight: $insight, valueWithSource: $valueWithSource, valueWithoutSource: $valueWithoutSource, differencePercent: $differencePercent, statisticalSignificance: $statisticalSignificance, performanceMetrics: $performanceMetrics)';
}


}

/// @nodoc
abstract mixin class $CorrelationResultCopyWith<$Res>  {
  factory $CorrelationResultCopyWith(CorrelationResult value, $Res Function(CorrelationResult) _then) = _$CorrelationResultCopyWithImpl;
@useResult
$Res call({
 String sourceLabel, String targetLabel, double coefficient, CorrelationStrength strength, String? sourceId, String? targetId, String? sourceType, String? targetType, int? sampleSize, String? insight, double? valueWithSource, double? valueWithoutSource, double? differencePercent, StatisticalSignificance? statisticalSignificance, PerformanceMetrics? performanceMetrics
});


$StatisticalSignificanceCopyWith<$Res>? get statisticalSignificance;$PerformanceMetricsCopyWith<$Res>? get performanceMetrics;

}
/// @nodoc
class _$CorrelationResultCopyWithImpl<$Res>
    implements $CorrelationResultCopyWith<$Res> {
  _$CorrelationResultCopyWithImpl(this._self, this._then);

  final CorrelationResult _self;
  final $Res Function(CorrelationResult) _then;

/// Create a copy of CorrelationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sourceLabel = null,Object? targetLabel = null,Object? coefficient = null,Object? strength = null,Object? sourceId = freezed,Object? targetId = freezed,Object? sourceType = freezed,Object? targetType = freezed,Object? sampleSize = freezed,Object? insight = freezed,Object? valueWithSource = freezed,Object? valueWithoutSource = freezed,Object? differencePercent = freezed,Object? statisticalSignificance = freezed,Object? performanceMetrics = freezed,}) {
  return _then(_self.copyWith(
sourceLabel: null == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String,targetLabel: null == targetLabel ? _self.targetLabel : targetLabel // ignore: cast_nullable_to_non_nullable
as String,coefficient: null == coefficient ? _self.coefficient : coefficient // ignore: cast_nullable_to_non_nullable
as double,strength: null == strength ? _self.strength : strength // ignore: cast_nullable_to_non_nullable
as CorrelationStrength,sourceId: freezed == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String?,targetId: freezed == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String?,sourceType: freezed == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String?,targetType: freezed == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String?,sampleSize: freezed == sampleSize ? _self.sampleSize : sampleSize // ignore: cast_nullable_to_non_nullable
as int?,insight: freezed == insight ? _self.insight : insight // ignore: cast_nullable_to_non_nullable
as String?,valueWithSource: freezed == valueWithSource ? _self.valueWithSource : valueWithSource // ignore: cast_nullable_to_non_nullable
as double?,valueWithoutSource: freezed == valueWithoutSource ? _self.valueWithoutSource : valueWithoutSource // ignore: cast_nullable_to_non_nullable
as double?,differencePercent: freezed == differencePercent ? _self.differencePercent : differencePercent // ignore: cast_nullable_to_non_nullable
as double?,statisticalSignificance: freezed == statisticalSignificance ? _self.statisticalSignificance : statisticalSignificance // ignore: cast_nullable_to_non_nullable
as StatisticalSignificance?,performanceMetrics: freezed == performanceMetrics ? _self.performanceMetrics : performanceMetrics // ignore: cast_nullable_to_non_nullable
as PerformanceMetrics?,
  ));
}
/// Create a copy of CorrelationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatisticalSignificanceCopyWith<$Res>? get statisticalSignificance {
    if (_self.statisticalSignificance == null) {
    return null;
  }

  return $StatisticalSignificanceCopyWith<$Res>(_self.statisticalSignificance!, (value) {
    return _then(_self.copyWith(statisticalSignificance: value));
  });
}/// Create a copy of CorrelationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PerformanceMetricsCopyWith<$Res>? get performanceMetrics {
    if (_self.performanceMetrics == null) {
    return null;
  }

  return $PerformanceMetricsCopyWith<$Res>(_self.performanceMetrics!, (value) {
    return _then(_self.copyWith(performanceMetrics: value));
  });
}
}


/// Adds pattern-matching-related methods to [CorrelationResult].
extension CorrelationResultPatterns on CorrelationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CorrelationResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CorrelationResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CorrelationResult value)  $default,){
final _that = this;
switch (_that) {
case _CorrelationResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CorrelationResult value)?  $default,){
final _that = this;
switch (_that) {
case _CorrelationResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String sourceLabel,  String targetLabel,  double coefficient,  CorrelationStrength strength,  String? sourceId,  String? targetId,  String? sourceType,  String? targetType,  int? sampleSize,  String? insight,  double? valueWithSource,  double? valueWithoutSource,  double? differencePercent,  StatisticalSignificance? statisticalSignificance,  PerformanceMetrics? performanceMetrics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CorrelationResult() when $default != null:
return $default(_that.sourceLabel,_that.targetLabel,_that.coefficient,_that.strength,_that.sourceId,_that.targetId,_that.sourceType,_that.targetType,_that.sampleSize,_that.insight,_that.valueWithSource,_that.valueWithoutSource,_that.differencePercent,_that.statisticalSignificance,_that.performanceMetrics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String sourceLabel,  String targetLabel,  double coefficient,  CorrelationStrength strength,  String? sourceId,  String? targetId,  String? sourceType,  String? targetType,  int? sampleSize,  String? insight,  double? valueWithSource,  double? valueWithoutSource,  double? differencePercent,  StatisticalSignificance? statisticalSignificance,  PerformanceMetrics? performanceMetrics)  $default,) {final _that = this;
switch (_that) {
case _CorrelationResult():
return $default(_that.sourceLabel,_that.targetLabel,_that.coefficient,_that.strength,_that.sourceId,_that.targetId,_that.sourceType,_that.targetType,_that.sampleSize,_that.insight,_that.valueWithSource,_that.valueWithoutSource,_that.differencePercent,_that.statisticalSignificance,_that.performanceMetrics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String sourceLabel,  String targetLabel,  double coefficient,  CorrelationStrength strength,  String? sourceId,  String? targetId,  String? sourceType,  String? targetType,  int? sampleSize,  String? insight,  double? valueWithSource,  double? valueWithoutSource,  double? differencePercent,  StatisticalSignificance? statisticalSignificance,  PerformanceMetrics? performanceMetrics)?  $default,) {final _that = this;
switch (_that) {
case _CorrelationResult() when $default != null:
return $default(_that.sourceLabel,_that.targetLabel,_that.coefficient,_that.strength,_that.sourceId,_that.targetId,_that.sourceType,_that.targetType,_that.sampleSize,_that.insight,_that.valueWithSource,_that.valueWithoutSource,_that.differencePercent,_that.statisticalSignificance,_that.performanceMetrics);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CorrelationResult extends CorrelationResult {
  const _CorrelationResult({required this.sourceLabel, required this.targetLabel, required this.coefficient, required this.strength, this.sourceId, this.targetId, this.sourceType, this.targetType, this.sampleSize, this.insight, this.valueWithSource, this.valueWithoutSource, this.differencePercent, this.statisticalSignificance, this.performanceMetrics}): super._();
  factory _CorrelationResult.fromJson(Map<String, dynamic> json) => _$CorrelationResultFromJson(json);

@override final  String sourceLabel;
@override final  String targetLabel;
@override final  double coefficient;
@override final  CorrelationStrength strength;
@override final  String? sourceId;
@override final  String? targetId;
@override final  String? sourceType;
@override final  String? targetType;
@override final  int? sampleSize;
@override final  String? insight;
@override final  double? valueWithSource;
@override final  double? valueWithoutSource;
@override final  double? differencePercent;
@override final  StatisticalSignificance? statisticalSignificance;
@override final  PerformanceMetrics? performanceMetrics;

/// Create a copy of CorrelationResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CorrelationResultCopyWith<_CorrelationResult> get copyWith => __$CorrelationResultCopyWithImpl<_CorrelationResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CorrelationResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CorrelationResult&&(identical(other.sourceLabel, sourceLabel) || other.sourceLabel == sourceLabel)&&(identical(other.targetLabel, targetLabel) || other.targetLabel == targetLabel)&&(identical(other.coefficient, coefficient) || other.coefficient == coefficient)&&(identical(other.strength, strength) || other.strength == strength)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.targetId, targetId) || other.targetId == targetId)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.targetType, targetType) || other.targetType == targetType)&&(identical(other.sampleSize, sampleSize) || other.sampleSize == sampleSize)&&(identical(other.insight, insight) || other.insight == insight)&&(identical(other.valueWithSource, valueWithSource) || other.valueWithSource == valueWithSource)&&(identical(other.valueWithoutSource, valueWithoutSource) || other.valueWithoutSource == valueWithoutSource)&&(identical(other.differencePercent, differencePercent) || other.differencePercent == differencePercent)&&(identical(other.statisticalSignificance, statisticalSignificance) || other.statisticalSignificance == statisticalSignificance)&&(identical(other.performanceMetrics, performanceMetrics) || other.performanceMetrics == performanceMetrics));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sourceLabel,targetLabel,coefficient,strength,sourceId,targetId,sourceType,targetType,sampleSize,insight,valueWithSource,valueWithoutSource,differencePercent,statisticalSignificance,performanceMetrics);

@override
String toString() {
  return 'CorrelationResult(sourceLabel: $sourceLabel, targetLabel: $targetLabel, coefficient: $coefficient, strength: $strength, sourceId: $sourceId, targetId: $targetId, sourceType: $sourceType, targetType: $targetType, sampleSize: $sampleSize, insight: $insight, valueWithSource: $valueWithSource, valueWithoutSource: $valueWithoutSource, differencePercent: $differencePercent, statisticalSignificance: $statisticalSignificance, performanceMetrics: $performanceMetrics)';
}


}

/// @nodoc
abstract mixin class _$CorrelationResultCopyWith<$Res> implements $CorrelationResultCopyWith<$Res> {
  factory _$CorrelationResultCopyWith(_CorrelationResult value, $Res Function(_CorrelationResult) _then) = __$CorrelationResultCopyWithImpl;
@override @useResult
$Res call({
 String sourceLabel, String targetLabel, double coefficient, CorrelationStrength strength, String? sourceId, String? targetId, String? sourceType, String? targetType, int? sampleSize, String? insight, double? valueWithSource, double? valueWithoutSource, double? differencePercent, StatisticalSignificance? statisticalSignificance, PerformanceMetrics? performanceMetrics
});


@override $StatisticalSignificanceCopyWith<$Res>? get statisticalSignificance;@override $PerformanceMetricsCopyWith<$Res>? get performanceMetrics;

}
/// @nodoc
class __$CorrelationResultCopyWithImpl<$Res>
    implements _$CorrelationResultCopyWith<$Res> {
  __$CorrelationResultCopyWithImpl(this._self, this._then);

  final _CorrelationResult _self;
  final $Res Function(_CorrelationResult) _then;

/// Create a copy of CorrelationResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sourceLabel = null,Object? targetLabel = null,Object? coefficient = null,Object? strength = null,Object? sourceId = freezed,Object? targetId = freezed,Object? sourceType = freezed,Object? targetType = freezed,Object? sampleSize = freezed,Object? insight = freezed,Object? valueWithSource = freezed,Object? valueWithoutSource = freezed,Object? differencePercent = freezed,Object? statisticalSignificance = freezed,Object? performanceMetrics = freezed,}) {
  return _then(_CorrelationResult(
sourceLabel: null == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String,targetLabel: null == targetLabel ? _self.targetLabel : targetLabel // ignore: cast_nullable_to_non_nullable
as String,coefficient: null == coefficient ? _self.coefficient : coefficient // ignore: cast_nullable_to_non_nullable
as double,strength: null == strength ? _self.strength : strength // ignore: cast_nullable_to_non_nullable
as CorrelationStrength,sourceId: freezed == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String?,targetId: freezed == targetId ? _self.targetId : targetId // ignore: cast_nullable_to_non_nullable
as String?,sourceType: freezed == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String?,targetType: freezed == targetType ? _self.targetType : targetType // ignore: cast_nullable_to_non_nullable
as String?,sampleSize: freezed == sampleSize ? _self.sampleSize : sampleSize // ignore: cast_nullable_to_non_nullable
as int?,insight: freezed == insight ? _self.insight : insight // ignore: cast_nullable_to_non_nullable
as String?,valueWithSource: freezed == valueWithSource ? _self.valueWithSource : valueWithSource // ignore: cast_nullable_to_non_nullable
as double?,valueWithoutSource: freezed == valueWithoutSource ? _self.valueWithoutSource : valueWithoutSource // ignore: cast_nullable_to_non_nullable
as double?,differencePercent: freezed == differencePercent ? _self.differencePercent : differencePercent // ignore: cast_nullable_to_non_nullable
as double?,statisticalSignificance: freezed == statisticalSignificance ? _self.statisticalSignificance : statisticalSignificance // ignore: cast_nullable_to_non_nullable
as StatisticalSignificance?,performanceMetrics: freezed == performanceMetrics ? _self.performanceMetrics : performanceMetrics // ignore: cast_nullable_to_non_nullable
as PerformanceMetrics?,
  ));
}

/// Create a copy of CorrelationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatisticalSignificanceCopyWith<$Res>? get statisticalSignificance {
    if (_self.statisticalSignificance == null) {
    return null;
  }

  return $StatisticalSignificanceCopyWith<$Res>(_self.statisticalSignificance!, (value) {
    return _then(_self.copyWith(statisticalSignificance: value));
  });
}/// Create a copy of CorrelationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PerformanceMetricsCopyWith<$Res>? get performanceMetrics {
    if (_self.performanceMetrics == null) {
    return null;
  }

  return $PerformanceMetricsCopyWith<$Res>(_self.performanceMetrics!, (value) {
    return _then(_self.copyWith(performanceMetrics: value));
  });
}
}


/// @nodoc
mixin _$StatisticalSignificance {

 double get pValue;// Probability correlation is by chance
 double get tStatistic;// t-test statistic
 int get degreesOfFreedom;// n - 2
 double get standardError;// Standard error of coefficient
 bool get isSignificant;// p < 0.05
 List<double> get confidenceInterval;
/// Create a copy of StatisticalSignificance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatisticalSignificanceCopyWith<StatisticalSignificance> get copyWith => _$StatisticalSignificanceCopyWithImpl<StatisticalSignificance>(this as StatisticalSignificance, _$identity);

  /// Serializes this StatisticalSignificance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatisticalSignificance&&(identical(other.pValue, pValue) || other.pValue == pValue)&&(identical(other.tStatistic, tStatistic) || other.tStatistic == tStatistic)&&(identical(other.degreesOfFreedom, degreesOfFreedom) || other.degreesOfFreedom == degreesOfFreedom)&&(identical(other.standardError, standardError) || other.standardError == standardError)&&(identical(other.isSignificant, isSignificant) || other.isSignificant == isSignificant)&&const DeepCollectionEquality().equals(other.confidenceInterval, confidenceInterval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pValue,tStatistic,degreesOfFreedom,standardError,isSignificant,const DeepCollectionEquality().hash(confidenceInterval));

@override
String toString() {
  return 'StatisticalSignificance(pValue: $pValue, tStatistic: $tStatistic, degreesOfFreedom: $degreesOfFreedom, standardError: $standardError, isSignificant: $isSignificant, confidenceInterval: $confidenceInterval)';
}


}

/// @nodoc
abstract mixin class $StatisticalSignificanceCopyWith<$Res>  {
  factory $StatisticalSignificanceCopyWith(StatisticalSignificance value, $Res Function(StatisticalSignificance) _then) = _$StatisticalSignificanceCopyWithImpl;
@useResult
$Res call({
 double pValue, double tStatistic, int degreesOfFreedom, double standardError, bool isSignificant, List<double> confidenceInterval
});




}
/// @nodoc
class _$StatisticalSignificanceCopyWithImpl<$Res>
    implements $StatisticalSignificanceCopyWith<$Res> {
  _$StatisticalSignificanceCopyWithImpl(this._self, this._then);

  final StatisticalSignificance _self;
  final $Res Function(StatisticalSignificance) _then;

/// Create a copy of StatisticalSignificance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pValue = null,Object? tStatistic = null,Object? degreesOfFreedom = null,Object? standardError = null,Object? isSignificant = null,Object? confidenceInterval = null,}) {
  return _then(_self.copyWith(
pValue: null == pValue ? _self.pValue : pValue // ignore: cast_nullable_to_non_nullable
as double,tStatistic: null == tStatistic ? _self.tStatistic : tStatistic // ignore: cast_nullable_to_non_nullable
as double,degreesOfFreedom: null == degreesOfFreedom ? _self.degreesOfFreedom : degreesOfFreedom // ignore: cast_nullable_to_non_nullable
as int,standardError: null == standardError ? _self.standardError : standardError // ignore: cast_nullable_to_non_nullable
as double,isSignificant: null == isSignificant ? _self.isSignificant : isSignificant // ignore: cast_nullable_to_non_nullable
as bool,confidenceInterval: null == confidenceInterval ? _self.confidenceInterval : confidenceInterval // ignore: cast_nullable_to_non_nullable
as List<double>,
  ));
}

}


/// Adds pattern-matching-related methods to [StatisticalSignificance].
extension StatisticalSignificancePatterns on StatisticalSignificance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatisticalSignificance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatisticalSignificance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatisticalSignificance value)  $default,){
final _that = this;
switch (_that) {
case _StatisticalSignificance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatisticalSignificance value)?  $default,){
final _that = this;
switch (_that) {
case _StatisticalSignificance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double pValue,  double tStatistic,  int degreesOfFreedom,  double standardError,  bool isSignificant,  List<double> confidenceInterval)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatisticalSignificance() when $default != null:
return $default(_that.pValue,_that.tStatistic,_that.degreesOfFreedom,_that.standardError,_that.isSignificant,_that.confidenceInterval);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double pValue,  double tStatistic,  int degreesOfFreedom,  double standardError,  bool isSignificant,  List<double> confidenceInterval)  $default,) {final _that = this;
switch (_that) {
case _StatisticalSignificance():
return $default(_that.pValue,_that.tStatistic,_that.degreesOfFreedom,_that.standardError,_that.isSignificant,_that.confidenceInterval);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double pValue,  double tStatistic,  int degreesOfFreedom,  double standardError,  bool isSignificant,  List<double> confidenceInterval)?  $default,) {final _that = this;
switch (_that) {
case _StatisticalSignificance() when $default != null:
return $default(_that.pValue,_that.tStatistic,_that.degreesOfFreedom,_that.standardError,_that.isSignificant,_that.confidenceInterval);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatisticalSignificance implements StatisticalSignificance {
  const _StatisticalSignificance({required this.pValue, required this.tStatistic, required this.degreesOfFreedom, required this.standardError, required this.isSignificant, final  List<double> confidenceInterval = const [0, 0]}): _confidenceInterval = confidenceInterval;
  factory _StatisticalSignificance.fromJson(Map<String, dynamic> json) => _$StatisticalSignificanceFromJson(json);

@override final  double pValue;
// Probability correlation is by chance
@override final  double tStatistic;
// t-test statistic
@override final  int degreesOfFreedom;
// n - 2
@override final  double standardError;
// Standard error of coefficient
@override final  bool isSignificant;
// p < 0.05
 final  List<double> _confidenceInterval;
// p < 0.05
@override@JsonKey() List<double> get confidenceInterval {
  if (_confidenceInterval is EqualUnmodifiableListView) return _confidenceInterval;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_confidenceInterval);
}


/// Create a copy of StatisticalSignificance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatisticalSignificanceCopyWith<_StatisticalSignificance> get copyWith => __$StatisticalSignificanceCopyWithImpl<_StatisticalSignificance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatisticalSignificanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatisticalSignificance&&(identical(other.pValue, pValue) || other.pValue == pValue)&&(identical(other.tStatistic, tStatistic) || other.tStatistic == tStatistic)&&(identical(other.degreesOfFreedom, degreesOfFreedom) || other.degreesOfFreedom == degreesOfFreedom)&&(identical(other.standardError, standardError) || other.standardError == standardError)&&(identical(other.isSignificant, isSignificant) || other.isSignificant == isSignificant)&&const DeepCollectionEquality().equals(other._confidenceInterval, _confidenceInterval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pValue,tStatistic,degreesOfFreedom,standardError,isSignificant,const DeepCollectionEquality().hash(_confidenceInterval));

@override
String toString() {
  return 'StatisticalSignificance(pValue: $pValue, tStatistic: $tStatistic, degreesOfFreedom: $degreesOfFreedom, standardError: $standardError, isSignificant: $isSignificant, confidenceInterval: $confidenceInterval)';
}


}

/// @nodoc
abstract mixin class _$StatisticalSignificanceCopyWith<$Res> implements $StatisticalSignificanceCopyWith<$Res> {
  factory _$StatisticalSignificanceCopyWith(_StatisticalSignificance value, $Res Function(_StatisticalSignificance) _then) = __$StatisticalSignificanceCopyWithImpl;
@override @useResult
$Res call({
 double pValue, double tStatistic, int degreesOfFreedom, double standardError, bool isSignificant, List<double> confidenceInterval
});




}
/// @nodoc
class __$StatisticalSignificanceCopyWithImpl<$Res>
    implements _$StatisticalSignificanceCopyWith<$Res> {
  __$StatisticalSignificanceCopyWithImpl(this._self, this._then);

  final _StatisticalSignificance _self;
  final $Res Function(_StatisticalSignificance) _then;

/// Create a copy of StatisticalSignificance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pValue = null,Object? tStatistic = null,Object? degreesOfFreedom = null,Object? standardError = null,Object? isSignificant = null,Object? confidenceInterval = null,}) {
  return _then(_StatisticalSignificance(
pValue: null == pValue ? _self.pValue : pValue // ignore: cast_nullable_to_non_nullable
as double,tStatistic: null == tStatistic ? _self.tStatistic : tStatistic // ignore: cast_nullable_to_non_nullable
as double,degreesOfFreedom: null == degreesOfFreedom ? _self.degreesOfFreedom : degreesOfFreedom // ignore: cast_nullable_to_non_nullable
as int,standardError: null == standardError ? _self.standardError : standardError // ignore: cast_nullable_to_non_nullable
as double,isSignificant: null == isSignificant ? _self.isSignificant : isSignificant // ignore: cast_nullable_to_non_nullable
as bool,confidenceInterval: null == confidenceInterval ? _self._confidenceInterval : confidenceInterval // ignore: cast_nullable_to_non_nullable
as List<double>,
  ));
}


}


/// @nodoc
mixin _$PerformanceMetrics {

 int get calculationTimeMs; int get dataPoints; String get algorithm;// 'ml_linalg_simd' or 'manual'
 int? get memoryUsedBytes;
/// Create a copy of PerformanceMetrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerformanceMetricsCopyWith<PerformanceMetrics> get copyWith => _$PerformanceMetricsCopyWithImpl<PerformanceMetrics>(this as PerformanceMetrics, _$identity);

  /// Serializes this PerformanceMetrics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PerformanceMetrics&&(identical(other.calculationTimeMs, calculationTimeMs) || other.calculationTimeMs == calculationTimeMs)&&(identical(other.dataPoints, dataPoints) || other.dataPoints == dataPoints)&&(identical(other.algorithm, algorithm) || other.algorithm == algorithm)&&(identical(other.memoryUsedBytes, memoryUsedBytes) || other.memoryUsedBytes == memoryUsedBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,calculationTimeMs,dataPoints,algorithm,memoryUsedBytes);

@override
String toString() {
  return 'PerformanceMetrics(calculationTimeMs: $calculationTimeMs, dataPoints: $dataPoints, algorithm: $algorithm, memoryUsedBytes: $memoryUsedBytes)';
}


}

/// @nodoc
abstract mixin class $PerformanceMetricsCopyWith<$Res>  {
  factory $PerformanceMetricsCopyWith(PerformanceMetrics value, $Res Function(PerformanceMetrics) _then) = _$PerformanceMetricsCopyWithImpl;
@useResult
$Res call({
 int calculationTimeMs, int dataPoints, String algorithm, int? memoryUsedBytes
});




}
/// @nodoc
class _$PerformanceMetricsCopyWithImpl<$Res>
    implements $PerformanceMetricsCopyWith<$Res> {
  _$PerformanceMetricsCopyWithImpl(this._self, this._then);

  final PerformanceMetrics _self;
  final $Res Function(PerformanceMetrics) _then;

/// Create a copy of PerformanceMetrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? calculationTimeMs = null,Object? dataPoints = null,Object? algorithm = null,Object? memoryUsedBytes = freezed,}) {
  return _then(_self.copyWith(
calculationTimeMs: null == calculationTimeMs ? _self.calculationTimeMs : calculationTimeMs // ignore: cast_nullable_to_non_nullable
as int,dataPoints: null == dataPoints ? _self.dataPoints : dataPoints // ignore: cast_nullable_to_non_nullable
as int,algorithm: null == algorithm ? _self.algorithm : algorithm // ignore: cast_nullable_to_non_nullable
as String,memoryUsedBytes: freezed == memoryUsedBytes ? _self.memoryUsedBytes : memoryUsedBytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PerformanceMetrics].
extension PerformanceMetricsPatterns on PerformanceMetrics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PerformanceMetrics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PerformanceMetrics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PerformanceMetrics value)  $default,){
final _that = this;
switch (_that) {
case _PerformanceMetrics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PerformanceMetrics value)?  $default,){
final _that = this;
switch (_that) {
case _PerformanceMetrics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int calculationTimeMs,  int dataPoints,  String algorithm,  int? memoryUsedBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PerformanceMetrics() when $default != null:
return $default(_that.calculationTimeMs,_that.dataPoints,_that.algorithm,_that.memoryUsedBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int calculationTimeMs,  int dataPoints,  String algorithm,  int? memoryUsedBytes)  $default,) {final _that = this;
switch (_that) {
case _PerformanceMetrics():
return $default(_that.calculationTimeMs,_that.dataPoints,_that.algorithm,_that.memoryUsedBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int calculationTimeMs,  int dataPoints,  String algorithm,  int? memoryUsedBytes)?  $default,) {final _that = this;
switch (_that) {
case _PerformanceMetrics() when $default != null:
return $default(_that.calculationTimeMs,_that.dataPoints,_that.algorithm,_that.memoryUsedBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PerformanceMetrics implements PerformanceMetrics {
  const _PerformanceMetrics({required this.calculationTimeMs, required this.dataPoints, required this.algorithm, this.memoryUsedBytes});
  factory _PerformanceMetrics.fromJson(Map<String, dynamic> json) => _$PerformanceMetricsFromJson(json);

@override final  int calculationTimeMs;
@override final  int dataPoints;
@override final  String algorithm;
// 'ml_linalg_simd' or 'manual'
@override final  int? memoryUsedBytes;

/// Create a copy of PerformanceMetrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerformanceMetricsCopyWith<_PerformanceMetrics> get copyWith => __$PerformanceMetricsCopyWithImpl<_PerformanceMetrics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PerformanceMetricsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PerformanceMetrics&&(identical(other.calculationTimeMs, calculationTimeMs) || other.calculationTimeMs == calculationTimeMs)&&(identical(other.dataPoints, dataPoints) || other.dataPoints == dataPoints)&&(identical(other.algorithm, algorithm) || other.algorithm == algorithm)&&(identical(other.memoryUsedBytes, memoryUsedBytes) || other.memoryUsedBytes == memoryUsedBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,calculationTimeMs,dataPoints,algorithm,memoryUsedBytes);

@override
String toString() {
  return 'PerformanceMetrics(calculationTimeMs: $calculationTimeMs, dataPoints: $dataPoints, algorithm: $algorithm, memoryUsedBytes: $memoryUsedBytes)';
}


}

/// @nodoc
abstract mixin class _$PerformanceMetricsCopyWith<$Res> implements $PerformanceMetricsCopyWith<$Res> {
  factory _$PerformanceMetricsCopyWith(_PerformanceMetrics value, $Res Function(_PerformanceMetrics) _then) = __$PerformanceMetricsCopyWithImpl;
@override @useResult
$Res call({
 int calculationTimeMs, int dataPoints, String algorithm, int? memoryUsedBytes
});




}
/// @nodoc
class __$PerformanceMetricsCopyWithImpl<$Res>
    implements _$PerformanceMetricsCopyWith<$Res> {
  __$PerformanceMetricsCopyWithImpl(this._self, this._then);

  final _PerformanceMetrics _self;
  final $Res Function(_PerformanceMetrics) _then;

/// Create a copy of PerformanceMetrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? calculationTimeMs = null,Object? dataPoints = null,Object? algorithm = null,Object? memoryUsedBytes = freezed,}) {
  return _then(_PerformanceMetrics(
calculationTimeMs: null == calculationTimeMs ? _self.calculationTimeMs : calculationTimeMs // ignore: cast_nullable_to_non_nullable
as int,dataPoints: null == dataPoints ? _self.dataPoints : dataPoints // ignore: cast_nullable_to_non_nullable
as int,algorithm: null == algorithm ? _self.algorithm : algorithm // ignore: cast_nullable_to_non_nullable
as String,memoryUsedBytes: freezed == memoryUsedBytes ? _self.memoryUsedBytes : memoryUsedBytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
