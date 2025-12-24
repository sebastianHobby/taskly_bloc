// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'today_tasks_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TodayTasksEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodayTasksEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TodayTasksEvent()';
}


}

/// @nodoc
class $TodayTasksEventCopyWith<$Res>  {
$TodayTasksEventCopyWith(TodayTasksEvent _, $Res Function(TodayTasksEvent) __);
}


/// Adds pattern-matching-related methods to [TodayTasksEvent].
extension TodayTasksEventPatterns on TodayTasksEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TodayTasksSubscriptionRequested value)?  subscriptionRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TodayTasksSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TodayTasksSubscriptionRequested value)  subscriptionRequested,}){
final _that = this;
switch (_that) {
case TodayTasksSubscriptionRequested():
return subscriptionRequested(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TodayTasksSubscriptionRequested value)?  subscriptionRequested,}){
final _that = this;
switch (_that) {
case TodayTasksSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  subscriptionRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TodayTasksSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  subscriptionRequested,}) {final _that = this;
switch (_that) {
case TodayTasksSubscriptionRequested():
return subscriptionRequested();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  subscriptionRequested,}) {final _that = this;
switch (_that) {
case TodayTasksSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested();case _:
  return null;

}
}

}

/// @nodoc


class TodayTasksSubscriptionRequested implements TodayTasksEvent {
  const TodayTasksSubscriptionRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodayTasksSubscriptionRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TodayTasksEvent.subscriptionRequested()';
}


}




/// @nodoc
mixin _$TodayTasksState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodayTasksState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TodayTasksState()';
}


}

/// @nodoc
class $TodayTasksStateCopyWith<$Res>  {
$TodayTasksStateCopyWith(TodayTasksState _, $Res Function(TodayTasksState) __);
}


/// Adds pattern-matching-related methods to [TodayTasksState].
extension TodayTasksStatePatterns on TodayTasksState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TodayTasksInitial value)?  initial,TResult Function( TodayTasksLoading value)?  loading,TResult Function( TodayTasksLoaded value)?  loaded,TResult Function( TodayTasksError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TodayTasksInitial() when initial != null:
return initial(_that);case TodayTasksLoading() when loading != null:
return loading(_that);case TodayTasksLoaded() when loaded != null:
return loaded(_that);case TodayTasksError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TodayTasksInitial value)  initial,required TResult Function( TodayTasksLoading value)  loading,required TResult Function( TodayTasksLoaded value)  loaded,required TResult Function( TodayTasksError value)  error,}){
final _that = this;
switch (_that) {
case TodayTasksInitial():
return initial(_that);case TodayTasksLoading():
return loading(_that);case TodayTasksLoaded():
return loaded(_that);case TodayTasksError():
return error(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TodayTasksInitial value)?  initial,TResult? Function( TodayTasksLoading value)?  loading,TResult? Function( TodayTasksLoaded value)?  loaded,TResult? Function( TodayTasksError value)?  error,}){
final _that = this;
switch (_that) {
case TodayTasksInitial() when initial != null:
return initial(_that);case TodayTasksLoading() when loading != null:
return loading(_that);case TodayTasksLoaded() when loaded != null:
return loaded(_that);case TodayTasksError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Task> tasks,  int incompleteCount)?  loaded,TResult Function( Object error,  StackTrace stackTrace)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TodayTasksInitial() when initial != null:
return initial();case TodayTasksLoading() when loading != null:
return loading();case TodayTasksLoaded() when loaded != null:
return loaded(_that.tasks,_that.incompleteCount);case TodayTasksError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Task> tasks,  int incompleteCount)  loaded,required TResult Function( Object error,  StackTrace stackTrace)  error,}) {final _that = this;
switch (_that) {
case TodayTasksInitial():
return initial();case TodayTasksLoading():
return loading();case TodayTasksLoaded():
return loaded(_that.tasks,_that.incompleteCount);case TodayTasksError():
return error(_that.error,_that.stackTrace);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Task> tasks,  int incompleteCount)?  loaded,TResult? Function( Object error,  StackTrace stackTrace)?  error,}) {final _that = this;
switch (_that) {
case TodayTasksInitial() when initial != null:
return initial();case TodayTasksLoading() when loading != null:
return loading();case TodayTasksLoaded() when loaded != null:
return loaded(_that.tasks,_that.incompleteCount);case TodayTasksError() when error != null:
return error(_that.error,_that.stackTrace);case _:
  return null;

}
}

}

/// @nodoc


class TodayTasksInitial implements TodayTasksState {
  const TodayTasksInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodayTasksInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TodayTasksState.initial()';
}


}




/// @nodoc


class TodayTasksLoading implements TodayTasksState {
  const TodayTasksLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodayTasksLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TodayTasksState.loading()';
}


}




/// @nodoc


class TodayTasksLoaded implements TodayTasksState {
  const TodayTasksLoaded({required final  List<Task> tasks, required this.incompleteCount}): _tasks = tasks;
  

 final  List<Task> _tasks;
 List<Task> get tasks {
  if (_tasks is EqualUnmodifiableListView) return _tasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasks);
}

 final  int incompleteCount;

/// Create a copy of TodayTasksState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TodayTasksLoadedCopyWith<TodayTasksLoaded> get copyWith => _$TodayTasksLoadedCopyWithImpl<TodayTasksLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodayTasksLoaded&&const DeepCollectionEquality().equals(other._tasks, _tasks)&&(identical(other.incompleteCount, incompleteCount) || other.incompleteCount == incompleteCount));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tasks),incompleteCount);

@override
String toString() {
  return 'TodayTasksState.loaded(tasks: $tasks, incompleteCount: $incompleteCount)';
}


}

/// @nodoc
abstract mixin class $TodayTasksLoadedCopyWith<$Res> implements $TodayTasksStateCopyWith<$Res> {
  factory $TodayTasksLoadedCopyWith(TodayTasksLoaded value, $Res Function(TodayTasksLoaded) _then) = _$TodayTasksLoadedCopyWithImpl;
@useResult
$Res call({
 List<Task> tasks, int incompleteCount
});




}
/// @nodoc
class _$TodayTasksLoadedCopyWithImpl<$Res>
    implements $TodayTasksLoadedCopyWith<$Res> {
  _$TodayTasksLoadedCopyWithImpl(this._self, this._then);

  final TodayTasksLoaded _self;
  final $Res Function(TodayTasksLoaded) _then;

/// Create a copy of TodayTasksState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tasks = null,Object? incompleteCount = null,}) {
  return _then(TodayTasksLoaded(
tasks: null == tasks ? _self._tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<Task>,incompleteCount: null == incompleteCount ? _self.incompleteCount : incompleteCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class TodayTasksError implements TodayTasksState {
  const TodayTasksError({required this.error, required this.stackTrace});
  

 final  Object error;
 final  StackTrace stackTrace;

/// Create a copy of TodayTasksState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TodayTasksErrorCopyWith<TodayTasksError> get copyWith => _$TodayTasksErrorCopyWithImpl<TodayTasksError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodayTasksError&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stackTrace);

@override
String toString() {
  return 'TodayTasksState.error(error: $error, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class $TodayTasksErrorCopyWith<$Res> implements $TodayTasksStateCopyWith<$Res> {
  factory $TodayTasksErrorCopyWith(TodayTasksError value, $Res Function(TodayTasksError) _then) = _$TodayTasksErrorCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace stackTrace
});




}
/// @nodoc
class _$TodayTasksErrorCopyWithImpl<$Res>
    implements $TodayTasksErrorCopyWith<$Res> {
  _$TodayTasksErrorCopyWithImpl(this._self, this._then);

  final TodayTasksError _self;
  final $Res Function(TodayTasksError) _then;

/// Create a copy of TodayTasksState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stackTrace = null,}) {
  return _then(TodayTasksError(
error: null == error ? _self.error : error ,stackTrace: null == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

// dart format on
