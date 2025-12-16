// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_detail_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProjectDetailEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDetailEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectDetailEvent()';
}


}

/// @nodoc
class $ProjectDetailEventCopyWith<$Res>  {
$ProjectDetailEventCopyWith(ProjectDetailEvent _, $Res Function(ProjectDetailEvent) __);
}


/// Adds pattern-matching-related methods to [ProjectDetailEvent].
extension ProjectDetailEventPatterns on ProjectDetailEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _ProjectDetailUpdate value)?  updateProject,TResult Function( _ProjectDetailDelete value)?  deleteProject,TResult Function( _ProjectDetailCreate value)?  createProject,TResult Function( _ProjectDetailGet value)?  getProject,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectDetailUpdate() when updateProject != null:
return updateProject(_that);case _ProjectDetailDelete() when deleteProject != null:
return deleteProject(_that);case _ProjectDetailCreate() when createProject != null:
return createProject(_that);case _ProjectDetailGet() when getProject != null:
return getProject(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _ProjectDetailUpdate value)  updateProject,required TResult Function( _ProjectDetailDelete value)  deleteProject,required TResult Function( _ProjectDetailCreate value)  createProject,required TResult Function( _ProjectDetailGet value)  getProject,}){
final _that = this;
switch (_that) {
case _ProjectDetailUpdate():
return updateProject(_that);case _ProjectDetailDelete():
return deleteProject(_that);case _ProjectDetailCreate():
return createProject(_that);case _ProjectDetailGet():
return getProject(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _ProjectDetailUpdate value)?  updateProject,TResult? Function( _ProjectDetailDelete value)?  deleteProject,TResult? Function( _ProjectDetailCreate value)?  createProject,TResult? Function( _ProjectDetailGet value)?  getProject,}){
final _that = this;
switch (_that) {
case _ProjectDetailUpdate() when updateProject != null:
return updateProject(_that);case _ProjectDetailDelete() when deleteProject != null:
return deleteProject(_that);case _ProjectDetailCreate() when createProject != null:
return createProject(_that);case _ProjectDetailGet() when getProject != null:
return getProject(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ProjectTableCompanion updateCompanion)?  updateProject,TResult Function( ProjectTableCompanion deleteCompanion)?  deleteProject,TResult Function( ProjectTableCompanion createCompanion)?  createProject,TResult Function( String projectId)?  getProject,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectDetailUpdate() when updateProject != null:
return updateProject(_that.updateCompanion);case _ProjectDetailDelete() when deleteProject != null:
return deleteProject(_that.deleteCompanion);case _ProjectDetailCreate() when createProject != null:
return createProject(_that.createCompanion);case _ProjectDetailGet() when getProject != null:
return getProject(_that.projectId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ProjectTableCompanion updateCompanion)  updateProject,required TResult Function( ProjectTableCompanion deleteCompanion)  deleteProject,required TResult Function( ProjectTableCompanion createCompanion)  createProject,required TResult Function( String projectId)  getProject,}) {final _that = this;
switch (_that) {
case _ProjectDetailUpdate():
return updateProject(_that.updateCompanion);case _ProjectDetailDelete():
return deleteProject(_that.deleteCompanion);case _ProjectDetailCreate():
return createProject(_that.createCompanion);case _ProjectDetailGet():
return getProject(_that.projectId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ProjectTableCompanion updateCompanion)?  updateProject,TResult? Function( ProjectTableCompanion deleteCompanion)?  deleteProject,TResult? Function( ProjectTableCompanion createCompanion)?  createProject,TResult? Function( String projectId)?  getProject,}) {final _that = this;
switch (_that) {
case _ProjectDetailUpdate() when updateProject != null:
return updateProject(_that.updateCompanion);case _ProjectDetailDelete() when deleteProject != null:
return deleteProject(_that.deleteCompanion);case _ProjectDetailCreate() when createProject != null:
return createProject(_that.createCompanion);case _ProjectDetailGet() when getProject != null:
return getProject(_that.projectId);case _:
  return null;

}
}

}

/// @nodoc


class _ProjectDetailUpdate implements ProjectDetailEvent {
  const _ProjectDetailUpdate({required this.updateCompanion});
  

 final  ProjectTableCompanion updateCompanion;

/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectDetailUpdateCopyWith<_ProjectDetailUpdate> get copyWith => __$ProjectDetailUpdateCopyWithImpl<_ProjectDetailUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDetailUpdate&&const DeepCollectionEquality().equals(other.updateCompanion, updateCompanion));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(updateCompanion));

@override
String toString() {
  return 'ProjectDetailEvent.updateProject(updateCompanion: $updateCompanion)';
}


}

/// @nodoc
abstract mixin class _$ProjectDetailUpdateCopyWith<$Res> implements $ProjectDetailEventCopyWith<$Res> {
  factory _$ProjectDetailUpdateCopyWith(_ProjectDetailUpdate value, $Res Function(_ProjectDetailUpdate) _then) = __$ProjectDetailUpdateCopyWithImpl;
@useResult
$Res call({
 ProjectTableCompanion updateCompanion
});




}
/// @nodoc
class __$ProjectDetailUpdateCopyWithImpl<$Res>
    implements _$ProjectDetailUpdateCopyWith<$Res> {
  __$ProjectDetailUpdateCopyWithImpl(this._self, this._then);

  final _ProjectDetailUpdate _self;
  final $Res Function(_ProjectDetailUpdate) _then;

/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? updateCompanion = freezed,}) {
  return _then(_ProjectDetailUpdate(
updateCompanion: freezed == updateCompanion ? _self.updateCompanion : updateCompanion // ignore: cast_nullable_to_non_nullable
as ProjectTableCompanion,
  ));
}


}

/// @nodoc


class _ProjectDetailDelete implements ProjectDetailEvent {
  const _ProjectDetailDelete({required this.deleteCompanion});
  

 final  ProjectTableCompanion deleteCompanion;

/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectDetailDeleteCopyWith<_ProjectDetailDelete> get copyWith => __$ProjectDetailDeleteCopyWithImpl<_ProjectDetailDelete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDetailDelete&&const DeepCollectionEquality().equals(other.deleteCompanion, deleteCompanion));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(deleteCompanion));

@override
String toString() {
  return 'ProjectDetailEvent.deleteProject(deleteCompanion: $deleteCompanion)';
}


}

/// @nodoc
abstract mixin class _$ProjectDetailDeleteCopyWith<$Res> implements $ProjectDetailEventCopyWith<$Res> {
  factory _$ProjectDetailDeleteCopyWith(_ProjectDetailDelete value, $Res Function(_ProjectDetailDelete) _then) = __$ProjectDetailDeleteCopyWithImpl;
@useResult
$Res call({
 ProjectTableCompanion deleteCompanion
});




}
/// @nodoc
class __$ProjectDetailDeleteCopyWithImpl<$Res>
    implements _$ProjectDetailDeleteCopyWith<$Res> {
  __$ProjectDetailDeleteCopyWithImpl(this._self, this._then);

  final _ProjectDetailDelete _self;
  final $Res Function(_ProjectDetailDelete) _then;

/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? deleteCompanion = freezed,}) {
  return _then(_ProjectDetailDelete(
deleteCompanion: freezed == deleteCompanion ? _self.deleteCompanion : deleteCompanion // ignore: cast_nullable_to_non_nullable
as ProjectTableCompanion,
  ));
}


}

/// @nodoc


class _ProjectDetailCreate implements ProjectDetailEvent {
  const _ProjectDetailCreate({required this.createCompanion});
  

 final  ProjectTableCompanion createCompanion;

/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectDetailCreateCopyWith<_ProjectDetailCreate> get copyWith => __$ProjectDetailCreateCopyWithImpl<_ProjectDetailCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDetailCreate&&const DeepCollectionEquality().equals(other.createCompanion, createCompanion));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(createCompanion));

@override
String toString() {
  return 'ProjectDetailEvent.createProject(createCompanion: $createCompanion)';
}


}

/// @nodoc
abstract mixin class _$ProjectDetailCreateCopyWith<$Res> implements $ProjectDetailEventCopyWith<$Res> {
  factory _$ProjectDetailCreateCopyWith(_ProjectDetailCreate value, $Res Function(_ProjectDetailCreate) _then) = __$ProjectDetailCreateCopyWithImpl;
@useResult
$Res call({
 ProjectTableCompanion createCompanion
});




}
/// @nodoc
class __$ProjectDetailCreateCopyWithImpl<$Res>
    implements _$ProjectDetailCreateCopyWith<$Res> {
  __$ProjectDetailCreateCopyWithImpl(this._self, this._then);

  final _ProjectDetailCreate _self;
  final $Res Function(_ProjectDetailCreate) _then;

/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? createCompanion = freezed,}) {
  return _then(_ProjectDetailCreate(
createCompanion: freezed == createCompanion ? _self.createCompanion : createCompanion // ignore: cast_nullable_to_non_nullable
as ProjectTableCompanion,
  ));
}


}

/// @nodoc


class _ProjectDetailGet implements ProjectDetailEvent {
  const _ProjectDetailGet({required this.projectId});
  

 final  String projectId;

/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectDetailGetCopyWith<_ProjectDetailGet> get copyWith => __$ProjectDetailGetCopyWithImpl<_ProjectDetailGet>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDetailGet&&(identical(other.projectId, projectId) || other.projectId == projectId));
}


@override
int get hashCode => Object.hash(runtimeType,projectId);

@override
String toString() {
  return 'ProjectDetailEvent.getProject(projectId: $projectId)';
}


}

/// @nodoc
abstract mixin class _$ProjectDetailGetCopyWith<$Res> implements $ProjectDetailEventCopyWith<$Res> {
  factory _$ProjectDetailGetCopyWith(_ProjectDetailGet value, $Res Function(_ProjectDetailGet) _then) = __$ProjectDetailGetCopyWithImpl;
@useResult
$Res call({
 String projectId
});




}
/// @nodoc
class __$ProjectDetailGetCopyWithImpl<$Res>
    implements _$ProjectDetailGetCopyWith<$Res> {
  __$ProjectDetailGetCopyWithImpl(this._self, this._then);

  final _ProjectDetailGet _self;
  final $Res Function(_ProjectDetailGet) _then;

/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? projectId = null,}) {
  return _then(_ProjectDetailGet(
projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ProjectDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectDetailState()';
}


}

/// @nodoc
class $ProjectDetailStateCopyWith<$Res>  {
$ProjectDetailStateCopyWith(ProjectDetailState _, $Res Function(ProjectDetailState) __);
}


/// Adds pattern-matching-related methods to [ProjectDetailState].
extension ProjectDetailStatePatterns on ProjectDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _ProjectDetailLoading value)?  loading,TResult Function( _ProjectDetailNewProject value)?  createProject,TResult Function( _ProjectDetailEditProject value)?  editProject,TResult Function( _ProjectDetailError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectDetailLoading() when loading != null:
return loading(_that);case _ProjectDetailNewProject() when createProject != null:
return createProject(_that);case _ProjectDetailEditProject() when editProject != null:
return editProject(_that);case _ProjectDetailError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _ProjectDetailLoading value)  loading,required TResult Function( _ProjectDetailNewProject value)  createProject,required TResult Function( _ProjectDetailEditProject value)  editProject,required TResult Function( _ProjectDetailError value)  error,}){
final _that = this;
switch (_that) {
case _ProjectDetailLoading():
return loading(_that);case _ProjectDetailNewProject():
return createProject(_that);case _ProjectDetailEditProject():
return editProject(_that);case _ProjectDetailError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _ProjectDetailLoading value)?  loading,TResult? Function( _ProjectDetailNewProject value)?  createProject,TResult? Function( _ProjectDetailEditProject value)?  editProject,TResult? Function( _ProjectDetailError value)?  error,}){
final _that = this;
switch (_that) {
case _ProjectDetailLoading() when loading != null:
return loading(_that);case _ProjectDetailNewProject() when createProject != null:
return createProject(_that);case _ProjectDetailEditProject() when editProject != null:
return editProject(_that);case _ProjectDetailError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  createProject,TResult Function()?  editProject,TResult Function( String message,  StackTrace stacktrace)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectDetailLoading() when loading != null:
return loading();case _ProjectDetailNewProject() when createProject != null:
return createProject();case _ProjectDetailEditProject() when editProject != null:
return editProject();case _ProjectDetailError() when error != null:
return error(_that.message,_that.stacktrace);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  createProject,required TResult Function()  editProject,required TResult Function( String message,  StackTrace stacktrace)  error,}) {final _that = this;
switch (_that) {
case _ProjectDetailLoading():
return loading();case _ProjectDetailNewProject():
return createProject();case _ProjectDetailEditProject():
return editProject();case _ProjectDetailError():
return error(_that.message,_that.stacktrace);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  createProject,TResult? Function()?  editProject,TResult? Function( String message,  StackTrace stacktrace)?  error,}) {final _that = this;
switch (_that) {
case _ProjectDetailLoading() when loading != null:
return loading();case _ProjectDetailNewProject() when createProject != null:
return createProject();case _ProjectDetailEditProject() when editProject != null:
return editProject();case _ProjectDetailError() when error != null:
return error(_that.message,_that.stacktrace);case _:
  return null;

}
}

}

/// @nodoc


class _ProjectDetailLoading implements ProjectDetailState {
  const _ProjectDetailLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDetailLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectDetailState.loading()';
}


}




/// @nodoc


class _ProjectDetailNewProject implements ProjectDetailState {
  const _ProjectDetailNewProject();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDetailNewProject);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectDetailState.createProject()';
}


}




/// @nodoc


class _ProjectDetailEditProject implements ProjectDetailState {
  const _ProjectDetailEditProject();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDetailEditProject);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectDetailState.editProject()';
}


}




/// @nodoc


class _ProjectDetailError implements ProjectDetailState {
  const _ProjectDetailError({required this.message, required this.stacktrace});
  

 final  String message;
 final  StackTrace stacktrace;

/// Create a copy of ProjectDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectDetailErrorCopyWith<_ProjectDetailError> get copyWith => __$ProjectDetailErrorCopyWithImpl<_ProjectDetailError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDetailError&&(identical(other.message, message) || other.message == message)&&(identical(other.stacktrace, stacktrace) || other.stacktrace == stacktrace));
}


@override
int get hashCode => Object.hash(runtimeType,message,stacktrace);

@override
String toString() {
  return 'ProjectDetailState.error(message: $message, stacktrace: $stacktrace)';
}


}

/// @nodoc
abstract mixin class _$ProjectDetailErrorCopyWith<$Res> implements $ProjectDetailStateCopyWith<$Res> {
  factory _$ProjectDetailErrorCopyWith(_ProjectDetailError value, $Res Function(_ProjectDetailError) _then) = __$ProjectDetailErrorCopyWithImpl;
@useResult
$Res call({
 String message, StackTrace stacktrace
});




}
/// @nodoc
class __$ProjectDetailErrorCopyWithImpl<$Res>
    implements _$ProjectDetailErrorCopyWith<$Res> {
  __$ProjectDetailErrorCopyWithImpl(this._self, this._then);

  final _ProjectDetailError _self;
  final $Res Function(_ProjectDetailError) _then;

/// Create a copy of ProjectDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,Object? stacktrace = null,}) {
  return _then(_ProjectDetailError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,stacktrace: null == stacktrace ? _self.stacktrace : stacktrace // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

// dart format on
