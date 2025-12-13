// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProjectModel {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectModel);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectModel()';
}


}

/// @nodoc
class $ProjectModelCopyWith<$Res>  {
$ProjectModelCopyWith(ProjectModel _, $Res Function(ProjectModel) __);
}


/// Adds pattern-matching-related methods to [ProjectModel].
extension ProjectModelPatterns on ProjectModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProjectCreateRequest value)?  create,TResult Function( ProjectUpdateRequest value)?  update,TResult Function( ProjectDeleteRequest value)?  delete,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProjectCreateRequest() when create != null:
return create(_that);case ProjectUpdateRequest() when update != null:
return update(_that);case ProjectDeleteRequest() when delete != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProjectCreateRequest value)  create,required TResult Function( ProjectUpdateRequest value)  update,required TResult Function( ProjectDeleteRequest value)  delete,}){
final _that = this;
switch (_that) {
case ProjectCreateRequest():
return create(_that);case ProjectUpdateRequest():
return update(_that);case ProjectDeleteRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProjectCreateRequest value)?  create,TResult? Function( ProjectUpdateRequest value)?  update,TResult? Function( ProjectDeleteRequest value)?  delete,}){
final _that = this;
switch (_that) {
case ProjectCreateRequest() when create != null:
return create(_that);case ProjectUpdateRequest() when update != null:
return update(_that);case ProjectDeleteRequest() when delete != null:
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
case ProjectCreateRequest() when create != null:
return create(_that.name,_that.completed,_that.description);case ProjectUpdateRequest() when update != null:
return update(_that.id,_that.name,_that.completed,_that.description);case ProjectDeleteRequest() when delete != null:
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
case ProjectCreateRequest():
return create(_that.name,_that.completed,_that.description);case ProjectUpdateRequest():
return update(_that.id,_that.name,_that.completed,_that.description);case ProjectDeleteRequest():
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
case ProjectCreateRequest() when create != null:
return create(_that.name,_that.completed,_that.description);case ProjectUpdateRequest() when update != null:
return update(_that.id,_that.name,_that.completed,_that.description);case ProjectDeleteRequest() when delete != null:
return delete(_that.id);case _:
  return null;

}
}

}

/// @nodoc


class ProjectCreateRequest implements ProjectModel {
  const ProjectCreateRequest({required this.name, this.completed, this.description});
  

 final  String name;
 final  bool? completed;
 final  String? description;

/// Create a copy of ProjectModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectCreateRequestCopyWith<ProjectCreateRequest> get copyWith => _$ProjectCreateRequestCopyWithImpl<ProjectCreateRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectCreateRequest&&(identical(other.name, name) || other.name == name)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,name,completed,description);

@override
String toString() {
  return 'ProjectModel.create(name: $name, completed: $completed, description: $description)';
}


}

/// @nodoc
abstract mixin class $ProjectCreateRequestCopyWith<$Res> implements $ProjectModelCopyWith<$Res> {
  factory $ProjectCreateRequestCopyWith(ProjectCreateRequest value, $Res Function(ProjectCreateRequest) _then) = _$ProjectCreateRequestCopyWithImpl;
@useResult
$Res call({
 String name, bool? completed, String? description
});




}
/// @nodoc
class _$ProjectCreateRequestCopyWithImpl<$Res>
    implements $ProjectCreateRequestCopyWith<$Res> {
  _$ProjectCreateRequestCopyWithImpl(this._self, this._then);

  final ProjectCreateRequest _self;
  final $Res Function(ProjectCreateRequest) _then;

/// Create a copy of ProjectModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? completed = freezed,Object? description = freezed,}) {
  return _then(ProjectCreateRequest(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,completed: freezed == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ProjectUpdateRequest implements ProjectModel {
  const ProjectUpdateRequest({required this.id, required this.name, required this.completed, required this.description});
  

 final  String id;
 final  String name;
 final  bool completed;
 final  String? description;

/// Create a copy of ProjectModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectUpdateRequestCopyWith<ProjectUpdateRequest> get copyWith => _$ProjectUpdateRequestCopyWithImpl<ProjectUpdateRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectUpdateRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,completed,description);

@override
String toString() {
  return 'ProjectModel.update(id: $id, name: $name, completed: $completed, description: $description)';
}


}

/// @nodoc
abstract mixin class $ProjectUpdateRequestCopyWith<$Res> implements $ProjectModelCopyWith<$Res> {
  factory $ProjectUpdateRequestCopyWith(ProjectUpdateRequest value, $Res Function(ProjectUpdateRequest) _then) = _$ProjectUpdateRequestCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool completed, String? description
});




}
/// @nodoc
class _$ProjectUpdateRequestCopyWithImpl<$Res>
    implements $ProjectUpdateRequestCopyWith<$Res> {
  _$ProjectUpdateRequestCopyWithImpl(this._self, this._then);

  final ProjectUpdateRequest _self;
  final $Res Function(ProjectUpdateRequest) _then;

/// Create a copy of ProjectModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? completed = null,Object? description = freezed,}) {
  return _then(ProjectUpdateRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ProjectDeleteRequest implements ProjectModel {
  const ProjectDeleteRequest({required this.id});
  

 final  String id;

/// Create a copy of ProjectModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectDeleteRequestCopyWith<ProjectDeleteRequest> get copyWith => _$ProjectDeleteRequestCopyWithImpl<ProjectDeleteRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDeleteRequest&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ProjectModel.delete(id: $id)';
}


}

/// @nodoc
abstract mixin class $ProjectDeleteRequestCopyWith<$Res> implements $ProjectModelCopyWith<$Res> {
  factory $ProjectDeleteRequestCopyWith(ProjectDeleteRequest value, $Res Function(ProjectDeleteRequest) _then) = _$ProjectDeleteRequestCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$ProjectDeleteRequestCopyWithImpl<$Res>
    implements $ProjectDeleteRequestCopyWith<$Res> {
  _$ProjectDeleteRequestCopyWithImpl(this._self, this._then);

  final ProjectDeleteRequest _self;
  final $Res Function(ProjectDeleteRequest) _then;

/// Create a copy of ProjectModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(ProjectDeleteRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
