// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trend_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrendData {

 List<TrendPoint> get points; TrendGranularity get granularity; double? get average; double? get min; double? get max; TrendDirection? get overallTrend;
/// Create a copy of TrendData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrendDataCopyWith<TrendData> get copyWith => _$TrendDataCopyWithImpl<TrendData>(this as TrendData, _$identity);

  /// Serializes this TrendData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrendData&&const DeepCollectionEquality().equals(other.points, points)&&(identical(other.granularity, granularity) || other.granularity == granularity)&&(identical(other.average, average) || other.average == average)&&(identical(other.min, min) || other.min == min)&&(identical(other.max, max) || other.max == max)&&(identical(other.overallTrend, overallTrend) || other.overallTrend == overallTrend));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(points),granularity,average,min,max,overallTrend);

@override
String toString() {
  return 'TrendData(points: $points, granularity: $granularity, average: $average, min: $min, max: $max, overallTrend: $overallTrend)';
}


}

/// @nodoc
abstract mixin class $TrendDataCopyWith<$Res>  {
  factory $TrendDataCopyWith(TrendData value, $Res Function(TrendData) _then) = _$TrendDataCopyWithImpl;
@useResult
$Res call({
 List<TrendPoint> points, TrendGranularity granularity, double? average, double? min, double? max, TrendDirection? overallTrend
});




}
/// @nodoc
class _$TrendDataCopyWithImpl<$Res>
    implements $TrendDataCopyWith<$Res> {
  _$TrendDataCopyWithImpl(this._self, this._then);

  final TrendData _self;
  final $Res Function(TrendData) _then;

/// Create a copy of TrendData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? points = null,Object? granularity = null,Object? average = freezed,Object? min = freezed,Object? max = freezed,Object? overallTrend = freezed,}) {
  return _then(_self.copyWith(
points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as List<TrendPoint>,granularity: null == granularity ? _self.granularity : granularity // ignore: cast_nullable_to_non_nullable
as TrendGranularity,average: freezed == average ? _self.average : average // ignore: cast_nullable_to_non_nullable
as double?,min: freezed == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as double?,max: freezed == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as double?,overallTrend: freezed == overallTrend ? _self.overallTrend : overallTrend // ignore: cast_nullable_to_non_nullable
as TrendDirection?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrendData].
extension TrendDataPatterns on TrendData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrendData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrendData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrendData value)  $default,){
final _that = this;
switch (_that) {
case _TrendData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrendData value)?  $default,){
final _that = this;
switch (_that) {
case _TrendData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TrendPoint> points,  TrendGranularity granularity,  double? average,  double? min,  double? max,  TrendDirection? overallTrend)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrendData() when $default != null:
return $default(_that.points,_that.granularity,_that.average,_that.min,_that.max,_that.overallTrend);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TrendPoint> points,  TrendGranularity granularity,  double? average,  double? min,  double? max,  TrendDirection? overallTrend)  $default,) {final _that = this;
switch (_that) {
case _TrendData():
return $default(_that.points,_that.granularity,_that.average,_that.min,_that.max,_that.overallTrend);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TrendPoint> points,  TrendGranularity granularity,  double? average,  double? min,  double? max,  TrendDirection? overallTrend)?  $default,) {final _that = this;
switch (_that) {
case _TrendData() when $default != null:
return $default(_that.points,_that.granularity,_that.average,_that.min,_that.max,_that.overallTrend);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrendData implements TrendData {
  const _TrendData({required final  List<TrendPoint> points, required this.granularity, this.average, this.min, this.max, this.overallTrend}): _points = points;
  factory _TrendData.fromJson(Map<String, dynamic> json) => _$TrendDataFromJson(json);

 final  List<TrendPoint> _points;
@override List<TrendPoint> get points {
  if (_points is EqualUnmodifiableListView) return _points;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_points);
}

@override final  TrendGranularity granularity;
@override final  double? average;
@override final  double? min;
@override final  double? max;
@override final  TrendDirection? overallTrend;

/// Create a copy of TrendData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrendDataCopyWith<_TrendData> get copyWith => __$TrendDataCopyWithImpl<_TrendData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrendDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrendData&&const DeepCollectionEquality().equals(other._points, _points)&&(identical(other.granularity, granularity) || other.granularity == granularity)&&(identical(other.average, average) || other.average == average)&&(identical(other.min, min) || other.min == min)&&(identical(other.max, max) || other.max == max)&&(identical(other.overallTrend, overallTrend) || other.overallTrend == overallTrend));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_points),granularity,average,min,max,overallTrend);

@override
String toString() {
  return 'TrendData(points: $points, granularity: $granularity, average: $average, min: $min, max: $max, overallTrend: $overallTrend)';
}


}

/// @nodoc
abstract mixin class _$TrendDataCopyWith<$Res> implements $TrendDataCopyWith<$Res> {
  factory _$TrendDataCopyWith(_TrendData value, $Res Function(_TrendData) _then) = __$TrendDataCopyWithImpl;
@override @useResult
$Res call({
 List<TrendPoint> points, TrendGranularity granularity, double? average, double? min, double? max, TrendDirection? overallTrend
});




}
/// @nodoc
class __$TrendDataCopyWithImpl<$Res>
    implements _$TrendDataCopyWith<$Res> {
  __$TrendDataCopyWithImpl(this._self, this._then);

  final _TrendData _self;
  final $Res Function(_TrendData) _then;

/// Create a copy of TrendData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? points = null,Object? granularity = null,Object? average = freezed,Object? min = freezed,Object? max = freezed,Object? overallTrend = freezed,}) {
  return _then(_TrendData(
points: null == points ? _self._points : points // ignore: cast_nullable_to_non_nullable
as List<TrendPoint>,granularity: null == granularity ? _self.granularity : granularity // ignore: cast_nullable_to_non_nullable
as TrendGranularity,average: freezed == average ? _self.average : average // ignore: cast_nullable_to_non_nullable
as double?,min: freezed == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as double?,max: freezed == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as double?,overallTrend: freezed == overallTrend ? _self.overallTrend : overallTrend // ignore: cast_nullable_to_non_nullable
as TrendDirection?,
  ));
}


}


/// @nodoc
mixin _$TrendPoint {

 DateTime get date; double get value; int? get sampleCount;
/// Create a copy of TrendPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrendPointCopyWith<TrendPoint> get copyWith => _$TrendPointCopyWithImpl<TrendPoint>(this as TrendPoint, _$identity);

  /// Serializes this TrendPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrendPoint&&(identical(other.date, date) || other.date == date)&&(identical(other.value, value) || other.value == value)&&(identical(other.sampleCount, sampleCount) || other.sampleCount == sampleCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,value,sampleCount);

@override
String toString() {
  return 'TrendPoint(date: $date, value: $value, sampleCount: $sampleCount)';
}


}

/// @nodoc
abstract mixin class $TrendPointCopyWith<$Res>  {
  factory $TrendPointCopyWith(TrendPoint value, $Res Function(TrendPoint) _then) = _$TrendPointCopyWithImpl;
@useResult
$Res call({
 DateTime date, double value, int? sampleCount
});




}
/// @nodoc
class _$TrendPointCopyWithImpl<$Res>
    implements $TrendPointCopyWith<$Res> {
  _$TrendPointCopyWithImpl(this._self, this._then);

  final TrendPoint _self;
  final $Res Function(TrendPoint) _then;

/// Create a copy of TrendPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? value = null,Object? sampleCount = freezed,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,sampleCount: freezed == sampleCount ? _self.sampleCount : sampleCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrendPoint].
extension TrendPointPatterns on TrendPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrendPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrendPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrendPoint value)  $default,){
final _that = this;
switch (_that) {
case _TrendPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrendPoint value)?  $default,){
final _that = this;
switch (_that) {
case _TrendPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  double value,  int? sampleCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrendPoint() when $default != null:
return $default(_that.date,_that.value,_that.sampleCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  double value,  int? sampleCount)  $default,) {final _that = this;
switch (_that) {
case _TrendPoint():
return $default(_that.date,_that.value,_that.sampleCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  double value,  int? sampleCount)?  $default,) {final _that = this;
switch (_that) {
case _TrendPoint() when $default != null:
return $default(_that.date,_that.value,_that.sampleCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrendPoint implements TrendPoint {
  const _TrendPoint({required this.date, required this.value, this.sampleCount});
  factory _TrendPoint.fromJson(Map<String, dynamic> json) => _$TrendPointFromJson(json);

@override final  DateTime date;
@override final  double value;
@override final  int? sampleCount;

/// Create a copy of TrendPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrendPointCopyWith<_TrendPoint> get copyWith => __$TrendPointCopyWithImpl<_TrendPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrendPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrendPoint&&(identical(other.date, date) || other.date == date)&&(identical(other.value, value) || other.value == value)&&(identical(other.sampleCount, sampleCount) || other.sampleCount == sampleCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,value,sampleCount);

@override
String toString() {
  return 'TrendPoint(date: $date, value: $value, sampleCount: $sampleCount)';
}


}

/// @nodoc
abstract mixin class _$TrendPointCopyWith<$Res> implements $TrendPointCopyWith<$Res> {
  factory _$TrendPointCopyWith(_TrendPoint value, $Res Function(_TrendPoint) _then) = __$TrendPointCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, double value, int? sampleCount
});




}
/// @nodoc
class __$TrendPointCopyWithImpl<$Res>
    implements _$TrendPointCopyWith<$Res> {
  __$TrendPointCopyWithImpl(this._self, this._then);

  final _TrendPoint _self;
  final $Res Function(_TrendPoint) _then;

/// Create a copy of TrendPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? value = null,Object? sampleCount = freezed,}) {
  return _then(_TrendPoint(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as double,sampleCount: freezed == sampleCount ? _self.sampleCount : sampleCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
