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
mixin _$ProjectListEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectListEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectListEvent()';
}


}

/// @nodoc
class $ProjectListEventCopyWith<$Res>  {
$ProjectListEventCopyWith(ProjectListEvent _, $Res Function(ProjectListEvent) __);
}


/// Adds pattern-matching-related methods to [ProjectListEvent].
extension ProjectListEventPatterns on ProjectListEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProjectListSubscriptionRequested value)?  projectsSubscriptionRequested,TResult Function( ProjectListToggleProjectCompletion value)?  toggleProjectCompletion,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProjectListSubscriptionRequested() when projectsSubscriptionRequested != null:
return projectsSubscriptionRequested(_that);case ProjectListToggleProjectCompletion() when toggleProjectCompletion != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProjectListSubscriptionRequested value)  projectsSubscriptionRequested,required TResult Function( ProjectListToggleProjectCompletion value)  toggleProjectCompletion,}){
final _that = this;
switch (_that) {
case ProjectListSubscriptionRequested():
return projectsSubscriptionRequested(_that);case ProjectListToggleProjectCompletion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProjectListSubscriptionRequested value)?  projectsSubscriptionRequested,TResult? Function( ProjectListToggleProjectCompletion value)?  toggleProjectCompletion,}){
final _that = this;
switch (_that) {
case ProjectListSubscriptionRequested() when projectsSubscriptionRequested != null:
return projectsSubscriptionRequested(_that);case ProjectListToggleProjectCompletion() when toggleProjectCompletion != null:
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
case ProjectListSubscriptionRequested() when projectsSubscriptionRequested != null:
return projectsSubscriptionRequested();case ProjectListToggleProjectCompletion() when toggleProjectCompletion != null:
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
case ProjectListSubscriptionRequested():
return projectsSubscriptionRequested();case ProjectListToggleProjectCompletion():
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
case ProjectListSubscriptionRequested() when projectsSubscriptionRequested != null:
return projectsSubscriptionRequested();case ProjectListToggleProjectCompletion() when toggleProjectCompletion != null:
return toggleProjectCompletion(_that.projectData);case _:
  return null;

}
}

}

/// @nodoc


class ProjectListSubscriptionRequested implements ProjectListEvent {
  const ProjectListSubscriptionRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectListSubscriptionRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectListEvent.projectsSubscriptionRequested()';
}


}




/// @nodoc


class ProjectListToggleProjectCompletion implements ProjectListEvent {
  const ProjectListToggleProjectCompletion({required this.projectData});
  

 final  ProjectTableData projectData;

/// Create a copy of ProjectListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectListToggleProjectCompletionCopyWith<ProjectListToggleProjectCompletion> get copyWith => _$ProjectListToggleProjectCompletionCopyWithImpl<ProjectListToggleProjectCompletion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectListToggleProjectCompletion&&const DeepCollectionEquality().equals(other.projectData, projectData));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(projectData));

@override
String toString() {
  return 'ProjectListEvent.toggleProjectCompletion(projectData: $projectData)';
}


}

/// @nodoc
abstract mixin class $ProjectListToggleProjectCompletionCopyWith<$Res> implements $ProjectListEventCopyWith<$Res> {
  factory $ProjectListToggleProjectCompletionCopyWith(ProjectListToggleProjectCompletion value, $Res Function(ProjectListToggleProjectCompletion) _then) = _$ProjectListToggleProjectCompletionCopyWithImpl;
@useResult
$Res call({
 ProjectTableData projectData
});




}
/// @nodoc
class _$ProjectListToggleProjectCompletionCopyWithImpl<$Res>
    implements $ProjectListToggleProjectCompletionCopyWith<$Res> {
  _$ProjectListToggleProjectCompletionCopyWithImpl(this._self, this._then);

  final ProjectListToggleProjectCompletion _self;
  final $Res Function(ProjectListToggleProjectCompletion) _then;

/// Create a copy of ProjectListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? projectData = freezed,}) {
  return _then(ProjectListToggleProjectCompletion(
projectData: freezed == projectData ? _self.projectData : projectData // ignore: cast_nullable_to_non_nullable
as ProjectTableData,
  ));
}


}

/// @nodoc
mixin _$ProjectListState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectListState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectListState()';
}


}

/// @nodoc
class $ProjectListStateCopyWith<$Res>  {
$ProjectListStateCopyWith(ProjectListState _, $Res Function(ProjectListState) __);
}


/// Adds pattern-matching-related methods to [ProjectListState].
extension ProjectListStatePatterns on ProjectListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProjectListInitial value)?  initial,TResult Function( ProjectListLoading value)?  loading,TResult Function( ProjectListLoaded value)?  loaded,TResult Function( ProjectListError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProjectListInitial() when initial != null:
return initial(_that);case ProjectListLoading() when loading != null:
return loading(_that);case ProjectListLoaded() when loaded != null:
return loaded(_that);case ProjectListError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProjectListInitial value)  initial,required TResult Function( ProjectListLoading value)  loading,required TResult Function( ProjectListLoaded value)  loaded,required TResult Function( ProjectListError value)  error,}){
final _that = this;
switch (_that) {
case ProjectListInitial():
return initial(_that);case ProjectListLoading():
return loading(_that);case ProjectListLoaded():
return loaded(_that);case ProjectListError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProjectListInitial value)?  initial,TResult? Function( ProjectListLoading value)?  loading,TResult? Function( ProjectListLoaded value)?  loaded,TResult? Function( ProjectListError value)?  error,}){
final _that = this;
switch (_that) {
case ProjectListInitial() when initial != null:
return initial(_that);case ProjectListLoading() when loading != null:
return loading(_that);case ProjectListLoaded() when loaded != null:
return loaded(_that);case ProjectListError() when error != null:
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
case ProjectListInitial() when initial != null:
return initial();case ProjectListLoading() when loading != null:
return loading();case ProjectListLoaded() when loaded != null:
return loaded(_that.projects);case ProjectListError() when error != null:
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
case ProjectListInitial():
return initial();case ProjectListLoading():
return loading();case ProjectListLoaded():
return loaded(_that.projects);case ProjectListError():
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
case ProjectListInitial() when initial != null:
return initial();case ProjectListLoading() when loading != null:
return loading();case ProjectListLoaded() when loaded != null:
return loaded(_that.projects);case ProjectListError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ProjectListInitial implements ProjectListState {
  const ProjectListInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectListInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectListState.initial()';
}


}




/// @nodoc


class ProjectListLoading implements ProjectListState {
  const ProjectListLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectListLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectListState.loading()';
}


}




/// @nodoc


class ProjectListLoaded implements ProjectListState {
  const ProjectListLoaded({required final  List<ProjectTableData> projects}): _projects = projects;
  

 final  List<ProjectTableData> _projects;
 List<ProjectTableData> get projects {
  if (_projects is EqualUnmodifiableListView) return _projects;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_projects);
}


/// Create a copy of ProjectListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectListLoadedCopyWith<ProjectListLoaded> get copyWith => _$ProjectListLoadedCopyWithImpl<ProjectListLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectListLoaded&&const DeepCollectionEquality().equals(other._projects, _projects));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_projects));

@override
String toString() {
  return 'ProjectListState.loaded(projects: $projects)';
}


}

/// @nodoc
abstract mixin class $ProjectListLoadedCopyWith<$Res> implements $ProjectListStateCopyWith<$Res> {
  factory $ProjectListLoadedCopyWith(ProjectListLoaded value, $Res Function(ProjectListLoaded) _then) = _$ProjectListLoadedCopyWithImpl;
@useResult
$Res call({
 List<ProjectTableData> projects
});




}
/// @nodoc
class _$ProjectListLoadedCopyWithImpl<$Res>
    implements $ProjectListLoadedCopyWith<$Res> {
  _$ProjectListLoadedCopyWithImpl(this._self, this._then);

  final ProjectListLoaded _self;
  final $Res Function(ProjectListLoaded) _then;

/// Create a copy of ProjectListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? projects = null,}) {
  return _then(ProjectListLoaded(
projects: null == projects ? _self._projects : projects // ignore: cast_nullable_to_non_nullable
as List<ProjectTableData>,
  ));
}


}

/// @nodoc


class ProjectListError implements ProjectListState {
  const ProjectListError({required this.message});
  

 final  String message;

/// Create a copy of ProjectListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectListErrorCopyWith<ProjectListError> get copyWith => _$ProjectListErrorCopyWithImpl<ProjectListError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectListError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ProjectListState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ProjectListErrorCopyWith<$Res> implements $ProjectListStateCopyWith<$Res> {
  factory $ProjectListErrorCopyWith(ProjectListError value, $Res Function(ProjectListError) _then) = _$ProjectListErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ProjectListErrorCopyWithImpl<$Res>
    implements $ProjectListErrorCopyWith<$Res> {
  _$ProjectListErrorCopyWithImpl(this._self, this._then);

  final ProjectListError _self;
  final $Res Function(ProjectListError) _then;

/// Create a copy of ProjectListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ProjectListError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
