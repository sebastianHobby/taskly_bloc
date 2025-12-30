// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workflow_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkflowItem<T> {

 T get entity; String get entityId; WorkflowItemStatus get status; DateTime? get lastReviewedAt; String? get notes;
/// Create a copy of WorkflowItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkflowItemCopyWith<T, WorkflowItem<T>> get copyWith => _$WorkflowItemCopyWithImpl<T, WorkflowItem<T>>(this as WorkflowItem<T>, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowItem<T>&&const DeepCollectionEquality().equals(other.entity, entity)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastReviewedAt, lastReviewedAt) || other.lastReviewedAt == lastReviewedAt)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(entity),entityId,status,lastReviewedAt,notes);

@override
String toString() {
  return 'WorkflowItem<$T>(entity: $entity, entityId: $entityId, status: $status, lastReviewedAt: $lastReviewedAt, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $WorkflowItemCopyWith<T,$Res>  {
  factory $WorkflowItemCopyWith(WorkflowItem<T> value, $Res Function(WorkflowItem<T>) _then) = _$WorkflowItemCopyWithImpl;
@useResult
$Res call({
 T entity, String entityId, WorkflowItemStatus status, DateTime? lastReviewedAt, String? notes
});




}
/// @nodoc
class _$WorkflowItemCopyWithImpl<T,$Res>
    implements $WorkflowItemCopyWith<T, $Res> {
  _$WorkflowItemCopyWithImpl(this._self, this._then);

  final WorkflowItem<T> _self;
  final $Res Function(WorkflowItem<T>) _then;

/// Create a copy of WorkflowItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entity = freezed,Object? entityId = null,Object? status = null,Object? lastReviewedAt = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
entity: freezed == entity ? _self.entity : entity // ignore: cast_nullable_to_non_nullable
as T,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorkflowItemStatus,lastReviewedAt: freezed == lastReviewedAt ? _self.lastReviewedAt : lastReviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkflowItem].
extension WorkflowItemPatterns<T> on WorkflowItem<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkflowItem<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkflowItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkflowItem<T> value)  $default,){
final _that = this;
switch (_that) {
case _WorkflowItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkflowItem<T> value)?  $default,){
final _that = this;
switch (_that) {
case _WorkflowItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( T entity,  String entityId,  WorkflowItemStatus status,  DateTime? lastReviewedAt,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkflowItem() when $default != null:
return $default(_that.entity,_that.entityId,_that.status,_that.lastReviewedAt,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( T entity,  String entityId,  WorkflowItemStatus status,  DateTime? lastReviewedAt,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _WorkflowItem():
return $default(_that.entity,_that.entityId,_that.status,_that.lastReviewedAt,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( T entity,  String entityId,  WorkflowItemStatus status,  DateTime? lastReviewedAt,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _WorkflowItem() when $default != null:
return $default(_that.entity,_that.entityId,_that.status,_that.lastReviewedAt,_that.notes);case _:
  return null;

}
}

}

/// @nodoc


class _WorkflowItem<T> implements WorkflowItem<T> {
  const _WorkflowItem({required this.entity, required this.entityId, this.status = WorkflowItemStatus.pending, this.lastReviewedAt, this.notes});
  

@override final  T entity;
@override final  String entityId;
@override@JsonKey() final  WorkflowItemStatus status;
@override final  DateTime? lastReviewedAt;
@override final  String? notes;

/// Create a copy of WorkflowItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkflowItemCopyWith<T, _WorkflowItem<T>> get copyWith => __$WorkflowItemCopyWithImpl<T, _WorkflowItem<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkflowItem<T>&&const DeepCollectionEquality().equals(other.entity, entity)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastReviewedAt, lastReviewedAt) || other.lastReviewedAt == lastReviewedAt)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(entity),entityId,status,lastReviewedAt,notes);

@override
String toString() {
  return 'WorkflowItem<$T>(entity: $entity, entityId: $entityId, status: $status, lastReviewedAt: $lastReviewedAt, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$WorkflowItemCopyWith<T,$Res> implements $WorkflowItemCopyWith<T, $Res> {
  factory _$WorkflowItemCopyWith(_WorkflowItem<T> value, $Res Function(_WorkflowItem<T>) _then) = __$WorkflowItemCopyWithImpl;
@override @useResult
$Res call({
 T entity, String entityId, WorkflowItemStatus status, DateTime? lastReviewedAt, String? notes
});




}
/// @nodoc
class __$WorkflowItemCopyWithImpl<T,$Res>
    implements _$WorkflowItemCopyWith<T, $Res> {
  __$WorkflowItemCopyWithImpl(this._self, this._then);

  final _WorkflowItem<T> _self;
  final $Res Function(_WorkflowItem<T>) _then;

/// Create a copy of WorkflowItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entity = freezed,Object? entityId = null,Object? status = null,Object? lastReviewedAt = freezed,Object? notes = freezed,}) {
  return _then(_WorkflowItem<T>(
entity: freezed == entity ? _self.entity : entity // ignore: cast_nullable_to_non_nullable
as T,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorkflowItemStatus,lastReviewedAt: freezed == lastReviewedAt ? _self.lastReviewedAt : lastReviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
