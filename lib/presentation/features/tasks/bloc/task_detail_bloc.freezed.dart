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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _TaskDetailUpdate value)?  update,TResult Function( _TaskDetailDelete value)?  delete,TResult Function( _TaskDetailCreate value)?  create,TResult Function( _TaskDetailLoadById value)?  loadById,TResult Function( _TaskDetailLoadInitialData value)?  loadInitialData,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskDetailUpdate() when update != null:
return update(_that);case _TaskDetailDelete() when delete != null:
return delete(_that);case _TaskDetailCreate() when create != null:
return create(_that);case _TaskDetailLoadById() when loadById != null:
return loadById(_that);case _TaskDetailLoadInitialData() when loadInitialData != null:
return loadInitialData(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _TaskDetailUpdate value)  update,required TResult Function( _TaskDetailDelete value)  delete,required TResult Function( _TaskDetailCreate value)  create,required TResult Function( _TaskDetailLoadById value)  loadById,required TResult Function( _TaskDetailLoadInitialData value)  loadInitialData,}){
final _that = this;
switch (_that) {
case _TaskDetailUpdate():
return update(_that);case _TaskDetailDelete():
return delete(_that);case _TaskDetailCreate():
return create(_that);case _TaskDetailLoadById():
return loadById(_that);case _TaskDetailLoadInitialData():
return loadInitialData(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _TaskDetailUpdate value)?  update,TResult? Function( _TaskDetailDelete value)?  delete,TResult? Function( _TaskDetailCreate value)?  create,TResult? Function( _TaskDetailLoadById value)?  loadById,TResult? Function( _TaskDetailLoadInitialData value)?  loadInitialData,}){
final _that = this;
switch (_that) {
case _TaskDetailUpdate() when update != null:
return update(_that);case _TaskDetailDelete() when delete != null:
return delete(_that);case _TaskDetailCreate() when create != null:
return create(_that);case _TaskDetailLoadById() when loadById != null:
return loadById(_that);case _TaskDetailLoadInitialData() when loadInitialData != null:
return loadInitialData(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( UpdateTaskCommand command)?  update,TResult Function( String id)?  delete,TResult Function( CreateTaskCommand command)?  create,TResult Function( String taskId)?  loadById,TResult Function()?  loadInitialData,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskDetailUpdate() when update != null:
return update(_that.command);case _TaskDetailDelete() when delete != null:
return delete(_that.id);case _TaskDetailCreate() when create != null:
return create(_that.command);case _TaskDetailLoadById() when loadById != null:
return loadById(_that.taskId);case _TaskDetailLoadInitialData() when loadInitialData != null:
return loadInitialData();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( UpdateTaskCommand command)  update,required TResult Function( String id)  delete,required TResult Function( CreateTaskCommand command)  create,required TResult Function( String taskId)  loadById,required TResult Function()  loadInitialData,}) {final _that = this;
switch (_that) {
case _TaskDetailUpdate():
return update(_that.command);case _TaskDetailDelete():
return delete(_that.id);case _TaskDetailCreate():
return create(_that.command);case _TaskDetailLoadById():
return loadById(_that.taskId);case _TaskDetailLoadInitialData():
return loadInitialData();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( UpdateTaskCommand command)?  update,TResult? Function( String id)?  delete,TResult? Function( CreateTaskCommand command)?  create,TResult? Function( String taskId)?  loadById,TResult? Function()?  loadInitialData,}) {final _that = this;
switch (_that) {
case _TaskDetailUpdate() when update != null:
return update(_that.command);case _TaskDetailDelete() when delete != null:
return delete(_that.id);case _TaskDetailCreate() when create != null:
return create(_that.command);case _TaskDetailLoadById() when loadById != null:
return loadById(_that.taskId);case _TaskDetailLoadInitialData() when loadInitialData != null:
return loadInitialData();case _:
  return null;

}
}

}

/// @nodoc


class _TaskDetailUpdate implements TaskDetailEvent {
  const _TaskDetailUpdate({required this.command});
  

 final  UpdateTaskCommand command;

/// Create a copy of TaskDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskDetailUpdateCopyWith<_TaskDetailUpdate> get copyWith => __$TaskDetailUpdateCopyWithImpl<_TaskDetailUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDetailUpdate&&(identical(other.command, command) || other.command == command));
}


@override
int get hashCode => Object.hash(runtimeType,command);

@override
String toString() {
  return 'TaskDetailEvent.update(command: $command)';
}


}

/// @nodoc
abstract mixin class _$TaskDetailUpdateCopyWith<$Res> implements $TaskDetailEventCopyWith<$Res> {
  factory _$TaskDetailUpdateCopyWith(_TaskDetailUpdate value, $Res Function(_TaskDetailUpdate) _then) = __$TaskDetailUpdateCopyWithImpl;
@useResult
$Res call({
 UpdateTaskCommand command
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
@pragma('vm:prefer-inline') $Res call({Object? command = null,}) {
  return _then(_TaskDetailUpdate(
command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as UpdateTaskCommand,
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
  const _TaskDetailCreate({required this.command});
  

 final  CreateTaskCommand command;

/// Create a copy of TaskDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskDetailCreateCopyWith<_TaskDetailCreate> get copyWith => __$TaskDetailCreateCopyWithImpl<_TaskDetailCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDetailCreate&&(identical(other.command, command) || other.command == command));
}


@override
int get hashCode => Object.hash(runtimeType,command);

@override
String toString() {
  return 'TaskDetailEvent.create(command: $command)';
}


}

/// @nodoc
abstract mixin class _$TaskDetailCreateCopyWith<$Res> implements $TaskDetailEventCopyWith<$Res> {
  factory _$TaskDetailCreateCopyWith(_TaskDetailCreate value, $Res Function(_TaskDetailCreate) _then) = __$TaskDetailCreateCopyWithImpl;
@useResult
$Res call({
 CreateTaskCommand command
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
@pragma('vm:prefer-inline') $Res call({Object? command = null,}) {
  return _then(_TaskDetailCreate(
command: null == command ? _self.command : command // ignore: cast_nullable_to_non_nullable
as CreateTaskCommand,
  ));
}


}

/// @nodoc


class _TaskDetailLoadById implements TaskDetailEvent {
  const _TaskDetailLoadById({required this.taskId});
  

 final  String taskId;

/// Create a copy of TaskDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskDetailLoadByIdCopyWith<_TaskDetailLoadById> get copyWith => __$TaskDetailLoadByIdCopyWithImpl<_TaskDetailLoadById>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDetailLoadById&&(identical(other.taskId, taskId) || other.taskId == taskId));
}


@override
int get hashCode => Object.hash(runtimeType,taskId);

@override
String toString() {
  return 'TaskDetailEvent.loadById(taskId: $taskId)';
}


}

/// @nodoc
abstract mixin class _$TaskDetailLoadByIdCopyWith<$Res> implements $TaskDetailEventCopyWith<$Res> {
  factory _$TaskDetailLoadByIdCopyWith(_TaskDetailLoadById value, $Res Function(_TaskDetailLoadById) _then) = __$TaskDetailLoadByIdCopyWithImpl;
@useResult
$Res call({
 String taskId
});




}
/// @nodoc
class __$TaskDetailLoadByIdCopyWithImpl<$Res>
    implements _$TaskDetailLoadByIdCopyWith<$Res> {
  __$TaskDetailLoadByIdCopyWithImpl(this._self, this._then);

  final _TaskDetailLoadById _self;
  final $Res Function(_TaskDetailLoadById) _then;

/// Create a copy of TaskDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? taskId = null,}) {
  return _then(_TaskDetailLoadById(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _TaskDetailLoadInitialData implements TaskDetailEvent {
  const _TaskDetailLoadInitialData();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDetailLoadInitialData);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskDetailEvent.loadInitialData()';
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TaskDetailInitial value)?  initial,TResult Function( TaskDetailValidationFailure value)?  validationFailure,TResult Function( TaskDetailInitialDataLoadSuccess value)?  initialDataLoadSuccess,TResult Function( TaskDetailOperationSuccess value)?  operationSuccess,TResult Function( TaskDetailOperationFailure value)?  operationFailure,TResult Function( TaskDetailLoadInProgress value)?  loadInProgress,TResult Function( TaskDetailLoadSuccess value)?  loadSuccess,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TaskDetailInitial() when initial != null:
return initial(_that);case TaskDetailValidationFailure() when validationFailure != null:
return validationFailure(_that);case TaskDetailInitialDataLoadSuccess() when initialDataLoadSuccess != null:
return initialDataLoadSuccess(_that);case TaskDetailOperationSuccess() when operationSuccess != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TaskDetailInitial value)  initial,required TResult Function( TaskDetailValidationFailure value)  validationFailure,required TResult Function( TaskDetailInitialDataLoadSuccess value)  initialDataLoadSuccess,required TResult Function( TaskDetailOperationSuccess value)  operationSuccess,required TResult Function( TaskDetailOperationFailure value)  operationFailure,required TResult Function( TaskDetailLoadInProgress value)  loadInProgress,required TResult Function( TaskDetailLoadSuccess value)  loadSuccess,}){
final _that = this;
switch (_that) {
case TaskDetailInitial():
return initial(_that);case TaskDetailValidationFailure():
return validationFailure(_that);case TaskDetailInitialDataLoadSuccess():
return initialDataLoadSuccess(_that);case TaskDetailOperationSuccess():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TaskDetailInitial value)?  initial,TResult? Function( TaskDetailValidationFailure value)?  validationFailure,TResult? Function( TaskDetailInitialDataLoadSuccess value)?  initialDataLoadSuccess,TResult? Function( TaskDetailOperationSuccess value)?  operationSuccess,TResult? Function( TaskDetailOperationFailure value)?  operationFailure,TResult? Function( TaskDetailLoadInProgress value)?  loadInProgress,TResult? Function( TaskDetailLoadSuccess value)?  loadSuccess,}){
final _that = this;
switch (_that) {
case TaskDetailInitial() when initial != null:
return initial(_that);case TaskDetailValidationFailure() when validationFailure != null:
return validationFailure(_that);case TaskDetailInitialDataLoadSuccess() when initialDataLoadSuccess != null:
return initialDataLoadSuccess(_that);case TaskDetailOperationSuccess() when operationSuccess != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( ValidationFailure failure)?  validationFailure,TResult Function( List<Project> availableProjects,  List<Value> availableValues)?  initialDataLoadSuccess,TResult Function( EntityOperation operation)?  operationSuccess,TResult Function( DetailBlocError<Task> errorDetails)?  operationFailure,TResult Function()?  loadInProgress,TResult Function( List<Project> availableProjects,  List<Value> availableValues,  Task task)?  loadSuccess,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TaskDetailInitial() when initial != null:
return initial();case TaskDetailValidationFailure() when validationFailure != null:
return validationFailure(_that.failure);case TaskDetailInitialDataLoadSuccess() when initialDataLoadSuccess != null:
return initialDataLoadSuccess(_that.availableProjects,_that.availableValues);case TaskDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that.operation);case TaskDetailOperationFailure() when operationFailure != null:
return operationFailure(_that.errorDetails);case TaskDetailLoadInProgress() when loadInProgress != null:
return loadInProgress();case TaskDetailLoadSuccess() when loadSuccess != null:
return loadSuccess(_that.availableProjects,_that.availableValues,_that.task);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( ValidationFailure failure)  validationFailure,required TResult Function( List<Project> availableProjects,  List<Value> availableValues)  initialDataLoadSuccess,required TResult Function( EntityOperation operation)  operationSuccess,required TResult Function( DetailBlocError<Task> errorDetails)  operationFailure,required TResult Function()  loadInProgress,required TResult Function( List<Project> availableProjects,  List<Value> availableValues,  Task task)  loadSuccess,}) {final _that = this;
switch (_that) {
case TaskDetailInitial():
return initial();case TaskDetailValidationFailure():
return validationFailure(_that.failure);case TaskDetailInitialDataLoadSuccess():
return initialDataLoadSuccess(_that.availableProjects,_that.availableValues);case TaskDetailOperationSuccess():
return operationSuccess(_that.operation);case TaskDetailOperationFailure():
return operationFailure(_that.errorDetails);case TaskDetailLoadInProgress():
return loadInProgress();case TaskDetailLoadSuccess():
return loadSuccess(_that.availableProjects,_that.availableValues,_that.task);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( ValidationFailure failure)?  validationFailure,TResult? Function( List<Project> availableProjects,  List<Value> availableValues)?  initialDataLoadSuccess,TResult? Function( EntityOperation operation)?  operationSuccess,TResult? Function( DetailBlocError<Task> errorDetails)?  operationFailure,TResult? Function()?  loadInProgress,TResult? Function( List<Project> availableProjects,  List<Value> availableValues,  Task task)?  loadSuccess,}) {final _that = this;
switch (_that) {
case TaskDetailInitial() when initial != null:
return initial();case TaskDetailValidationFailure() when validationFailure != null:
return validationFailure(_that.failure);case TaskDetailInitialDataLoadSuccess() when initialDataLoadSuccess != null:
return initialDataLoadSuccess(_that.availableProjects,_that.availableValues);case TaskDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that.operation);case TaskDetailOperationFailure() when operationFailure != null:
return operationFailure(_that.errorDetails);case TaskDetailLoadInProgress() when loadInProgress != null:
return loadInProgress();case TaskDetailLoadSuccess() when loadSuccess != null:
return loadSuccess(_that.availableProjects,_that.availableValues,_that.task);case _:
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


class TaskDetailValidationFailure implements TaskDetailState {
  const TaskDetailValidationFailure({required this.failure});
  

 final  ValidationFailure failure;

/// Create a copy of TaskDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskDetailValidationFailureCopyWith<TaskDetailValidationFailure> get copyWith => _$TaskDetailValidationFailureCopyWithImpl<TaskDetailValidationFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskDetailValidationFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'TaskDetailState.validationFailure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $TaskDetailValidationFailureCopyWith<$Res> implements $TaskDetailStateCopyWith<$Res> {
  factory $TaskDetailValidationFailureCopyWith(TaskDetailValidationFailure value, $Res Function(TaskDetailValidationFailure) _then) = _$TaskDetailValidationFailureCopyWithImpl;
@useResult
$Res call({
 ValidationFailure failure
});




}
/// @nodoc
class _$TaskDetailValidationFailureCopyWithImpl<$Res>
    implements $TaskDetailValidationFailureCopyWith<$Res> {
  _$TaskDetailValidationFailureCopyWithImpl(this._self, this._then);

  final TaskDetailValidationFailure _self;
  final $Res Function(TaskDetailValidationFailure) _then;

/// Create a copy of TaskDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(TaskDetailValidationFailure(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as ValidationFailure,
  ));
}


}

/// @nodoc


class TaskDetailInitialDataLoadSuccess implements TaskDetailState {
  const TaskDetailInitialDataLoadSuccess({required final  List<Project> availableProjects, required final  List<Value> availableValues}): _availableProjects = availableProjects,_availableValues = availableValues;
  

 final  List<Project> _availableProjects;
 List<Project> get availableProjects {
  if (_availableProjects is EqualUnmodifiableListView) return _availableProjects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableProjects);
}

 final  List<Value> _availableValues;
 List<Value> get availableValues {
  if (_availableValues is EqualUnmodifiableListView) return _availableValues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableValues);
}


/// Create a copy of TaskDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskDetailInitialDataLoadSuccessCopyWith<TaskDetailInitialDataLoadSuccess> get copyWith => _$TaskDetailInitialDataLoadSuccessCopyWithImpl<TaskDetailInitialDataLoadSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskDetailInitialDataLoadSuccess&&const DeepCollectionEquality().equals(other._availableProjects, _availableProjects)&&const DeepCollectionEquality().equals(other._availableValues, _availableValues));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_availableProjects),const DeepCollectionEquality().hash(_availableValues));

@override
String toString() {
  return 'TaskDetailState.initialDataLoadSuccess(availableProjects: $availableProjects, availableValues: $availableValues)';
}


}

/// @nodoc
abstract mixin class $TaskDetailInitialDataLoadSuccessCopyWith<$Res> implements $TaskDetailStateCopyWith<$Res> {
  factory $TaskDetailInitialDataLoadSuccessCopyWith(TaskDetailInitialDataLoadSuccess value, $Res Function(TaskDetailInitialDataLoadSuccess) _then) = _$TaskDetailInitialDataLoadSuccessCopyWithImpl;
@useResult
$Res call({
 List<Project> availableProjects, List<Value> availableValues
});




}
/// @nodoc
class _$TaskDetailInitialDataLoadSuccessCopyWithImpl<$Res>
    implements $TaskDetailInitialDataLoadSuccessCopyWith<$Res> {
  _$TaskDetailInitialDataLoadSuccessCopyWithImpl(this._self, this._then);

  final TaskDetailInitialDataLoadSuccess _self;
  final $Res Function(TaskDetailInitialDataLoadSuccess) _then;

/// Create a copy of TaskDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? availableProjects = null,Object? availableValues = null,}) {
  return _then(TaskDetailInitialDataLoadSuccess(
availableProjects: null == availableProjects ? _self._availableProjects : availableProjects // ignore: cast_nullable_to_non_nullable
as List<Project>,availableValues: null == availableValues ? _self._availableValues : availableValues // ignore: cast_nullable_to_non_nullable
as List<Value>,
  ));
}


}

/// @nodoc


class TaskDetailOperationSuccess implements TaskDetailState {
  const TaskDetailOperationSuccess({required this.operation});
  

 final  EntityOperation operation;

/// Create a copy of TaskDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskDetailOperationSuccessCopyWith<TaskDetailOperationSuccess> get copyWith => _$TaskDetailOperationSuccessCopyWithImpl<TaskDetailOperationSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskDetailOperationSuccess&&(identical(other.operation, operation) || other.operation == operation));
}


@override
int get hashCode => Object.hash(runtimeType,operation);

@override
String toString() {
  return 'TaskDetailState.operationSuccess(operation: $operation)';
}


}

/// @nodoc
abstract mixin class $TaskDetailOperationSuccessCopyWith<$Res> implements $TaskDetailStateCopyWith<$Res> {
  factory $TaskDetailOperationSuccessCopyWith(TaskDetailOperationSuccess value, $Res Function(TaskDetailOperationSuccess) _then) = _$TaskDetailOperationSuccessCopyWithImpl;
@useResult
$Res call({
 EntityOperation operation
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
@pragma('vm:prefer-inline') $Res call({Object? operation = null,}) {
  return _then(TaskDetailOperationSuccess(
operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as EntityOperation,
  ));
}


}

/// @nodoc


class TaskDetailOperationFailure implements TaskDetailState {
  const TaskDetailOperationFailure({required this.errorDetails});
  

 final  DetailBlocError<Task> errorDetails;

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
 DetailBlocError<Task> errorDetails
});




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
as DetailBlocError<Task>,
  ));
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
  const TaskDetailLoadSuccess({required final  List<Project> availableProjects, required final  List<Value> availableValues, required this.task}): _availableProjects = availableProjects,_availableValues = availableValues;
  

 final  List<Project> _availableProjects;
 List<Project> get availableProjects {
  if (_availableProjects is EqualUnmodifiableListView) return _availableProjects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableProjects);
}

 final  List<Value> _availableValues;
 List<Value> get availableValues {
  if (_availableValues is EqualUnmodifiableListView) return _availableValues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableValues);
}

 final  Task task;

/// Create a copy of TaskDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskDetailLoadSuccessCopyWith<TaskDetailLoadSuccess> get copyWith => _$TaskDetailLoadSuccessCopyWithImpl<TaskDetailLoadSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskDetailLoadSuccess&&const DeepCollectionEquality().equals(other._availableProjects, _availableProjects)&&const DeepCollectionEquality().equals(other._availableValues, _availableValues)&&(identical(other.task, task) || other.task == task));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_availableProjects),const DeepCollectionEquality().hash(_availableValues),task);

@override
String toString() {
  return 'TaskDetailState.loadSuccess(availableProjects: $availableProjects, availableValues: $availableValues, task: $task)';
}


}

/// @nodoc
abstract mixin class $TaskDetailLoadSuccessCopyWith<$Res> implements $TaskDetailStateCopyWith<$Res> {
  factory $TaskDetailLoadSuccessCopyWith(TaskDetailLoadSuccess value, $Res Function(TaskDetailLoadSuccess) _then) = _$TaskDetailLoadSuccessCopyWithImpl;
@useResult
$Res call({
 List<Project> availableProjects, List<Value> availableValues, Task task
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
@pragma('vm:prefer-inline') $Res call({Object? availableProjects = null,Object? availableValues = null,Object? task = null,}) {
  return _then(TaskDetailLoadSuccess(
availableProjects: null == availableProjects ? _self._availableProjects : availableProjects // ignore: cast_nullable_to_non_nullable
as List<Project>,availableValues: null == availableValues ? _self._availableValues : availableValues // ignore: cast_nullable_to_non_nullable
as List<Value>,task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as Task,
  ));
}


}

// dart format on
