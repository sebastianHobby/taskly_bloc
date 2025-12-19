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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _TaskDetailUpdate value)?  update,TResult Function( _TaskDetailDelete value)?  delete,TResult Function( _TaskDetailCreate value)?  create,TResult Function( _TaskDetailGet value)?  get,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskDetailUpdate() when update != null:
return update(_that);case _TaskDetailDelete() when delete != null:
return delete(_that);case _TaskDetailCreate() when create != null:
return create(_that);case _TaskDetailGet() when get != null:
return get(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _TaskDetailUpdate value)  update,required TResult Function( _TaskDetailDelete value)  delete,required TResult Function( _TaskDetailCreate value)  create,required TResult Function( _TaskDetailGet value)  get,}){
final _that = this;
switch (_that) {
case _TaskDetailUpdate():
return update(_that);case _TaskDetailDelete():
return delete(_that);case _TaskDetailCreate():
return create(_that);case _TaskDetailGet():
return get(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _TaskDetailUpdate value)?  update,TResult? Function( _TaskDetailDelete value)?  delete,TResult? Function( _TaskDetailCreate value)?  create,TResult? Function( _TaskDetailGet value)?  get,}){
final _that = this;
switch (_that) {
case _TaskDetailUpdate() when update != null:
return update(_that);case _TaskDetailDelete() when delete != null:
return delete(_that);case _TaskDetailCreate() when create != null:
return create(_that);case _TaskDetailGet() when get != null:
return get(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String name,  String? description,  bool completed)?  update,TResult Function( String id)?  delete,TResult Function( String name,  String? description)?  create,TResult Function( String taskId)?  get,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskDetailUpdate() when update != null:
return update(_that.id,_that.name,_that.description,_that.completed);case _TaskDetailDelete() when delete != null:
return delete(_that.id);case _TaskDetailCreate() when create != null:
return create(_that.name,_that.description);case _TaskDetailGet() when get != null:
return get(_that.taskId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String name,  String? description,  bool completed)  update,required TResult Function( String id)  delete,required TResult Function( String name,  String? description)  create,required TResult Function( String taskId)  get,}) {final _that = this;
switch (_that) {
case _TaskDetailUpdate():
return update(_that.id,_that.name,_that.description,_that.completed);case _TaskDetailDelete():
return delete(_that.id);case _TaskDetailCreate():
return create(_that.name,_that.description);case _TaskDetailGet():
return get(_that.taskId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String name,  String? description,  bool completed)?  update,TResult? Function( String id)?  delete,TResult? Function( String name,  String? description)?  create,TResult? Function( String taskId)?  get,}) {final _that = this;
switch (_that) {
case _TaskDetailUpdate() when update != null:
return update(_that.id,_that.name,_that.description,_that.completed);case _TaskDetailDelete() when delete != null:
return delete(_that.id);case _TaskDetailCreate() when create != null:
return create(_that.name,_that.description);case _TaskDetailGet() when get != null:
return get(_that.taskId);case _:
  return null;

}
}

}

/// @nodoc


class _TaskDetailUpdate implements TaskDetailEvent {
  const _TaskDetailUpdate({required this.id, required this.name, required this.description, required this.completed});
  

 final  String id;
 final  String name;
 final  String? description;
 final  bool completed;

/// Create a copy of TaskDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskDetailUpdateCopyWith<_TaskDetailUpdate> get copyWith => __$TaskDetailUpdateCopyWithImpl<_TaskDetailUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDetailUpdate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.completed, completed) || other.completed == completed));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,completed);

@override
String toString() {
  return 'TaskDetailEvent.update(id: $id, name: $name, description: $description, completed: $completed)';
}


}

/// @nodoc
abstract mixin class _$TaskDetailUpdateCopyWith<$Res> implements $TaskDetailEventCopyWith<$Res> {
  factory _$TaskDetailUpdateCopyWith(_TaskDetailUpdate value, $Res Function(_TaskDetailUpdate) _then) = __$TaskDetailUpdateCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description, bool completed
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
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? completed = null,}) {
  return _then(_TaskDetailUpdate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _TaskDetailDelete implements TaskDetailEvent {
  const _TaskDetailDelete({required this.id});
  

 final  String id;

/// Create a copy of TaskDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskDetailDeleteCopyWith<_TaskDetailDelete> get copyWith => __$TaskDetailDeleteCopyWithImpl<_TaskDetailDelete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDetailDelete&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'TaskDetailEvent.delete(id: $id)';
}


}

/// @nodoc
abstract mixin class _$TaskDetailDeleteCopyWith<$Res> implements $TaskDetailEventCopyWith<$Res> {
  factory _$TaskDetailDeleteCopyWith(_TaskDetailDelete value, $Res Function(_TaskDetailDelete) _then) = __$TaskDetailDeleteCopyWithImpl;
@useResult
$Res call({
 String id
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
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_TaskDetailDelete(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _TaskDetailCreate implements TaskDetailEvent {
  const _TaskDetailCreate({required this.name, required this.description});
  

 final  String name;
 final  String? description;

/// Create a copy of TaskDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskDetailCreateCopyWith<_TaskDetailCreate> get copyWith => __$TaskDetailCreateCopyWithImpl<_TaskDetailCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDetailCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,name,description);

@override
String toString() {
  return 'TaskDetailEvent.create(name: $name, description: $description)';
}


}

/// @nodoc
abstract mixin class _$TaskDetailCreateCopyWith<$Res> implements $TaskDetailEventCopyWith<$Res> {
  factory _$TaskDetailCreateCopyWith(_TaskDetailCreate value, $Res Function(_TaskDetailCreate) _then) = __$TaskDetailCreateCopyWithImpl;
@useResult
$Res call({
 String name, String? description
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
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = freezed,}) {
  return _then(_TaskDetailCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class _TaskDetailGet implements TaskDetailEvent {
  const _TaskDetailGet({required this.taskId});
  

 final  String taskId;

/// Create a copy of TaskDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskDetailGetCopyWith<_TaskDetailGet> get copyWith => __$TaskDetailGetCopyWithImpl<_TaskDetailGet>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDetailGet&&(identical(other.taskId, taskId) || other.taskId == taskId));
}


@override
int get hashCode => Object.hash(runtimeType,taskId);

@override
String toString() {
  return 'TaskDetailEvent.get(taskId: $taskId)';
}


}

/// @nodoc
abstract mixin class _$TaskDetailGetCopyWith<$Res> implements $TaskDetailEventCopyWith<$Res> {
  factory _$TaskDetailGetCopyWith(_TaskDetailGet value, $Res Function(_TaskDetailGet) _then) = __$TaskDetailGetCopyWithImpl;
@useResult
$Res call({
 String taskId
});




}
/// @nodoc
class __$TaskDetailGetCopyWithImpl<$Res>
    implements _$TaskDetailGetCopyWith<$Res> {
  __$TaskDetailGetCopyWithImpl(this._self, this._then);

  final _TaskDetailGet _self;
  final $Res Function(_TaskDetailGet) _then;

/// Create a copy of TaskDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? taskId = null,}) {
  return _then(_TaskDetailGet(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$TaskDetailError {

 String get message; StackTrace? get stackTrace;
/// Create a copy of TaskDetailError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskDetailErrorCopyWith<TaskDetailError> get copyWith => _$TaskDetailErrorCopyWithImpl<TaskDetailError>(this as TaskDetailError, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskDetailError&&(identical(other.message, message) || other.message == message)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}


@override
int get hashCode => Object.hash(runtimeType,message,stackTrace);

@override
String toString() {
  return 'TaskDetailError(message: $message, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class $TaskDetailErrorCopyWith<$Res>  {
  factory $TaskDetailErrorCopyWith(TaskDetailError value, $Res Function(TaskDetailError) _then) = _$TaskDetailErrorCopyWithImpl;
@useResult
$Res call({
 String message, StackTrace? stackTrace
});




}
/// @nodoc
class _$TaskDetailErrorCopyWithImpl<$Res>
    implements $TaskDetailErrorCopyWith<$Res> {
  _$TaskDetailErrorCopyWithImpl(this._self, this._then);

  final TaskDetailError _self;
  final $Res Function(TaskDetailError) _then;

/// Create a copy of TaskDetailError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,Object? stackTrace = freezed,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace?,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskDetailError].
extension TaskDetailErrorPatterns on TaskDetailError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskDetailError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskDetailError() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskDetailError value)  $default,){
final _that = this;
switch (_that) {
case _TaskDetailError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskDetailError value)?  $default,){
final _that = this;
switch (_that) {
case _TaskDetailError() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String message,  StackTrace? stackTrace)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskDetailError() when $default != null:
return $default(_that.message,_that.stackTrace);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String message,  StackTrace? stackTrace)  $default,) {final _that = this;
switch (_that) {
case _TaskDetailError():
return $default(_that.message,_that.stackTrace);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String message,  StackTrace? stackTrace)?  $default,) {final _that = this;
switch (_that) {
case _TaskDetailError() when $default != null:
return $default(_that.message,_that.stackTrace);case _:
  return null;

}
}

}

/// @nodoc


class _TaskDetailError implements TaskDetailError {
  const _TaskDetailError({required this.message, this.stackTrace});
  

@override final  String message;
@override final  StackTrace? stackTrace;

/// Create a copy of TaskDetailError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskDetailErrorCopyWith<_TaskDetailError> get copyWith => __$TaskDetailErrorCopyWithImpl<_TaskDetailError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDetailError&&(identical(other.message, message) || other.message == message)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}


@override
int get hashCode => Object.hash(runtimeType,message,stackTrace);

@override
String toString() {
  return 'TaskDetailError(message: $message, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class _$TaskDetailErrorCopyWith<$Res> implements $TaskDetailErrorCopyWith<$Res> {
  factory _$TaskDetailErrorCopyWith(_TaskDetailError value, $Res Function(_TaskDetailError) _then) = __$TaskDetailErrorCopyWithImpl;
@override @useResult
$Res call({
 String message, StackTrace? stackTrace
});




}
/// @nodoc
class __$TaskDetailErrorCopyWithImpl<$Res>
    implements _$TaskDetailErrorCopyWith<$Res> {
  __$TaskDetailErrorCopyWithImpl(this._self, this._then);

  final _TaskDetailError _self;
  final $Res Function(_TaskDetailError) _then;

/// Create a copy of TaskDetailError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? stackTrace = freezed,}) {
  return _then(_TaskDetailError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace?,
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TaskDetailInitial value)?  initial,TResult Function( TaskDetailOperationSuccess value)?  operationSuccess,TResult Function( TaskDetailOperationFailure value)?  operationFailure,TResult Function( TaskDetailLoadInProgress value)?  loadInProgress,TResult Function( TaskDetailLoadSuccess value)?  loadSuccess,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TaskDetailInitial() when initial != null:
return initial(_that);case TaskDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that);case TaskDetailOperationFailure() when operationFailure != null:
return operationFailure(_that);case TaskDetailLoadInProgress() when loadInProgress != null:
return loadInProgress(_that);case TaskDetailLoadSuccess() when loadSuccess != null:
return loadSuccess(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TaskDetailInitial value)  initial,required TResult Function( TaskDetailOperationSuccess value)  operationSuccess,required TResult Function( TaskDetailOperationFailure value)  operationFailure,required TResult Function( TaskDetailLoadInProgress value)  loadInProgress,required TResult Function( TaskDetailLoadSuccess value)  loadSuccess,}){
final _that = this;
switch (_that) {
case TaskDetailInitial():
return initial(_that);case TaskDetailOperationSuccess():
return operationSuccess(_that);case TaskDetailOperationFailure():
return operationFailure(_that);case TaskDetailLoadInProgress():
return loadInProgress(_that);case TaskDetailLoadSuccess():
return loadSuccess(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TaskDetailInitial value)?  initial,TResult? Function( TaskDetailOperationSuccess value)?  operationSuccess,TResult? Function( TaskDetailOperationFailure value)?  operationFailure,TResult? Function( TaskDetailLoadInProgress value)?  loadInProgress,TResult? Function( TaskDetailLoadSuccess value)?  loadSuccess,}){
final _that = this;
switch (_that) {
case TaskDetailInitial() when initial != null:
return initial(_that);case TaskDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that);case TaskDetailOperationFailure() when operationFailure != null:
return operationFailure(_that);case TaskDetailLoadInProgress() when loadInProgress != null:
return loadInProgress(_that);case TaskDetailLoadSuccess() when loadSuccess != null:
return loadSuccess(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( String message)?  operationSuccess,TResult Function( TaskDetailError errorDetails)?  operationFailure,TResult Function()?  loadInProgress,TResult Function( TaskTableData task)?  loadSuccess,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TaskDetailInitial() when initial != null:
return initial();case TaskDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that.message);case TaskDetailOperationFailure() when operationFailure != null:
return operationFailure(_that.errorDetails);case TaskDetailLoadInProgress() when loadInProgress != null:
return loadInProgress();case TaskDetailLoadSuccess() when loadSuccess != null:
return loadSuccess(_that.task);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( String message)  operationSuccess,required TResult Function( TaskDetailError errorDetails)  operationFailure,required TResult Function()  loadInProgress,required TResult Function( TaskTableData task)  loadSuccess,}) {final _that = this;
switch (_that) {
case TaskDetailInitial():
return initial();case TaskDetailOperationSuccess():
return operationSuccess(_that.message);case TaskDetailOperationFailure():
return operationFailure(_that.errorDetails);case TaskDetailLoadInProgress():
return loadInProgress();case TaskDetailLoadSuccess():
return loadSuccess(_that.task);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( String message)?  operationSuccess,TResult? Function( TaskDetailError errorDetails)?  operationFailure,TResult? Function()?  loadInProgress,TResult? Function( TaskTableData task)?  loadSuccess,}) {final _that = this;
switch (_that) {
case TaskDetailInitial() when initial != null:
return initial();case TaskDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that.message);case TaskDetailOperationFailure() when operationFailure != null:
return operationFailure(_that.errorDetails);case TaskDetailLoadInProgress() when loadInProgress != null:
return loadInProgress();case TaskDetailLoadSuccess() when loadSuccess != null:
return loadSuccess(_that.task);case _:
  return null;

}
}

}

/// @nodoc


class TaskDetailInitial implements TaskDetailState {
  const TaskDetailInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskDetailInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskDetailState.initial()';
}


}




/// @nodoc


class TaskDetailOperationSuccess implements TaskDetailState {
  const TaskDetailOperationSuccess({required this.message});
  

 final  String message;

/// Create a copy of TaskDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskDetailOperationSuccessCopyWith<TaskDetailOperationSuccess> get copyWith => _$TaskDetailOperationSuccessCopyWithImpl<TaskDetailOperationSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskDetailOperationSuccess&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'TaskDetailState.operationSuccess(message: $message)';
}


}

/// @nodoc
abstract mixin class $TaskDetailOperationSuccessCopyWith<$Res> implements $TaskDetailStateCopyWith<$Res> {
  factory $TaskDetailOperationSuccessCopyWith(TaskDetailOperationSuccess value, $Res Function(TaskDetailOperationSuccess) _then) = _$TaskDetailOperationSuccessCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$TaskDetailOperationSuccessCopyWithImpl<$Res>
    implements $TaskDetailOperationSuccessCopyWith<$Res> {
  _$TaskDetailOperationSuccessCopyWithImpl(this._self, this._then);

  final TaskDetailOperationSuccess _self;
  final $Res Function(TaskDetailOperationSuccess) _then;

/// Create a copy of TaskDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(TaskDetailOperationSuccess(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class TaskDetailOperationFailure implements TaskDetailState {
  const TaskDetailOperationFailure({required this.errorDetails});
  

 final  TaskDetailError errorDetails;

/// Create a copy of TaskDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskDetailOperationFailureCopyWith<TaskDetailOperationFailure> get copyWith => _$TaskDetailOperationFailureCopyWithImpl<TaskDetailOperationFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskDetailOperationFailure&&(identical(other.errorDetails, errorDetails) || other.errorDetails == errorDetails));
}


@override
int get hashCode => Object.hash(runtimeType,errorDetails);

@override
String toString() {
  return 'TaskDetailState.operationFailure(errorDetails: $errorDetails)';
}


}

/// @nodoc
abstract mixin class $TaskDetailOperationFailureCopyWith<$Res> implements $TaskDetailStateCopyWith<$Res> {
  factory $TaskDetailOperationFailureCopyWith(TaskDetailOperationFailure value, $Res Function(TaskDetailOperationFailure) _then) = _$TaskDetailOperationFailureCopyWithImpl;
@useResult
$Res call({
 TaskDetailError errorDetails
});


$TaskDetailErrorCopyWith<$Res> get errorDetails;

}
/// @nodoc
class _$TaskDetailOperationFailureCopyWithImpl<$Res>
    implements $TaskDetailOperationFailureCopyWith<$Res> {
  _$TaskDetailOperationFailureCopyWithImpl(this._self, this._then);

  final TaskDetailOperationFailure _self;
  final $Res Function(TaskDetailOperationFailure) _then;

/// Create a copy of TaskDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorDetails = null,}) {
  return _then(TaskDetailOperationFailure(
errorDetails: null == errorDetails ? _self.errorDetails : errorDetails // ignore: cast_nullable_to_non_nullable
as TaskDetailError,
  ));
}

/// Create a copy of TaskDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskDetailErrorCopyWith<$Res> get errorDetails {
  
  return $TaskDetailErrorCopyWith<$Res>(_self.errorDetails, (value) {
    return _then(_self.copyWith(errorDetails: value));
  });
}
}

/// @nodoc


class TaskDetailLoadInProgress implements TaskDetailState {
  const TaskDetailLoadInProgress();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskDetailLoadInProgress);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskDetailState.loadInProgress()';
}


}




/// @nodoc


class TaskDetailLoadSuccess implements TaskDetailState {
  const TaskDetailLoadSuccess({required this.task});
  

 final  TaskTableData task;

/// Create a copy of TaskDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskDetailLoadSuccessCopyWith<TaskDetailLoadSuccess> get copyWith => _$TaskDetailLoadSuccessCopyWithImpl<TaskDetailLoadSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskDetailLoadSuccess&&const DeepCollectionEquality().equals(other.task, task));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(task));

@override
String toString() {
  return 'TaskDetailState.loadSuccess(task: $task)';
}


}

/// @nodoc
abstract mixin class $TaskDetailLoadSuccessCopyWith<$Res> implements $TaskDetailStateCopyWith<$Res> {
  factory $TaskDetailLoadSuccessCopyWith(TaskDetailLoadSuccess value, $Res Function(TaskDetailLoadSuccess) _then) = _$TaskDetailLoadSuccessCopyWithImpl;
@useResult
$Res call({
 TaskTableData task
});




}
/// @nodoc
class _$TaskDetailLoadSuccessCopyWithImpl<$Res>
    implements $TaskDetailLoadSuccessCopyWith<$Res> {
  _$TaskDetailLoadSuccessCopyWithImpl(this._self, this._then);

  final TaskDetailLoadSuccess _self;
  final $Res Function(TaskDetailLoadSuccess) _then;

/// Create a copy of TaskDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? task = freezed,}) {
  return _then(TaskDetailLoadSuccess(
task: freezed == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as TaskTableData,
  ));
}


}

// dart format on
