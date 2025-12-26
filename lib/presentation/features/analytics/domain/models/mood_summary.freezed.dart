// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mood_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MoodSummary {

 double get average; int get totalEntries; int get min; int get max; Map<int, int> get distribution;
/// Create a copy of MoodSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoodSummaryCopyWith<MoodSummary> get copyWith => _$MoodSummaryCopyWithImpl<MoodSummary>(this as MoodSummary, _$identity);

  /// Serializes this MoodSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoodSummary&&(identical(other.average, average) || other.average == average)&&(identical(other.totalEntries, totalEntries) || other.totalEntries == totalEntries)&&(identical(other.min, min) || other.min == min)&&(identical(other.max, max) || other.max == max)&&const DeepCollectionEquality().equals(other.distribution, distribution));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,average,totalEntries,min,max,const DeepCollectionEquality().hash(distribution));

@override
String toString() {
  return 'MoodSummary(average: $average, totalEntries: $totalEntries, min: $min, max: $max, distribution: $distribution)';
}


}

/// @nodoc
abstract mixin class $MoodSummaryCopyWith<$Res>  {
  factory $MoodSummaryCopyWith(MoodSummary value, $Res Function(MoodSummary) _then) = _$MoodSummaryCopyWithImpl;
@useResult
$Res call({
 double average, int totalEntries, int min, int max, Map<int, int> distribution
});




}
/// @nodoc
class _$MoodSummaryCopyWithImpl<$Res>
    implements $MoodSummaryCopyWith<$Res> {
  _$MoodSummaryCopyWithImpl(this._self, this._then);

  final MoodSummary _self;
  final $Res Function(MoodSummary) _then;

/// Create a copy of MoodSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? average = null,Object? totalEntries = null,Object? min = null,Object? max = null,Object? distribution = null,}) {
  return _then(_self.copyWith(
average: null == average ? _self.average : average // ignore: cast_nullable_to_non_nullable
as double,totalEntries: null == totalEntries ? _self.totalEntries : totalEntries // ignore: cast_nullable_to_non_nullable
as int,min: null == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as int,max: null == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as int,distribution: null == distribution ? _self.distribution : distribution // ignore: cast_nullable_to_non_nullable
as Map<int, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [MoodSummary].
extension MoodSummaryPatterns on MoodSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MoodSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MoodSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MoodSummary value)  $default,){
final _that = this;
switch (_that) {
case _MoodSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MoodSummary value)?  $default,){
final _that = this;
switch (_that) {
case _MoodSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double average,  int totalEntries,  int min,  int max,  Map<int, int> distribution)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MoodSummary() when $default != null:
return $default(_that.average,_that.totalEntries,_that.min,_that.max,_that.distribution);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double average,  int totalEntries,  int min,  int max,  Map<int, int> distribution)  $default,) {final _that = this;
switch (_that) {
case _MoodSummary():
return $default(_that.average,_that.totalEntries,_that.min,_that.max,_that.distribution);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double average,  int totalEntries,  int min,  int max,  Map<int, int> distribution)?  $default,) {final _that = this;
switch (_that) {
case _MoodSummary() when $default != null:
return $default(_that.average,_that.totalEntries,_that.min,_that.max,_that.distribution);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MoodSummary implements MoodSummary {
  const _MoodSummary({required this.average, required this.totalEntries, required this.min, required this.max, required final  Map<int, int> distribution}): _distribution = distribution;
  factory _MoodSummary.fromJson(Map<String, dynamic> json) => _$MoodSummaryFromJson(json);

@override final  double average;
@override final  int totalEntries;
@override final  int min;
@override final  int max;
 final  Map<int, int> _distribution;
@override Map<int, int> get distribution {
  if (_distribution is EqualUnmodifiableMapView) return _distribution;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_distribution);
}


/// Create a copy of MoodSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MoodSummaryCopyWith<_MoodSummary> get copyWith => __$MoodSummaryCopyWithImpl<_MoodSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MoodSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MoodSummary&&(identical(other.average, average) || other.average == average)&&(identical(other.totalEntries, totalEntries) || other.totalEntries == totalEntries)&&(identical(other.min, min) || other.min == min)&&(identical(other.max, max) || other.max == max)&&const DeepCollectionEquality().equals(other._distribution, _distribution));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,average,totalEntries,min,max,const DeepCollectionEquality().hash(_distribution));

@override
String toString() {
  return 'MoodSummary(average: $average, totalEntries: $totalEntries, min: $min, max: $max, distribution: $distribution)';
}


}

/// @nodoc
abstract mixin class _$MoodSummaryCopyWith<$Res> implements $MoodSummaryCopyWith<$Res> {
  factory _$MoodSummaryCopyWith(_MoodSummary value, $Res Function(_MoodSummary) _then) = __$MoodSummaryCopyWithImpl;
@override @useResult
$Res call({
 double average, int totalEntries, int min, int max, Map<int, int> distribution
});




}
/// @nodoc
class __$MoodSummaryCopyWithImpl<$Res>
    implements _$MoodSummaryCopyWith<$Res> {
  __$MoodSummaryCopyWithImpl(this._self, this._then);

  final _MoodSummary _self;
  final $Res Function(_MoodSummary) _then;

/// Create a copy of MoodSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? average = null,Object? totalEntries = null,Object? min = null,Object? max = null,Object? distribution = null,}) {
  return _then(_MoodSummary(
average: null == average ? _self.average : average // ignore: cast_nullable_to_non_nullable
as double,totalEntries: null == totalEntries ? _self.totalEntries : totalEntries // ignore: cast_nullable_to_non_nullable
as int,min: null == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as int,max: null == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as int,distribution: null == distribution ? _self._distribution : distribution // ignore: cast_nullable_to_non_nullable
as Map<int, int>,
  ));
}


}

// dart format on
