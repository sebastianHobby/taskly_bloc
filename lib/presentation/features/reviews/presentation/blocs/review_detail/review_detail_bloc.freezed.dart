// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_detail_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReviewDetailEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewDetailEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReviewDetailEvent()';
}


}

/// @nodoc
class $ReviewDetailEventCopyWith<$Res>  {
$ReviewDetailEventCopyWith(ReviewDetailEvent _, $Res Function(ReviewDetailEvent) __);
}


/// Adds pattern-matching-related methods to [ReviewDetailEvent].
extension ReviewDetailEventPatterns on ReviewDetailEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Load value)?  load,TResult Function( _LoadEntities value)?  loadEntities,TResult Function( _ExecuteAction value)?  executeAction,TResult Function( _CompleteReview value)?  completeReview,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Load() when load != null:
return load(_that);case _LoadEntities() when loadEntities != null:
return loadEntities(_that);case _ExecuteAction() when executeAction != null:
return executeAction(_that);case _CompleteReview() when completeReview != null:
return completeReview(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Load value)  load,required TResult Function( _LoadEntities value)  loadEntities,required TResult Function( _ExecuteAction value)  executeAction,required TResult Function( _CompleteReview value)  completeReview,}){
final _that = this;
switch (_that) {
case _Load():
return load(_that);case _LoadEntities():
return loadEntities(_that);case _ExecuteAction():
return executeAction(_that);case _CompleteReview():
return completeReview(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Load value)?  load,TResult? Function( _LoadEntities value)?  loadEntities,TResult? Function( _ExecuteAction value)?  executeAction,TResult? Function( _CompleteReview value)?  completeReview,}){
final _that = this;
switch (_that) {
case _Load() when load != null:
return load(_that);case _LoadEntities() when loadEntities != null:
return loadEntities(_that);case _ExecuteAction() when executeAction != null:
return executeAction(_that);case _CompleteReview() when completeReview != null:
return completeReview(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String reviewId)?  load,TResult Function()?  loadEntities,TResult Function( String entityId,  ReviewAction action)?  executeAction,TResult Function()?  completeReview,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Load() when load != null:
return load(_that.reviewId);case _LoadEntities() when loadEntities != null:
return loadEntities();case _ExecuteAction() when executeAction != null:
return executeAction(_that.entityId,_that.action);case _CompleteReview() when completeReview != null:
return completeReview();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String reviewId)  load,required TResult Function()  loadEntities,required TResult Function( String entityId,  ReviewAction action)  executeAction,required TResult Function()  completeReview,}) {final _that = this;
switch (_that) {
case _Load():
return load(_that.reviewId);case _LoadEntities():
return loadEntities();case _ExecuteAction():
return executeAction(_that.entityId,_that.action);case _CompleteReview():
return completeReview();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String reviewId)?  load,TResult? Function()?  loadEntities,TResult? Function( String entityId,  ReviewAction action)?  executeAction,TResult? Function()?  completeReview,}) {final _that = this;
switch (_that) {
case _Load() when load != null:
return load(_that.reviewId);case _LoadEntities() when loadEntities != null:
return loadEntities();case _ExecuteAction() when executeAction != null:
return executeAction(_that.entityId,_that.action);case _CompleteReview() when completeReview != null:
return completeReview();case _:
  return null;

}
}

}

/// @nodoc


class _Load implements ReviewDetailEvent {
  const _Load(this.reviewId);
  

 final  String reviewId;

/// Create a copy of ReviewDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadCopyWith<_Load> get copyWith => __$LoadCopyWithImpl<_Load>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Load&&(identical(other.reviewId, reviewId) || other.reviewId == reviewId));
}


@override
int get hashCode => Object.hash(runtimeType,reviewId);

@override
String toString() {
  return 'ReviewDetailEvent.load(reviewId: $reviewId)';
}


}

/// @nodoc
abstract mixin class _$LoadCopyWith<$Res> implements $ReviewDetailEventCopyWith<$Res> {
  factory _$LoadCopyWith(_Load value, $Res Function(_Load) _then) = __$LoadCopyWithImpl;
@useResult
$Res call({
 String reviewId
});




}
/// @nodoc
class __$LoadCopyWithImpl<$Res>
    implements _$LoadCopyWith<$Res> {
  __$LoadCopyWithImpl(this._self, this._then);

  final _Load _self;
  final $Res Function(_Load) _then;

/// Create a copy of ReviewDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reviewId = null,}) {
  return _then(_Load(
null == reviewId ? _self.reviewId : reviewId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _LoadEntities implements ReviewDetailEvent {
  const _LoadEntities();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadEntities);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReviewDetailEvent.loadEntities()';
}


}




/// @nodoc


class _ExecuteAction implements ReviewDetailEvent {
  const _ExecuteAction({required this.entityId, required this.action});
  

 final  String entityId;
 final  ReviewAction action;

/// Create a copy of ReviewDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExecuteActionCopyWith<_ExecuteAction> get copyWith => __$ExecuteActionCopyWithImpl<_ExecuteAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExecuteAction&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.action, action) || other.action == action));
}


@override
int get hashCode => Object.hash(runtimeType,entityId,action);

@override
String toString() {
  return 'ReviewDetailEvent.executeAction(entityId: $entityId, action: $action)';
}


}

/// @nodoc
abstract mixin class _$ExecuteActionCopyWith<$Res> implements $ReviewDetailEventCopyWith<$Res> {
  factory _$ExecuteActionCopyWith(_ExecuteAction value, $Res Function(_ExecuteAction) _then) = __$ExecuteActionCopyWithImpl;
@useResult
$Res call({
 String entityId, ReviewAction action
});


$ReviewActionCopyWith<$Res> get action;

}
/// @nodoc
class __$ExecuteActionCopyWithImpl<$Res>
    implements _$ExecuteActionCopyWith<$Res> {
  __$ExecuteActionCopyWithImpl(this._self, this._then);

  final _ExecuteAction _self;
  final $Res Function(_ExecuteAction) _then;

/// Create a copy of ReviewDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entityId = null,Object? action = null,}) {
  return _then(_ExecuteAction(
entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as ReviewAction,
  ));
}

/// Create a copy of ReviewDetailEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewActionCopyWith<$Res> get action {
  
  return $ReviewActionCopyWith<$Res>(_self.action, (value) {
    return _then(_self.copyWith(action: value));
  });
}
}

/// @nodoc


class _CompleteReview implements ReviewDetailEvent {
  const _CompleteReview();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompleteReview);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReviewDetailEvent.completeReview()';
}


}




/// @nodoc
mixin _$ReviewDetailState {

 Review? get review; List<Task> get tasks; List<Project> get projects; Map<String, ReviewAction> get actions; bool get isLoading; bool get isExecutingActions; String? get error;
/// Create a copy of ReviewDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewDetailStateCopyWith<ReviewDetailState> get copyWith => _$ReviewDetailStateCopyWithImpl<ReviewDetailState>(this as ReviewDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewDetailState&&(identical(other.review, review) || other.review == review)&&const DeepCollectionEquality().equals(other.tasks, tasks)&&const DeepCollectionEquality().equals(other.projects, projects)&&const DeepCollectionEquality().equals(other.actions, actions)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isExecutingActions, isExecutingActions) || other.isExecutingActions == isExecutingActions)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,review,const DeepCollectionEquality().hash(tasks),const DeepCollectionEquality().hash(projects),const DeepCollectionEquality().hash(actions),isLoading,isExecutingActions,error);

@override
String toString() {
  return 'ReviewDetailState(review: $review, tasks: $tasks, projects: $projects, actions: $actions, isLoading: $isLoading, isExecutingActions: $isExecutingActions, error: $error)';
}


}

/// @nodoc
abstract mixin class $ReviewDetailStateCopyWith<$Res>  {
  factory $ReviewDetailStateCopyWith(ReviewDetailState value, $Res Function(ReviewDetailState) _then) = _$ReviewDetailStateCopyWithImpl;
@useResult
$Res call({
 Review? review, List<Task> tasks, List<Project> projects, Map<String, ReviewAction> actions, bool isLoading, bool isExecutingActions, String? error
});


$ReviewCopyWith<$Res>? get review;

}
/// @nodoc
class _$ReviewDetailStateCopyWithImpl<$Res>
    implements $ReviewDetailStateCopyWith<$Res> {
  _$ReviewDetailStateCopyWithImpl(this._self, this._then);

  final ReviewDetailState _self;
  final $Res Function(ReviewDetailState) _then;

/// Create a copy of ReviewDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? review = freezed,Object? tasks = null,Object? projects = null,Object? actions = null,Object? isLoading = null,Object? isExecutingActions = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
review: freezed == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as Review?,tasks: null == tasks ? _self.tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<Task>,projects: null == projects ? _self.projects : projects // ignore: cast_nullable_to_non_nullable
as List<Project>,actions: null == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as Map<String, ReviewAction>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isExecutingActions: null == isExecutingActions ? _self.isExecutingActions : isExecutingActions // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ReviewDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewCopyWith<$Res>? get review {
    if (_self.review == null) {
    return null;
  }

  return $ReviewCopyWith<$Res>(_self.review!, (value) {
    return _then(_self.copyWith(review: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReviewDetailState].
extension ReviewDetailStatePatterns on ReviewDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewDetailState value)  $default,){
final _that = this;
switch (_that) {
case _ReviewDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Review? review,  List<Task> tasks,  List<Project> projects,  Map<String, ReviewAction> actions,  bool isLoading,  bool isExecutingActions,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewDetailState() when $default != null:
return $default(_that.review,_that.tasks,_that.projects,_that.actions,_that.isLoading,_that.isExecutingActions,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Review? review,  List<Task> tasks,  List<Project> projects,  Map<String, ReviewAction> actions,  bool isLoading,  bool isExecutingActions,  String? error)  $default,) {final _that = this;
switch (_that) {
case _ReviewDetailState():
return $default(_that.review,_that.tasks,_that.projects,_that.actions,_that.isLoading,_that.isExecutingActions,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Review? review,  List<Task> tasks,  List<Project> projects,  Map<String, ReviewAction> actions,  bool isLoading,  bool isExecutingActions,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _ReviewDetailState() when $default != null:
return $default(_that.review,_that.tasks,_that.projects,_that.actions,_that.isLoading,_that.isExecutingActions,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _ReviewDetailState implements ReviewDetailState {
  const _ReviewDetailState({this.review, final  List<Task> tasks = const [], final  List<Project> projects = const [], final  Map<String, ReviewAction> actions = const {}, this.isLoading = true, this.isExecutingActions = false, this.error}): _tasks = tasks,_projects = projects,_actions = actions;
  

@override final  Review? review;
 final  List<Task> _tasks;
@override@JsonKey() List<Task> get tasks {
  if (_tasks is EqualUnmodifiableListView) return _tasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasks);
}

 final  List<Project> _projects;
@override@JsonKey() List<Project> get projects {
  if (_projects is EqualUnmodifiableListView) return _projects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_projects);
}

 final  Map<String, ReviewAction> _actions;
@override@JsonKey() Map<String, ReviewAction> get actions {
  if (_actions is EqualUnmodifiableMapView) return _actions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_actions);
}

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isExecutingActions;
@override final  String? error;

/// Create a copy of ReviewDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewDetailStateCopyWith<_ReviewDetailState> get copyWith => __$ReviewDetailStateCopyWithImpl<_ReviewDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewDetailState&&(identical(other.review, review) || other.review == review)&&const DeepCollectionEquality().equals(other._tasks, _tasks)&&const DeepCollectionEquality().equals(other._projects, _projects)&&const DeepCollectionEquality().equals(other._actions, _actions)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isExecutingActions, isExecutingActions) || other.isExecutingActions == isExecutingActions)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,review,const DeepCollectionEquality().hash(_tasks),const DeepCollectionEquality().hash(_projects),const DeepCollectionEquality().hash(_actions),isLoading,isExecutingActions,error);

@override
String toString() {
  return 'ReviewDetailState(review: $review, tasks: $tasks, projects: $projects, actions: $actions, isLoading: $isLoading, isExecutingActions: $isExecutingActions, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ReviewDetailStateCopyWith<$Res> implements $ReviewDetailStateCopyWith<$Res> {
  factory _$ReviewDetailStateCopyWith(_ReviewDetailState value, $Res Function(_ReviewDetailState) _then) = __$ReviewDetailStateCopyWithImpl;
@override @useResult
$Res call({
 Review? review, List<Task> tasks, List<Project> projects, Map<String, ReviewAction> actions, bool isLoading, bool isExecutingActions, String? error
});


@override $ReviewCopyWith<$Res>? get review;

}
/// @nodoc
class __$ReviewDetailStateCopyWithImpl<$Res>
    implements _$ReviewDetailStateCopyWith<$Res> {
  __$ReviewDetailStateCopyWithImpl(this._self, this._then);

  final _ReviewDetailState _self;
  final $Res Function(_ReviewDetailState) _then;

/// Create a copy of ReviewDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? review = freezed,Object? tasks = null,Object? projects = null,Object? actions = null,Object? isLoading = null,Object? isExecutingActions = null,Object? error = freezed,}) {
  return _then(_ReviewDetailState(
review: freezed == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as Review?,tasks: null == tasks ? _self._tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<Task>,projects: null == projects ? _self._projects : projects // ignore: cast_nullable_to_non_nullable
as List<Project>,actions: null == actions ? _self._actions : actions // ignore: cast_nullable_to_non_nullable
as Map<String, ReviewAction>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isExecutingActions: null == isExecutingActions ? _self.isExecutingActions : isExecutingActions // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ReviewDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewCopyWith<$Res>? get review {
    if (_self.review == null) {
    return null;
  }

  return $ReviewCopyWith<$Res>(_self.review!, (value) {
    return _then(_self.copyWith(review: value));
  });
}
}

// dart format on
