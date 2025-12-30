// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workflow_run_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WorkflowRunEvent implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'WorkflowRunEvent'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowRunEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'WorkflowRunEvent()';
}


}

/// @nodoc
class $WorkflowRunEventCopyWith<$Res>  {
$WorkflowRunEventCopyWith(WorkflowRunEvent _, $Res Function(WorkflowRunEvent) __);
}


/// Adds pattern-matching-related methods to [WorkflowRunEvent].
extension WorkflowRunEventPatterns on WorkflowRunEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Started value)?  started,TResult Function( _ItemMarkedReviewed value)?  itemMarkedReviewed,TResult Function( _ItemSkipped value)?  itemSkipped,TResult Function( _NextItemRequested value)?  nextItemRequested,TResult Function( _PreviousItemRequested value)?  previousItemRequested,TResult Function( _ItemJumpedTo value)?  itemJumpedTo,TResult Function( _WorkflowCompleted value)?  workflowCompleted,TResult Function( _ProblemAcknowledged value)?  problemAcknowledged,TResult Function( _ProblemSnoozed value)?  problemSnoozed,TResult Function( _ProblemDismissed value)?  problemDismissed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Started() when started != null:
return started(_that);case _ItemMarkedReviewed() when itemMarkedReviewed != null:
return itemMarkedReviewed(_that);case _ItemSkipped() when itemSkipped != null:
return itemSkipped(_that);case _NextItemRequested() when nextItemRequested != null:
return nextItemRequested(_that);case _PreviousItemRequested() when previousItemRequested != null:
return previousItemRequested(_that);case _ItemJumpedTo() when itemJumpedTo != null:
return itemJumpedTo(_that);case _WorkflowCompleted() when workflowCompleted != null:
return workflowCompleted(_that);case _ProblemAcknowledged() when problemAcknowledged != null:
return problemAcknowledged(_that);case _ProblemSnoozed() when problemSnoozed != null:
return problemSnoozed(_that);case _ProblemDismissed() when problemDismissed != null:
return problemDismissed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Started value)  started,required TResult Function( _ItemMarkedReviewed value)  itemMarkedReviewed,required TResult Function( _ItemSkipped value)  itemSkipped,required TResult Function( _NextItemRequested value)  nextItemRequested,required TResult Function( _PreviousItemRequested value)  previousItemRequested,required TResult Function( _ItemJumpedTo value)  itemJumpedTo,required TResult Function( _WorkflowCompleted value)  workflowCompleted,required TResult Function( _ProblemAcknowledged value)  problemAcknowledged,required TResult Function( _ProblemSnoozed value)  problemSnoozed,required TResult Function( _ProblemDismissed value)  problemDismissed,}){
final _that = this;
switch (_that) {
case _Started():
return started(_that);case _ItemMarkedReviewed():
return itemMarkedReviewed(_that);case _ItemSkipped():
return itemSkipped(_that);case _NextItemRequested():
return nextItemRequested(_that);case _PreviousItemRequested():
return previousItemRequested(_that);case _ItemJumpedTo():
return itemJumpedTo(_that);case _WorkflowCompleted():
return workflowCompleted(_that);case _ProblemAcknowledged():
return problemAcknowledged(_that);case _ProblemSnoozed():
return problemSnoozed(_that);case _ProblemDismissed():
return problemDismissed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Started value)?  started,TResult? Function( _ItemMarkedReviewed value)?  itemMarkedReviewed,TResult? Function( _ItemSkipped value)?  itemSkipped,TResult? Function( _NextItemRequested value)?  nextItemRequested,TResult? Function( _PreviousItemRequested value)?  previousItemRequested,TResult? Function( _ItemJumpedTo value)?  itemJumpedTo,TResult? Function( _WorkflowCompleted value)?  workflowCompleted,TResult? Function( _ProblemAcknowledged value)?  problemAcknowledged,TResult? Function( _ProblemSnoozed value)?  problemSnoozed,TResult? Function( _ProblemDismissed value)?  problemDismissed,}){
final _that = this;
switch (_that) {
case _Started() when started != null:
return started(_that);case _ItemMarkedReviewed() when itemMarkedReviewed != null:
return itemMarkedReviewed(_that);case _ItemSkipped() when itemSkipped != null:
return itemSkipped(_that);case _NextItemRequested() when nextItemRequested != null:
return nextItemRequested(_that);case _PreviousItemRequested() when previousItemRequested != null:
return previousItemRequested(_that);case _ItemJumpedTo() when itemJumpedTo != null:
return itemJumpedTo(_that);case _WorkflowCompleted() when workflowCompleted != null:
return workflowCompleted(_that);case _ProblemAcknowledged() when problemAcknowledged != null:
return problemAcknowledged(_that);case _ProblemSnoozed() when problemSnoozed != null:
return problemSnoozed(_that);case _ProblemDismissed() when problemDismissed != null:
return problemDismissed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function( String entityId,  String? notes)?  itemMarkedReviewed,TResult Function( String entityId,  String? reason)?  itemSkipped,TResult Function()?  nextItemRequested,TResult Function()?  previousItemRequested,TResult Function( int index)?  itemJumpedTo,TResult Function()?  workflowCompleted,TResult Function( ProblemType problemType,  EntityType entityType,  String entityId)?  problemAcknowledged,TResult Function( ProblemType problemType,  EntityType entityType,  String entityId)?  problemSnoozed,TResult Function( ProblemType problemType,  EntityType entityType,  String entityId)?  problemDismissed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Started() when started != null:
return started();case _ItemMarkedReviewed() when itemMarkedReviewed != null:
return itemMarkedReviewed(_that.entityId,_that.notes);case _ItemSkipped() when itemSkipped != null:
return itemSkipped(_that.entityId,_that.reason);case _NextItemRequested() when nextItemRequested != null:
return nextItemRequested();case _PreviousItemRequested() when previousItemRequested != null:
return previousItemRequested();case _ItemJumpedTo() when itemJumpedTo != null:
return itemJumpedTo(_that.index);case _WorkflowCompleted() when workflowCompleted != null:
return workflowCompleted();case _ProblemAcknowledged() when problemAcknowledged != null:
return problemAcknowledged(_that.problemType,_that.entityType,_that.entityId);case _ProblemSnoozed() when problemSnoozed != null:
return problemSnoozed(_that.problemType,_that.entityType,_that.entityId);case _ProblemDismissed() when problemDismissed != null:
return problemDismissed(_that.problemType,_that.entityType,_that.entityId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function( String entityId,  String? notes)  itemMarkedReviewed,required TResult Function( String entityId,  String? reason)  itemSkipped,required TResult Function()  nextItemRequested,required TResult Function()  previousItemRequested,required TResult Function( int index)  itemJumpedTo,required TResult Function()  workflowCompleted,required TResult Function( ProblemType problemType,  EntityType entityType,  String entityId)  problemAcknowledged,required TResult Function( ProblemType problemType,  EntityType entityType,  String entityId)  problemSnoozed,required TResult Function( ProblemType problemType,  EntityType entityType,  String entityId)  problemDismissed,}) {final _that = this;
switch (_that) {
case _Started():
return started();case _ItemMarkedReviewed():
return itemMarkedReviewed(_that.entityId,_that.notes);case _ItemSkipped():
return itemSkipped(_that.entityId,_that.reason);case _NextItemRequested():
return nextItemRequested();case _PreviousItemRequested():
return previousItemRequested();case _ItemJumpedTo():
return itemJumpedTo(_that.index);case _WorkflowCompleted():
return workflowCompleted();case _ProblemAcknowledged():
return problemAcknowledged(_that.problemType,_that.entityType,_that.entityId);case _ProblemSnoozed():
return problemSnoozed(_that.problemType,_that.entityType,_that.entityId);case _ProblemDismissed():
return problemDismissed(_that.problemType,_that.entityType,_that.entityId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function( String entityId,  String? notes)?  itemMarkedReviewed,TResult? Function( String entityId,  String? reason)?  itemSkipped,TResult? Function()?  nextItemRequested,TResult? Function()?  previousItemRequested,TResult? Function( int index)?  itemJumpedTo,TResult? Function()?  workflowCompleted,TResult? Function( ProblemType problemType,  EntityType entityType,  String entityId)?  problemAcknowledged,TResult? Function( ProblemType problemType,  EntityType entityType,  String entityId)?  problemSnoozed,TResult? Function( ProblemType problemType,  EntityType entityType,  String entityId)?  problemDismissed,}) {final _that = this;
switch (_that) {
case _Started() when started != null:
return started();case _ItemMarkedReviewed() when itemMarkedReviewed != null:
return itemMarkedReviewed(_that.entityId,_that.notes);case _ItemSkipped() when itemSkipped != null:
return itemSkipped(_that.entityId,_that.reason);case _NextItemRequested() when nextItemRequested != null:
return nextItemRequested();case _PreviousItemRequested() when previousItemRequested != null:
return previousItemRequested();case _ItemJumpedTo() when itemJumpedTo != null:
return itemJumpedTo(_that.index);case _WorkflowCompleted() when workflowCompleted != null:
return workflowCompleted();case _ProblemAcknowledged() when problemAcknowledged != null:
return problemAcknowledged(_that.problemType,_that.entityType,_that.entityId);case _ProblemSnoozed() when problemSnoozed != null:
return problemSnoozed(_that.problemType,_that.entityType,_that.entityId);case _ProblemDismissed() when problemDismissed != null:
return problemDismissed(_that.problemType,_that.entityType,_that.entityId);case _:
  return null;

}
}

}

/// @nodoc


class _Started with DiagnosticableTreeMixin implements WorkflowRunEvent {
  const _Started();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'WorkflowRunEvent.started'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Started);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'WorkflowRunEvent.started()';
}


}




/// @nodoc


class _ItemMarkedReviewed with DiagnosticableTreeMixin implements WorkflowRunEvent {
  const _ItemMarkedReviewed({required this.entityId, this.notes});
  

 final  String entityId;
 final  String? notes;

/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemMarkedReviewedCopyWith<_ItemMarkedReviewed> get copyWith => __$ItemMarkedReviewedCopyWithImpl<_ItemMarkedReviewed>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'WorkflowRunEvent.itemMarkedReviewed'))
    ..add(DiagnosticsProperty('entityId', entityId))..add(DiagnosticsProperty('notes', notes));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemMarkedReviewed&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.notes, notes) || other.notes == notes));
}


@override
int get hashCode => Object.hash(runtimeType,entityId,notes);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'WorkflowRunEvent.itemMarkedReviewed(entityId: $entityId, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$ItemMarkedReviewedCopyWith<$Res> implements $WorkflowRunEventCopyWith<$Res> {
  factory _$ItemMarkedReviewedCopyWith(_ItemMarkedReviewed value, $Res Function(_ItemMarkedReviewed) _then) = __$ItemMarkedReviewedCopyWithImpl;
@useResult
$Res call({
 String entityId, String? notes
});




}
/// @nodoc
class __$ItemMarkedReviewedCopyWithImpl<$Res>
    implements _$ItemMarkedReviewedCopyWith<$Res> {
  __$ItemMarkedReviewedCopyWithImpl(this._self, this._then);

  final _ItemMarkedReviewed _self;
  final $Res Function(_ItemMarkedReviewed) _then;

/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entityId = null,Object? notes = freezed,}) {
  return _then(_ItemMarkedReviewed(
entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _ItemSkipped with DiagnosticableTreeMixin implements WorkflowRunEvent {
  const _ItemSkipped({required this.entityId, this.reason});
  

 final  String entityId;
 final  String? reason;

/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemSkippedCopyWith<_ItemSkipped> get copyWith => __$ItemSkippedCopyWithImpl<_ItemSkipped>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'WorkflowRunEvent.itemSkipped'))
    ..add(DiagnosticsProperty('entityId', entityId))..add(DiagnosticsProperty('reason', reason));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemSkipped&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode => Object.hash(runtimeType,entityId,reason);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'WorkflowRunEvent.itemSkipped(entityId: $entityId, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$ItemSkippedCopyWith<$Res> implements $WorkflowRunEventCopyWith<$Res> {
  factory _$ItemSkippedCopyWith(_ItemSkipped value, $Res Function(_ItemSkipped) _then) = __$ItemSkippedCopyWithImpl;
@useResult
$Res call({
 String entityId, String? reason
});




}
/// @nodoc
class __$ItemSkippedCopyWithImpl<$Res>
    implements _$ItemSkippedCopyWith<$Res> {
  __$ItemSkippedCopyWithImpl(this._self, this._then);

  final _ItemSkipped _self;
  final $Res Function(_ItemSkipped) _then;

/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entityId = null,Object? reason = freezed,}) {
  return _then(_ItemSkipped(
entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _NextItemRequested with DiagnosticableTreeMixin implements WorkflowRunEvent {
  const _NextItemRequested();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'WorkflowRunEvent.nextItemRequested'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NextItemRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'WorkflowRunEvent.nextItemRequested()';
}


}




/// @nodoc


class _PreviousItemRequested with DiagnosticableTreeMixin implements WorkflowRunEvent {
  const _PreviousItemRequested();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'WorkflowRunEvent.previousItemRequested'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PreviousItemRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'WorkflowRunEvent.previousItemRequested()';
}


}




/// @nodoc


class _ItemJumpedTo with DiagnosticableTreeMixin implements WorkflowRunEvent {
  const _ItemJumpedTo({required this.index});
  

 final  int index;

/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemJumpedToCopyWith<_ItemJumpedTo> get copyWith => __$ItemJumpedToCopyWithImpl<_ItemJumpedTo>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'WorkflowRunEvent.itemJumpedTo'))
    ..add(DiagnosticsProperty('index', index));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemJumpedTo&&(identical(other.index, index) || other.index == index));
}


@override
int get hashCode => Object.hash(runtimeType,index);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'WorkflowRunEvent.itemJumpedTo(index: $index)';
}


}

/// @nodoc
abstract mixin class _$ItemJumpedToCopyWith<$Res> implements $WorkflowRunEventCopyWith<$Res> {
  factory _$ItemJumpedToCopyWith(_ItemJumpedTo value, $Res Function(_ItemJumpedTo) _then) = __$ItemJumpedToCopyWithImpl;
@useResult
$Res call({
 int index
});




}
/// @nodoc
class __$ItemJumpedToCopyWithImpl<$Res>
    implements _$ItemJumpedToCopyWith<$Res> {
  __$ItemJumpedToCopyWithImpl(this._self, this._then);

  final _ItemJumpedTo _self;
  final $Res Function(_ItemJumpedTo) _then;

/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? index = null,}) {
  return _then(_ItemJumpedTo(
index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class _WorkflowCompleted with DiagnosticableTreeMixin implements WorkflowRunEvent {
  const _WorkflowCompleted();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'WorkflowRunEvent.workflowCompleted'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkflowCompleted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'WorkflowRunEvent.workflowCompleted()';
}


}




/// @nodoc


class _ProblemAcknowledged with DiagnosticableTreeMixin implements WorkflowRunEvent {
  const _ProblemAcknowledged({required this.problemType, required this.entityType, required this.entityId});
  

 final  ProblemType problemType;
 final  EntityType entityType;
 final  String entityId;

/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProblemAcknowledgedCopyWith<_ProblemAcknowledged> get copyWith => __$ProblemAcknowledgedCopyWithImpl<_ProblemAcknowledged>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'WorkflowRunEvent.problemAcknowledged'))
    ..add(DiagnosticsProperty('problemType', problemType))..add(DiagnosticsProperty('entityType', entityType))..add(DiagnosticsProperty('entityId', entityId));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProblemAcknowledged&&(identical(other.problemType, problemType) || other.problemType == problemType)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId));
}


@override
int get hashCode => Object.hash(runtimeType,problemType,entityType,entityId);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'WorkflowRunEvent.problemAcknowledged(problemType: $problemType, entityType: $entityType, entityId: $entityId)';
}


}

/// @nodoc
abstract mixin class _$ProblemAcknowledgedCopyWith<$Res> implements $WorkflowRunEventCopyWith<$Res> {
  factory _$ProblemAcknowledgedCopyWith(_ProblemAcknowledged value, $Res Function(_ProblemAcknowledged) _then) = __$ProblemAcknowledgedCopyWithImpl;
@useResult
$Res call({
 ProblemType problemType, EntityType entityType, String entityId
});




}
/// @nodoc
class __$ProblemAcknowledgedCopyWithImpl<$Res>
    implements _$ProblemAcknowledgedCopyWith<$Res> {
  __$ProblemAcknowledgedCopyWithImpl(this._self, this._then);

  final _ProblemAcknowledged _self;
  final $Res Function(_ProblemAcknowledged) _then;

/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? problemType = null,Object? entityType = null,Object? entityId = null,}) {
  return _then(_ProblemAcknowledged(
problemType: null == problemType ? _self.problemType : problemType // ignore: cast_nullable_to_non_nullable
as ProblemType,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ProblemSnoozed with DiagnosticableTreeMixin implements WorkflowRunEvent {
  const _ProblemSnoozed({required this.problemType, required this.entityType, required this.entityId});
  

 final  ProblemType problemType;
 final  EntityType entityType;
 final  String entityId;

/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProblemSnoozedCopyWith<_ProblemSnoozed> get copyWith => __$ProblemSnoozedCopyWithImpl<_ProblemSnoozed>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'WorkflowRunEvent.problemSnoozed'))
    ..add(DiagnosticsProperty('problemType', problemType))..add(DiagnosticsProperty('entityType', entityType))..add(DiagnosticsProperty('entityId', entityId));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProblemSnoozed&&(identical(other.problemType, problemType) || other.problemType == problemType)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId));
}


@override
int get hashCode => Object.hash(runtimeType,problemType,entityType,entityId);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'WorkflowRunEvent.problemSnoozed(problemType: $problemType, entityType: $entityType, entityId: $entityId)';
}


}

/// @nodoc
abstract mixin class _$ProblemSnoozedCopyWith<$Res> implements $WorkflowRunEventCopyWith<$Res> {
  factory _$ProblemSnoozedCopyWith(_ProblemSnoozed value, $Res Function(_ProblemSnoozed) _then) = __$ProblemSnoozedCopyWithImpl;
@useResult
$Res call({
 ProblemType problemType, EntityType entityType, String entityId
});




}
/// @nodoc
class __$ProblemSnoozedCopyWithImpl<$Res>
    implements _$ProblemSnoozedCopyWith<$Res> {
  __$ProblemSnoozedCopyWithImpl(this._self, this._then);

  final _ProblemSnoozed _self;
  final $Res Function(_ProblemSnoozed) _then;

/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? problemType = null,Object? entityType = null,Object? entityId = null,}) {
  return _then(_ProblemSnoozed(
problemType: null == problemType ? _self.problemType : problemType // ignore: cast_nullable_to_non_nullable
as ProblemType,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ProblemDismissed with DiagnosticableTreeMixin implements WorkflowRunEvent {
  const _ProblemDismissed({required this.problemType, required this.entityType, required this.entityId});
  

 final  ProblemType problemType;
 final  EntityType entityType;
 final  String entityId;

/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProblemDismissedCopyWith<_ProblemDismissed> get copyWith => __$ProblemDismissedCopyWithImpl<_ProblemDismissed>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'WorkflowRunEvent.problemDismissed'))
    ..add(DiagnosticsProperty('problemType', problemType))..add(DiagnosticsProperty('entityType', entityType))..add(DiagnosticsProperty('entityId', entityId));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProblemDismissed&&(identical(other.problemType, problemType) || other.problemType == problemType)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId));
}


@override
int get hashCode => Object.hash(runtimeType,problemType,entityType,entityId);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'WorkflowRunEvent.problemDismissed(problemType: $problemType, entityType: $entityType, entityId: $entityId)';
}


}

/// @nodoc
abstract mixin class _$ProblemDismissedCopyWith<$Res> implements $WorkflowRunEventCopyWith<$Res> {
  factory _$ProblemDismissedCopyWith(_ProblemDismissed value, $Res Function(_ProblemDismissed) _then) = __$ProblemDismissedCopyWithImpl;
@useResult
$Res call({
 ProblemType problemType, EntityType entityType, String entityId
});




}
/// @nodoc
class __$ProblemDismissedCopyWithImpl<$Res>
    implements _$ProblemDismissedCopyWith<$Res> {
  __$ProblemDismissedCopyWithImpl(this._self, this._then);

  final _ProblemDismissed _self;
  final $Res Function(_ProblemDismissed) _then;

/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? problemType = null,Object? entityType = null,Object? entityId = null,}) {
  return _then(_ProblemDismissed(
problemType: null == problemType ? _self.problemType : problemType // ignore: cast_nullable_to_non_nullable
as ProblemType,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
