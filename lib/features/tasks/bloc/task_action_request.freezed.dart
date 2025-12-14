// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_action_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskActionRequest {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskActionRequest);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskActionRequest()';
}


}

/// @nodoc
class $TaskActionRequestCopyWith<$Res>  {
$TaskActionRequestCopyWith(TaskActionRequest _, $Res Function(TaskActionRequest) __);
}


/// Adds pattern-matching-related methods to [TaskActionRequest].
extension TaskActionRequestPatterns on TaskActionRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TaskActionRequestCreate value)?  create,TResult Function( TaskActionRequestUpdate value)?  update,TResult Function( TaskActionRequestDelete value)?  delete,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TaskActionRequestCreate() when create != null:
return create(_that);case TaskActionRequestUpdate() when update != null:
return update(_that);case TaskActionRequestDelete() when delete != null:
return delete(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TaskActionRequestCreate value)  create,required TResult Function( TaskActionRequestUpdate value)  update,required TResult Function( TaskActionRequestDelete value)  delete,}){
final _that = this;
switch (_that) {
case TaskActionRequestCreate():
return create(_that);case TaskActionRequestUpdate():
return update(_that);case TaskActionRequestDelete():
return delete(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TaskActionRequestCreate value)?  create,TResult? Function( TaskActionRequestUpdate value)?  update,TResult? Function( TaskActionRequestDelete value)?  delete,}){
final _that = this;
switch (_that) {
case TaskActionRequestCreate() when create != null:
return create(_that);case TaskActionRequestUpdate() when update != null:
return update(_that);case TaskActionRequestDelete() when delete != null:
return delete(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String name,  bool? completed,  String? description)?  create,TResult Function( TaskDto taskToUpdate,  String? name,  bool? completed,  String? description)?  update,TResult Function( TaskDto taskToDelete)?  delete,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TaskActionRequestCreate() when create != null:
return create(_that.name,_that.completed,_that.description);case TaskActionRequestUpdate() when update != null:
return update(_that.taskToUpdate,_that.name,_that.completed,_that.description);case TaskActionRequestDelete() when delete != null:
return delete(_that.taskToDelete);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String name,  bool? completed,  String? description)  create,required TResult Function( TaskDto taskToUpdate,  String? name,  bool? completed,  String? description)  update,required TResult Function( TaskDto taskToDelete)  delete,}) {final _that = this;
switch (_that) {
case TaskActionRequestCreate():
return create(_that.name,_that.completed,_that.description);case TaskActionRequestUpdate():
return update(_that.taskToUpdate,_that.name,_that.completed,_that.description);case TaskActionRequestDelete():
return delete(_that.taskToDelete);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String name,  bool? completed,  String? description)?  create,TResult? Function( TaskDto taskToUpdate,  String? name,  bool? completed,  String? description)?  update,TResult? Function( TaskDto taskToDelete)?  delete,}) {final _that = this;
switch (_that) {
case TaskActionRequestCreate() when create != null:
return create(_that.name,_that.completed,_that.description);case TaskActionRequestUpdate() when update != null:
return update(_that.taskToUpdate,_that.name,_that.completed,_that.description);case TaskActionRequestDelete() when delete != null:
return delete(_that.taskToDelete);case _:
  return null;

}
}

}

/// @nodoc


class TaskActionRequestCreate implements TaskActionRequest {
  const TaskActionRequestCreate({required this.name, this.completed, this.description});
  

 final  String name;
 final  bool? completed;
 final  String? description;

/// Create a copy of TaskActionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskActionRequestCreateCopyWith<TaskActionRequestCreate> get copyWith => _$TaskActionRequestCreateCopyWithImpl<TaskActionRequestCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskActionRequestCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,name,completed,description);

@override
String toString() {
  return 'TaskActionRequest.create(name: $name, completed: $completed, description: $description)';
}


}

/// @nodoc
abstract mixin class $TaskActionRequestCreateCopyWith<$Res> implements $TaskActionRequestCopyWith<$Res> {
  factory $TaskActionRequestCreateCopyWith(TaskActionRequestCreate value, $Res Function(TaskActionRequestCreate) _then) = _$TaskActionRequestCreateCopyWithImpl;
@useResult
$Res call({
 String name, bool? completed, String? description
});




}
/// @nodoc
class _$TaskActionRequestCreateCopyWithImpl<$Res>
    implements $TaskActionRequestCreateCopyWith<$Res> {
  _$TaskActionRequestCreateCopyWithImpl(this._self, this._then);

  final TaskActionRequestCreate _self;
  final $Res Function(TaskActionRequestCreate) _then;

/// Create a copy of TaskActionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? completed = freezed,Object? description = freezed,}) {
  return _then(TaskActionRequestCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,completed: freezed == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class TaskActionRequestUpdate implements TaskActionRequest {
  const TaskActionRequestUpdate({required this.taskToUpdate, required this.name, required this.completed, required this.description});
  

 final  TaskDto taskToUpdate;
 final  String? name;
 final  bool? completed;
 final  String? description;

/// Create a copy of TaskActionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskActionRequestUpdateCopyWith<TaskActionRequestUpdate> get copyWith => _$TaskActionRequestUpdateCopyWithImpl<TaskActionRequestUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskActionRequestUpdate&&(identical(other.taskToUpdate, taskToUpdate) || other.taskToUpdate == taskToUpdate)&&(identical(other.name, name) || other.name == name)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,taskToUpdate,name,completed,description);

@override
String toString() {
  return 'TaskActionRequest.update(taskToUpdate: $taskToUpdate, name: $name, completed: $completed, description: $description)';
}


}

/// @nodoc
abstract mixin class $TaskActionRequestUpdateCopyWith<$Res> implements $TaskActionRequestCopyWith<$Res> {
  factory $TaskActionRequestUpdateCopyWith(TaskActionRequestUpdate value, $Res Function(TaskActionRequestUpdate) _then) = _$TaskActionRequestUpdateCopyWithImpl;
@useResult
$Res call({
 TaskDto taskToUpdate, String? name, bool? completed, String? description
});


$TaskDtoCopyWith<$Res> get taskToUpdate;

}
/// @nodoc
class _$TaskActionRequestUpdateCopyWithImpl<$Res>
    implements $TaskActionRequestUpdateCopyWith<$Res> {
  _$TaskActionRequestUpdateCopyWithImpl(this._self, this._then);

  final TaskActionRequestUpdate _self;
  final $Res Function(TaskActionRequestUpdate) _then;

/// Create a copy of TaskActionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? taskToUpdate = null,Object? name = freezed,Object? completed = freezed,Object? description = freezed,}) {
  return _then(TaskActionRequestUpdate(
taskToUpdate: null == taskToUpdate ? _self.taskToUpdate : taskToUpdate // ignore: cast_nullable_to_non_nullable
as TaskDto,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,completed: freezed == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of TaskActionRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskDtoCopyWith<$Res> get taskToUpdate {
  
  return $TaskDtoCopyWith<$Res>(_self.taskToUpdate, (value) {
    return _then(_self.copyWith(taskToUpdate: value));
  });
}
}

/// @nodoc


class TaskActionRequestDelete implements TaskActionRequest {
  const TaskActionRequestDelete({required this.taskToDelete});
  

 final  TaskDto taskToDelete;

/// Create a copy of TaskActionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskActionRequestDeleteCopyWith<TaskActionRequestDelete> get copyWith => _$TaskActionRequestDeleteCopyWithImpl<TaskActionRequestDelete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskActionRequestDelete&&(identical(other.taskToDelete, taskToDelete) || other.taskToDelete == taskToDelete));
}


@override
int get hashCode => Object.hash(runtimeType,taskToDelete);

@override
String toString() {
  return 'TaskActionRequest.delete(taskToDelete: $taskToDelete)';
}


}

/// @nodoc
abstract mixin class $TaskActionRequestDeleteCopyWith<$Res> implements $TaskActionRequestCopyWith<$Res> {
  factory $TaskActionRequestDeleteCopyWith(TaskActionRequestDelete value, $Res Function(TaskActionRequestDelete) _then) = _$TaskActionRequestDeleteCopyWithImpl;
@useResult
$Res call({
 TaskDto taskToDelete
});


$TaskDtoCopyWith<$Res> get taskToDelete;

}
/// @nodoc
class _$TaskActionRequestDeleteCopyWithImpl<$Res>
    implements $TaskActionRequestDeleteCopyWith<$Res> {
  _$TaskActionRequestDeleteCopyWithImpl(this._self, this._then);

  final TaskActionRequestDelete _self;
  final $Res Function(TaskActionRequestDelete) _then;

/// Create a copy of TaskActionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? taskToDelete = null,}) {
  return _then(TaskActionRequestDelete(
taskToDelete: null == taskToDelete ? _self.taskToDelete : taskToDelete // ignore: cast_nullable_to_non_nullable
as TaskDto,
  ));
}

/// Create a copy of TaskActionRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TaskDtoCopyWith<$Res> get taskToDelete {
  
  return $TaskDtoCopyWith<$Res>(_self.taskToDelete, (value) {
    return _then(_self.copyWith(taskToDelete: value));
  });
}
}

// dart format on
