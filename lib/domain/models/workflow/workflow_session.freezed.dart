// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workflow_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkflowSession {

 String get id; String get userId; String get screenId; DateTime get startedAt; DateTime get createdAt; DateTime get updatedAt; WorkflowStatus get status; DateTime? get completedAt; int get totalItems; int get itemsReviewed; int get itemsSkipped; String? get sessionNotes;
/// Create a copy of WorkflowSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkflowSessionCopyWith<WorkflowSession> get copyWith => _$WorkflowSessionCopyWithImpl<WorkflowSession>(this as WorkflowSession, _$identity);

  /// Serializes this WorkflowSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowSession&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.screenId, screenId) || other.screenId == screenId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.itemsReviewed, itemsReviewed) || other.itemsReviewed == itemsReviewed)&&(identical(other.itemsSkipped, itemsSkipped) || other.itemsSkipped == itemsSkipped)&&(identical(other.sessionNotes, sessionNotes) || other.sessionNotes == sessionNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,screenId,startedAt,createdAt,updatedAt,status,completedAt,totalItems,itemsReviewed,itemsSkipped,sessionNotes);

@override
String toString() {
  return 'WorkflowSession(id: $id, userId: $userId, screenId: $screenId, startedAt: $startedAt, createdAt: $createdAt, updatedAt: $updatedAt, status: $status, completedAt: $completedAt, totalItems: $totalItems, itemsReviewed: $itemsReviewed, itemsSkipped: $itemsSkipped, sessionNotes: $sessionNotes)';
}


}

/// @nodoc
abstract mixin class $WorkflowSessionCopyWith<$Res>  {
  factory $WorkflowSessionCopyWith(WorkflowSession value, $Res Function(WorkflowSession) _then) = _$WorkflowSessionCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String screenId, DateTime startedAt, DateTime createdAt, DateTime updatedAt, WorkflowStatus status, DateTime? completedAt, int totalItems, int itemsReviewed, int itemsSkipped, String? sessionNotes
});




}
/// @nodoc
class _$WorkflowSessionCopyWithImpl<$Res>
    implements $WorkflowSessionCopyWith<$Res> {
  _$WorkflowSessionCopyWithImpl(this._self, this._then);

  final WorkflowSession _self;
  final $Res Function(WorkflowSession) _then;

/// Create a copy of WorkflowSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? screenId = null,Object? startedAt = null,Object? createdAt = null,Object? updatedAt = null,Object? status = null,Object? completedAt = freezed,Object? totalItems = null,Object? itemsReviewed = null,Object? itemsSkipped = null,Object? sessionNotes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,screenId: null == screenId ? _self.screenId : screenId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorkflowStatus,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,itemsReviewed: null == itemsReviewed ? _self.itemsReviewed : itemsReviewed // ignore: cast_nullable_to_non_nullable
as int,itemsSkipped: null == itemsSkipped ? _self.itemsSkipped : itemsSkipped // ignore: cast_nullable_to_non_nullable
as int,sessionNotes: freezed == sessionNotes ? _self.sessionNotes : sessionNotes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkflowSession].
extension WorkflowSessionPatterns on WorkflowSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkflowSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkflowSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkflowSession value)  $default,){
final _that = this;
switch (_that) {
case _WorkflowSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkflowSession value)?  $default,){
final _that = this;
switch (_that) {
case _WorkflowSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String screenId,  DateTime startedAt,  DateTime createdAt,  DateTime updatedAt,  WorkflowStatus status,  DateTime? completedAt,  int totalItems,  int itemsReviewed,  int itemsSkipped,  String? sessionNotes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkflowSession() when $default != null:
return $default(_that.id,_that.userId,_that.screenId,_that.startedAt,_that.createdAt,_that.updatedAt,_that.status,_that.completedAt,_that.totalItems,_that.itemsReviewed,_that.itemsSkipped,_that.sessionNotes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String screenId,  DateTime startedAt,  DateTime createdAt,  DateTime updatedAt,  WorkflowStatus status,  DateTime? completedAt,  int totalItems,  int itemsReviewed,  int itemsSkipped,  String? sessionNotes)  $default,) {final _that = this;
switch (_that) {
case _WorkflowSession():
return $default(_that.id,_that.userId,_that.screenId,_that.startedAt,_that.createdAt,_that.updatedAt,_that.status,_that.completedAt,_that.totalItems,_that.itemsReviewed,_that.itemsSkipped,_that.sessionNotes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String screenId,  DateTime startedAt,  DateTime createdAt,  DateTime updatedAt,  WorkflowStatus status,  DateTime? completedAt,  int totalItems,  int itemsReviewed,  int itemsSkipped,  String? sessionNotes)?  $default,) {final _that = this;
switch (_that) {
case _WorkflowSession() when $default != null:
return $default(_that.id,_that.userId,_that.screenId,_that.startedAt,_that.createdAt,_that.updatedAt,_that.status,_that.completedAt,_that.totalItems,_that.itemsReviewed,_that.itemsSkipped,_that.sessionNotes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkflowSession implements WorkflowSession {
  const _WorkflowSession({required this.id, required this.userId, required this.screenId, required this.startedAt, required this.createdAt, required this.updatedAt, this.status = WorkflowStatus.inProgress, this.completedAt, this.totalItems = 0, this.itemsReviewed = 0, this.itemsSkipped = 0, this.sessionNotes});
  factory _WorkflowSession.fromJson(Map<String, dynamic> json) => _$WorkflowSessionFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String screenId;
@override final  DateTime startedAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override@JsonKey() final  WorkflowStatus status;
@override final  DateTime? completedAt;
@override@JsonKey() final  int totalItems;
@override@JsonKey() final  int itemsReviewed;
@override@JsonKey() final  int itemsSkipped;
@override final  String? sessionNotes;

/// Create a copy of WorkflowSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkflowSessionCopyWith<_WorkflowSession> get copyWith => __$WorkflowSessionCopyWithImpl<_WorkflowSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkflowSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkflowSession&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.screenId, screenId) || other.screenId == screenId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.itemsReviewed, itemsReviewed) || other.itemsReviewed == itemsReviewed)&&(identical(other.itemsSkipped, itemsSkipped) || other.itemsSkipped == itemsSkipped)&&(identical(other.sessionNotes, sessionNotes) || other.sessionNotes == sessionNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,screenId,startedAt,createdAt,updatedAt,status,completedAt,totalItems,itemsReviewed,itemsSkipped,sessionNotes);

@override
String toString() {
  return 'WorkflowSession(id: $id, userId: $userId, screenId: $screenId, startedAt: $startedAt, createdAt: $createdAt, updatedAt: $updatedAt, status: $status, completedAt: $completedAt, totalItems: $totalItems, itemsReviewed: $itemsReviewed, itemsSkipped: $itemsSkipped, sessionNotes: $sessionNotes)';
}


}

/// @nodoc
abstract mixin class _$WorkflowSessionCopyWith<$Res> implements $WorkflowSessionCopyWith<$Res> {
  factory _$WorkflowSessionCopyWith(_WorkflowSession value, $Res Function(_WorkflowSession) _then) = __$WorkflowSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String screenId, DateTime startedAt, DateTime createdAt, DateTime updatedAt, WorkflowStatus status, DateTime? completedAt, int totalItems, int itemsReviewed, int itemsSkipped, String? sessionNotes
});




}
/// @nodoc
class __$WorkflowSessionCopyWithImpl<$Res>
    implements _$WorkflowSessionCopyWith<$Res> {
  __$WorkflowSessionCopyWithImpl(this._self, this._then);

  final _WorkflowSession _self;
  final $Res Function(_WorkflowSession) _then;

/// Create a copy of WorkflowSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? screenId = null,Object? startedAt = null,Object? createdAt = null,Object? updatedAt = null,Object? status = null,Object? completedAt = freezed,Object? totalItems = null,Object? itemsReviewed = null,Object? itemsSkipped = null,Object? sessionNotes = freezed,}) {
  return _then(_WorkflowSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,screenId: null == screenId ? _self.screenId : screenId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as WorkflowStatus,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,itemsReviewed: null == itemsReviewed ? _self.itemsReviewed : itemsReviewed // ignore: cast_nullable_to_non_nullable
as int,itemsSkipped: null == itemsSkipped ? _self.itemsSkipped : itemsSkipped // ignore: cast_nullable_to_non_nullable
as int,sessionNotes: freezed == sessionNotes ? _self.sessionNotes : sessionNotes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$WorkflowItemReview {

 String get id; String get sessionId; String get userId; String get entityId; EntityType get entityType; WorkflowAction get action; DateTime get reviewedAt; DateTime get createdAt; DateTime get updatedAt; String? get reviewNotes;
/// Create a copy of WorkflowItemReview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkflowItemReviewCopyWith<WorkflowItemReview> get copyWith => _$WorkflowItemReviewCopyWithImpl<WorkflowItemReview>(this as WorkflowItemReview, _$identity);

  /// Serializes this WorkflowItemReview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowItemReview&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.action, action) || other.action == action)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.reviewNotes, reviewNotes) || other.reviewNotes == reviewNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,userId,entityId,entityType,action,reviewedAt,createdAt,updatedAt,reviewNotes);

@override
String toString() {
  return 'WorkflowItemReview(id: $id, sessionId: $sessionId, userId: $userId, entityId: $entityId, entityType: $entityType, action: $action, reviewedAt: $reviewedAt, createdAt: $createdAt, updatedAt: $updatedAt, reviewNotes: $reviewNotes)';
}


}

/// @nodoc
abstract mixin class $WorkflowItemReviewCopyWith<$Res>  {
  factory $WorkflowItemReviewCopyWith(WorkflowItemReview value, $Res Function(WorkflowItemReview) _then) = _$WorkflowItemReviewCopyWithImpl;
@useResult
$Res call({
 String id, String sessionId, String userId, String entityId, EntityType entityType, WorkflowAction action, DateTime reviewedAt, DateTime createdAt, DateTime updatedAt, String? reviewNotes
});




}
/// @nodoc
class _$WorkflowItemReviewCopyWithImpl<$Res>
    implements $WorkflowItemReviewCopyWith<$Res> {
  _$WorkflowItemReviewCopyWithImpl(this._self, this._then);

  final WorkflowItemReview _self;
  final $Res Function(WorkflowItemReview) _then;

/// Create a copy of WorkflowItemReview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? userId = null,Object? entityId = null,Object? entityType = null,Object? action = null,Object? reviewedAt = null,Object? createdAt = null,Object? updatedAt = null,Object? reviewNotes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as WorkflowAction,reviewedAt: null == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reviewNotes: freezed == reviewNotes ? _self.reviewNotes : reviewNotes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkflowItemReview].
extension WorkflowItemReviewPatterns on WorkflowItemReview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkflowItemReview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkflowItemReview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkflowItemReview value)  $default,){
final _that = this;
switch (_that) {
case _WorkflowItemReview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkflowItemReview value)?  $default,){
final _that = this;
switch (_that) {
case _WorkflowItemReview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sessionId,  String userId,  String entityId,  EntityType entityType,  WorkflowAction action,  DateTime reviewedAt,  DateTime createdAt,  DateTime updatedAt,  String? reviewNotes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkflowItemReview() when $default != null:
return $default(_that.id,_that.sessionId,_that.userId,_that.entityId,_that.entityType,_that.action,_that.reviewedAt,_that.createdAt,_that.updatedAt,_that.reviewNotes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sessionId,  String userId,  String entityId,  EntityType entityType,  WorkflowAction action,  DateTime reviewedAt,  DateTime createdAt,  DateTime updatedAt,  String? reviewNotes)  $default,) {final _that = this;
switch (_that) {
case _WorkflowItemReview():
return $default(_that.id,_that.sessionId,_that.userId,_that.entityId,_that.entityType,_that.action,_that.reviewedAt,_that.createdAt,_that.updatedAt,_that.reviewNotes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sessionId,  String userId,  String entityId,  EntityType entityType,  WorkflowAction action,  DateTime reviewedAt,  DateTime createdAt,  DateTime updatedAt,  String? reviewNotes)?  $default,) {final _that = this;
switch (_that) {
case _WorkflowItemReview() when $default != null:
return $default(_that.id,_that.sessionId,_that.userId,_that.entityId,_that.entityType,_that.action,_that.reviewedAt,_that.createdAt,_that.updatedAt,_that.reviewNotes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkflowItemReview implements WorkflowItemReview {
  const _WorkflowItemReview({required this.id, required this.sessionId, required this.userId, required this.entityId, required this.entityType, required this.action, required this.reviewedAt, required this.createdAt, required this.updatedAt, this.reviewNotes});
  factory _WorkflowItemReview.fromJson(Map<String, dynamic> json) => _$WorkflowItemReviewFromJson(json);

@override final  String id;
@override final  String sessionId;
@override final  String userId;
@override final  String entityId;
@override final  EntityType entityType;
@override final  WorkflowAction action;
@override final  DateTime reviewedAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? reviewNotes;

/// Create a copy of WorkflowItemReview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkflowItemReviewCopyWith<_WorkflowItemReview> get copyWith => __$WorkflowItemReviewCopyWithImpl<_WorkflowItemReview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkflowItemReviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkflowItemReview&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.action, action) || other.action == action)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.reviewNotes, reviewNotes) || other.reviewNotes == reviewNotes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,userId,entityId,entityType,action,reviewedAt,createdAt,updatedAt,reviewNotes);

@override
String toString() {
  return 'WorkflowItemReview(id: $id, sessionId: $sessionId, userId: $userId, entityId: $entityId, entityType: $entityType, action: $action, reviewedAt: $reviewedAt, createdAt: $createdAt, updatedAt: $updatedAt, reviewNotes: $reviewNotes)';
}


}

/// @nodoc
abstract mixin class _$WorkflowItemReviewCopyWith<$Res> implements $WorkflowItemReviewCopyWith<$Res> {
  factory _$WorkflowItemReviewCopyWith(_WorkflowItemReview value, $Res Function(_WorkflowItemReview) _then) = __$WorkflowItemReviewCopyWithImpl;
@override @useResult
$Res call({
 String id, String sessionId, String userId, String entityId, EntityType entityType, WorkflowAction action, DateTime reviewedAt, DateTime createdAt, DateTime updatedAt, String? reviewNotes
});




}
/// @nodoc
class __$WorkflowItemReviewCopyWithImpl<$Res>
    implements _$WorkflowItemReviewCopyWith<$Res> {
  __$WorkflowItemReviewCopyWithImpl(this._self, this._then);

  final _WorkflowItemReview _self;
  final $Res Function(_WorkflowItemReview) _then;

/// Create a copy of WorkflowItemReview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? userId = null,Object? entityId = null,Object? entityType = null,Object? action = null,Object? reviewedAt = null,Object? createdAt = null,Object? updatedAt = null,Object? reviewNotes = freezed,}) {
  return _then(_WorkflowItemReview(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as WorkflowAction,reviewedAt: null == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reviewNotes: freezed == reviewNotes ? _self.reviewNotes : reviewNotes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$WorkflowProgress {

 int get totalItems; int get completedItems; int get remainingItems; double get percentageComplete; Duration get timeElapsed;
/// Create a copy of WorkflowProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkflowProgressCopyWith<WorkflowProgress> get copyWith => _$WorkflowProgressCopyWithImpl<WorkflowProgress>(this as WorkflowProgress, _$identity);

  /// Serializes this WorkflowProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowProgress&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.completedItems, completedItems) || other.completedItems == completedItems)&&(identical(other.remainingItems, remainingItems) || other.remainingItems == remainingItems)&&(identical(other.percentageComplete, percentageComplete) || other.percentageComplete == percentageComplete)&&(identical(other.timeElapsed, timeElapsed) || other.timeElapsed == timeElapsed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalItems,completedItems,remainingItems,percentageComplete,timeElapsed);

@override
String toString() {
  return 'WorkflowProgress(totalItems: $totalItems, completedItems: $completedItems, remainingItems: $remainingItems, percentageComplete: $percentageComplete, timeElapsed: $timeElapsed)';
}


}

/// @nodoc
abstract mixin class $WorkflowProgressCopyWith<$Res>  {
  factory $WorkflowProgressCopyWith(WorkflowProgress value, $Res Function(WorkflowProgress) _then) = _$WorkflowProgressCopyWithImpl;
@useResult
$Res call({
 int totalItems, int completedItems, int remainingItems, double percentageComplete, Duration timeElapsed
});




}
/// @nodoc
class _$WorkflowProgressCopyWithImpl<$Res>
    implements $WorkflowProgressCopyWith<$Res> {
  _$WorkflowProgressCopyWithImpl(this._self, this._then);

  final WorkflowProgress _self;
  final $Res Function(WorkflowProgress) _then;

/// Create a copy of WorkflowProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalItems = null,Object? completedItems = null,Object? remainingItems = null,Object? percentageComplete = null,Object? timeElapsed = null,}) {
  return _then(_self.copyWith(
totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,completedItems: null == completedItems ? _self.completedItems : completedItems // ignore: cast_nullable_to_non_nullable
as int,remainingItems: null == remainingItems ? _self.remainingItems : remainingItems // ignore: cast_nullable_to_non_nullable
as int,percentageComplete: null == percentageComplete ? _self.percentageComplete : percentageComplete // ignore: cast_nullable_to_non_nullable
as double,timeElapsed: null == timeElapsed ? _self.timeElapsed : timeElapsed // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkflowProgress].
extension WorkflowProgressPatterns on WorkflowProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkflowProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkflowProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkflowProgress value)  $default,){
final _that = this;
switch (_that) {
case _WorkflowProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkflowProgress value)?  $default,){
final _that = this;
switch (_that) {
case _WorkflowProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalItems,  int completedItems,  int remainingItems,  double percentageComplete,  Duration timeElapsed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkflowProgress() when $default != null:
return $default(_that.totalItems,_that.completedItems,_that.remainingItems,_that.percentageComplete,_that.timeElapsed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalItems,  int completedItems,  int remainingItems,  double percentageComplete,  Duration timeElapsed)  $default,) {final _that = this;
switch (_that) {
case _WorkflowProgress():
return $default(_that.totalItems,_that.completedItems,_that.remainingItems,_that.percentageComplete,_that.timeElapsed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalItems,  int completedItems,  int remainingItems,  double percentageComplete,  Duration timeElapsed)?  $default,) {final _that = this;
switch (_that) {
case _WorkflowProgress() when $default != null:
return $default(_that.totalItems,_that.completedItems,_that.remainingItems,_that.percentageComplete,_that.timeElapsed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkflowProgress implements WorkflowProgress {
  const _WorkflowProgress({required this.totalItems, required this.completedItems, required this.remainingItems, required this.percentageComplete, required this.timeElapsed});
  factory _WorkflowProgress.fromJson(Map<String, dynamic> json) => _$WorkflowProgressFromJson(json);

@override final  int totalItems;
@override final  int completedItems;
@override final  int remainingItems;
@override final  double percentageComplete;
@override final  Duration timeElapsed;

/// Create a copy of WorkflowProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkflowProgressCopyWith<_WorkflowProgress> get copyWith => __$WorkflowProgressCopyWithImpl<_WorkflowProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkflowProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkflowProgress&&(identical(other.totalItems, totalItems) || other.totalItems == totalItems)&&(identical(other.completedItems, completedItems) || other.completedItems == completedItems)&&(identical(other.remainingItems, remainingItems) || other.remainingItems == remainingItems)&&(identical(other.percentageComplete, percentageComplete) || other.percentageComplete == percentageComplete)&&(identical(other.timeElapsed, timeElapsed) || other.timeElapsed == timeElapsed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalItems,completedItems,remainingItems,percentageComplete,timeElapsed);

@override
String toString() {
  return 'WorkflowProgress(totalItems: $totalItems, completedItems: $completedItems, remainingItems: $remainingItems, percentageComplete: $percentageComplete, timeElapsed: $timeElapsed)';
}


}

/// @nodoc
abstract mixin class _$WorkflowProgressCopyWith<$Res> implements $WorkflowProgressCopyWith<$Res> {
  factory _$WorkflowProgressCopyWith(_WorkflowProgress value, $Res Function(_WorkflowProgress) _then) = __$WorkflowProgressCopyWithImpl;
@override @useResult
$Res call({
 int totalItems, int completedItems, int remainingItems, double percentageComplete, Duration timeElapsed
});




}
/// @nodoc
class __$WorkflowProgressCopyWithImpl<$Res>
    implements _$WorkflowProgressCopyWith<$Res> {
  __$WorkflowProgressCopyWithImpl(this._self, this._then);

  final _WorkflowProgress _self;
  final $Res Function(_WorkflowProgress) _then;

/// Create a copy of WorkflowProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalItems = null,Object? completedItems = null,Object? remainingItems = null,Object? percentageComplete = null,Object? timeElapsed = null,}) {
  return _then(_WorkflowProgress(
totalItems: null == totalItems ? _self.totalItems : totalItems // ignore: cast_nullable_to_non_nullable
as int,completedItems: null == completedItems ? _self.completedItems : completedItems // ignore: cast_nullable_to_non_nullable
as int,remainingItems: null == remainingItems ? _self.remainingItems : remainingItems // ignore: cast_nullable_to_non_nullable
as int,percentageComplete: null == percentageComplete ? _self.percentageComplete : percentageComplete // ignore: cast_nullable_to_non_nullable
as double,timeElapsed: null == timeElapsed ? _self.timeElapsed : timeElapsed // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

// dart format on
