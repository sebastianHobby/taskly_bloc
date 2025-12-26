// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Review {

 String get id; String get userId; String get name; ReviewQuery get query; String get rrule; DateTime get nextDueDate; DateTime get createdAt; DateTime get updatedAt; String? get description; DateTime? get lastCompletedAt; DateTime? get deletedAt;
/// Create a copy of Review
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewCopyWith<Review> get copyWith => _$ReviewCopyWithImpl<Review>(this as Review, _$identity);

  /// Serializes this Review to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Review&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.query, query) || other.query == query)&&(identical(other.rrule, rrule) || other.rrule == rrule)&&(identical(other.nextDueDate, nextDueDate) || other.nextDueDate == nextDueDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.lastCompletedAt, lastCompletedAt) || other.lastCompletedAt == lastCompletedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,query,rrule,nextDueDate,createdAt,updatedAt,description,lastCompletedAt,deletedAt);

@override
String toString() {
  return 'Review(id: $id, userId: $userId, name: $name, query: $query, rrule: $rrule, nextDueDate: $nextDueDate, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, lastCompletedAt: $lastCompletedAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class $ReviewCopyWith<$Res>  {
  factory $ReviewCopyWith(Review value, $Res Function(Review) _then) = _$ReviewCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String name, ReviewQuery query, String rrule, DateTime nextDueDate, DateTime createdAt, DateTime updatedAt, String? description, DateTime? lastCompletedAt, DateTime? deletedAt
});


$ReviewQueryCopyWith<$Res> get query;

}
/// @nodoc
class _$ReviewCopyWithImpl<$Res>
    implements $ReviewCopyWith<$Res> {
  _$ReviewCopyWithImpl(this._self, this._then);

  final Review _self;
  final $Res Function(Review) _then;

/// Create a copy of Review
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? query = null,Object? rrule = null,Object? nextDueDate = null,Object? createdAt = null,Object? updatedAt = null,Object? description = freezed,Object? lastCompletedAt = freezed,Object? deletedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as ReviewQuery,rrule: null == rrule ? _self.rrule : rrule // ignore: cast_nullable_to_non_nullable
as String,nextDueDate: null == nextDueDate ? _self.nextDueDate : nextDueDate // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,lastCompletedAt: freezed == lastCompletedAt ? _self.lastCompletedAt : lastCompletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Review
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewQueryCopyWith<$Res> get query {
  
  return $ReviewQueryCopyWith<$Res>(_self.query, (value) {
    return _then(_self.copyWith(query: value));
  });
}
}


/// Adds pattern-matching-related methods to [Review].
extension ReviewPatterns on Review {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Review value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Review() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Review value)  $default,){
final _that = this;
switch (_that) {
case _Review():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Review value)?  $default,){
final _that = this;
switch (_that) {
case _Review() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String name,  ReviewQuery query,  String rrule,  DateTime nextDueDate,  DateTime createdAt,  DateTime updatedAt,  String? description,  DateTime? lastCompletedAt,  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Review() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.query,_that.rrule,_that.nextDueDate,_that.createdAt,_that.updatedAt,_that.description,_that.lastCompletedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String name,  ReviewQuery query,  String rrule,  DateTime nextDueDate,  DateTime createdAt,  DateTime updatedAt,  String? description,  DateTime? lastCompletedAt,  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _Review():
return $default(_that.id,_that.userId,_that.name,_that.query,_that.rrule,_that.nextDueDate,_that.createdAt,_that.updatedAt,_that.description,_that.lastCompletedAt,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String name,  ReviewQuery query,  String rrule,  DateTime nextDueDate,  DateTime createdAt,  DateTime updatedAt,  String? description,  DateTime? lastCompletedAt,  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _Review() when $default != null:
return $default(_that.id,_that.userId,_that.name,_that.query,_that.rrule,_that.nextDueDate,_that.createdAt,_that.updatedAt,_that.description,_that.lastCompletedAt,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Review implements Review {
  const _Review({required this.id, required this.userId, required this.name, required this.query, required this.rrule, required this.nextDueDate, required this.createdAt, required this.updatedAt, this.description, this.lastCompletedAt, this.deletedAt});
  factory _Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String name;
@override final  ReviewQuery query;
@override final  String rrule;
@override final  DateTime nextDueDate;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? description;
@override final  DateTime? lastCompletedAt;
@override final  DateTime? deletedAt;

/// Create a copy of Review
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewCopyWith<_Review> get copyWith => __$ReviewCopyWithImpl<_Review>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Review&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.name, name) || other.name == name)&&(identical(other.query, query) || other.query == query)&&(identical(other.rrule, rrule) || other.rrule == rrule)&&(identical(other.nextDueDate, nextDueDate) || other.nextDueDate == nextDueDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.description, description) || other.description == description)&&(identical(other.lastCompletedAt, lastCompletedAt) || other.lastCompletedAt == lastCompletedAt)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,name,query,rrule,nextDueDate,createdAt,updatedAt,description,lastCompletedAt,deletedAt);

@override
String toString() {
  return 'Review(id: $id, userId: $userId, name: $name, query: $query, rrule: $rrule, nextDueDate: $nextDueDate, createdAt: $createdAt, updatedAt: $updatedAt, description: $description, lastCompletedAt: $lastCompletedAt, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$ReviewCopyWith<$Res> implements $ReviewCopyWith<$Res> {
  factory _$ReviewCopyWith(_Review value, $Res Function(_Review) _then) = __$ReviewCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String name, ReviewQuery query, String rrule, DateTime nextDueDate, DateTime createdAt, DateTime updatedAt, String? description, DateTime? lastCompletedAt, DateTime? deletedAt
});


@override $ReviewQueryCopyWith<$Res> get query;

}
/// @nodoc
class __$ReviewCopyWithImpl<$Res>
    implements _$ReviewCopyWith<$Res> {
  __$ReviewCopyWithImpl(this._self, this._then);

  final _Review _self;
  final $Res Function(_Review) _then;

/// Create a copy of Review
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? name = null,Object? query = null,Object? rrule = null,Object? nextDueDate = null,Object? createdAt = null,Object? updatedAt = null,Object? description = freezed,Object? lastCompletedAt = freezed,Object? deletedAt = freezed,}) {
  return _then(_Review(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as ReviewQuery,rrule: null == rrule ? _self.rrule : rrule // ignore: cast_nullable_to_non_nullable
as String,nextDueDate: null == nextDueDate ? _self.nextDueDate : nextDueDate // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,lastCompletedAt: freezed == lastCompletedAt ? _self.lastCompletedAt : lastCompletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Review
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewQueryCopyWith<$Res> get query {
  
  return $ReviewQueryCopyWith<$Res>(_self.query, (value) {
    return _then(_self.copyWith(query: value));
  });
}
}

// dart format on
