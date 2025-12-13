// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'projects_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProjectsEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectsEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectsEvent()';
}


}

/// @nodoc
class $ProjectsEventCopyWith<$Res>  {
$ProjectsEventCopyWith(ProjectsEvent _, $Res Function(ProjectsEvent) __);
}


/// Adds pattern-matching-related methods to [ProjectsEvent].
extension ProjectsEventPatterns on ProjectsEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProjectsSubscriptionRequested value)?  projectsSubscriptionRequested,TResult Function( ProjectsUpdateProject value)?  updateProject,TResult Function( ProjectsDeleteProject value)?  deleteProject,TResult Function( ProjectsCreateProject value)?  createProject,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProjectsSubscriptionRequested() when projectsSubscriptionRequested != null:
return projectsSubscriptionRequested(_that);case ProjectsUpdateProject() when updateProject != null:
return updateProject(_that);case ProjectsDeleteProject() when deleteProject != null:
return deleteProject(_that);case ProjectsCreateProject() when createProject != null:
return createProject(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProjectsSubscriptionRequested value)  projectsSubscriptionRequested,required TResult Function( ProjectsUpdateProject value)  updateProject,required TResult Function( ProjectsDeleteProject value)  deleteProject,required TResult Function( ProjectsCreateProject value)  createProject,}){
final _that = this;
switch (_that) {
case ProjectsSubscriptionRequested():
return projectsSubscriptionRequested(_that);case ProjectsUpdateProject():
return updateProject(_that);case ProjectsDeleteProject():
return deleteProject(_that);case ProjectsCreateProject():
return createProject(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProjectsSubscriptionRequested value)?  projectsSubscriptionRequested,TResult? Function( ProjectsUpdateProject value)?  updateProject,TResult? Function( ProjectsDeleteProject value)?  deleteProject,TResult? Function( ProjectsCreateProject value)?  createProject,}){
final _that = this;
switch (_that) {
case ProjectsSubscriptionRequested() when projectsSubscriptionRequested != null:
return projectsSubscriptionRequested(_that);case ProjectsUpdateProject() when updateProject != null:
return updateProject(_that);case ProjectsDeleteProject() when deleteProject != null:
return deleteProject(_that);case ProjectsCreateProject() when createProject != null:
return createProject(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  projectsSubscriptionRequested,TResult Function( ProjectUpdateRequest updateRequest)?  updateProject,TResult Function( ProjectDeleteRequest deleteRequest)?  deleteProject,TResult Function( ProjectCreateRequest createRequest)?  createProject,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProjectsSubscriptionRequested() when projectsSubscriptionRequested != null:
return projectsSubscriptionRequested();case ProjectsUpdateProject() when updateProject != null:
return updateProject(_that.updateRequest);case ProjectsDeleteProject() when deleteProject != null:
return deleteProject(_that.deleteRequest);case ProjectsCreateProject() when createProject != null:
return createProject(_that.createRequest);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  projectsSubscriptionRequested,required TResult Function( ProjectUpdateRequest updateRequest)  updateProject,required TResult Function( ProjectDeleteRequest deleteRequest)  deleteProject,required TResult Function( ProjectCreateRequest createRequest)  createProject,}) {final _that = this;
switch (_that) {
case ProjectsSubscriptionRequested():
return projectsSubscriptionRequested();case ProjectsUpdateProject():
return updateProject(_that.updateRequest);case ProjectsDeleteProject():
return deleteProject(_that.deleteRequest);case ProjectsCreateProject():
return createProject(_that.createRequest);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  projectsSubscriptionRequested,TResult? Function( ProjectUpdateRequest updateRequest)?  updateProject,TResult? Function( ProjectDeleteRequest deleteRequest)?  deleteProject,TResult? Function( ProjectCreateRequest createRequest)?  createProject,}) {final _that = this;
switch (_that) {
case ProjectsSubscriptionRequested() when projectsSubscriptionRequested != null:
return projectsSubscriptionRequested();case ProjectsUpdateProject() when updateProject != null:
return updateProject(_that.updateRequest);case ProjectsDeleteProject() when deleteProject != null:
return deleteProject(_that.deleteRequest);case ProjectsCreateProject() when createProject != null:
return createProject(_that.createRequest);case _:
  return null;

}
}

}

/// @nodoc


class ProjectsSubscriptionRequested implements ProjectsEvent {
  const ProjectsSubscriptionRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectsSubscriptionRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectsEvent.projectsSubscriptionRequested()';
}


}




/// @nodoc


class ProjectsUpdateProject implements ProjectsEvent {
  const ProjectsUpdateProject({required this.updateRequest});
  

 final  ProjectUpdateRequest updateRequest;

/// Create a copy of ProjectsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectsUpdateProjectCopyWith<ProjectsUpdateProject> get copyWith => _$ProjectsUpdateProjectCopyWithImpl<ProjectsUpdateProject>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectsUpdateProject&&const DeepCollectionEquality().equals(other.updateRequest, updateRequest));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(updateRequest));

@override
String toString() {
  return 'ProjectsEvent.updateProject(updateRequest: $updateRequest)';
}


}

/// @nodoc
abstract mixin class $ProjectsUpdateProjectCopyWith<$Res> implements $ProjectsEventCopyWith<$Res> {
  factory $ProjectsUpdateProjectCopyWith(ProjectsUpdateProject value, $Res Function(ProjectsUpdateProject) _then) = _$ProjectsUpdateProjectCopyWithImpl;
@useResult
$Res call({
 ProjectUpdateRequest updateRequest
});




}
/// @nodoc
class _$ProjectsUpdateProjectCopyWithImpl<$Res>
    implements $ProjectsUpdateProjectCopyWith<$Res> {
  _$ProjectsUpdateProjectCopyWithImpl(this._self, this._then);

  final ProjectsUpdateProject _self;
  final $Res Function(ProjectsUpdateProject) _then;

/// Create a copy of ProjectsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? updateRequest = freezed,}) {
  return _then(ProjectsUpdateProject(
updateRequest: freezed == updateRequest ? _self.updateRequest : updateRequest // ignore: cast_nullable_to_non_nullable
as ProjectUpdateRequest,
  ));
}


}

/// @nodoc


class ProjectsDeleteProject implements ProjectsEvent {
  const ProjectsDeleteProject({required this.deleteRequest});
  

 final  ProjectDeleteRequest deleteRequest;

/// Create a copy of ProjectsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectsDeleteProjectCopyWith<ProjectsDeleteProject> get copyWith => _$ProjectsDeleteProjectCopyWithImpl<ProjectsDeleteProject>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectsDeleteProject&&const DeepCollectionEquality().equals(other.deleteRequest, deleteRequest));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(deleteRequest));

@override
String toString() {
  return 'ProjectsEvent.deleteProject(deleteRequest: $deleteRequest)';
}


}

/// @nodoc
abstract mixin class $ProjectsDeleteProjectCopyWith<$Res> implements $ProjectsEventCopyWith<$Res> {
  factory $ProjectsDeleteProjectCopyWith(ProjectsDeleteProject value, $Res Function(ProjectsDeleteProject) _then) = _$ProjectsDeleteProjectCopyWithImpl;
@useResult
$Res call({
 ProjectDeleteRequest deleteRequest
});




}
/// @nodoc
class _$ProjectsDeleteProjectCopyWithImpl<$Res>
    implements $ProjectsDeleteProjectCopyWith<$Res> {
  _$ProjectsDeleteProjectCopyWithImpl(this._self, this._then);

  final ProjectsDeleteProject _self;
  final $Res Function(ProjectsDeleteProject) _then;

/// Create a copy of ProjectsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? deleteRequest = freezed,}) {
  return _then(ProjectsDeleteProject(
deleteRequest: freezed == deleteRequest ? _self.deleteRequest : deleteRequest // ignore: cast_nullable_to_non_nullable
as ProjectDeleteRequest,
  ));
}


}

/// @nodoc


class ProjectsCreateProject implements ProjectsEvent {
  const ProjectsCreateProject({required this.createRequest});
  

 final  ProjectCreateRequest createRequest;

/// Create a copy of ProjectsEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectsCreateProjectCopyWith<ProjectsCreateProject> get copyWith => _$ProjectsCreateProjectCopyWithImpl<ProjectsCreateProject>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectsCreateProject&&const DeepCollectionEquality().equals(other.createRequest, createRequest));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(createRequest));

@override
String toString() {
  return 'ProjectsEvent.createProject(createRequest: $createRequest)';
}


}

/// @nodoc
abstract mixin class $ProjectsCreateProjectCopyWith<$Res> implements $ProjectsEventCopyWith<$Res> {
  factory $ProjectsCreateProjectCopyWith(ProjectsCreateProject value, $Res Function(ProjectsCreateProject) _then) = _$ProjectsCreateProjectCopyWithImpl;
@useResult
$Res call({
 ProjectCreateRequest createRequest
});




}
/// @nodoc
class _$ProjectsCreateProjectCopyWithImpl<$Res>
    implements $ProjectsCreateProjectCopyWith<$Res> {
  _$ProjectsCreateProjectCopyWithImpl(this._self, this._then);

  final ProjectsCreateProject _self;
  final $Res Function(ProjectsCreateProject) _then;

/// Create a copy of ProjectsEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? createRequest = freezed,}) {
  return _then(ProjectsCreateProject(
createRequest: freezed == createRequest ? _self.createRequest : createRequest // ignore: cast_nullable_to_non_nullable
as ProjectCreateRequest,
  ));
}


}

/// @nodoc
mixin _$ProjectsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectsState()';
}


}

/// @nodoc
class $ProjectsStateCopyWith<$Res>  {
$ProjectsStateCopyWith(ProjectsState _, $Res Function(ProjectsState) __);
}


/// Adds pattern-matching-related methods to [ProjectsState].
extension ProjectsStatePatterns on ProjectsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProjectsInitial value)?  initial,TResult Function( ProjectsLoading value)?  loading,TResult Function( ProjectsLoaded value)?  loaded,TResult Function( ProjectsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProjectsInitial() when initial != null:
return initial(_that);case ProjectsLoading() when loading != null:
return loading(_that);case ProjectsLoaded() when loaded != null:
return loaded(_that);case ProjectsError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProjectsInitial value)  initial,required TResult Function( ProjectsLoading value)  loading,required TResult Function( ProjectsLoaded value)  loaded,required TResult Function( ProjectsError value)  error,}){
final _that = this;
switch (_that) {
case ProjectsInitial():
return initial(_that);case ProjectsLoading():
return loading(_that);case ProjectsLoaded():
return loaded(_that);case ProjectsError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProjectsInitial value)?  initial,TResult? Function( ProjectsLoading value)?  loading,TResult? Function( ProjectsLoaded value)?  loaded,TResult? Function( ProjectsError value)?  error,}){
final _that = this;
switch (_that) {
case ProjectsInitial() when initial != null:
return initial(_that);case ProjectsLoading() when loading != null:
return loading(_that);case ProjectsLoaded() when loaded != null:
return loaded(_that);case ProjectsError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<ProjectDto> projects)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProjectsInitial() when initial != null:
return initial();case ProjectsLoading() when loading != null:
return loading();case ProjectsLoaded() when loaded != null:
return loaded(_that.projects);case ProjectsError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<ProjectDto> projects)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case ProjectsInitial():
return initial();case ProjectsLoading():
return loading();case ProjectsLoaded():
return loaded(_that.projects);case ProjectsError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<ProjectDto> projects)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case ProjectsInitial() when initial != null:
return initial();case ProjectsLoading() when loading != null:
return loading();case ProjectsLoaded() when loaded != null:
return loaded(_that.projects);case ProjectsError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ProjectsInitial implements ProjectsState {
  const ProjectsInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectsInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectsState.initial()';
}


}




/// @nodoc


class ProjectsLoading implements ProjectsState {
  const ProjectsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectsState.loading()';
}


}




/// @nodoc


class ProjectsLoaded implements ProjectsState {
  const ProjectsLoaded({required final  List<ProjectDto> projects}): _projects = projects;
  

 final  List<ProjectDto> _projects;
 List<ProjectDto> get projects {
  if (_projects is EqualUnmodifiableListView) return _projects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_projects);
}


/// Create a copy of ProjectsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectsLoadedCopyWith<ProjectsLoaded> get copyWith => _$ProjectsLoadedCopyWithImpl<ProjectsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectsLoaded&&const DeepCollectionEquality().equals(other._projects, _projects));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_projects));

@override
String toString() {
  return 'ProjectsState.loaded(projects: $projects)';
}


}

/// @nodoc
abstract mixin class $ProjectsLoadedCopyWith<$Res> implements $ProjectsStateCopyWith<$Res> {
  factory $ProjectsLoadedCopyWith(ProjectsLoaded value, $Res Function(ProjectsLoaded) _then) = _$ProjectsLoadedCopyWithImpl;
@useResult
$Res call({
 List<ProjectDto> projects
});




}
/// @nodoc
class _$ProjectsLoadedCopyWithImpl<$Res>
    implements $ProjectsLoadedCopyWith<$Res> {
  _$ProjectsLoadedCopyWithImpl(this._self, this._then);

  final ProjectsLoaded _self;
  final $Res Function(ProjectsLoaded) _then;

/// Create a copy of ProjectsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? projects = null,}) {
  return _then(ProjectsLoaded(
projects: null == projects ? _self._projects : projects // ignore: cast_nullable_to_non_nullable
as List<ProjectDto>,
  ));
}


}

/// @nodoc


class ProjectsError implements ProjectsState {
  const ProjectsError({required this.message});
  

 final  String message;

/// Create a copy of ProjectsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectsErrorCopyWith<ProjectsError> get copyWith => _$ProjectsErrorCopyWithImpl<ProjectsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectsError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ProjectsState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ProjectsErrorCopyWith<$Res> implements $ProjectsStateCopyWith<$Res> {
  factory $ProjectsErrorCopyWith(ProjectsError value, $Res Function(ProjectsError) _then) = _$ProjectsErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ProjectsErrorCopyWithImpl<$Res>
    implements $ProjectsErrorCopyWith<$Res> {
  _$ProjectsErrorCopyWithImpl(this._self, this._then);

  final ProjectsError _self;
  final $Res Function(ProjectsError) _then;

/// Create a copy of ProjectsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ProjectsError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
