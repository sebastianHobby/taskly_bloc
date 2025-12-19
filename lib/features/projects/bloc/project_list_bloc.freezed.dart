// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_list_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProjectOverviewEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectOverviewEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectOverviewEvent()';
}


}

/// @nodoc
class $ProjectOverviewEventCopyWith<$Res>  {
$ProjectOverviewEventCopyWith(ProjectOverviewEvent _, $Res Function(ProjectOverviewEvent) __);
}


/// Adds pattern-matching-related methods to [ProjectOverviewEvent].
extension ProjectOverviewEventPatterns on ProjectOverviewEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProjectOverviewSubscriptionRequested value)?  projectsSubscriptionRequested,TResult Function( ProjectOverviewToggleProjectCompletion value)?  toggleProjectCompletion,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProjectOverviewSubscriptionRequested() when projectsSubscriptionRequested != null:
return projectsSubscriptionRequested(_that);case ProjectOverviewToggleProjectCompletion() when toggleProjectCompletion != null:
return toggleProjectCompletion(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProjectOverviewSubscriptionRequested value)  projectsSubscriptionRequested,required TResult Function( ProjectOverviewToggleProjectCompletion value)  toggleProjectCompletion,}){
final _that = this;
switch (_that) {
case ProjectOverviewSubscriptionRequested():
return projectsSubscriptionRequested(_that);case ProjectOverviewToggleProjectCompletion():
return toggleProjectCompletion(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProjectOverviewSubscriptionRequested value)?  projectsSubscriptionRequested,TResult? Function( ProjectOverviewToggleProjectCompletion value)?  toggleProjectCompletion,}){
final _that = this;
switch (_that) {
case ProjectOverviewSubscriptionRequested() when projectsSubscriptionRequested != null:
return projectsSubscriptionRequested(_that);case ProjectOverviewToggleProjectCompletion() when toggleProjectCompletion != null:
return toggleProjectCompletion(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  projectsSubscriptionRequested,TResult Function( ProjectTableData projectData)?  toggleProjectCompletion,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProjectOverviewSubscriptionRequested() when projectsSubscriptionRequested != null:
return projectsSubscriptionRequested();case ProjectOverviewToggleProjectCompletion() when toggleProjectCompletion != null:
return toggleProjectCompletion(_that.projectData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  projectsSubscriptionRequested,required TResult Function( ProjectTableData projectData)  toggleProjectCompletion,}) {final _that = this;
switch (_that) {
case ProjectOverviewSubscriptionRequested():
return projectsSubscriptionRequested();case ProjectOverviewToggleProjectCompletion():
return toggleProjectCompletion(_that.projectData);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  projectsSubscriptionRequested,TResult? Function( ProjectTableData projectData)?  toggleProjectCompletion,}) {final _that = this;
switch (_that) {
case ProjectOverviewSubscriptionRequested() when projectsSubscriptionRequested != null:
return projectsSubscriptionRequested();case ProjectOverviewToggleProjectCompletion() when toggleProjectCompletion != null:
return toggleProjectCompletion(_that.projectData);case _:
  return null;

}
}

}

/// @nodoc


class ProjectOverviewSubscriptionRequested implements ProjectOverviewEvent {
  const ProjectOverviewSubscriptionRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectOverviewSubscriptionRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectOverviewEvent.projectsSubscriptionRequested()';
}


}




/// @nodoc


class ProjectOverviewToggleProjectCompletion implements ProjectOverviewEvent {
  const ProjectOverviewToggleProjectCompletion({required this.projectData});
  

 final  ProjectTableData projectData;

/// Create a copy of ProjectOverviewEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectOverviewToggleProjectCompletionCopyWith<ProjectOverviewToggleProjectCompletion> get copyWith => _$ProjectOverviewToggleProjectCompletionCopyWithImpl<ProjectOverviewToggleProjectCompletion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectOverviewToggleProjectCompletion&&const DeepCollectionEquality().equals(other.projectData, projectData));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(projectData));

@override
String toString() {
  return 'ProjectOverviewEvent.toggleProjectCompletion(projectData: $projectData)';
}


}

/// @nodoc
abstract mixin class $ProjectOverviewToggleProjectCompletionCopyWith<$Res> implements $ProjectOverviewEventCopyWith<$Res> {
  factory $ProjectOverviewToggleProjectCompletionCopyWith(ProjectOverviewToggleProjectCompletion value, $Res Function(ProjectOverviewToggleProjectCompletion) _then) = _$ProjectOverviewToggleProjectCompletionCopyWithImpl;
@useResult
$Res call({
 ProjectTableData projectData
});




}
/// @nodoc
class _$ProjectOverviewToggleProjectCompletionCopyWithImpl<$Res>
    implements $ProjectOverviewToggleProjectCompletionCopyWith<$Res> {
  _$ProjectOverviewToggleProjectCompletionCopyWithImpl(this._self, this._then);

  final ProjectOverviewToggleProjectCompletion _self;
  final $Res Function(ProjectOverviewToggleProjectCompletion) _then;

/// Create a copy of ProjectOverviewEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? projectData = freezed,}) {
  return _then(ProjectOverviewToggleProjectCompletion(
projectData: freezed == projectData ? _self.projectData : projectData // ignore: cast_nullable_to_non_nullable
as ProjectTableData,
  ));
}


}

/// @nodoc
mixin _$ProjectOverviewState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectOverviewState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectOverviewState()';
}


}

/// @nodoc
class $ProjectOverviewStateCopyWith<$Res>  {
$ProjectOverviewStateCopyWith(ProjectOverviewState _, $Res Function(ProjectOverviewState) __);
}


/// Adds pattern-matching-related methods to [ProjectOverviewState].
extension ProjectOverviewStatePatterns on ProjectOverviewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProjectOverviewInitial value)?  initial,TResult Function( ProjectOverviewLoading value)?  loading,TResult Function( ProjectOverviewLoaded value)?  loaded,TResult Function( ProjectOverviewError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProjectOverviewInitial() when initial != null:
return initial(_that);case ProjectOverviewLoading() when loading != null:
return loading(_that);case ProjectOverviewLoaded() when loaded != null:
return loaded(_that);case ProjectOverviewError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProjectOverviewInitial value)  initial,required TResult Function( ProjectOverviewLoading value)  loading,required TResult Function( ProjectOverviewLoaded value)  loaded,required TResult Function( ProjectOverviewError value)  error,}){
final _that = this;
switch (_that) {
case ProjectOverviewInitial():
return initial(_that);case ProjectOverviewLoading():
return loading(_that);case ProjectOverviewLoaded():
return loaded(_that);case ProjectOverviewError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProjectOverviewInitial value)?  initial,TResult? Function( ProjectOverviewLoading value)?  loading,TResult? Function( ProjectOverviewLoaded value)?  loaded,TResult? Function( ProjectOverviewError value)?  error,}){
final _that = this;
switch (_that) {
case ProjectOverviewInitial() when initial != null:
return initial(_that);case ProjectOverviewLoading() when loading != null:
return loading(_that);case ProjectOverviewLoaded() when loaded != null:
return loaded(_that);case ProjectOverviewError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<ProjectTableData> projects)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProjectOverviewInitial() when initial != null:
return initial();case ProjectOverviewLoading() when loading != null:
return loading();case ProjectOverviewLoaded() when loaded != null:
return loaded(_that.projects);case ProjectOverviewError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<ProjectTableData> projects)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case ProjectOverviewInitial():
return initial();case ProjectOverviewLoading():
return loading();case ProjectOverviewLoaded():
return loaded(_that.projects);case ProjectOverviewError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<ProjectTableData> projects)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case ProjectOverviewInitial() when initial != null:
return initial();case ProjectOverviewLoading() when loading != null:
return loading();case ProjectOverviewLoaded() when loaded != null:
return loaded(_that.projects);case ProjectOverviewError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ProjectOverviewInitial implements ProjectOverviewState {
  const ProjectOverviewInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectOverviewInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectOverviewState.initial()';
}


}




/// @nodoc


class ProjectOverviewLoading implements ProjectOverviewState {
  const ProjectOverviewLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectOverviewLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectOverviewState.loading()';
}


}




/// @nodoc


class ProjectOverviewLoaded implements ProjectOverviewState {
  const ProjectOverviewLoaded({required final  List<ProjectTableData> projects}): _projects = projects;
  

 final  List<ProjectTableData> _projects;
 List<ProjectTableData> get projects {
  if (_projects is EqualUnmodifiableListView) return _projects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_projects);
}


/// Create a copy of ProjectOverviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectOverviewLoadedCopyWith<ProjectOverviewLoaded> get copyWith => _$ProjectOverviewLoadedCopyWithImpl<ProjectOverviewLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectOverviewLoaded&&const DeepCollectionEquality().equals(other._projects, _projects));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_projects));

@override
String toString() {
  return 'ProjectOverviewState.loaded(projects: $projects)';
}


}

/// @nodoc
abstract mixin class $ProjectOverviewLoadedCopyWith<$Res> implements $ProjectOverviewStateCopyWith<$Res> {
  factory $ProjectOverviewLoadedCopyWith(ProjectOverviewLoaded value, $Res Function(ProjectOverviewLoaded) _then) = _$ProjectOverviewLoadedCopyWithImpl;
@useResult
$Res call({
 List<ProjectTableData> projects
});




}
/// @nodoc
class _$ProjectOverviewLoadedCopyWithImpl<$Res>
    implements $ProjectOverviewLoadedCopyWith<$Res> {
  _$ProjectOverviewLoadedCopyWithImpl(this._self, this._then);

  final ProjectOverviewLoaded _self;
  final $Res Function(ProjectOverviewLoaded) _then;

/// Create a copy of ProjectOverviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? projects = null,}) {
  return _then(ProjectOverviewLoaded(
projects: null == projects ? _self._projects : projects // ignore: cast_nullable_to_non_nullable
as List<ProjectTableData>,
  ));
}


}

/// @nodoc


class ProjectOverviewError implements ProjectOverviewState {
  const ProjectOverviewError({required this.message});
  

 final  String message;

/// Create a copy of ProjectOverviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectOverviewErrorCopyWith<ProjectOverviewError> get copyWith => _$ProjectOverviewErrorCopyWithImpl<ProjectOverviewError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectOverviewError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ProjectOverviewState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ProjectOverviewErrorCopyWith<$Res> implements $ProjectOverviewStateCopyWith<$Res> {
  factory $ProjectOverviewErrorCopyWith(ProjectOverviewError value, $Res Function(ProjectOverviewError) _then) = _$ProjectOverviewErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ProjectOverviewErrorCopyWithImpl<$Res>
    implements $ProjectOverviewErrorCopyWith<$Res> {
  _$ProjectOverviewErrorCopyWithImpl(this._self, this._then);

  final ProjectOverviewError _self;
  final $Res Function(ProjectOverviewError) _then;

/// Create a copy of ProjectOverviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ProjectOverviewError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
