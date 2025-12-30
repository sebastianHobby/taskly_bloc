// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'problem_acknowledgment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProblemAcknowledgment {

 String get id; String get userId; ProblemType get problemType; String get entityId; EntityType get entityType; DateTime get acknowledgedAt; DateTime get createdAt; DateTime get updatedAt; ResolutionAction? get resolutionAction; DateTime? get snoozeUntil;
/// Create a copy of ProblemAcknowledgment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProblemAcknowledgmentCopyWith<ProblemAcknowledgment> get copyWith => _$ProblemAcknowledgmentCopyWithImpl<ProblemAcknowledgment>(this as ProblemAcknowledgment, _$identity);

  /// Serializes this ProblemAcknowledgment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProblemAcknowledgment&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.problemType, problemType) || other.problemType == problemType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.acknowledgedAt, acknowledgedAt) || other.acknowledgedAt == acknowledgedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.resolutionAction, resolutionAction) || other.resolutionAction == resolutionAction)&&(identical(other.snoozeUntil, snoozeUntil) || other.snoozeUntil == snoozeUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,problemType,entityId,entityType,acknowledgedAt,createdAt,updatedAt,resolutionAction,snoozeUntil);

@override
String toString() {
  return 'ProblemAcknowledgment(id: $id, userId: $userId, problemType: $problemType, entityId: $entityId, entityType: $entityType, acknowledgedAt: $acknowledgedAt, createdAt: $createdAt, updatedAt: $updatedAt, resolutionAction: $resolutionAction, snoozeUntil: $snoozeUntil)';
}


}

/// @nodoc
abstract mixin class $ProblemAcknowledgmentCopyWith<$Res>  {
  factory $ProblemAcknowledgmentCopyWith(ProblemAcknowledgment value, $Res Function(ProblemAcknowledgment) _then) = _$ProblemAcknowledgmentCopyWithImpl;
@useResult
$Res call({
 String id, String userId, ProblemType problemType, String entityId, EntityType entityType, DateTime acknowledgedAt, DateTime createdAt, DateTime updatedAt, ResolutionAction? resolutionAction, DateTime? snoozeUntil
});




}
/// @nodoc
class _$ProblemAcknowledgmentCopyWithImpl<$Res>
    implements $ProblemAcknowledgmentCopyWith<$Res> {
  _$ProblemAcknowledgmentCopyWithImpl(this._self, this._then);

  final ProblemAcknowledgment _self;
  final $Res Function(ProblemAcknowledgment) _then;

/// Create a copy of ProblemAcknowledgment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? problemType = null,Object? entityId = null,Object? entityType = null,Object? acknowledgedAt = null,Object? createdAt = null,Object? updatedAt = null,Object? resolutionAction = freezed,Object? snoozeUntil = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,problemType: null == problemType ? _self.problemType : problemType // ignore: cast_nullable_to_non_nullable
as ProblemType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,acknowledgedAt: null == acknowledgedAt ? _self.acknowledgedAt : acknowledgedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,resolutionAction: freezed == resolutionAction ? _self.resolutionAction : resolutionAction // ignore: cast_nullable_to_non_nullable
as ResolutionAction?,snoozeUntil: freezed == snoozeUntil ? _self.snoozeUntil : snoozeUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProblemAcknowledgment].
extension ProblemAcknowledgmentPatterns on ProblemAcknowledgment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProblemAcknowledgment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProblemAcknowledgment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProblemAcknowledgment value)  $default,){
final _that = this;
switch (_that) {
case _ProblemAcknowledgment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProblemAcknowledgment value)?  $default,){
final _that = this;
switch (_that) {
case _ProblemAcknowledgment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  ProblemType problemType,  String entityId,  EntityType entityType,  DateTime acknowledgedAt,  DateTime createdAt,  DateTime updatedAt,  ResolutionAction? resolutionAction,  DateTime? snoozeUntil)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProblemAcknowledgment() when $default != null:
return $default(_that.id,_that.userId,_that.problemType,_that.entityId,_that.entityType,_that.acknowledgedAt,_that.createdAt,_that.updatedAt,_that.resolutionAction,_that.snoozeUntil);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  ProblemType problemType,  String entityId,  EntityType entityType,  DateTime acknowledgedAt,  DateTime createdAt,  DateTime updatedAt,  ResolutionAction? resolutionAction,  DateTime? snoozeUntil)  $default,) {final _that = this;
switch (_that) {
case _ProblemAcknowledgment():
return $default(_that.id,_that.userId,_that.problemType,_that.entityId,_that.entityType,_that.acknowledgedAt,_that.createdAt,_that.updatedAt,_that.resolutionAction,_that.snoozeUntil);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  ProblemType problemType,  String entityId,  EntityType entityType,  DateTime acknowledgedAt,  DateTime createdAt,  DateTime updatedAt,  ResolutionAction? resolutionAction,  DateTime? snoozeUntil)?  $default,) {final _that = this;
switch (_that) {
case _ProblemAcknowledgment() when $default != null:
return $default(_that.id,_that.userId,_that.problemType,_that.entityId,_that.entityType,_that.acknowledgedAt,_that.createdAt,_that.updatedAt,_that.resolutionAction,_that.snoozeUntil);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProblemAcknowledgment implements ProblemAcknowledgment {
  const _ProblemAcknowledgment({required this.id, required this.userId, required this.problemType, required this.entityId, required this.entityType, required this.acknowledgedAt, required this.createdAt, required this.updatedAt, this.resolutionAction, this.snoozeUntil});
  factory _ProblemAcknowledgment.fromJson(Map<String, dynamic> json) => _$ProblemAcknowledgmentFromJson(json);

@override final  String id;
@override final  String userId;
@override final  ProblemType problemType;
@override final  String entityId;
@override final  EntityType entityType;
@override final  DateTime acknowledgedAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  ResolutionAction? resolutionAction;
@override final  DateTime? snoozeUntil;

/// Create a copy of ProblemAcknowledgment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProblemAcknowledgmentCopyWith<_ProblemAcknowledgment> get copyWith => __$ProblemAcknowledgmentCopyWithImpl<_ProblemAcknowledgment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProblemAcknowledgmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProblemAcknowledgment&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.problemType, problemType) || other.problemType == problemType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.acknowledgedAt, acknowledgedAt) || other.acknowledgedAt == acknowledgedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.resolutionAction, resolutionAction) || other.resolutionAction == resolutionAction)&&(identical(other.snoozeUntil, snoozeUntil) || other.snoozeUntil == snoozeUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,problemType,entityId,entityType,acknowledgedAt,createdAt,updatedAt,resolutionAction,snoozeUntil);

@override
String toString() {
  return 'ProblemAcknowledgment(id: $id, userId: $userId, problemType: $problemType, entityId: $entityId, entityType: $entityType, acknowledgedAt: $acknowledgedAt, createdAt: $createdAt, updatedAt: $updatedAt, resolutionAction: $resolutionAction, snoozeUntil: $snoozeUntil)';
}


}

/// @nodoc
abstract mixin class _$ProblemAcknowledgmentCopyWith<$Res> implements $ProblemAcknowledgmentCopyWith<$Res> {
  factory _$ProblemAcknowledgmentCopyWith(_ProblemAcknowledgment value, $Res Function(_ProblemAcknowledgment) _then) = __$ProblemAcknowledgmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, ProblemType problemType, String entityId, EntityType entityType, DateTime acknowledgedAt, DateTime createdAt, DateTime updatedAt, ResolutionAction? resolutionAction, DateTime? snoozeUntil
});




}
/// @nodoc
class __$ProblemAcknowledgmentCopyWithImpl<$Res>
    implements _$ProblemAcknowledgmentCopyWith<$Res> {
  __$ProblemAcknowledgmentCopyWithImpl(this._self, this._then);

  final _ProblemAcknowledgment _self;
  final $Res Function(_ProblemAcknowledgment) _then;

/// Create a copy of ProblemAcknowledgment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? problemType = null,Object? entityId = null,Object? entityType = null,Object? acknowledgedAt = null,Object? createdAt = null,Object? updatedAt = null,Object? resolutionAction = freezed,Object? snoozeUntil = freezed,}) {
  return _then(_ProblemAcknowledgment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,problemType: null == problemType ? _self.problemType : problemType // ignore: cast_nullable_to_non_nullable
as ProblemType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,acknowledgedAt: null == acknowledgedAt ? _self.acknowledgedAt : acknowledgedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,resolutionAction: freezed == resolutionAction ? _self.resolutionAction : resolutionAction // ignore: cast_nullable_to_non_nullable
as ResolutionAction?,snoozeUntil: freezed == snoozeUntil ? _self.snoozeUntil : snoozeUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$DetectedProblem {

 ProblemType get type; String get entityId; EntityType get entityType; String get title; String get description; String get suggestedAction; bool? get isAcknowledged; DateTime? get acknowledgedAt;
/// Create a copy of DetectedProblem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DetectedProblemCopyWith<DetectedProblem> get copyWith => _$DetectedProblemCopyWithImpl<DetectedProblem>(this as DetectedProblem, _$identity);

  /// Serializes this DetectedProblem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DetectedProblem&&(identical(other.type, type) || other.type == type)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.suggestedAction, suggestedAction) || other.suggestedAction == suggestedAction)&&(identical(other.isAcknowledged, isAcknowledged) || other.isAcknowledged == isAcknowledged)&&(identical(other.acknowledgedAt, acknowledgedAt) || other.acknowledgedAt == acknowledgedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,entityId,entityType,title,description,suggestedAction,isAcknowledged,acknowledgedAt);

@override
String toString() {
  return 'DetectedProblem(type: $type, entityId: $entityId, entityType: $entityType, title: $title, description: $description, suggestedAction: $suggestedAction, isAcknowledged: $isAcknowledged, acknowledgedAt: $acknowledgedAt)';
}


}

/// @nodoc
abstract mixin class $DetectedProblemCopyWith<$Res>  {
  factory $DetectedProblemCopyWith(DetectedProblem value, $Res Function(DetectedProblem) _then) = _$DetectedProblemCopyWithImpl;
@useResult
$Res call({
 ProblemType type, String entityId, EntityType entityType, String title, String description, String suggestedAction, bool? isAcknowledged, DateTime? acknowledgedAt
});




}
/// @nodoc
class _$DetectedProblemCopyWithImpl<$Res>
    implements $DetectedProblemCopyWith<$Res> {
  _$DetectedProblemCopyWithImpl(this._self, this._then);

  final DetectedProblem _self;
  final $Res Function(DetectedProblem) _then;

/// Create a copy of DetectedProblem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? entityId = null,Object? entityType = null,Object? title = null,Object? description = null,Object? suggestedAction = null,Object? isAcknowledged = freezed,Object? acknowledgedAt = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ProblemType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,suggestedAction: null == suggestedAction ? _self.suggestedAction : suggestedAction // ignore: cast_nullable_to_non_nullable
as String,isAcknowledged: freezed == isAcknowledged ? _self.isAcknowledged : isAcknowledged // ignore: cast_nullable_to_non_nullable
as bool?,acknowledgedAt: freezed == acknowledgedAt ? _self.acknowledgedAt : acknowledgedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [DetectedProblem].
extension DetectedProblemPatterns on DetectedProblem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DetectedProblem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DetectedProblem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DetectedProblem value)  $default,){
final _that = this;
switch (_that) {
case _DetectedProblem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DetectedProblem value)?  $default,){
final _that = this;
switch (_that) {
case _DetectedProblem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ProblemType type,  String entityId,  EntityType entityType,  String title,  String description,  String suggestedAction,  bool? isAcknowledged,  DateTime? acknowledgedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DetectedProblem() when $default != null:
return $default(_that.type,_that.entityId,_that.entityType,_that.title,_that.description,_that.suggestedAction,_that.isAcknowledged,_that.acknowledgedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ProblemType type,  String entityId,  EntityType entityType,  String title,  String description,  String suggestedAction,  bool? isAcknowledged,  DateTime? acknowledgedAt)  $default,) {final _that = this;
switch (_that) {
case _DetectedProblem():
return $default(_that.type,_that.entityId,_that.entityType,_that.title,_that.description,_that.suggestedAction,_that.isAcknowledged,_that.acknowledgedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ProblemType type,  String entityId,  EntityType entityType,  String title,  String description,  String suggestedAction,  bool? isAcknowledged,  DateTime? acknowledgedAt)?  $default,) {final _that = this;
switch (_that) {
case _DetectedProblem() when $default != null:
return $default(_that.type,_that.entityId,_that.entityType,_that.title,_that.description,_that.suggestedAction,_that.isAcknowledged,_that.acknowledgedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DetectedProblem implements DetectedProblem {
  const _DetectedProblem({required this.type, required this.entityId, required this.entityType, required this.title, required this.description, required this.suggestedAction, this.isAcknowledged, this.acknowledgedAt});
  factory _DetectedProblem.fromJson(Map<String, dynamic> json) => _$DetectedProblemFromJson(json);

@override final  ProblemType type;
@override final  String entityId;
@override final  EntityType entityType;
@override final  String title;
@override final  String description;
@override final  String suggestedAction;
@override final  bool? isAcknowledged;
@override final  DateTime? acknowledgedAt;

/// Create a copy of DetectedProblem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DetectedProblemCopyWith<_DetectedProblem> get copyWith => __$DetectedProblemCopyWithImpl<_DetectedProblem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DetectedProblemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DetectedProblem&&(identical(other.type, type) || other.type == type)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.suggestedAction, suggestedAction) || other.suggestedAction == suggestedAction)&&(identical(other.isAcknowledged, isAcknowledged) || other.isAcknowledged == isAcknowledged)&&(identical(other.acknowledgedAt, acknowledgedAt) || other.acknowledgedAt == acknowledgedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,entityId,entityType,title,description,suggestedAction,isAcknowledged,acknowledgedAt);

@override
String toString() {
  return 'DetectedProblem(type: $type, entityId: $entityId, entityType: $entityType, title: $title, description: $description, suggestedAction: $suggestedAction, isAcknowledged: $isAcknowledged, acknowledgedAt: $acknowledgedAt)';
}


}

/// @nodoc
abstract mixin class _$DetectedProblemCopyWith<$Res> implements $DetectedProblemCopyWith<$Res> {
  factory _$DetectedProblemCopyWith(_DetectedProblem value, $Res Function(_DetectedProblem) _then) = __$DetectedProblemCopyWithImpl;
@override @useResult
$Res call({
 ProblemType type, String entityId, EntityType entityType, String title, String description, String suggestedAction, bool? isAcknowledged, DateTime? acknowledgedAt
});




}
/// @nodoc
class __$DetectedProblemCopyWithImpl<$Res>
    implements _$DetectedProblemCopyWith<$Res> {
  __$DetectedProblemCopyWithImpl(this._self, this._then);

  final _DetectedProblem _self;
  final $Res Function(_DetectedProblem) _then;

/// Create a copy of DetectedProblem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? entityId = null,Object? entityType = null,Object? title = null,Object? description = null,Object? suggestedAction = null,Object? isAcknowledged = freezed,Object? acknowledgedAt = freezed,}) {
  return _then(_DetectedProblem(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ProblemType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,suggestedAction: null == suggestedAction ? _self.suggestedAction : suggestedAction // ignore: cast_nullable_to_non_nullable
as String,isAcknowledged: freezed == isAcknowledged ? _self.isAcknowledged : isAcknowledged // ignore: cast_nullable_to_non_nullable
as bool?,acknowledgedAt: freezed == acknowledgedAt ? _self.acknowledgedAt : acknowledgedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
