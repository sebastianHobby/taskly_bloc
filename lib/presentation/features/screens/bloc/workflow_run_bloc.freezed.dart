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
mixin _$WorkflowRunEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowRunEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Started value)?  started,TResult Function( _ItemActionRequested value)?  itemActionRequested,TResult Function( _CompleteRequested value)?  completeRequested,TResult Function( _AbandonRequested value)?  abandonRequested,TResult Function( _SessionUpdated value)?  sessionUpdated,TResult Function( _ReviewsUpdated value)?  reviewsUpdated,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Started() when started != null:
return started(_that);case _ItemActionRequested() when itemActionRequested != null:
return itemActionRequested(_that);case _CompleteRequested() when completeRequested != null:
return completeRequested(_that);case _AbandonRequested() when abandonRequested != null:
return abandonRequested(_that);case _SessionUpdated() when sessionUpdated != null:
return sessionUpdated(_that);case _ReviewsUpdated() when reviewsUpdated != null:
return reviewsUpdated(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Started value)  started,required TResult Function( _ItemActionRequested value)  itemActionRequested,required TResult Function( _CompleteRequested value)  completeRequested,required TResult Function( _AbandonRequested value)  abandonRequested,required TResult Function( _SessionUpdated value)  sessionUpdated,required TResult Function( _ReviewsUpdated value)  reviewsUpdated,}){
final _that = this;
switch (_that) {
case _Started():
return started(_that);case _ItemActionRequested():
return itemActionRequested(_that);case _CompleteRequested():
return completeRequested(_that);case _AbandonRequested():
return abandonRequested(_that);case _SessionUpdated():
return sessionUpdated(_that);case _ReviewsUpdated():
return reviewsUpdated(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Started value)?  started,TResult? Function( _ItemActionRequested value)?  itemActionRequested,TResult? Function( _CompleteRequested value)?  completeRequested,TResult? Function( _AbandonRequested value)?  abandonRequested,TResult? Function( _SessionUpdated value)?  sessionUpdated,TResult? Function( _ReviewsUpdated value)?  reviewsUpdated,}){
final _that = this;
switch (_that) {
case _Started() when started != null:
return started(_that);case _ItemActionRequested() when itemActionRequested != null:
return itemActionRequested(_that);case _CompleteRequested() when completeRequested != null:
return completeRequested(_that);case _AbandonRequested() when abandonRequested != null:
return abandonRequested(_that);case _SessionUpdated() when sessionUpdated != null:
return sessionUpdated(_that);case _ReviewsUpdated() when reviewsUpdated != null:
return reviewsUpdated(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function( String entityId,  EntityType entityType,  WorkflowAction action)?  itemActionRequested,TResult Function()?  completeRequested,TResult Function()?  abandonRequested,TResult Function( WorkflowSession? session)?  sessionUpdated,TResult Function( List<WorkflowItemReview> reviews)?  reviewsUpdated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Started() when started != null:
return started();case _ItemActionRequested() when itemActionRequested != null:
return itemActionRequested(_that.entityId,_that.entityType,_that.action);case _CompleteRequested() when completeRequested != null:
return completeRequested();case _AbandonRequested() when abandonRequested != null:
return abandonRequested();case _SessionUpdated() when sessionUpdated != null:
return sessionUpdated(_that.session);case _ReviewsUpdated() when reviewsUpdated != null:
return reviewsUpdated(_that.reviews);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function( String entityId,  EntityType entityType,  WorkflowAction action)  itemActionRequested,required TResult Function()  completeRequested,required TResult Function()  abandonRequested,required TResult Function( WorkflowSession? session)  sessionUpdated,required TResult Function( List<WorkflowItemReview> reviews)  reviewsUpdated,}) {final _that = this;
switch (_that) {
case _Started():
return started();case _ItemActionRequested():
return itemActionRequested(_that.entityId,_that.entityType,_that.action);case _CompleteRequested():
return completeRequested();case _AbandonRequested():
return abandonRequested();case _SessionUpdated():
return sessionUpdated(_that.session);case _ReviewsUpdated():
return reviewsUpdated(_that.reviews);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function( String entityId,  EntityType entityType,  WorkflowAction action)?  itemActionRequested,TResult? Function()?  completeRequested,TResult? Function()?  abandonRequested,TResult? Function( WorkflowSession? session)?  sessionUpdated,TResult? Function( List<WorkflowItemReview> reviews)?  reviewsUpdated,}) {final _that = this;
switch (_that) {
case _Started() when started != null:
return started();case _ItemActionRequested() when itemActionRequested != null:
return itemActionRequested(_that.entityId,_that.entityType,_that.action);case _CompleteRequested() when completeRequested != null:
return completeRequested();case _AbandonRequested() when abandonRequested != null:
return abandonRequested();case _SessionUpdated() when sessionUpdated != null:
return sessionUpdated(_that.session);case _ReviewsUpdated() when reviewsUpdated != null:
return reviewsUpdated(_that.reviews);case _:
  return null;

}
}

}

/// @nodoc


class _Started implements WorkflowRunEvent {
  const _Started();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Started);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WorkflowRunEvent.started()';
}


}




/// @nodoc


class _ItemActionRequested implements WorkflowRunEvent {
  const _ItemActionRequested({required this.entityId, required this.entityType, required this.action});
  

 final  String entityId;
 final  EntityType entityType;
 final  WorkflowAction action;

/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemActionRequestedCopyWith<_ItemActionRequested> get copyWith => __$ItemActionRequestedCopyWithImpl<_ItemActionRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemActionRequested&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode => Object.hash(runtimeType,entityId,entityType,action);

@override
String toString() {
  return 'WorkflowRunEvent.itemActionRequested(entityId: $entityId, entityType: $entityType, action: $action)';
}


}

/// @nodoc
abstract mixin class _$ItemActionRequestedCopyWith<$Res> implements $WorkflowRunEventCopyWith<$Res> {
  factory _$ItemActionRequestedCopyWith(_ItemActionRequested value, $Res Function(_ItemActionRequested) _then) = __$ItemActionRequestedCopyWithImpl;
@useResult
$Res call({
 String entityId, EntityType entityType, WorkflowAction action
});




}
/// @nodoc
class __$ItemActionRequestedCopyWithImpl<$Res>
    implements _$ItemActionRequestedCopyWith<$Res> {
  __$ItemActionRequestedCopyWithImpl(this._self, this._then);

  final _ItemActionRequested _self;
  final $Res Function(_ItemActionRequested) _then;

/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entityId = null,Object? entityType = null,Object? action = null,}) {
  return _then(_ItemActionRequested(
entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as WorkflowAction,
  ));
}


}

/// @nodoc


class _CompleteRequested implements WorkflowRunEvent {
  const _CompleteRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompleteRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WorkflowRunEvent.completeRequested()';
}


}




/// @nodoc


class _AbandonRequested implements WorkflowRunEvent {
  const _AbandonRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AbandonRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WorkflowRunEvent.abandonRequested()';
}


}




/// @nodoc


class _SessionUpdated implements WorkflowRunEvent {
  const _SessionUpdated({this.session});
  

 final  WorkflowSession? session;

/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionUpdatedCopyWith<_SessionUpdated> get copyWith => __$SessionUpdatedCopyWithImpl<_SessionUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionUpdated&&(identical(other.session, session) || other.session == session));
}


@override
int get hashCode => Object.hash(runtimeType,session);

@override
String toString() {
  return 'WorkflowRunEvent.sessionUpdated(session: $session)';
}


}

/// @nodoc
abstract mixin class _$SessionUpdatedCopyWith<$Res> implements $WorkflowRunEventCopyWith<$Res> {
  factory _$SessionUpdatedCopyWith(_SessionUpdated value, $Res Function(_SessionUpdated) _then) = __$SessionUpdatedCopyWithImpl;
@useResult
$Res call({
 WorkflowSession? session
});


$WorkflowSessionCopyWith<$Res>? get session;

}
/// @nodoc
class __$SessionUpdatedCopyWithImpl<$Res>
    implements _$SessionUpdatedCopyWith<$Res> {
  __$SessionUpdatedCopyWithImpl(this._self, this._then);

  final _SessionUpdated _self;
  final $Res Function(_SessionUpdated) _then;

/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = freezed,}) {
  return _then(_SessionUpdated(
session: freezed == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as WorkflowSession?,
  ));
}

/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkflowSessionCopyWith<$Res>? get session {
    if (_self.session == null) {
    return null;
  }

  return $WorkflowSessionCopyWith<$Res>(_self.session!, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

/// @nodoc


class _ReviewsUpdated implements WorkflowRunEvent {
  const _ReviewsUpdated({required final  List<WorkflowItemReview> reviews}): _reviews = reviews;
  

 final  List<WorkflowItemReview> _reviews;
 List<WorkflowItemReview> get reviews {
  if (_reviews is EqualUnmodifiableListView) return _reviews;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reviews);
}


/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewsUpdatedCopyWith<_ReviewsUpdated> get copyWith => __$ReviewsUpdatedCopyWithImpl<_ReviewsUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewsUpdated&&const DeepCollectionEquality().equals(other._reviews, _reviews));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_reviews));

@override
String toString() {
  return 'WorkflowRunEvent.reviewsUpdated(reviews: $reviews)';
}


}

/// @nodoc
abstract mixin class _$ReviewsUpdatedCopyWith<$Res> implements $WorkflowRunEventCopyWith<$Res> {
  factory _$ReviewsUpdatedCopyWith(_ReviewsUpdated value, $Res Function(_ReviewsUpdated) _then) = __$ReviewsUpdatedCopyWithImpl;
@useResult
$Res call({
 List<WorkflowItemReview> reviews
});




}
/// @nodoc
class __$ReviewsUpdatedCopyWithImpl<$Res>
    implements _$ReviewsUpdatedCopyWith<$Res> {
  __$ReviewsUpdatedCopyWithImpl(this._self, this._then);

  final _ReviewsUpdated _self;
  final $Res Function(_ReviewsUpdated) _then;

/// Create a copy of WorkflowRunEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reviews = null,}) {
  return _then(_ReviewsUpdated(
reviews: null == reviews ? _self._reviews : reviews // ignore: cast_nullable_to_non_nullable
as List<WorkflowItemReview>,
  ));
}


}

/// @nodoc
mixin _$WorkflowRunState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowRunState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WorkflowRunState()';
}


}

/// @nodoc
class $WorkflowRunStateCopyWith<$Res>  {
$WorkflowRunStateCopyWith(WorkflowRunState _, $Res Function(WorkflowRunState) __);
}


/// Adds pattern-matching-related methods to [WorkflowRunState].
extension WorkflowRunStatePatterns on WorkflowRunState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Loading value)?  loading,TResult Function( _Running value)?  running,TResult Function( _Completed value)?  completed,TResult Function( _Abandoned value)?  abandoned,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Loading() when loading != null:
return loading(_that);case _Running() when running != null:
return running(_that);case _Completed() when completed != null:
return completed(_that);case _Abandoned() when abandoned != null:
return abandoned(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Loading value)  loading,required TResult Function( _Running value)  running,required TResult Function( _Completed value)  completed,required TResult Function( _Abandoned value)  abandoned,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Loading():
return loading(_that);case _Running():
return running(_that);case _Completed():
return completed(_that);case _Abandoned():
return abandoned(_that);case _Error():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Loading value)?  loading,TResult? Function( _Running value)?  running,TResult? Function( _Completed value)?  completed,TResult? Function( _Abandoned value)?  abandoned,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Loading() when loading != null:
return loading(_that);case _Running() when running != null:
return running(_that);case _Completed() when completed != null:
return completed(_that);case _Abandoned() when abandoned != null:
return abandoned(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( WorkflowScreen screen,  WorkflowSession session,  List<WorkflowItemVm> items,  Map<String, WorkflowAction> actionByEntityId)?  running,TResult Function( WorkflowScreen screen,  WorkflowSession session)?  completed,TResult Function( WorkflowScreen screen,  WorkflowSession session)?  abandoned,TResult Function( Object error,  StackTrace stackTrace)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Loading() when loading != null:
return loading();case _Running() when running != null:
return running(_that.screen,_that.session,_that.items,_that.actionByEntityId);case _Completed() when completed != null:
return completed(_that.screen,_that.session);case _Abandoned() when abandoned != null:
return abandoned(_that.screen,_that.session);case _Error() when error != null:
return error(_that.error,_that.stackTrace);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( WorkflowScreen screen,  WorkflowSession session,  List<WorkflowItemVm> items,  Map<String, WorkflowAction> actionByEntityId)  running,required TResult Function( WorkflowScreen screen,  WorkflowSession session)  completed,required TResult Function( WorkflowScreen screen,  WorkflowSession session)  abandoned,required TResult Function( Object error,  StackTrace stackTrace)  error,}) {final _that = this;
switch (_that) {
case _Loading():
return loading();case _Running():
return running(_that.screen,_that.session,_that.items,_that.actionByEntityId);case _Completed():
return completed(_that.screen,_that.session);case _Abandoned():
return abandoned(_that.screen,_that.session);case _Error():
return error(_that.error,_that.stackTrace);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( WorkflowScreen screen,  WorkflowSession session,  List<WorkflowItemVm> items,  Map<String, WorkflowAction> actionByEntityId)?  running,TResult? Function( WorkflowScreen screen,  WorkflowSession session)?  completed,TResult? Function( WorkflowScreen screen,  WorkflowSession session)?  abandoned,TResult? Function( Object error,  StackTrace stackTrace)?  error,}) {final _that = this;
switch (_that) {
case _Loading() when loading != null:
return loading();case _Running() when running != null:
return running(_that.screen,_that.session,_that.items,_that.actionByEntityId);case _Completed() when completed != null:
return completed(_that.screen,_that.session);case _Abandoned() when abandoned != null:
return abandoned(_that.screen,_that.session);case _Error() when error != null:
return error(_that.error,_that.stackTrace);case _:
  return null;

}
}

}

/// @nodoc


class _Loading implements WorkflowRunState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WorkflowRunState.loading()';
}


}




/// @nodoc


class _Running implements WorkflowRunState {
  const _Running({required this.screen, required this.session, required final  List<WorkflowItemVm> items, required final  Map<String, WorkflowAction> actionByEntityId}): _items = items,_actionByEntityId = actionByEntityId;
  

 final  WorkflowScreen screen;
 final  WorkflowSession session;
 final  List<WorkflowItemVm> _items;
 List<WorkflowItemVm> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  Map<String, WorkflowAction> _actionByEntityId;
 Map<String, WorkflowAction> get actionByEntityId {
  if (_actionByEntityId is EqualUnmodifiableMapView) return _actionByEntityId;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_actionByEntityId);
}


/// Create a copy of WorkflowRunState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RunningCopyWith<_Running> get copyWith => __$RunningCopyWithImpl<_Running>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Running&&const DeepCollectionEquality().equals(other.screen, screen)&&(identical(other.session, session) || other.session == session)&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._actionByEntityId, _actionByEntityId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(screen),session,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_actionByEntityId));

@override
String toString() {
  return 'WorkflowRunState.running(screen: $screen, session: $session, items: $items, actionByEntityId: $actionByEntityId)';
}


}

/// @nodoc
abstract mixin class _$RunningCopyWith<$Res> implements $WorkflowRunStateCopyWith<$Res> {
  factory _$RunningCopyWith(_Running value, $Res Function(_Running) _then) = __$RunningCopyWithImpl;
@useResult
$Res call({
 WorkflowScreen screen, WorkflowSession session, List<WorkflowItemVm> items, Map<String, WorkflowAction> actionByEntityId
});


$WorkflowSessionCopyWith<$Res> get session;

}
/// @nodoc
class __$RunningCopyWithImpl<$Res>
    implements _$RunningCopyWith<$Res> {
  __$RunningCopyWithImpl(this._self, this._then);

  final _Running _self;
  final $Res Function(_Running) _then;

/// Create a copy of WorkflowRunState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? screen = freezed,Object? session = null,Object? items = null,Object? actionByEntityId = null,}) {
  return _then(_Running(
screen: freezed == screen ? _self.screen : screen // ignore: cast_nullable_to_non_nullable
as WorkflowScreen,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as WorkflowSession,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<WorkflowItemVm>,actionByEntityId: null == actionByEntityId ? _self._actionByEntityId : actionByEntityId // ignore: cast_nullable_to_non_nullable
as Map<String, WorkflowAction>,
  ));
}

/// Create a copy of WorkflowRunState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkflowSessionCopyWith<$Res> get session {
  
  return $WorkflowSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

/// @nodoc


class _Completed implements WorkflowRunState {
  const _Completed({required this.screen, required this.session});
  

 final  WorkflowScreen screen;
 final  WorkflowSession session;

/// Create a copy of WorkflowRunState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompletedCopyWith<_Completed> get copyWith => __$CompletedCopyWithImpl<_Completed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Completed&&const DeepCollectionEquality().equals(other.screen, screen)&&(identical(other.session, session) || other.session == session));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(screen),session);

@override
String toString() {
  return 'WorkflowRunState.completed(screen: $screen, session: $session)';
}


}

/// @nodoc
abstract mixin class _$CompletedCopyWith<$Res> implements $WorkflowRunStateCopyWith<$Res> {
  factory _$CompletedCopyWith(_Completed value, $Res Function(_Completed) _then) = __$CompletedCopyWithImpl;
@useResult
$Res call({
 WorkflowScreen screen, WorkflowSession session
});


$WorkflowSessionCopyWith<$Res> get session;

}
/// @nodoc
class __$CompletedCopyWithImpl<$Res>
    implements _$CompletedCopyWith<$Res> {
  __$CompletedCopyWithImpl(this._self, this._then);

  final _Completed _self;
  final $Res Function(_Completed) _then;

/// Create a copy of WorkflowRunState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? screen = freezed,Object? session = null,}) {
  return _then(_Completed(
screen: freezed == screen ? _self.screen : screen // ignore: cast_nullable_to_non_nullable
as WorkflowScreen,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as WorkflowSession,
  ));
}

/// Create a copy of WorkflowRunState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkflowSessionCopyWith<$Res> get session {
  
  return $WorkflowSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

/// @nodoc


class _Abandoned implements WorkflowRunState {
  const _Abandoned({required this.screen, required this.session});
  

 final  WorkflowScreen screen;
 final  WorkflowSession session;

/// Create a copy of WorkflowRunState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AbandonedCopyWith<_Abandoned> get copyWith => __$AbandonedCopyWithImpl<_Abandoned>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Abandoned&&const DeepCollectionEquality().equals(other.screen, screen)&&(identical(other.session, session) || other.session == session));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(screen),session);

@override
String toString() {
  return 'WorkflowRunState.abandoned(screen: $screen, session: $session)';
}


}

/// @nodoc
abstract mixin class _$AbandonedCopyWith<$Res> implements $WorkflowRunStateCopyWith<$Res> {
  factory _$AbandonedCopyWith(_Abandoned value, $Res Function(_Abandoned) _then) = __$AbandonedCopyWithImpl;
@useResult
$Res call({
 WorkflowScreen screen, WorkflowSession session
});


$WorkflowSessionCopyWith<$Res> get session;

}
/// @nodoc
class __$AbandonedCopyWithImpl<$Res>
    implements _$AbandonedCopyWith<$Res> {
  __$AbandonedCopyWithImpl(this._self, this._then);

  final _Abandoned _self;
  final $Res Function(_Abandoned) _then;

/// Create a copy of WorkflowRunState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? screen = freezed,Object? session = null,}) {
  return _then(_Abandoned(
screen: freezed == screen ? _self.screen : screen // ignore: cast_nullable_to_non_nullable
as WorkflowScreen,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as WorkflowSession,
  ));
}

/// Create a copy of WorkflowRunState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkflowSessionCopyWith<$Res> get session {
  
  return $WorkflowSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

/// @nodoc


class _Error implements WorkflowRunState {
  const _Error({required this.error, required this.stackTrace});
  

 final  Object error;
 final  StackTrace stackTrace;

/// Create a copy of WorkflowRunState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stackTrace);

@override
String toString() {
  return 'WorkflowRunState.error(error: $error, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $WorkflowRunStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace stackTrace
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of WorkflowRunState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stackTrace = null,}) {
  return _then(_Error(
error: null == error ? _self.error : error ,stackTrace: null == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

/// @nodoc
mixin _$WorkflowItemVm {

 String get entityId; EntityType get entityType; String get title;
/// Create a copy of WorkflowItemVm
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkflowItemVmCopyWith<WorkflowItemVm> get copyWith => _$WorkflowItemVmCopyWithImpl<WorkflowItemVm>(this as WorkflowItemVm, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowItemVm&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode => Object.hash(runtimeType,entityId,entityType,title);

@override
String toString() {
  return 'WorkflowItemVm(entityId: $entityId, entityType: $entityType, title: $title)';
}


}

/// @nodoc
abstract mixin class $WorkflowItemVmCopyWith<$Res>  {
  factory $WorkflowItemVmCopyWith(WorkflowItemVm value, $Res Function(WorkflowItemVm) _then) = _$WorkflowItemVmCopyWithImpl;
@useResult
$Res call({
 String entityId, EntityType entityType, String title
});




}
/// @nodoc
class _$WorkflowItemVmCopyWithImpl<$Res>
    implements $WorkflowItemVmCopyWith<$Res> {
  _$WorkflowItemVmCopyWithImpl(this._self, this._then);

  final WorkflowItemVm _self;
  final $Res Function(WorkflowItemVm) _then;

/// Create a copy of WorkflowItemVm
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entityId = null,Object? entityType = null,Object? title = null,}) {
  return _then(_self.copyWith(
entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkflowItemVm].
extension WorkflowItemVmPatterns on WorkflowItemVm {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkflowItemVm value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkflowItemVm() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkflowItemVm value)  $default,){
final _that = this;
switch (_that) {
case _WorkflowItemVm():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkflowItemVm value)?  $default,){
final _that = this;
switch (_that) {
case _WorkflowItemVm() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String entityId,  EntityType entityType,  String title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkflowItemVm() when $default != null:
return $default(_that.entityId,_that.entityType,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String entityId,  EntityType entityType,  String title)  $default,) {final _that = this;
switch (_that) {
case _WorkflowItemVm():
return $default(_that.entityId,_that.entityType,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String entityId,  EntityType entityType,  String title)?  $default,) {final _that = this;
switch (_that) {
case _WorkflowItemVm() when $default != null:
return $default(_that.entityId,_that.entityType,_that.title);case _:
  return null;

}
}

}

/// @nodoc


class _WorkflowItemVm implements WorkflowItemVm {
  const _WorkflowItemVm({required this.entityId, required this.entityType, required this.title});
  

@override final  String entityId;
@override final  EntityType entityType;
@override final  String title;

/// Create a copy of WorkflowItemVm
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkflowItemVmCopyWith<_WorkflowItemVm> get copyWith => __$WorkflowItemVmCopyWithImpl<_WorkflowItemVm>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkflowItemVm&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.title, title) || other.title == title));
}


@override
int get hashCode => Object.hash(runtimeType,entityId,entityType,title);

@override
String toString() {
  return 'WorkflowItemVm(entityId: $entityId, entityType: $entityType, title: $title)';
}


}

/// @nodoc
abstract mixin class _$WorkflowItemVmCopyWith<$Res> implements $WorkflowItemVmCopyWith<$Res> {
  factory _$WorkflowItemVmCopyWith(_WorkflowItemVm value, $Res Function(_WorkflowItemVm) _then) = __$WorkflowItemVmCopyWithImpl;
@override @useResult
$Res call({
 String entityId, EntityType entityType, String title
});




}
/// @nodoc
class __$WorkflowItemVmCopyWithImpl<$Res>
    implements _$WorkflowItemVmCopyWith<$Res> {
  __$WorkflowItemVmCopyWithImpl(this._self, this._then);

  final _WorkflowItemVm _self;
  final $Res Function(_WorkflowItemVm) _then;

/// Create a copy of WorkflowItemVm
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entityId = null,Object? entityType = null,Object? title = null,}) {
  return _then(_WorkflowItemVm(
entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
