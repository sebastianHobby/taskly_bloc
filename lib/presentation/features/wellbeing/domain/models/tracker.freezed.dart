// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tracker.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Tracker {

 String get id; String get userId; String get name; TrackerResponseType get responseType; TrackerResponseConfig get config; TrackerEntryScope get entryScope; DateTime get createdAt; DateTime get updatedAt; String? get description; int get sortOrder;
/// Create a copy of Tracker
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackerCopyWith<Tracker> get copyWith => _$TrackerCopyWithImpl<Tracker>(this as Tracker, _$identity);

  /// Serializes this Tracker to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Tracker&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.responseType, responseType) || other.responseType == responseType)&&(identical(other.config, config) || other.config == config)&&(identical(other.entryScope, entryScope) || other.entryScope == entryScope)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,responseType,config,entryScope,createdAt,updatedAt,description,sortOrder);

@override
String toString() {
  return 'Tracker(id: $id, userId: $userId, name: $name, responseType: $responseType, config: $config, entryScope: $entryScope, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $TrackerCopyWith<$Res>  {
  factory $TrackerCopyWith(Tracker value, $Res Function(Tracker) _then) = _$TrackerCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String name, TrackerResponseType responseType, TrackerResponseConfig config, TrackerEntryScope entryScope, DateTime createdAt, DateTime updatedAt, String? description, int sortOrder
});


$TrackerResponseConfigCopyWith<$Res> get config;

}
/// @nodoc
class _$TrackerCopyWithImpl<$Res>
    implements $TrackerCopyWith<$Res> {
  _$TrackerCopyWithImpl(this._self, this._then);

  final Tracker _self;
  final $Res Function(Tracker) _then;

/// Create a copy of Tracker
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? responseType = null,Object? config = null,Object? entryScope = null,Object? createdAt = null,Object? updatedAt = null,Object? description = freezed,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,responseType: null == responseType ? _self.responseType : responseType // ignore: cast_nullable_to_non_nullable
as TrackerResponseType,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as TrackerResponseConfig,entryScope: null == entryScope ? _self.entryScope : entryScope // ignore: cast_nullable_to_non_nullable
as TrackerEntryScope,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of Tracker
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackerResponseConfigCopyWith<$Res> get config {
  
  return $TrackerResponseConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}


/// Adds pattern-matching-related methods to [Tracker].
extension TrackerPatterns on Tracker {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Tracker value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Tracker() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Tracker value)  $default,){
final _that = this;
switch (_that) {
case _Tracker():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Tracker value)?  $default,){
final _that = this;
switch (_that) {
case _Tracker() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String name,  TrackerResponseType responseType,  TrackerResponseConfig config,  TrackerEntryScope entryScope,  DateTime createdAt,  DateTime updatedAt,  String? description,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Tracker() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.responseType,_that.config,_that.entryScope,_that.createdAt,_that.updatedAt,_that.description,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String name,  TrackerResponseType responseType,  TrackerResponseConfig config,  TrackerEntryScope entryScope,  DateTime createdAt,  DateTime updatedAt,  String? description,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _Tracker():
return $default(_that.id,_that.userId,_that.name,_that.responseType,_that.config,_that.entryScope,_that.createdAt,_that.updatedAt,_that.description,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String name,  TrackerResponseType responseType,  TrackerResponseConfig config,  TrackerEntryScope entryScope,  DateTime createdAt,  DateTime updatedAt,  String? description,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _Tracker() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.responseType,_that.config,_that.entryScope,_that.createdAt,_that.updatedAt,_that.description,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Tracker implements Tracker {
  const _Tracker({required this.id, required this.userId, required this.name, required this.responseType, required this.config, required this.entryScope, required this.createdAt, required this.updatedAt, this.description, this.sortOrder = 0});
  factory _Tracker.fromJson(Map<String, dynamic> json) => _$TrackerFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String name;
@override final  TrackerResponseType responseType;
@override final  TrackerResponseConfig config;
@override final  TrackerEntryScope entryScope;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? description;
@override@JsonKey() final  int sortOrder;

/// Create a copy of Tracker
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackerCopyWith<_Tracker> get copyWith => __$TrackerCopyWithImpl<_Tracker>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Tracker&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.responseType, responseType) || other.responseType == responseType)&&(identical(other.config, config) || other.config == config)&&(identical(other.entryScope, entryScope) || other.entryScope == entryScope)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,responseType,config,entryScope,createdAt,updatedAt,description,sortOrder);

@override
String toString() {
  return 'Tracker(id: $id, userId: $userId, name: $name, responseType: $responseType, config: $config, entryScope: $entryScope, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$TrackerCopyWith<$Res> implements $TrackerCopyWith<$Res> {
  factory _$TrackerCopyWith(_Tracker value, $Res Function(_Tracker) _then) = __$TrackerCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String name, TrackerResponseType responseType, TrackerResponseConfig config, TrackerEntryScope entryScope, DateTime createdAt, DateTime updatedAt, String? description, int sortOrder
});


@override $TrackerResponseConfigCopyWith<$Res> get config;

}
/// @nodoc
class __$TrackerCopyWithImpl<$Res>
    implements _$TrackerCopyWith<$Res> {
  __$TrackerCopyWithImpl(this._self, this._then);

  final _Tracker _self;
  final $Res Function(_Tracker) _then;

/// Create a copy of Tracker
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? responseType = null,Object? config = null,Object? entryScope = null,Object? createdAt = null,Object? updatedAt = null,Object? description = freezed,Object? sortOrder = null,}) {
  return _then(_Tracker(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,responseType: null == responseType ? _self.responseType : responseType // ignore: cast_nullable_to_non_nullable
as TrackerResponseType,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as TrackerResponseConfig,entryScope: null == entryScope ? _self.entryScope : entryScope // ignore: cast_nullable_to_non_nullable
as TrackerEntryScope,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of Tracker
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackerResponseConfigCopyWith<$Res> get config {
  
  return $TrackerResponseConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}

// dart format on
