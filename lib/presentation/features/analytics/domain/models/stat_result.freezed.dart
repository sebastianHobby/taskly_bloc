// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stat_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StatResult {

 String get label; num get value; String? get formattedValue; String? get description; StatSeverity? get severity; TrendDirection? get trend;
/// Create a copy of StatResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatResultCopyWith<StatResult> get copyWith => _$StatResultCopyWithImpl<StatResult>(this as StatResult, _$identity);

  /// Serializes this StatResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatResult&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value)&&(identical(other.formattedValue, formattedValue) || other.formattedValue == formattedValue)&&(identical(other.description, description) || other.description == description)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.trend, trend) || other.trend == trend));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,value,formattedValue,description,severity,trend);

@override
String toString() {
  return 'StatResult(label: $label, value: $value, formattedValue: $formattedValue, description: $description, severity: $severity, trend: $trend)';
}


}

/// @nodoc
abstract mixin class $StatResultCopyWith<$Res>  {
  factory $StatResultCopyWith(StatResult value, $Res Function(StatResult) _then) = _$StatResultCopyWithImpl;
@useResult
$Res call({
 String label, num value, String? formattedValue, String? description, StatSeverity? severity, TrendDirection? trend
});




}
/// @nodoc
class _$StatResultCopyWithImpl<$Res>
    implements $StatResultCopyWith<$Res> {
  _$StatResultCopyWithImpl(this._self, this._then);

  final StatResult _self;
  final $Res Function(StatResult) _then;

/// Create a copy of StatResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? value = null,Object? formattedValue = freezed,Object? description = freezed,Object? severity = freezed,Object? trend = freezed,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as num,formattedValue: freezed == formattedValue ? _self.formattedValue : formattedValue // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,severity: freezed == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as StatSeverity?,trend: freezed == trend ? _self.trend : trend // ignore: cast_nullable_to_non_nullable
as TrendDirection?,
  ));
}

}


/// Adds pattern-matching-related methods to [StatResult].
extension StatResultPatterns on StatResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatResult value)  $default,){
final _that = this;
switch (_that) {
case _StatResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatResult value)?  $default,){
final _that = this;
switch (_that) {
case _StatResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  num value,  String? formattedValue,  String? description,  StatSeverity? severity,  TrendDirection? trend)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatResult() when $default != null:
return $default(_that.label,_that.value,_that.formattedValue,_that.description,_that.severity,_that.trend);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  num value,  String? formattedValue,  String? description,  StatSeverity? severity,  TrendDirection? trend)  $default,) {final _that = this;
switch (_that) {
case _StatResult():
return $default(_that.label,_that.value,_that.formattedValue,_that.description,_that.severity,_that.trend);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  num value,  String? formattedValue,  String? description,  StatSeverity? severity,  TrendDirection? trend)?  $default,) {final _that = this;
switch (_that) {
case _StatResult() when $default != null:
return $default(_that.label,_that.value,_that.formattedValue,_that.description,_that.severity,_that.trend);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatResult implements StatResult {
  const _StatResult({required this.label, required this.value, this.formattedValue, this.description, this.severity, this.trend});
  factory _StatResult.fromJson(Map<String, dynamic> json) => _$StatResultFromJson(json);

@override final  String label;
@override final  num value;
@override final  String? formattedValue;
@override final  String? description;
@override final  StatSeverity? severity;
@override final  TrendDirection? trend;

/// Create a copy of StatResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatResultCopyWith<_StatResult> get copyWith => __$StatResultCopyWithImpl<_StatResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatResult&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value)&&(identical(other.formattedValue, formattedValue) || other.formattedValue == formattedValue)&&(identical(other.description, description) || other.description == description)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.trend, trend) || other.trend == trend));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,value,formattedValue,description,severity,trend);

@override
String toString() {
  return 'StatResult(label: $label, value: $value, formattedValue: $formattedValue, description: $description, severity: $severity, trend: $trend)';
}


}

/// @nodoc
abstract mixin class _$StatResultCopyWith<$Res> implements $StatResultCopyWith<$Res> {
  factory _$StatResultCopyWith(_StatResult value, $Res Function(_StatResult) _then) = __$StatResultCopyWithImpl;
@override @useResult
$Res call({
 String label, num value, String? formattedValue, String? description, StatSeverity? severity, TrendDirection? trend
});




}
/// @nodoc
class __$StatResultCopyWithImpl<$Res>
    implements _$StatResultCopyWith<$Res> {
  __$StatResultCopyWithImpl(this._self, this._then);

  final _StatResult _self;
  final $Res Function(_StatResult) _then;

/// Create a copy of StatResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? value = null,Object? formattedValue = freezed,Object? description = freezed,Object? severity = freezed,Object? trend = freezed,}) {
  return _then(_StatResult(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as num,formattedValue: freezed == formattedValue ? _self.formattedValue : formattedValue // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,severity: freezed == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as StatSeverity?,trend: freezed == trend ? _self.trend : trend // ignore: cast_nullable_to_non_nullable
as TrendDirection?,
  ));
}


}

// dart format on
