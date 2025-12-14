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
mixin _$ProjectActionRequest {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectActionRequest);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectActionRequest()';
}


}

/// @nodoc
class $ProjectActionRequestCopyWith<$Res>  {
$ProjectActionRequestCopyWith(ProjectActionRequest _, $Res Function(ProjectActionRequest) __);
}


/// Adds pattern-matching-related methods to [ProjectActionRequest].
extension ProjectActionRequestPatterns on ProjectActionRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProjectActionRequestCreate value)?  create,TResult Function( ProjectActionRequestUpdate value)?  update,TResult Function( ProjectActionRequestDelete value)?  delete,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProjectActionRequestCreate() when create != null:
return create(_that);case ProjectActionRequestUpdate() when update != null:
return update(_that);case ProjectActionRequestDelete() when delete != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProjectActionRequestCreate value)  create,required TResult Function( ProjectActionRequestUpdate value)  update,required TResult Function( ProjectActionRequestDelete value)  delete,}){
final _that = this;
switch (_that) {
case ProjectActionRequestCreate():
return create(_that);case ProjectActionRequestUpdate():
return update(_that);case ProjectActionRequestDelete():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProjectActionRequestCreate value)?  create,TResult? Function( ProjectActionRequestUpdate value)?  update,TResult? Function( ProjectActionRequestDelete value)?  delete,}){
final _that = this;
switch (_that) {
case ProjectActionRequestCreate() when create != null:
return create(_that);case ProjectActionRequestUpdate() when update != null:
return update(_that);case ProjectActionRequestDelete() when delete != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String name,  bool? completed,  String? description)?  create,TResult Function( ProjectDto projectToUpdate,  String? name,  bool? completed,  String? description)?  update,TResult Function( ProjectDto projectToDelete)?  delete,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProjectActionRequestCreate() when create != null:
return create(_that.name,_that.completed,_that.description);case ProjectActionRequestUpdate() when update != null:
return update(_that.projectToUpdate,_that.name,_that.completed,_that.description);case ProjectActionRequestDelete() when delete != null:
return delete(_that.projectToDelete);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String name,  bool? completed,  String? description)  create,required TResult Function( ProjectDto projectToUpdate,  String? name,  bool? completed,  String? description)  update,required TResult Function( ProjectDto projectToDelete)  delete,}) {final _that = this;
switch (_that) {
case ProjectActionRequestCreate():
return create(_that.name,_that.completed,_that.description);case ProjectActionRequestUpdate():
return update(_that.projectToUpdate,_that.name,_that.completed,_that.description);case ProjectActionRequestDelete():
return delete(_that.projectToDelete);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String name,  bool? completed,  String? description)?  create,TResult? Function( ProjectDto projectToUpdate,  String? name,  bool? completed,  String? description)?  update,TResult? Function( ProjectDto projectToDelete)?  delete,}) {final _that = this;
switch (_that) {
case ProjectActionRequestCreate() when create != null:
return create(_that.name,_that.completed,_that.description);case ProjectActionRequestUpdate() when update != null:
return update(_that.projectToUpdate,_that.name,_that.completed,_that.description);case ProjectActionRequestDelete() when delete != null:
return delete(_that.projectToDelete);case _:
  return null;

}
}

}

/// @nodoc


class ProjectActionRequestCreate implements ProjectActionRequest {
  const ProjectActionRequestCreate({required this.name, this.completed, this.description});
  

 final  String name;
 final  bool? completed;
 final  String? description;

/// Create a copy of ProjectActionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectActionRequestCreateCopyWith<ProjectActionRequestCreate> get copyWith => _$ProjectActionRequestCreateCopyWithImpl<ProjectActionRequestCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectActionRequestCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,name,completed,description);

@override
String toString() {
  return 'ProjectActionRequest.create(name: $name, completed: $completed, description: $description)';
}


}

/// @nodoc
abstract mixin class $ProjectActionRequestCreateCopyWith<$Res> implements $ProjectActionRequestCopyWith<$Res> {
  factory $ProjectActionRequestCreateCopyWith(ProjectActionRequestCreate value, $Res Function(ProjectActionRequestCreate) _then) = _$ProjectActionRequestCreateCopyWithImpl;
@useResult
$Res call({
 String name, bool? completed, String? description
});




}
/// @nodoc
class _$ProjectActionRequestCreateCopyWithImpl<$Res>
    implements $ProjectActionRequestCreateCopyWith<$Res> {
  _$ProjectActionRequestCreateCopyWithImpl(this._self, this._then);

  final ProjectActionRequestCreate _self;
  final $Res Function(ProjectActionRequestCreate) _then;

/// Create a copy of ProjectActionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? completed = freezed,Object? description = freezed,}) {
  return _then(ProjectActionRequestCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,completed: freezed == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ProjectActionRequestUpdate implements ProjectActionRequest {
  const ProjectActionRequestUpdate({required this.projectToUpdate, required this.name, required this.completed, required this.description});
  

 final  ProjectDto projectToUpdate;
 final  String? name;
 final  bool? completed;
 final  String? description;

/// Create a copy of ProjectActionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectActionRequestUpdateCopyWith<ProjectActionRequestUpdate> get copyWith => _$ProjectActionRequestUpdateCopyWithImpl<ProjectActionRequestUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectActionRequestUpdate&&(identical(other.projectToUpdate, projectToUpdate) || other.projectToUpdate == projectToUpdate)&&(identical(other.name, name) || other.name == name)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,projectToUpdate,name,completed,description);

@override
String toString() {
  return 'ProjectActionRequest.update(projectToUpdate: $projectToUpdate, name: $name, completed: $completed, description: $description)';
}


}

/// @nodoc
abstract mixin class $ProjectActionRequestUpdateCopyWith<$Res> implements $ProjectActionRequestCopyWith<$Res> {
  factory $ProjectActionRequestUpdateCopyWith(ProjectActionRequestUpdate value, $Res Function(ProjectActionRequestUpdate) _then) = _$ProjectActionRequestUpdateCopyWithImpl;
@useResult
$Res call({
 ProjectDto projectToUpdate, String? name, bool? completed, String? description
});


$ProjectDtoCopyWith<$Res> get projectToUpdate;

}
/// @nodoc
class _$ProjectActionRequestUpdateCopyWithImpl<$Res>
    implements $ProjectActionRequestUpdateCopyWith<$Res> {
  _$ProjectActionRequestUpdateCopyWithImpl(this._self, this._then);

  final ProjectActionRequestUpdate _self;
  final $Res Function(ProjectActionRequestUpdate) _then;

/// Create a copy of ProjectActionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? projectToUpdate = null,Object? name = freezed,Object? completed = freezed,Object? description = freezed,}) {
  return _then(ProjectActionRequestUpdate(
projectToUpdate: null == projectToUpdate ? _self.projectToUpdate : projectToUpdate // ignore: cast_nullable_to_non_nullable
as ProjectDto,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,completed: freezed == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ProjectActionRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectDtoCopyWith<$Res> get projectToUpdate {
  
  return $ProjectDtoCopyWith<$Res>(_self.projectToUpdate, (value) {
    return _then(_self.copyWith(projectToUpdate: value));
  });
}
}

/// @nodoc


class ProjectActionRequestDelete implements ProjectActionRequest {
  const ProjectActionRequestDelete({required this.projectToDelete});
  

 final  ProjectDto projectToDelete;

/// Create a copy of ProjectActionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectActionRequestDeleteCopyWith<ProjectActionRequestDelete> get copyWith => _$ProjectActionRequestDeleteCopyWithImpl<ProjectActionRequestDelete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectActionRequestDelete&&(identical(other.projectToDelete, projectToDelete) || other.projectToDelete == projectToDelete));
}


@override
int get hashCode => Object.hash(runtimeType,projectToDelete);

@override
String toString() {
  return 'ProjectActionRequest.delete(projectToDelete: $projectToDelete)';
}


}

/// @nodoc
abstract mixin class $ProjectActionRequestDeleteCopyWith<$Res> implements $ProjectActionRequestCopyWith<$Res> {
  factory $ProjectActionRequestDeleteCopyWith(ProjectActionRequestDelete value, $Res Function(ProjectActionRequestDelete) _then) = _$ProjectActionRequestDeleteCopyWithImpl;
@useResult
$Res call({
 ProjectDto projectToDelete
});


$ProjectDtoCopyWith<$Res> get projectToDelete;

}
/// @nodoc
class _$ProjectActionRequestDeleteCopyWithImpl<$Res>
    implements $ProjectActionRequestDeleteCopyWith<$Res> {
  _$ProjectActionRequestDeleteCopyWithImpl(this._self, this._then);

  final ProjectActionRequestDelete _self;
  final $Res Function(ProjectActionRequestDelete) _then;

/// Create a copy of ProjectActionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? projectToDelete = null,}) {
  return _then(ProjectActionRequestDelete(
projectToDelete: null == projectToDelete ? _self.projectToDelete : projectToDelete // ignore: cast_nullable_to_non_nullable
as ProjectDto,
  ));
}

/// Create a copy of ProjectActionRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectDtoCopyWith<$Res> get projectToDelete {
  
  return $ProjectDtoCopyWith<$Res>(_self.projectToDelete, (value) {
    return _then(_self.copyWith(projectToDelete: value));
  });
}
}

// dart format on
