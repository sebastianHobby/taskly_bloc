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
mixin _$TaskListEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskListEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskListEvent()';
}


}

/// @nodoc
class $TaskListEventCopyWith<$Res>  {
$TaskListEventCopyWith(TaskListEvent _, $Res Function(TaskListEvent) __);
}


/// Adds pattern-matching-related methods to [TaskListEvent].
extension TaskListEventPatterns on TaskListEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TaskListSubscriptionRequested value)?  subscriptionRequested,TResult Function( TaskListToggleTaskCompletion value)?  toggleTaskCompletion,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TaskListSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested(_that);case TaskListToggleTaskCompletion() when toggleTaskCompletion != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TaskListSubscriptionRequested value)  subscriptionRequested,required TResult Function( TaskListToggleTaskCompletion value)  toggleTaskCompletion,}){
final _that = this;
switch (_that) {
case TaskListSubscriptionRequested():
return subscriptionRequested(_that);case TaskListToggleTaskCompletion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TaskListSubscriptionRequested value)?  subscriptionRequested,TResult? Function( TaskListToggleTaskCompletion value)?  toggleTaskCompletion,}){
final _that = this;
switch (_that) {
case TaskListSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested(_that);case TaskListToggleTaskCompletion() when toggleTaskCompletion != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  subscriptionRequested,TResult Function( TaskDto taskDto)?  toggleTaskCompletion,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TaskListSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested();case TaskListToggleTaskCompletion() when toggleTaskCompletion != null:
return toggleTaskCompletion(_that.taskDto);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  subscriptionRequested,required TResult Function( TaskDto taskDto)  toggleTaskCompletion,}) {final _that = this;
switch (_that) {
case TaskListSubscriptionRequested():
return subscriptionRequested();case TaskListToggleTaskCompletion():
return toggleTaskCompletion(_that.taskDto);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  subscriptionRequested,TResult? Function( TaskDto taskDto)?  toggleTaskCompletion,}) {final _that = this;
switch (_that) {
case TaskListSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested();case TaskListToggleTaskCompletion() when toggleTaskCompletion != null:
return toggleTaskCompletion(_that.taskDto);case _:
  return null;

}
}

}

/// @nodoc


class TaskListSubscriptionRequested implements TaskListEvent {
  const TaskListSubscriptionRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskListSubscriptionRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskListEvent.subscriptionRequested()';
}


}




/// @nodoc


class TaskListToggleTaskCompletion implements TaskListEvent {
  const TaskListToggleTaskCompletion({required this.taskDto});
  

 final  TaskDto taskDto;

/// Create a copy of TaskListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskListToggleTaskCompletionCopyWith<TaskListToggleTaskCompletion> get copyWith => _$TaskListToggleTaskCompletionCopyWithImpl<TaskListToggleTaskCompletion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskListToggleTaskCompletion&&(identical(other.taskDto, taskDto) || other.taskDto == taskDto));
}


@override
int get hashCode => Object.hash(runtimeType,taskDto);

@override
String toString() {
  return 'TaskListEvent.toggleTaskCompletion(taskDto: $taskDto)';
}


}

/// @nodoc
abstract mixin class $TaskListToggleTaskCompletionCopyWith<$Res> implements $TaskListEventCopyWith<$Res> {
  factory $TaskListToggleTaskCompletionCopyWith(TaskListToggleTaskCompletion value, $Res Function(TaskListToggleTaskCompletion) _then) = _$TaskListToggleTaskCompletionCopyWithImpl;
@useResult
$Res call({
 TaskDto taskDto
});


$TaskDtoCopyWith<$Res> get taskDto;

}
/// @nodoc
class _$TaskListToggleTaskCompletionCopyWithImpl<$Res>
    implements $TaskListToggleTaskCompletionCopyWith<$Res> {
  _$TaskListToggleTaskCompletionCopyWithImpl(this._self, this._then);

  final TaskListToggleTaskCompletion _self;
  final $Res Function(TaskListToggleTaskCompletion) _then;

/// Create a copy of TaskListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? taskDto = null,}) {
  return _then(TaskListToggleTaskCompletion(
taskDto: null == taskDto ? _self.taskDto : taskDto // ignore: cast_nullable_to_non_nullable
as TaskDto,
  ));
}

/// Create a copy of TaskListEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskDtoCopyWith<$Res> get taskDto {
  
  return $TaskDtoCopyWith<$Res>(_self.taskDto, (value) {
    return _then(_self.copyWith(taskDto: value));
  });
}
}

/// @nodoc
mixin _$TaskListState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskListState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskListState()';
}


}

/// @nodoc
class $TaskListStateCopyWith<$Res>  {
$TaskListStateCopyWith(TaskListState _, $Res Function(TaskListState) __);
}


/// Adds pattern-matching-related methods to [TaskListState].
extension TaskListStatePatterns on TaskListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _TaskListInitial value)?  initial,TResult Function( _TaskListLoading value)?  loading,TResult Function( _TaskListLoaded value)?  loaded,TResult Function( _TaskListError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskListInitial() when initial != null:
return initial(_that);case _TaskListLoading() when loading != null:
return loading(_that);case _TaskListLoaded() when loaded != null:
return loaded(_that);case _TaskListError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _TaskListInitial value)  initial,required TResult Function( _TaskListLoading value)  loading,required TResult Function( _TaskListLoaded value)  loaded,required TResult Function( _TaskListError value)  error,}){
final _that = this;
switch (_that) {
case _TaskListInitial():
return initial(_that);case _TaskListLoading():
return loading(_that);case _TaskListLoaded():
return loaded(_that);case _TaskListError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _TaskListInitial value)?  initial,TResult? Function( _TaskListLoading value)?  loading,TResult? Function( _TaskListLoaded value)?  loaded,TResult? Function( _TaskListError value)?  error,}){
final _that = this;
switch (_that) {
case _TaskListInitial() when initial != null:
return initial(_that);case _TaskListLoading() when loading != null:
return loading(_that);case _TaskListLoaded() when loaded != null:
return loaded(_that);case _TaskListError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<TaskDto> tasks)?  loaded,TResult Function( String message,  StackTrace stacktrace)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskListInitial() when initial != null:
return initial();case _TaskListLoading() when loading != null:
return loading();case _TaskListLoaded() when loaded != null:
return loaded(_that.tasks);case _TaskListError() when error != null:
return error(_that.message,_that.stacktrace);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<TaskDto> tasks)  loaded,required TResult Function( String message,  StackTrace stacktrace)  error,}) {final _that = this;
switch (_that) {
case _TaskListInitial():
return initial();case _TaskListLoading():
return loading();case _TaskListLoaded():
return loaded(_that.tasks);case _TaskListError():
return error(_that.message,_that.stacktrace);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<TaskDto> tasks)?  loaded,TResult? Function( String message,  StackTrace stacktrace)?  error,}) {final _that = this;
switch (_that) {
case _TaskListInitial() when initial != null:
return initial();case _TaskListLoading() when loading != null:
return loading();case _TaskListLoaded() when loaded != null:
return loaded(_that.tasks);case _TaskListError() when error != null:
return error(_that.message,_that.stacktrace);case _:
  return null;

}
}

}

/// @nodoc


class _TaskListInitial implements TaskListState {
  const _TaskListInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskListInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskListState.initial()';
}


}




/// @nodoc


class _TaskListLoading implements TaskListState {
  const _TaskListLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskListLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskListState.loading()';
}


}




/// @nodoc


class _TaskListLoaded implements TaskListState {
  const _TaskListLoaded({required final  List<TaskDto> tasks}): _tasks = tasks;
  

 final  List<TaskDto> _tasks;
 List<TaskDto> get tasks {
  if (_tasks is EqualUnmodifiableListView) return _tasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasks);
}


/// Create a copy of TaskListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskListLoadedCopyWith<_TaskListLoaded> get copyWith => __$TaskListLoadedCopyWithImpl<_TaskListLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskListLoaded&&const DeepCollectionEquality().equals(other._tasks, _tasks));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tasks));

@override
String toString() {
  return 'TaskListState.loaded(tasks: $tasks)';
}


}

/// @nodoc
abstract mixin class _$TaskListLoadedCopyWith<$Res> implements $TaskListStateCopyWith<$Res> {
  factory _$TaskListLoadedCopyWith(_TaskListLoaded value, $Res Function(_TaskListLoaded) _then) = __$TaskListLoadedCopyWithImpl;
@useResult
$Res call({
 List<TaskDto> tasks
});




}
/// @nodoc
class __$TaskListLoadedCopyWithImpl<$Res>
    implements _$TaskListLoadedCopyWith<$Res> {
  __$TaskListLoadedCopyWithImpl(this._self, this._then);

  final _TaskListLoaded _self;
  final $Res Function(_TaskListLoaded) _then;

/// Create a copy of TaskListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tasks = null,}) {
  return _then(_TaskListLoaded(
tasks: null == tasks ? _self._tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<TaskDto>,
  ));
}


}

/// @nodoc


class _TaskListError implements TaskListState {
  const _TaskListError({required this.message, required this.stacktrace});
  

 final  String message;
 final  StackTrace stacktrace;

/// Create a copy of TaskListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskListErrorCopyWith<_TaskListError> get copyWith => __$TaskListErrorCopyWithImpl<_TaskListError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskListError&&(identical(other.message, message) || other.message == message)&&(identical(other.stacktrace, stacktrace) || other.stacktrace == stacktrace));
}


@override
int get hashCode => Object.hash(runtimeType,message,stacktrace);

@override
String toString() {
  return 'TaskListState.error(message: $message, stacktrace: $stacktrace)';
}


}

/// @nodoc
abstract mixin class _$TaskListErrorCopyWith<$Res> implements $TaskListStateCopyWith<$Res> {
  factory _$TaskListErrorCopyWith(_TaskListError value, $Res Function(_TaskListError) _then) = __$TaskListErrorCopyWithImpl;
@useResult
$Res call({
 String message, StackTrace stacktrace
});




}
/// @nodoc
class __$TaskListErrorCopyWithImpl<$Res>
    implements _$TaskListErrorCopyWith<$Res> {
  __$TaskListErrorCopyWithImpl(this._self, this._then);

  final _TaskListError _self;
  final $Res Function(_TaskListError) _then;

/// Create a copy of TaskListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? stacktrace = null,}) {
  return _then(_TaskListError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,stacktrace: null == stacktrace ? _self.stacktrace : stacktrace // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

// dart format on
