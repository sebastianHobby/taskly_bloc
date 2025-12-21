// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_list_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskOverviewEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskOverviewEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskOverviewEvent()';
}


}

/// @nodoc
class $TaskOverviewEventCopyWith<$Res>  {
$TaskOverviewEventCopyWith(TaskOverviewEvent _, $Res Function(TaskOverviewEvent) __);
}


/// Adds pattern-matching-related methods to [TaskOverviewEvent].
extension TaskOverviewEventPatterns on TaskOverviewEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TaskOverviewSubscriptionRequested value)?  subscriptionRequested,TResult Function( TaskOverviewQueryChanged value)?  queryChanged,TResult Function( TaskOverviewToggleTaskCompletion value)?  toggleTaskCompletion,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TaskOverviewSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested(_that);case TaskOverviewQueryChanged() when queryChanged != null:
return queryChanged(_that);case TaskOverviewToggleTaskCompletion() when toggleTaskCompletion != null:
return toggleTaskCompletion(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TaskOverviewSubscriptionRequested value)  subscriptionRequested,required TResult Function( TaskOverviewQueryChanged value)  queryChanged,required TResult Function( TaskOverviewToggleTaskCompletion value)  toggleTaskCompletion,}){
final _that = this;
switch (_that) {
case TaskOverviewSubscriptionRequested():
return subscriptionRequested(_that);case TaskOverviewQueryChanged():
return queryChanged(_that);case TaskOverviewToggleTaskCompletion():
return toggleTaskCompletion(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TaskOverviewSubscriptionRequested value)?  subscriptionRequested,TResult? Function( TaskOverviewQueryChanged value)?  queryChanged,TResult? Function( TaskOverviewToggleTaskCompletion value)?  toggleTaskCompletion,}){
final _that = this;
switch (_that) {
case TaskOverviewSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested(_that);case TaskOverviewQueryChanged() when queryChanged != null:
return queryChanged(_that);case TaskOverviewToggleTaskCompletion() when toggleTaskCompletion != null:
return toggleTaskCompletion(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  subscriptionRequested,TResult Function( TaskListQuery query)?  queryChanged,TResult Function( Task task)?  toggleTaskCompletion,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TaskOverviewSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested();case TaskOverviewQueryChanged() when queryChanged != null:
return queryChanged(_that.query);case TaskOverviewToggleTaskCompletion() when toggleTaskCompletion != null:
return toggleTaskCompletion(_that.task);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  subscriptionRequested,required TResult Function( TaskListQuery query)  queryChanged,required TResult Function( Task task)  toggleTaskCompletion,}) {final _that = this;
switch (_that) {
case TaskOverviewSubscriptionRequested():
return subscriptionRequested();case TaskOverviewQueryChanged():
return queryChanged(_that.query);case TaskOverviewToggleTaskCompletion():
return toggleTaskCompletion(_that.task);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  subscriptionRequested,TResult? Function( TaskListQuery query)?  queryChanged,TResult? Function( Task task)?  toggleTaskCompletion,}) {final _that = this;
switch (_that) {
case TaskOverviewSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested();case TaskOverviewQueryChanged() when queryChanged != null:
return queryChanged(_that.query);case TaskOverviewToggleTaskCompletion() when toggleTaskCompletion != null:
return toggleTaskCompletion(_that.task);case _:
  return null;

}
}

}

/// @nodoc


class TaskOverviewSubscriptionRequested implements TaskOverviewEvent {
  const TaskOverviewSubscriptionRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskOverviewSubscriptionRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskOverviewEvent.subscriptionRequested()';
}


}




/// @nodoc


class TaskOverviewQueryChanged implements TaskOverviewEvent {
  const TaskOverviewQueryChanged({required this.query});
  

 final  TaskListQuery query;

/// Create a copy of TaskOverviewEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskOverviewQueryChangedCopyWith<TaskOverviewQueryChanged> get copyWith => _$TaskOverviewQueryChangedCopyWithImpl<TaskOverviewQueryChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskOverviewQueryChanged&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,query);

@override
String toString() {
  return 'TaskOverviewEvent.queryChanged(query: $query)';
}


}

/// @nodoc
abstract mixin class $TaskOverviewQueryChangedCopyWith<$Res> implements $TaskOverviewEventCopyWith<$Res> {
  factory $TaskOverviewQueryChangedCopyWith(TaskOverviewQueryChanged value, $Res Function(TaskOverviewQueryChanged) _then) = _$TaskOverviewQueryChangedCopyWithImpl;
@useResult
$Res call({
 TaskListQuery query
});




}
/// @nodoc
class _$TaskOverviewQueryChangedCopyWithImpl<$Res>
    implements $TaskOverviewQueryChangedCopyWith<$Res> {
  _$TaskOverviewQueryChangedCopyWithImpl(this._self, this._then);

  final TaskOverviewQueryChanged _self;
  final $Res Function(TaskOverviewQueryChanged) _then;

/// Create a copy of TaskOverviewEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,}) {
  return _then(TaskOverviewQueryChanged(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as TaskListQuery,
  ));
}


}

/// @nodoc


class TaskOverviewToggleTaskCompletion implements TaskOverviewEvent {
  const TaskOverviewToggleTaskCompletion({required this.task});
  

 final  Task task;

/// Create a copy of TaskOverviewEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskOverviewToggleTaskCompletionCopyWith<TaskOverviewToggleTaskCompletion> get copyWith => _$TaskOverviewToggleTaskCompletionCopyWithImpl<TaskOverviewToggleTaskCompletion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskOverviewToggleTaskCompletion&&(identical(other.task, task) || other.task == task));
}


@override
int get hashCode => Object.hash(runtimeType,task);

@override
String toString() {
  return 'TaskOverviewEvent.toggleTaskCompletion(task: $task)';
}


}

/// @nodoc
abstract mixin class $TaskOverviewToggleTaskCompletionCopyWith<$Res> implements $TaskOverviewEventCopyWith<$Res> {
  factory $TaskOverviewToggleTaskCompletionCopyWith(TaskOverviewToggleTaskCompletion value, $Res Function(TaskOverviewToggleTaskCompletion) _then) = _$TaskOverviewToggleTaskCompletionCopyWithImpl;
@useResult
$Res call({
 Task task
});




}
/// @nodoc
class _$TaskOverviewToggleTaskCompletionCopyWithImpl<$Res>
    implements $TaskOverviewToggleTaskCompletionCopyWith<$Res> {
  _$TaskOverviewToggleTaskCompletionCopyWithImpl(this._self, this._then);

  final TaskOverviewToggleTaskCompletion _self;
  final $Res Function(TaskOverviewToggleTaskCompletion) _then;

/// Create a copy of TaskOverviewEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? task = null,}) {
  return _then(TaskOverviewToggleTaskCompletion(
task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as Task,
  ));
}


}

/// @nodoc
mixin _$TaskOverviewState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskOverviewState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskOverviewState()';
}


}

/// @nodoc
class $TaskOverviewStateCopyWith<$Res>  {
$TaskOverviewStateCopyWith(TaskOverviewState _, $Res Function(TaskOverviewState) __);
}


/// Adds pattern-matching-related methods to [TaskOverviewState].
extension TaskOverviewStatePatterns on TaskOverviewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TaskOverviewInitial value)?  initial,TResult Function( TaskOverviewLoading value)?  loading,TResult Function( TaskOverviewLoaded value)?  loaded,TResult Function( TaskOverviewError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TaskOverviewInitial() when initial != null:
return initial(_that);case TaskOverviewLoading() when loading != null:
return loading(_that);case TaskOverviewLoaded() when loaded != null:
return loaded(_that);case TaskOverviewError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TaskOverviewInitial value)  initial,required TResult Function( TaskOverviewLoading value)  loading,required TResult Function( TaskOverviewLoaded value)  loaded,required TResult Function( TaskOverviewError value)  error,}){
final _that = this;
switch (_that) {
case TaskOverviewInitial():
return initial(_that);case TaskOverviewLoading():
return loading(_that);case TaskOverviewLoaded():
return loaded(_that);case TaskOverviewError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TaskOverviewInitial value)?  initial,TResult? Function( TaskOverviewLoading value)?  loading,TResult? Function( TaskOverviewLoaded value)?  loaded,TResult? Function( TaskOverviewError value)?  error,}){
final _that = this;
switch (_that) {
case TaskOverviewInitial() when initial != null:
return initial(_that);case TaskOverviewLoading() when loading != null:
return loading(_that);case TaskOverviewLoaded() when loaded != null:
return loaded(_that);case TaskOverviewError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Task> tasks,  TaskListQuery query)?  loaded,TResult Function( Object error,  StackTrace stacktrace)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TaskOverviewInitial() when initial != null:
return initial();case TaskOverviewLoading() when loading != null:
return loading();case TaskOverviewLoaded() when loaded != null:
return loaded(_that.tasks,_that.query);case TaskOverviewError() when error != null:
return error(_that.error,_that.stacktrace);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Task> tasks,  TaskListQuery query)  loaded,required TResult Function( Object error,  StackTrace stacktrace)  error,}) {final _that = this;
switch (_that) {
case TaskOverviewInitial():
return initial();case TaskOverviewLoading():
return loading();case TaskOverviewLoaded():
return loaded(_that.tasks,_that.query);case TaskOverviewError():
return error(_that.error,_that.stacktrace);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Task> tasks,  TaskListQuery query)?  loaded,TResult? Function( Object error,  StackTrace stacktrace)?  error,}) {final _that = this;
switch (_that) {
case TaskOverviewInitial() when initial != null:
return initial();case TaskOverviewLoading() when loading != null:
return loading();case TaskOverviewLoaded() when loaded != null:
return loaded(_that.tasks,_that.query);case TaskOverviewError() when error != null:
return error(_that.error,_that.stacktrace);case _:
  return null;

}
}

}

/// @nodoc


class TaskOverviewInitial implements TaskOverviewState {
  const TaskOverviewInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskOverviewInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskOverviewState.initial()';
}


}




/// @nodoc


class TaskOverviewLoading implements TaskOverviewState {
  const TaskOverviewLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskOverviewLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskOverviewState.loading()';
}


}




/// @nodoc


class TaskOverviewLoaded implements TaskOverviewState {
  const TaskOverviewLoaded({required final  List<Task> tasks, required this.query}): _tasks = tasks;
  

 final  List<Task> _tasks;
 List<Task> get tasks {
  if (_tasks is EqualUnmodifiableListView) return _tasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasks);
}

 final  TaskListQuery query;

/// Create a copy of TaskOverviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskOverviewLoadedCopyWith<TaskOverviewLoaded> get copyWith => _$TaskOverviewLoadedCopyWithImpl<TaskOverviewLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskOverviewLoaded&&const DeepCollectionEquality().equals(other._tasks, _tasks)&&(identical(other.query, query) || other.query == query));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tasks),query);

@override
String toString() {
  return 'TaskOverviewState.loaded(tasks: $tasks, query: $query)';
}


}

/// @nodoc
abstract mixin class $TaskOverviewLoadedCopyWith<$Res> implements $TaskOverviewStateCopyWith<$Res> {
  factory $TaskOverviewLoadedCopyWith(TaskOverviewLoaded value, $Res Function(TaskOverviewLoaded) _then) = _$TaskOverviewLoadedCopyWithImpl;
@useResult
$Res call({
 List<Task> tasks, TaskListQuery query
});




}
/// @nodoc
class _$TaskOverviewLoadedCopyWithImpl<$Res>
    implements $TaskOverviewLoadedCopyWith<$Res> {
  _$TaskOverviewLoadedCopyWithImpl(this._self, this._then);

  final TaskOverviewLoaded _self;
  final $Res Function(TaskOverviewLoaded) _then;

/// Create a copy of TaskOverviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tasks = null,Object? query = null,}) {
  return _then(TaskOverviewLoaded(
tasks: null == tasks ? _self._tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<Task>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as TaskListQuery,
  ));
}


}

/// @nodoc


class TaskOverviewError implements TaskOverviewState {
  const TaskOverviewError({required this.error, required this.stacktrace});
  

 final  Object error;
 final  StackTrace stacktrace;

/// Create a copy of TaskOverviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskOverviewErrorCopyWith<TaskOverviewError> get copyWith => _$TaskOverviewErrorCopyWithImpl<TaskOverviewError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskOverviewError&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stacktrace, stacktrace) || other.stacktrace == stacktrace));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stacktrace);

@override
String toString() {
  return 'TaskOverviewState.error(error: $error, stacktrace: $stacktrace)';
}


}

/// @nodoc
abstract mixin class $TaskOverviewErrorCopyWith<$Res> implements $TaskOverviewStateCopyWith<$Res> {
  factory $TaskOverviewErrorCopyWith(TaskOverviewError value, $Res Function(TaskOverviewError) _then) = _$TaskOverviewErrorCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace stacktrace
});




}
/// @nodoc
class _$TaskOverviewErrorCopyWithImpl<$Res>
    implements $TaskOverviewErrorCopyWith<$Res> {
  _$TaskOverviewErrorCopyWithImpl(this._self, this._then);

  final TaskOverviewError _self;
  final $Res Function(TaskOverviewError) _then;

/// Create a copy of TaskOverviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stacktrace = null,}) {
  return _then(TaskOverviewError(
error: null == error ? _self.error : error ,stacktrace: null == stacktrace ? _self.stacktrace : stacktrace // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

// dart format on
