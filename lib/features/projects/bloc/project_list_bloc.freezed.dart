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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProjectOverviewSubscriptionRequested value)?  projectsSubscriptionRequested,TResult Function( ProjectOverviewToggleProjectCompletion value)?  toggleProjectCompletion,TResult Function( ProjectOverviewSortChanged value)?  sortChanged,TResult Function( ProjectOverviewTaskCountsUpdated value)?  taskCountsUpdated,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProjectOverviewSubscriptionRequested() when projectsSubscriptionRequested != null:
return projectsSubscriptionRequested(_that);case ProjectOverviewToggleProjectCompletion() when toggleProjectCompletion != null:
return toggleProjectCompletion(_that);case ProjectOverviewSortChanged() when sortChanged != null:
return sortChanged(_that);case ProjectOverviewTaskCountsUpdated() when taskCountsUpdated != null:
return taskCountsUpdated(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProjectOverviewSubscriptionRequested value)  projectsSubscriptionRequested,required TResult Function( ProjectOverviewToggleProjectCompletion value)  toggleProjectCompletion,required TResult Function( ProjectOverviewSortChanged value)  sortChanged,required TResult Function( ProjectOverviewTaskCountsUpdated value)  taskCountsUpdated,}){
final _that = this;
switch (_that) {
case ProjectOverviewSubscriptionRequested():
return projectsSubscriptionRequested(_that);case ProjectOverviewToggleProjectCompletion():
return toggleProjectCompletion(_that);case ProjectOverviewSortChanged():
return sortChanged(_that);case ProjectOverviewTaskCountsUpdated():
return taskCountsUpdated(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProjectOverviewSubscriptionRequested value)?  projectsSubscriptionRequested,TResult? Function( ProjectOverviewToggleProjectCompletion value)?  toggleProjectCompletion,TResult? Function( ProjectOverviewSortChanged value)?  sortChanged,TResult? Function( ProjectOverviewTaskCountsUpdated value)?  taskCountsUpdated,}){
final _that = this;
switch (_that) {
case ProjectOverviewSubscriptionRequested() when projectsSubscriptionRequested != null:
return projectsSubscriptionRequested(_that);case ProjectOverviewToggleProjectCompletion() when toggleProjectCompletion != null:
return toggleProjectCompletion(_that);case ProjectOverviewSortChanged() when sortChanged != null:
return sortChanged(_that);case ProjectOverviewTaskCountsUpdated() when taskCountsUpdated != null:
return taskCountsUpdated(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  projectsSubscriptionRequested,TResult Function( Project project)?  toggleProjectCompletion,TResult Function( SortPreferences preferences)?  sortChanged,TResult Function( Map<String, ProjectTaskCounts> taskCounts)?  taskCountsUpdated,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProjectOverviewSubscriptionRequested() when projectsSubscriptionRequested != null:
return projectsSubscriptionRequested();case ProjectOverviewToggleProjectCompletion() when toggleProjectCompletion != null:
return toggleProjectCompletion(_that.project);case ProjectOverviewSortChanged() when sortChanged != null:
return sortChanged(_that.preferences);case ProjectOverviewTaskCountsUpdated() when taskCountsUpdated != null:
return taskCountsUpdated(_that.taskCounts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  projectsSubscriptionRequested,required TResult Function( Project project)  toggleProjectCompletion,required TResult Function( SortPreferences preferences)  sortChanged,required TResult Function( Map<String, ProjectTaskCounts> taskCounts)  taskCountsUpdated,}) {final _that = this;
switch (_that) {
case ProjectOverviewSubscriptionRequested():
return projectsSubscriptionRequested();case ProjectOverviewToggleProjectCompletion():
return toggleProjectCompletion(_that.project);case ProjectOverviewSortChanged():
return sortChanged(_that.preferences);case ProjectOverviewTaskCountsUpdated():
return taskCountsUpdated(_that.taskCounts);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  projectsSubscriptionRequested,TResult? Function( Project project)?  toggleProjectCompletion,TResult? Function( SortPreferences preferences)?  sortChanged,TResult? Function( Map<String, ProjectTaskCounts> taskCounts)?  taskCountsUpdated,}) {final _that = this;
switch (_that) {
case ProjectOverviewSubscriptionRequested() when projectsSubscriptionRequested != null:
return projectsSubscriptionRequested();case ProjectOverviewToggleProjectCompletion() when toggleProjectCompletion != null:
return toggleProjectCompletion(_that.project);case ProjectOverviewSortChanged() when sortChanged != null:
return sortChanged(_that.preferences);case ProjectOverviewTaskCountsUpdated() when taskCountsUpdated != null:
return taskCountsUpdated(_that.taskCounts);case _:
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
  const ProjectOverviewToggleProjectCompletion({required this.project});
  

 final  Project project;

/// Create a copy of ProjectOverviewEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectOverviewToggleProjectCompletionCopyWith<ProjectOverviewToggleProjectCompletion> get copyWith => _$ProjectOverviewToggleProjectCompletionCopyWithImpl<ProjectOverviewToggleProjectCompletion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectOverviewToggleProjectCompletion&&(identical(other.project, project) || other.project == project));
}


@override
int get hashCode => Object.hash(runtimeType,project);

@override
String toString() {
  return 'ProjectOverviewEvent.toggleProjectCompletion(project: $project)';
}


}

/// @nodoc
abstract mixin class $ProjectOverviewToggleProjectCompletionCopyWith<$Res> implements $ProjectOverviewEventCopyWith<$Res> {
  factory $ProjectOverviewToggleProjectCompletionCopyWith(ProjectOverviewToggleProjectCompletion value, $Res Function(ProjectOverviewToggleProjectCompletion) _then) = _$ProjectOverviewToggleProjectCompletionCopyWithImpl;
@useResult
$Res call({
 Project project
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
@pragma('vm:prefer-inline') $Res call({Object? project = null,}) {
  return _then(ProjectOverviewToggleProjectCompletion(
project: null == project ? _self.project : project // ignore: cast_nullable_to_non_nullable
as Project,
  ));
}


}

/// @nodoc


class ProjectOverviewSortChanged implements ProjectOverviewEvent {
  const ProjectOverviewSortChanged({required this.preferences});
  

 final  SortPreferences preferences;

/// Create a copy of ProjectOverviewEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectOverviewSortChangedCopyWith<ProjectOverviewSortChanged> get copyWith => _$ProjectOverviewSortChangedCopyWithImpl<ProjectOverviewSortChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectOverviewSortChanged&&(identical(other.preferences, preferences) || other.preferences == preferences));
}


@override
int get hashCode => Object.hash(runtimeType,preferences);

@override
String toString() {
  return 'ProjectOverviewEvent.sortChanged(preferences: $preferences)';
}


}

/// @nodoc
abstract mixin class $ProjectOverviewSortChangedCopyWith<$Res> implements $ProjectOverviewEventCopyWith<$Res> {
  factory $ProjectOverviewSortChangedCopyWith(ProjectOverviewSortChanged value, $Res Function(ProjectOverviewSortChanged) _then) = _$ProjectOverviewSortChangedCopyWithImpl;
@useResult
$Res call({
 SortPreferences preferences
});




}
/// @nodoc
class _$ProjectOverviewSortChangedCopyWithImpl<$Res>
    implements $ProjectOverviewSortChangedCopyWith<$Res> {
  _$ProjectOverviewSortChangedCopyWithImpl(this._self, this._then);

  final ProjectOverviewSortChanged _self;
  final $Res Function(ProjectOverviewSortChanged) _then;

/// Create a copy of ProjectOverviewEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? preferences = null,}) {
  return _then(ProjectOverviewSortChanged(
preferences: null == preferences ? _self.preferences : preferences // ignore: cast_nullable_to_non_nullable
as SortPreferences,
  ));
}


}

/// @nodoc


class ProjectOverviewTaskCountsUpdated implements ProjectOverviewEvent {
  const ProjectOverviewTaskCountsUpdated({required final  Map<String, ProjectTaskCounts> taskCounts}): _taskCounts = taskCounts;
  

 final  Map<String, ProjectTaskCounts> _taskCounts;
 Map<String, ProjectTaskCounts> get taskCounts {
  if (_taskCounts is EqualUnmodifiableMapView) return _taskCounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_taskCounts);
}


/// Create a copy of ProjectOverviewEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectOverviewTaskCountsUpdatedCopyWith<ProjectOverviewTaskCountsUpdated> get copyWith => _$ProjectOverviewTaskCountsUpdatedCopyWithImpl<ProjectOverviewTaskCountsUpdated>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectOverviewTaskCountsUpdated&&const DeepCollectionEquality().equals(other._taskCounts, _taskCounts));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_taskCounts));

@override
String toString() {
  return 'ProjectOverviewEvent.taskCountsUpdated(taskCounts: $taskCounts)';
}


}

/// @nodoc
abstract mixin class $ProjectOverviewTaskCountsUpdatedCopyWith<$Res> implements $ProjectOverviewEventCopyWith<$Res> {
  factory $ProjectOverviewTaskCountsUpdatedCopyWith(ProjectOverviewTaskCountsUpdated value, $Res Function(ProjectOverviewTaskCountsUpdated) _then) = _$ProjectOverviewTaskCountsUpdatedCopyWithImpl;
@useResult
$Res call({
 Map<String, ProjectTaskCounts> taskCounts
});




}
/// @nodoc
class _$ProjectOverviewTaskCountsUpdatedCopyWithImpl<$Res>
    implements $ProjectOverviewTaskCountsUpdatedCopyWith<$Res> {
  _$ProjectOverviewTaskCountsUpdatedCopyWithImpl(this._self, this._then);

  final ProjectOverviewTaskCountsUpdated _self;
  final $Res Function(ProjectOverviewTaskCountsUpdated) _then;

/// Create a copy of ProjectOverviewEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? taskCounts = null,}) {
  return _then(ProjectOverviewTaskCountsUpdated(
taskCounts: null == taskCounts ? _self._taskCounts : taskCounts // ignore: cast_nullable_to_non_nullable
as Map<String, ProjectTaskCounts>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Project> projects,  Map<String, ProjectTaskCounts> taskCounts)?  loaded,TResult Function( Object error)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProjectOverviewInitial() when initial != null:
return initial();case ProjectOverviewLoading() when loading != null:
return loading();case ProjectOverviewLoaded() when loaded != null:
return loaded(_that.projects,_that.taskCounts);case ProjectOverviewError() when error != null:
return error(_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Project> projects,  Map<String, ProjectTaskCounts> taskCounts)  loaded,required TResult Function( Object error)  error,}) {final _that = this;
switch (_that) {
case ProjectOverviewInitial():
return initial();case ProjectOverviewLoading():
return loading();case ProjectOverviewLoaded():
return loaded(_that.projects,_that.taskCounts);case ProjectOverviewError():
return error(_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Project> projects,  Map<String, ProjectTaskCounts> taskCounts)?  loaded,TResult? Function( Object error)?  error,}) {final _that = this;
switch (_that) {
case ProjectOverviewInitial() when initial != null:
return initial();case ProjectOverviewLoading() when loading != null:
return loading();case ProjectOverviewLoaded() when loaded != null:
return loaded(_that.projects,_that.taskCounts);case ProjectOverviewError() when error != null:
return error(_that.error);case _:
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
  const ProjectOverviewLoaded({required final  List<Project> projects, final  Map<String, ProjectTaskCounts> taskCounts = const {}}): _projects = projects,_taskCounts = taskCounts;
  

 final  List<Project> _projects;
 List<Project> get projects {
  if (_projects is EqualUnmodifiableListView) return _projects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_projects);
}

 final  Map<String, ProjectTaskCounts> _taskCounts;
@JsonKey() Map<String, ProjectTaskCounts> get taskCounts {
  if (_taskCounts is EqualUnmodifiableMapView) return _taskCounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_taskCounts);
}


/// Create a copy of ProjectOverviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectOverviewLoadedCopyWith<ProjectOverviewLoaded> get copyWith => _$ProjectOverviewLoadedCopyWithImpl<ProjectOverviewLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectOverviewLoaded&&const DeepCollectionEquality().equals(other._projects, _projects)&&const DeepCollectionEquality().equals(other._taskCounts, _taskCounts));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_projects),const DeepCollectionEquality().hash(_taskCounts));

@override
String toString() {
  return 'ProjectOverviewState.loaded(projects: $projects, taskCounts: $taskCounts)';
}


}

/// @nodoc
abstract mixin class $ProjectOverviewLoadedCopyWith<$Res> implements $ProjectOverviewStateCopyWith<$Res> {
  factory $ProjectOverviewLoadedCopyWith(ProjectOverviewLoaded value, $Res Function(ProjectOverviewLoaded) _then) = _$ProjectOverviewLoadedCopyWithImpl;
@useResult
$Res call({
 List<Project> projects, Map<String, ProjectTaskCounts> taskCounts
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
@pragma('vm:prefer-inline') $Res call({Object? projects = null,Object? taskCounts = null,}) {
  return _then(ProjectOverviewLoaded(
projects: null == projects ? _self._projects : projects // ignore: cast_nullable_to_non_nullable
as List<Project>,taskCounts: null == taskCounts ? _self._taskCounts : taskCounts // ignore: cast_nullable_to_non_nullable
as Map<String, ProjectTaskCounts>,
  ));
}


}

/// @nodoc


class ProjectOverviewError implements ProjectOverviewState {
  const ProjectOverviewError({required this.error});
  

 final  Object error;

/// Create a copy of ProjectOverviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectOverviewErrorCopyWith<ProjectOverviewError> get copyWith => _$ProjectOverviewErrorCopyWithImpl<ProjectOverviewError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectOverviewError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'ProjectOverviewState.error(error: $error)';
}


}

/// @nodoc
abstract mixin class $ProjectOverviewErrorCopyWith<$Res> implements $ProjectOverviewStateCopyWith<$Res> {
  factory $ProjectOverviewErrorCopyWith(ProjectOverviewError value, $Res Function(ProjectOverviewError) _then) = _$ProjectOverviewErrorCopyWithImpl;
@useResult
$Res call({
 Object error
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
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(ProjectOverviewError(
error: null == error ? _self.error : error ,
  ));
}


}

// dart format on
