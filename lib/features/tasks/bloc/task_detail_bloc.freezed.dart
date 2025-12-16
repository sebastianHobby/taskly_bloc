// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_detail_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskDetailEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskDetailEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskDetailEvent()';
}


}

/// @nodoc
class $TaskDetailEventCopyWith<$Res>  {
$TaskDetailEventCopyWith(TaskDetailEvent _, $Res Function(TaskDetailEvent) __);
}


/// Adds pattern-matching-related methods to [TaskDetailEvent].
extension TaskDetailEventPatterns on TaskDetailEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _TaskDetailUpdate value)?  updateTask,TResult Function( _TaskDetailDelete value)?  deleteTask,TResult Function( _TaskDetailCreate value)?  createTask,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskDetailUpdate() when updateTask != null:
return updateTask(_that);case _TaskDetailDelete() when deleteTask != null:
return deleteTask(_that);case _TaskDetailCreate() when createTask != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _TaskDetailUpdate value)  updateTask,required TResult Function( _TaskDetailDelete value)  deleteTask,required TResult Function( _TaskDetailCreate value)  createTask,}){
final _that = this;
switch (_that) {
case _TaskDetailUpdate():
return updateTask(_that);case _TaskDetailDelete():
return deleteTask(_that);case _TaskDetailCreate():
return createTask(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _TaskDetailUpdate value)?  updateTask,TResult? Function( _TaskDetailDelete value)?  deleteTask,TResult? Function( _TaskDetailCreate value)?  createTask,}){
final _that = this;
switch (_that) {
case _TaskDetailUpdate() when updateTask != null:
return updateTask(_that);case _TaskDetailDelete() when deleteTask != null:
return deleteTask(_that);case _TaskDetailCreate() when createTask != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( TaskTableCompanion updateRequest)?  updateTask,TResult Function( TaskTableCompanion deleteRequest)?  deleteTask,TResult Function( TaskTableCompanion createRequest)?  createTask,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskDetailUpdate() when updateTask != null:
return updateTask(_that.updateRequest);case _TaskDetailDelete() when deleteTask != null:
return deleteTask(_that.deleteRequest);case _TaskDetailCreate() when createTask != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( TaskTableCompanion updateRequest)  updateTask,required TResult Function( TaskTableCompanion deleteRequest)  deleteTask,required TResult Function( TaskTableCompanion createRequest)  createTask,}) {final _that = this;
switch (_that) {
case _TaskDetailUpdate():
return updateTask(_that.updateRequest);case _TaskDetailDelete():
return deleteTask(_that.deleteRequest);case _TaskDetailCreate():
return createTask(_that.createRequest);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( TaskTableCompanion updateRequest)?  updateTask,TResult? Function( TaskTableCompanion deleteRequest)?  deleteTask,TResult? Function( TaskTableCompanion createRequest)?  createTask,}) {final _that = this;
switch (_that) {
case _TaskDetailUpdate() when updateTask != null:
return updateTask(_that.updateRequest);case _TaskDetailDelete() when deleteTask != null:
return deleteTask(_that.deleteRequest);case _TaskDetailCreate() when createTask != null:
return createTask(_that.createRequest);case _:
  return null;

}
}

}

/// @nodoc


class _TaskDetailUpdate implements TaskDetailEvent {
  const _TaskDetailUpdate({required this.updateRequest});
  

 final  TaskTableCompanion updateRequest;

/// Create a copy of TaskDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskDetailUpdateCopyWith<_TaskDetailUpdate> get copyWith => __$TaskDetailUpdateCopyWithImpl<_TaskDetailUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDetailUpdate&&const DeepCollectionEquality().equals(other.updateRequest, updateRequest));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(updateRequest));

@override
String toString() {
  return 'TaskDetailEvent.updateTask(updateRequest: $updateRequest)';
}


}

/// @nodoc
abstract mixin class _$TaskDetailUpdateCopyWith<$Res> implements $TaskDetailEventCopyWith<$Res> {
  factory _$TaskDetailUpdateCopyWith(_TaskDetailUpdate value, $Res Function(_TaskDetailUpdate) _then) = __$TaskDetailUpdateCopyWithImpl;
@useResult
$Res call({
 TaskTableCompanion updateRequest
});




}
/// @nodoc
class __$TaskDetailUpdateCopyWithImpl<$Res>
    implements _$TaskDetailUpdateCopyWith<$Res> {
  __$TaskDetailUpdateCopyWithImpl(this._self, this._then);

  final _TaskDetailUpdate _self;
  final $Res Function(_TaskDetailUpdate) _then;

/// Create a copy of TaskDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? updateRequest = freezed,}) {
  return _then(_TaskDetailUpdate(
updateRequest: freezed == updateRequest ? _self.updateRequest : updateRequest // ignore: cast_nullable_to_non_nullable
as TaskTableCompanion,
  ));
}


}

/// @nodoc


class _TaskDetailDelete implements TaskDetailEvent {
  const _TaskDetailDelete({required this.deleteRequest});
  

 final  TaskTableCompanion deleteRequest;

/// Create a copy of TaskDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskDetailDeleteCopyWith<_TaskDetailDelete> get copyWith => __$TaskDetailDeleteCopyWithImpl<_TaskDetailDelete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDetailDelete&&const DeepCollectionEquality().equals(other.deleteRequest, deleteRequest));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(deleteRequest));

@override
String toString() {
  return 'TaskDetailEvent.deleteTask(deleteRequest: $deleteRequest)';
}


}

/// @nodoc
abstract mixin class _$TaskDetailDeleteCopyWith<$Res> implements $TaskDetailEventCopyWith<$Res> {
  factory _$TaskDetailDeleteCopyWith(_TaskDetailDelete value, $Res Function(_TaskDetailDelete) _then) = __$TaskDetailDeleteCopyWithImpl;
@useResult
$Res call({
 TaskTableCompanion deleteRequest
});




}
/// @nodoc
class __$TaskDetailDeleteCopyWithImpl<$Res>
    implements _$TaskDetailDeleteCopyWith<$Res> {
  __$TaskDetailDeleteCopyWithImpl(this._self, this._then);

  final _TaskDetailDelete _self;
  final $Res Function(_TaskDetailDelete) _then;

/// Create a copy of TaskDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? deleteRequest = freezed,}) {
  return _then(_TaskDetailDelete(
deleteRequest: freezed == deleteRequest ? _self.deleteRequest : deleteRequest // ignore: cast_nullable_to_non_nullable
as TaskTableCompanion,
  ));
}


}

/// @nodoc


class _TaskDetailCreate implements TaskDetailEvent {
  const _TaskDetailCreate({required this.createRequest});
  

 final  TaskTableCompanion createRequest;

/// Create a copy of TaskDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskDetailCreateCopyWith<_TaskDetailCreate> get copyWith => __$TaskDetailCreateCopyWithImpl<_TaskDetailCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDetailCreate&&const DeepCollectionEquality().equals(other.createRequest, createRequest));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(createRequest));

@override
String toString() {
  return 'TaskDetailEvent.createTask(createRequest: $createRequest)';
}


}

/// @nodoc
abstract mixin class _$TaskDetailCreateCopyWith<$Res> implements $TaskDetailEventCopyWith<$Res> {
  factory _$TaskDetailCreateCopyWith(_TaskDetailCreate value, $Res Function(_TaskDetailCreate) _then) = __$TaskDetailCreateCopyWithImpl;
@useResult
$Res call({
 TaskTableCompanion createRequest
});




}
/// @nodoc
class __$TaskDetailCreateCopyWithImpl<$Res>
    implements _$TaskDetailCreateCopyWith<$Res> {
  __$TaskDetailCreateCopyWithImpl(this._self, this._then);

  final _TaskDetailCreate _self;
  final $Res Function(_TaskDetailCreate) _then;

/// Create a copy of TaskDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? createRequest = freezed,}) {
  return _then(_TaskDetailCreate(
createRequest: freezed == createRequest ? _self.createRequest : createRequest // ignore: cast_nullable_to_non_nullable
as TaskTableCompanion,
  ));
}


}

/// @nodoc
mixin _$TaskDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskDetailState()';
}


}

/// @nodoc
class $TaskDetailStateCopyWith<$Res>  {
$TaskDetailStateCopyWith(TaskDetailState _, $Res Function(TaskDetailState) __);
}


/// Adds pattern-matching-related methods to [TaskDetailState].
extension TaskDetailStatePatterns on TaskDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _TaskDetailInitial value)?  initial,TResult Function( _TaskDetailError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskDetailInitial() when initial != null:
return initial(_that);case _TaskDetailError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _TaskDetailInitial value)  initial,required TResult Function( _TaskDetailError value)  error,}){
final _that = this;
switch (_that) {
case _TaskDetailInitial():
return initial(_that);case _TaskDetailError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _TaskDetailInitial value)?  initial,TResult? Function( _TaskDetailError value)?  error,}){
final _that = this;
switch (_that) {
case _TaskDetailInitial() when initial != null:
return initial(_that);case _TaskDetailError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( String message,  StackTrace stacktrace)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskDetailInitial() when initial != null:
return initial();case _TaskDetailError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( String message,  StackTrace stacktrace)  error,}) {final _that = this;
switch (_that) {
case _TaskDetailInitial():
return initial();case _TaskDetailError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( String message,  StackTrace stacktrace)?  error,}) {final _that = this;
switch (_that) {
case _TaskDetailInitial() when initial != null:
return initial();case _TaskDetailError() when error != null:
return error(_that.message,_that.stacktrace);case _:
  return null;

}
}

}

/// @nodoc


class _TaskDetailInitial implements TaskDetailState {
  const _TaskDetailInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDetailInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskDetailState.initial()';
}


}




/// @nodoc


class _TaskDetailError implements TaskDetailState {
  const _TaskDetailError({required this.message, required this.stacktrace});
  

 final  String message;
 final  StackTrace stacktrace;

/// Create a copy of TaskDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskDetailErrorCopyWith<_TaskDetailError> get copyWith => __$TaskDetailErrorCopyWithImpl<_TaskDetailError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDetailError&&(identical(other.message, message) || other.message == message)&&(identical(other.stacktrace, stacktrace) || other.stacktrace == stacktrace));
}


@override
int get hashCode => Object.hash(runtimeType,message,stacktrace);

@override
String toString() {
  return 'TaskDetailState.error(message: $message, stacktrace: $stacktrace)';
}


}

/// @nodoc
abstract mixin class _$TaskDetailErrorCopyWith<$Res> implements $TaskDetailStateCopyWith<$Res> {
  factory _$TaskDetailErrorCopyWith(_TaskDetailError value, $Res Function(_TaskDetailError) _then) = __$TaskDetailErrorCopyWithImpl;
@useResult
$Res call({
 String message, StackTrace stacktrace
});




}
/// @nodoc
class __$TaskDetailErrorCopyWithImpl<$Res>
    implements _$TaskDetailErrorCopyWith<$Res> {
  __$TaskDetailErrorCopyWithImpl(this._self, this._then);

  final _TaskDetailError _self;
  final $Res Function(_TaskDetailError) _then;

/// Create a copy of TaskDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? stacktrace = null,}) {
  return _then(_TaskDetailError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,stacktrace: null == stacktrace ? _self.stacktrace : stacktrace // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

// dart format on
