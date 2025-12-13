// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskModel {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskModel);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TaskModel()';
}


}

/// @nodoc
class $TaskModelCopyWith<$Res>  {
$TaskModelCopyWith(TaskModel _, $Res Function(TaskModel) __);
}


/// Adds pattern-matching-related methods to [TaskModel].
extension TaskModelPatterns on TaskModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TaskCreateRequest value)?  create,TResult Function( TaskUpdateRequest value)?  update,TResult Function( TaskDeleteRequest value)?  delete,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TaskCreateRequest() when create != null:
return create(_that);case TaskUpdateRequest() when update != null:
return update(_that);case TaskDeleteRequest() when delete != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TaskCreateRequest value)  create,required TResult Function( TaskUpdateRequest value)  update,required TResult Function( TaskDeleteRequest value)  delete,}){
final _that = this;
switch (_that) {
case TaskCreateRequest():
return create(_that);case TaskUpdateRequest():
return update(_that);case TaskDeleteRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TaskCreateRequest value)?  create,TResult? Function( TaskUpdateRequest value)?  update,TResult? Function( TaskDeleteRequest value)?  delete,}){
final _that = this;
switch (_that) {
case TaskCreateRequest() when create != null:
return create(_that);case TaskUpdateRequest() when update != null:
return update(_that);case TaskDeleteRequest() when delete != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String name,  bool? completed,  String? description)?  create,TResult Function( String id,  String name,  bool completed,  String? description)?  update,TResult Function( String id)?  delete,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TaskCreateRequest() when create != null:
return create(_that.name,_that.completed,_that.description);case TaskUpdateRequest() when update != null:
return update(_that.id,_that.name,_that.completed,_that.description);case TaskDeleteRequest() when delete != null:
return delete(_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String name,  bool? completed,  String? description)  create,required TResult Function( String id,  String name,  bool completed,  String? description)  update,required TResult Function( String id)  delete,}) {final _that = this;
switch (_that) {
case TaskCreateRequest():
return create(_that.name,_that.completed,_that.description);case TaskUpdateRequest():
return update(_that.id,_that.name,_that.completed,_that.description);case TaskDeleteRequest():
return delete(_that.id);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String name,  bool? completed,  String? description)?  create,TResult? Function( String id,  String name,  bool completed,  String? description)?  update,TResult? Function( String id)?  delete,}) {final _that = this;
switch (_that) {
case TaskCreateRequest() when create != null:
return create(_that.name,_that.completed,_that.description);case TaskUpdateRequest() when update != null:
return update(_that.id,_that.name,_that.completed,_that.description);case TaskDeleteRequest() when delete != null:
return delete(_that.id);case _:
  return null;

}
}

}

/// @nodoc


class TaskCreateRequest implements TaskModel {
  const TaskCreateRequest({required this.name, this.completed, this.description});
  

 final  String name;
 final  bool? completed;
 final  String? description;

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCreateRequestCopyWith<TaskCreateRequest> get copyWith => _$TaskCreateRequestCopyWithImpl<TaskCreateRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskCreateRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,name,completed,description);

@override
String toString() {
  return 'TaskModel.create(name: $name, completed: $completed, description: $description)';
}


}

/// @nodoc
abstract mixin class $TaskCreateRequestCopyWith<$Res> implements $TaskModelCopyWith<$Res> {
  factory $TaskCreateRequestCopyWith(TaskCreateRequest value, $Res Function(TaskCreateRequest) _then) = _$TaskCreateRequestCopyWithImpl;
@useResult
$Res call({
 String name, bool? completed, String? description
});




}
/// @nodoc
class _$TaskCreateRequestCopyWithImpl<$Res>
    implements $TaskCreateRequestCopyWith<$Res> {
  _$TaskCreateRequestCopyWithImpl(this._self, this._then);

  final TaskCreateRequest _self;
  final $Res Function(TaskCreateRequest) _then;

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? completed = freezed,Object? description = freezed,}) {
  return _then(TaskCreateRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,completed: freezed == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class TaskUpdateRequest implements TaskModel {
  const TaskUpdateRequest({required this.id, required this.name, required this.completed, required this.description});
  

 final  String id;
 final  String name;
 final  bool completed;
 final  String? description;

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskUpdateRequestCopyWith<TaskUpdateRequest> get copyWith => _$TaskUpdateRequestCopyWithImpl<TaskUpdateRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskUpdateRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,completed,description);

@override
String toString() {
  return 'TaskModel.update(id: $id, name: $name, completed: $completed, description: $description)';
}


}

/// @nodoc
abstract mixin class $TaskUpdateRequestCopyWith<$Res> implements $TaskModelCopyWith<$Res> {
  factory $TaskUpdateRequestCopyWith(TaskUpdateRequest value, $Res Function(TaskUpdateRequest) _then) = _$TaskUpdateRequestCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool completed, String? description
});




}
/// @nodoc
class _$TaskUpdateRequestCopyWithImpl<$Res>
    implements $TaskUpdateRequestCopyWith<$Res> {
  _$TaskUpdateRequestCopyWithImpl(this._self, this._then);

  final TaskUpdateRequest _self;
  final $Res Function(TaskUpdateRequest) _then;

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? completed = null,Object? description = freezed,}) {
  return _then(TaskUpdateRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class TaskDeleteRequest implements TaskModel {
  const TaskDeleteRequest({required this.id});
  

 final  String id;

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskDeleteRequestCopyWith<TaskDeleteRequest> get copyWith => _$TaskDeleteRequestCopyWithImpl<TaskDeleteRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskDeleteRequest&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'TaskModel.delete(id: $id)';
}


}

/// @nodoc
abstract mixin class $TaskDeleteRequestCopyWith<$Res> implements $TaskModelCopyWith<$Res> {
  factory $TaskDeleteRequestCopyWith(TaskDeleteRequest value, $Res Function(TaskDeleteRequest) _then) = _$TaskDeleteRequestCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$TaskDeleteRequestCopyWithImpl<$Res>
    implements $TaskDeleteRequestCopyWith<$Res> {
  _$TaskDeleteRequestCopyWithImpl(this._self, this._then);

  final TaskDeleteRequest _self;
  final $Res Function(TaskDeleteRequest) _then;

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(TaskDeleteRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
