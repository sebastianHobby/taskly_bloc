// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_tracker_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DailyTrackerResponse {

 String get id; DateTime get responseDate;// Date only (time component ignored for logic)
 String get trackerId; TrackerResponseValue get value; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of DailyTrackerResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyTrackerResponseCopyWith<DailyTrackerResponse> get copyWith => _$DailyTrackerResponseCopyWithImpl<DailyTrackerResponse>(this as DailyTrackerResponse, _$identity);

  /// Serializes this DailyTrackerResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyTrackerResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.responseDate, responseDate) || other.responseDate == responseDate)&&(identical(other.trackerId, trackerId) || other.trackerId == trackerId)&&(identical(other.value, value) || other.value == value)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,responseDate,trackerId,value,createdAt,updatedAt);

@override
String toString() {
  return 'DailyTrackerResponse(id: $id, responseDate: $responseDate, trackerId: $trackerId, value: $value, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $DailyTrackerResponseCopyWith<$Res>  {
  factory $DailyTrackerResponseCopyWith(DailyTrackerResponse value, $Res Function(DailyTrackerResponse) _then) = _$DailyTrackerResponseCopyWithImpl;
@useResult
$Res call({
 String id, DateTime responseDate, String trackerId, TrackerResponseValue value, DateTime createdAt, DateTime updatedAt
});


$TrackerResponseValueCopyWith<$Res> get value;

}
/// @nodoc
class _$DailyTrackerResponseCopyWithImpl<$Res>
    implements $DailyTrackerResponseCopyWith<$Res> {
  _$DailyTrackerResponseCopyWithImpl(this._self, this._then);

  final DailyTrackerResponse _self;
  final $Res Function(DailyTrackerResponse) _then;

/// Create a copy of DailyTrackerResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? responseDate = null,Object? trackerId = null,Object? value = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,responseDate: null == responseDate ? _self.responseDate : responseDate // ignore: cast_nullable_to_non_nullable
as DateTime,trackerId: null == trackerId ? _self.trackerId : trackerId // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TrackerResponseValue,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of DailyTrackerResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackerResponseValueCopyWith<$Res> get value {
  
  return $TrackerResponseValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}


/// Adds pattern-matching-related methods to [DailyTrackerResponse].
extension DailyTrackerResponsePatterns on DailyTrackerResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyTrackerResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyTrackerResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyTrackerResponse value)  $default,){
final _that = this;
switch (_that) {
case _DailyTrackerResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyTrackerResponse value)?  $default,){
final _that = this;
switch (_that) {
case _DailyTrackerResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime responseDate,  String trackerId,  TrackerResponseValue value,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyTrackerResponse() when $default != null:
return $default(_that.id,_that.responseDate,_that.trackerId,_that.value,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime responseDate,  String trackerId,  TrackerResponseValue value,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _DailyTrackerResponse():
return $default(_that.id,_that.responseDate,_that.trackerId,_that.value,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime responseDate,  String trackerId,  TrackerResponseValue value,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _DailyTrackerResponse() when $default != null:
return $default(_that.id,_that.responseDate,_that.trackerId,_that.value,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _DailyTrackerResponse implements DailyTrackerResponse {
  const _DailyTrackerResponse({required this.id, required this.responseDate, required this.trackerId, required this.value, required this.createdAt, required this.updatedAt});
  factory _DailyTrackerResponse.fromJson(Map<String, dynamic> json) => _$DailyTrackerResponseFromJson(json);

@override final  String id;
@override final  DateTime responseDate;
// Date only (time component ignored for logic)
@override final  String trackerId;
@override final  TrackerResponseValue value;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of DailyTrackerResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyTrackerResponseCopyWith<_DailyTrackerResponse> get copyWith => __$DailyTrackerResponseCopyWithImpl<_DailyTrackerResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyTrackerResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyTrackerResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.responseDate, responseDate) || other.responseDate == responseDate)&&(identical(other.trackerId, trackerId) || other.trackerId == trackerId)&&(identical(other.value, value) || other.value == value)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,responseDate,trackerId,value,createdAt,updatedAt);

@override
String toString() {
  return 'DailyTrackerResponse(id: $id, responseDate: $responseDate, trackerId: $trackerId, value: $value, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$DailyTrackerResponseCopyWith<$Res> implements $DailyTrackerResponseCopyWith<$Res> {
  factory _$DailyTrackerResponseCopyWith(_DailyTrackerResponse value, $Res Function(_DailyTrackerResponse) _then) = __$DailyTrackerResponseCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime responseDate, String trackerId, TrackerResponseValue value, DateTime createdAt, DateTime updatedAt
});


@override $TrackerResponseValueCopyWith<$Res> get value;

}
/// @nodoc
class __$DailyTrackerResponseCopyWithImpl<$Res>
    implements _$DailyTrackerResponseCopyWith<$Res> {
  __$DailyTrackerResponseCopyWithImpl(this._self, this._then);

  final _DailyTrackerResponse _self;
  final $Res Function(_DailyTrackerResponse) _then;

/// Create a copy of DailyTrackerResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? responseDate = null,Object? trackerId = null,Object? value = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_DailyTrackerResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,responseDate: null == responseDate ? _self.responseDate : responseDate // ignore: cast_nullable_to_non_nullable
as DateTime,trackerId: null == trackerId ? _self.trackerId : trackerId // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TrackerResponseValue,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of DailyTrackerResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackerResponseValueCopyWith<$Res> get value {
  
  return $TrackerResponseValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

// dart format on
