// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tasks_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TasksEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TasksEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TasksEvent()';
}


}

/// @nodoc
class $TasksEventCopyWith<$Res>  {
$TasksEventCopyWith(TasksEvent _, $Res Function(TasksEvent) __);
}


/// Adds pattern-matching-related methods to [TasksEvent].
extension TasksEventPatterns on TasksEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TasksSubscriptionRequested value)?  tasksSubscriptionRequested,TResult Function( TasksUpdateTask value)?  updateTask,TResult Function( TasksDeleteTask value)?  deleteTask,TResult Function( TasksCreateTask value)?  createTask,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TasksSubscriptionRequested() when tasksSubscriptionRequested != null:
return tasksSubscriptionRequested(_that);case TasksUpdateTask() when updateTask != null:
return updateTask(_that);case TasksDeleteTask() when deleteTask != null:
return deleteTask(_that);case TasksCreateTask() when createTask != null:
return createTask(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TasksSubscriptionRequested value)  tasksSubscriptionRequested,required TResult Function( TasksUpdateTask value)  updateTask,required TResult Function( TasksDeleteTask value)  deleteTask,required TResult Function( TasksCreateTask value)  createTask,}){
final _that = this;
switch (_that) {
case TasksSubscriptionRequested():
return tasksSubscriptionRequested(_that);case TasksUpdateTask():
return updateTask(_that);case TasksDeleteTask():
return deleteTask(_that);case TasksCreateTask():
return createTask(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TasksSubscriptionRequested value)?  tasksSubscriptionRequested,TResult? Function( TasksUpdateTask value)?  updateTask,TResult? Function( TasksDeleteTask value)?  deleteTask,TResult? Function( TasksCreateTask value)?  createTask,}){
final _that = this;
switch (_that) {
case TasksSubscriptionRequested() when tasksSubscriptionRequested != null:
return tasksSubscriptionRequested(_that);case TasksUpdateTask() when updateTask != null:
return updateTask(_that);case TasksDeleteTask() when deleteTask != null:
return deleteTask(_that);case TasksCreateTask() when createTask != null:
return createTask(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  tasksSubscriptionRequested,TResult Function( TaskUpdateRequest updateRequest)?  updateTask,TResult Function( TaskDeleteRequest deleteRequest)?  deleteTask,TResult Function( TaskCreateRequest createRequest)?  createTask,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TasksSubscriptionRequested() when tasksSubscriptionRequested != null:
return tasksSubscriptionRequested();case TasksUpdateTask() when updateTask != null:
return updateTask(_that.updateRequest);case TasksDeleteTask() when deleteTask != null:
return deleteTask(_that.deleteRequest);case TasksCreateTask() when createTask != null:
return createTask(_that.createRequest);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  tasksSubscriptionRequested,required TResult Function( TaskUpdateRequest updateRequest)  updateTask,required TResult Function( TaskDeleteRequest deleteRequest)  deleteTask,required TResult Function( TaskCreateRequest createRequest)  createTask,}) {final _that = this;
switch (_that) {
case TasksSubscriptionRequested():
return tasksSubscriptionRequested();case TasksUpdateTask():
return updateTask(_that.updateRequest);case TasksDeleteTask():
return deleteTask(_that.deleteRequest);case TasksCreateTask():
return createTask(_that.createRequest);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  tasksSubscriptionRequested,TResult? Function( TaskUpdateRequest updateRequest)?  updateTask,TResult? Function( TaskDeleteRequest deleteRequest)?  deleteTask,TResult? Function( TaskCreateRequest createRequest)?  createTask,}) {final _that = this;
switch (_that) {
case TasksSubscriptionRequested() when tasksSubscriptionRequested != null:
return tasksSubscriptionRequested();case TasksUpdateTask() when updateTask != null:
return updateTask(_that.updateRequest);case TasksDeleteTask() when deleteTask != null:
return deleteTask(_that.deleteRequest);case TasksCreateTask() when createTask != null:
return createTask(_that.createRequest);case _:
  return null;

}
}

}

/// @nodoc


class TasksSubscriptionRequested implements TasksEvent {
  const TasksSubscriptionRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TasksSubscriptionRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TasksEvent.tasksSubscriptionRequested()';
}


}




/// @nodoc


class TasksUpdateTask implements TasksEvent {
  const TasksUpdateTask({required this.updateRequest});
  

 final  TaskUpdateRequest updateRequest;

/// Create a copy of TasksEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TasksUpdateTaskCopyWith<TasksUpdateTask> get copyWith => _$TasksUpdateTaskCopyWithImpl<TasksUpdateTask>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TasksUpdateTask&&const DeepCollectionEquality().equals(other.updateRequest, updateRequest));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(updateRequest));

@override
String toString() {
  return 'TasksEvent.updateTask(updateRequest: $updateRequest)';
}


}

/// @nodoc
abstract mixin class $TasksUpdateTaskCopyWith<$Res> implements $TasksEventCopyWith<$Res> {
  factory $TasksUpdateTaskCopyWith(TasksUpdateTask value, $Res Function(TasksUpdateTask) _then) = _$TasksUpdateTaskCopyWithImpl;
@useResult
$Res call({
 TaskUpdateRequest updateRequest
});




}
/// @nodoc
class _$TasksUpdateTaskCopyWithImpl<$Res>
    implements $TasksUpdateTaskCopyWith<$Res> {
  _$TasksUpdateTaskCopyWithImpl(this._self, this._then);

  final TasksUpdateTask _self;
  final $Res Function(TasksUpdateTask) _then;

/// Create a copy of TasksEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? updateRequest = freezed,}) {
  return _then(TasksUpdateTask(
updateRequest: freezed == updateRequest ? _self.updateRequest : updateRequest // ignore: cast_nullable_to_non_nullable
as TaskUpdateRequest,
  ));
}


}

/// @nodoc


class TasksDeleteTask implements TasksEvent {
  const TasksDeleteTask({required this.deleteRequest});
  

 final  TaskDeleteRequest deleteRequest;

/// Create a copy of TasksEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TasksDeleteTaskCopyWith<TasksDeleteTask> get copyWith => _$TasksDeleteTaskCopyWithImpl<TasksDeleteTask>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TasksDeleteTask&&const DeepCollectionEquality().equals(other.deleteRequest, deleteRequest));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(deleteRequest));

@override
String toString() {
  return 'TasksEvent.deleteTask(deleteRequest: $deleteRequest)';
}


}

/// @nodoc
abstract mixin class $TasksDeleteTaskCopyWith<$Res> implements $TasksEventCopyWith<$Res> {
  factory $TasksDeleteTaskCopyWith(TasksDeleteTask value, $Res Function(TasksDeleteTask) _then) = _$TasksDeleteTaskCopyWithImpl;
@useResult
$Res call({
 TaskDeleteRequest deleteRequest
});




}
/// @nodoc
class _$TasksDeleteTaskCopyWithImpl<$Res>
    implements $TasksDeleteTaskCopyWith<$Res> {
  _$TasksDeleteTaskCopyWithImpl(this._self, this._then);

  final TasksDeleteTask _self;
  final $Res Function(TasksDeleteTask) _then;

/// Create a copy of TasksEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? deleteRequest = freezed,}) {
  return _then(TasksDeleteTask(
deleteRequest: freezed == deleteRequest ? _self.deleteRequest : deleteRequest // ignore: cast_nullable_to_non_nullable
as TaskDeleteRequest,
  ));
}


}

/// @nodoc


class TasksCreateTask implements TasksEvent {
  const TasksCreateTask({required this.createRequest});
  

 final  TaskCreateRequest createRequest;

/// Create a copy of TasksEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TasksCreateTaskCopyWith<TasksCreateTask> get copyWith => _$TasksCreateTaskCopyWithImpl<TasksCreateTask>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TasksCreateTask&&const DeepCollectionEquality().equals(other.createRequest, createRequest));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(createRequest));

@override
String toString() {
  return 'TasksEvent.createTask(createRequest: $createRequest)';
}


}

/// @nodoc
abstract mixin class $TasksCreateTaskCopyWith<$Res> implements $TasksEventCopyWith<$Res> {
  factory $TasksCreateTaskCopyWith(TasksCreateTask value, $Res Function(TasksCreateTask) _then) = _$TasksCreateTaskCopyWithImpl;
@useResult
$Res call({
 TaskCreateRequest createRequest
});




}
/// @nodoc
class _$TasksCreateTaskCopyWithImpl<$Res>
    implements $TasksCreateTaskCopyWith<$Res> {
  _$TasksCreateTaskCopyWithImpl(this._self, this._then);

  final TasksCreateTask _self;
  final $Res Function(TasksCreateTask) _then;

/// Create a copy of TasksEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? createRequest = freezed,}) {
  return _then(TasksCreateTask(
createRequest: freezed == createRequest ? _self.createRequest : createRequest // ignore: cast_nullable_to_non_nullable
as TaskCreateRequest,
  ));
}


}

/// @nodoc
mixin _$TasksState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TasksState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TasksState()';
}


}

/// @nodoc
class $TasksStateCopyWith<$Res>  {
$TasksStateCopyWith(TasksState _, $Res Function(TasksState) __);
}


/// Adds pattern-matching-related methods to [TasksState].
extension TasksStatePatterns on TasksState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TasksInitial value)?  initial,TResult Function( TasksLoading value)?  loading,TResult Function( TasksLoaded value)?  loaded,TResult Function( TasksError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TasksInitial() when initial != null:
return initial(_that);case TasksLoading() when loading != null:
return loading(_that);case TasksLoaded() when loaded != null:
return loaded(_that);case TasksError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TasksInitial value)  initial,required TResult Function( TasksLoading value)  loading,required TResult Function( TasksLoaded value)  loaded,required TResult Function( TasksError value)  error,}){
final _that = this;
switch (_that) {
case TasksInitial():
return initial(_that);case TasksLoading():
return loading(_that);case TasksLoaded():
return loaded(_that);case TasksError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TasksInitial value)?  initial,TResult? Function( TasksLoading value)?  loading,TResult? Function( TasksLoaded value)?  loaded,TResult? Function( TasksError value)?  error,}){
final _that = this;
switch (_that) {
case TasksInitial() when initial != null:
return initial(_that);case TasksLoading() when loading != null:
return loading(_that);case TasksLoaded() when loaded != null:
return loaded(_that);case TasksError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<TaskDto> tasks)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TasksInitial() when initial != null:
return initial();case TasksLoading() when loading != null:
return loading();case TasksLoaded() when loaded != null:
return loaded(_that.tasks);case TasksError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<TaskDto> tasks)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case TasksInitial():
return initial();case TasksLoading():
return loading();case TasksLoaded():
return loaded(_that.tasks);case TasksError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<TaskDto> tasks)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case TasksInitial() when initial != null:
return initial();case TasksLoading() when loading != null:
return loading();case TasksLoaded() when loaded != null:
return loaded(_that.tasks);case TasksError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class TasksInitial implements TasksState {
  const TasksInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TasksInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TasksState.initial()';
}


}




/// @nodoc


class TasksLoading implements TasksState {
  const TasksLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TasksLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TasksState.loading()';
}


}




/// @nodoc


class TasksLoaded implements TasksState {
  const TasksLoaded({required final  List<TaskDto> tasks}): _tasks = tasks;
  

 final  List<TaskDto> _tasks;
 List<TaskDto> get tasks {
  if (_tasks is EqualUnmodifiableListView) return _tasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasks);
}


/// Create a copy of TasksState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TasksLoadedCopyWith<TasksLoaded> get copyWith => _$TasksLoadedCopyWithImpl<TasksLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TasksLoaded&&const DeepCollectionEquality().equals(other._tasks, _tasks));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tasks));

@override
String toString() {
  return 'TasksState.loaded(tasks: $tasks)';
}


}

/// @nodoc
abstract mixin class $TasksLoadedCopyWith<$Res> implements $TasksStateCopyWith<$Res> {
  factory $TasksLoadedCopyWith(TasksLoaded value, $Res Function(TasksLoaded) _then) = _$TasksLoadedCopyWithImpl;
@useResult
$Res call({
 List<TaskDto> tasks
});




}
/// @nodoc
class _$TasksLoadedCopyWithImpl<$Res>
    implements $TasksLoadedCopyWith<$Res> {
  _$TasksLoadedCopyWithImpl(this._self, this._then);

  final TasksLoaded _self;
  final $Res Function(TasksLoaded) _then;

/// Create a copy of TasksState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tasks = null,}) {
  return _then(TasksLoaded(
tasks: null == tasks ? _self._tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<TaskDto>,
  ));
}


}

/// @nodoc


class TasksError implements TasksState {
  const TasksError({required this.message});
  

 final  String message;

/// Create a copy of TasksState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TasksErrorCopyWith<TasksError> get copyWith => _$TasksErrorCopyWithImpl<TasksError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TasksError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'TasksState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $TasksErrorCopyWith<$Res> implements $TasksStateCopyWith<$Res> {
  factory $TasksErrorCopyWith(TasksError value, $Res Function(TasksError) _then) = _$TasksErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$TasksErrorCopyWithImpl<$Res>
    implements $TasksErrorCopyWith<$Res> {
  _$TasksErrorCopyWithImpl(this._self, this._then);

  final TasksError _self;
  final $Res Function(TasksError) _then;

/// Create a copy of TasksState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(TasksError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
