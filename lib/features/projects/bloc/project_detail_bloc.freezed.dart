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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _ProjectDetailUpdate value)?  update,TResult Function( _ProjectDetailDelete value)?  delete,TResult Function( _ProjectDetailCreate value)?  create,TResult Function( _ProjectDetailGet value)?  get,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectDetailUpdate() when update != null:
return update(_that);case _ProjectDetailDelete() when delete != null:
return delete(_that);case _ProjectDetailCreate() when create != null:
return create(_that);case _ProjectDetailGet() when get != null:
return get(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _ProjectDetailUpdate value)  update,required TResult Function( _ProjectDetailDelete value)  delete,required TResult Function( _ProjectDetailCreate value)  create,required TResult Function( _ProjectDetailGet value)  get,}){
final _that = this;
switch (_that) {
case _ProjectDetailUpdate():
return update(_that);case _ProjectDetailDelete():
return delete(_that);case _ProjectDetailCreate():
return create(_that);case _ProjectDetailGet():
return get(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _ProjectDetailUpdate value)?  update,TResult? Function( _ProjectDetailDelete value)?  delete,TResult? Function( _ProjectDetailCreate value)?  create,TResult? Function( _ProjectDetailGet value)?  get,}){
final _that = this;
switch (_that) {
case _ProjectDetailUpdate() when update != null:
return update(_that);case _ProjectDetailDelete() when delete != null:
return delete(_that);case _ProjectDetailCreate() when create != null:
return create(_that);case _ProjectDetailGet() when get != null:
return get(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String name,  bool completed)?  update,TResult Function( String id)?  delete,TResult Function( String name)?  create,TResult Function( String projectId)?  get,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectDetailUpdate() when update != null:
return update(_that.id,_that.name,_that.completed);case _ProjectDetailDelete() when delete != null:
return delete(_that.id);case _ProjectDetailCreate() when create != null:
return create(_that.name);case _ProjectDetailGet() when get != null:
return get(_that.projectId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String name,  bool completed)  update,required TResult Function( String id)  delete,required TResult Function( String name)  create,required TResult Function( String projectId)  get,}) {final _that = this;
switch (_that) {
case _ProjectDetailUpdate():
return update(_that.id,_that.name,_that.completed);case _ProjectDetailDelete():
return delete(_that.id);case _ProjectDetailCreate():
return create(_that.name);case _ProjectDetailGet():
return get(_that.projectId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String name,  bool completed)?  update,TResult? Function( String id)?  delete,TResult? Function( String name)?  create,TResult? Function( String projectId)?  get,}) {final _that = this;
switch (_that) {
case _ProjectDetailUpdate() when update != null:
return update(_that.id,_that.name,_that.completed);case _ProjectDetailDelete() when delete != null:
return delete(_that.id);case _ProjectDetailCreate() when create != null:
return create(_that.name);case _ProjectDetailGet() when get != null:
return get(_that.projectId);case _:
  return null;

}
}

}

/// @nodoc


class _ProjectDetailUpdate implements ProjectDetailEvent {
  const _ProjectDetailUpdate({required this.id, required this.name, required this.completed});
  

 final  String id;
 final  String name;
 final  bool completed;

/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectDetailUpdateCopyWith<_ProjectDetailUpdate> get copyWith => __$ProjectDetailUpdateCopyWithImpl<_ProjectDetailUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDetailUpdate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.completed, completed) || other.completed == completed));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,completed);

@override
String toString() {
  return 'ProjectDetailEvent.update(id: $id, name: $name, completed: $completed)';
}


}

/// @nodoc
abstract mixin class _$ProjectDetailUpdateCopyWith<$Res> implements $ProjectDetailEventCopyWith<$Res> {
  factory _$ProjectDetailUpdateCopyWith(_ProjectDetailUpdate value, $Res Function(_ProjectDetailUpdate) _then) = __$ProjectDetailUpdateCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool completed
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
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? completed = null,}) {
  return _then(_ProjectDetailUpdate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class _ProjectDetailDelete implements ProjectDetailEvent {
  const _ProjectDetailDelete({required this.id});
  

 final  String id;

/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectDetailDeleteCopyWith<_ProjectDetailDelete> get copyWith => __$ProjectDetailDeleteCopyWithImpl<_ProjectDetailDelete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDetailDelete&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ProjectDetailEvent.delete(id: $id)';
}


}

/// @nodoc
abstract mixin class _$ProjectDetailDeleteCopyWith<$Res> implements $ProjectDetailEventCopyWith<$Res> {
  factory _$ProjectDetailDeleteCopyWith(_ProjectDetailDelete value, $Res Function(_ProjectDetailDelete) _then) = __$ProjectDetailDeleteCopyWithImpl;
@useResult
$Res call({
 String id
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
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_ProjectDetailDelete(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ProjectDetailCreate implements ProjectDetailEvent {
  const _ProjectDetailCreate({required this.name});
  

 final  String name;

/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectDetailCreateCopyWith<_ProjectDetailCreate> get copyWith => __$ProjectDetailCreateCopyWithImpl<_ProjectDetailCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDetailCreate&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'ProjectDetailEvent.create(name: $name)';
}


}

/// @nodoc
abstract mixin class _$ProjectDetailCreateCopyWith<$Res> implements $ProjectDetailEventCopyWith<$Res> {
  factory _$ProjectDetailCreateCopyWith(_ProjectDetailCreate value, $Res Function(_ProjectDetailCreate) _then) = __$ProjectDetailCreateCopyWithImpl;
@useResult
$Res call({
 String name
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
@pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(_ProjectDetailCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
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
  return 'ProjectDetailEvent.get(projectId: $projectId)';
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
mixin _$ProjectDetailError {

 String get message; StackTrace? get stackTrace;
/// Create a copy of ProjectDetailError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectDetailErrorCopyWith<ProjectDetailError> get copyWith => _$ProjectDetailErrorCopyWithImpl<ProjectDetailError>(this as ProjectDetailError, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDetailError&&(identical(other.message, message) || other.message == message)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}


@override
int get hashCode => Object.hash(runtimeType,message,stackTrace);

@override
String toString() {
  return 'ProjectDetailError(message: $message, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class $ProjectDetailErrorCopyWith<$Res>  {
  factory $ProjectDetailErrorCopyWith(ProjectDetailError value, $Res Function(ProjectDetailError) _then) = _$ProjectDetailErrorCopyWithImpl;
@useResult
$Res call({
 String message, StackTrace? stackTrace
});




}
/// @nodoc
class _$ProjectDetailErrorCopyWithImpl<$Res>
    implements $ProjectDetailErrorCopyWith<$Res> {
  _$ProjectDetailErrorCopyWithImpl(this._self, this._then);

  final ProjectDetailError _self;
  final $Res Function(ProjectDetailError) _then;

/// Create a copy of ProjectDetailError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,Object? stackTrace = freezed,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectDetailError].
extension ProjectDetailErrorPatterns on ProjectDetailError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectDetailError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectDetailError() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectDetailError value)  $default,){
final _that = this;
switch (_that) {
case _ProjectDetailError():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectDetailError value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectDetailError() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String message,  StackTrace? stackTrace)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectDetailError() when $default != null:
return $default(_that.message,_that.stackTrace);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String message,  StackTrace? stackTrace)  $default,) {final _that = this;
switch (_that) {
case _ProjectDetailError():
return $default(_that.message,_that.stackTrace);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String message,  StackTrace? stackTrace)?  $default,) {final _that = this;
switch (_that) {
case _ProjectDetailError() when $default != null:
return $default(_that.message,_that.stackTrace);case _:
  return null;

}
}

}

/// @nodoc


class _ProjectDetailError implements ProjectDetailError {
  const _ProjectDetailError({required this.message, this.stackTrace});
  

@override final  String message;
@override final  StackTrace? stackTrace;

/// Create a copy of ProjectDetailError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectDetailErrorCopyWith<_ProjectDetailError> get copyWith => __$ProjectDetailErrorCopyWithImpl<_ProjectDetailError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDetailError&&(identical(other.message, message) || other.message == message)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}


@override
int get hashCode => Object.hash(runtimeType,message,stackTrace);

@override
String toString() {
  return 'ProjectDetailError(message: $message, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class _$ProjectDetailErrorCopyWith<$Res> implements $ProjectDetailErrorCopyWith<$Res> {
  factory _$ProjectDetailErrorCopyWith(_ProjectDetailError value, $Res Function(_ProjectDetailError) _then) = __$ProjectDetailErrorCopyWithImpl;
@override @useResult
$Res call({
 String message, StackTrace? stackTrace
});




}
/// @nodoc
class __$ProjectDetailErrorCopyWithImpl<$Res>
    implements _$ProjectDetailErrorCopyWith<$Res> {
  __$ProjectDetailErrorCopyWithImpl(this._self, this._then);

  final _ProjectDetailError _self;
  final $Res Function(_ProjectDetailError) _then;

/// Create a copy of ProjectDetailError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? stackTrace = freezed,}) {
  return _then(_ProjectDetailError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace?,
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProjectDetailInitial value)?  initial,TResult Function( ProjectDetailOperationSuccess value)?  operationSuccess,TResult Function( ProjectDetailOperationFailure value)?  operationFailure,TResult Function( ProjectDetailLoadInProgress value)?  loadInProgress,TResult Function( ProjectDetailLoadSuccess value)?  loadSuccess,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProjectDetailInitial() when initial != null:
return initial(_that);case ProjectDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that);case ProjectDetailOperationFailure() when operationFailure != null:
return operationFailure(_that);case ProjectDetailLoadInProgress() when loadInProgress != null:
return loadInProgress(_that);case ProjectDetailLoadSuccess() when loadSuccess != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProjectDetailInitial value)  initial,required TResult Function( ProjectDetailOperationSuccess value)  operationSuccess,required TResult Function( ProjectDetailOperationFailure value)  operationFailure,required TResult Function( ProjectDetailLoadInProgress value)  loadInProgress,required TResult Function( ProjectDetailLoadSuccess value)  loadSuccess,}){
final _that = this;
switch (_that) {
case ProjectDetailInitial():
return initial(_that);case ProjectDetailOperationSuccess():
return operationSuccess(_that);case ProjectDetailOperationFailure():
return operationFailure(_that);case ProjectDetailLoadInProgress():
return loadInProgress(_that);case ProjectDetailLoadSuccess():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProjectDetailInitial value)?  initial,TResult? Function( ProjectDetailOperationSuccess value)?  operationSuccess,TResult? Function( ProjectDetailOperationFailure value)?  operationFailure,TResult? Function( ProjectDetailLoadInProgress value)?  loadInProgress,TResult? Function( ProjectDetailLoadSuccess value)?  loadSuccess,}){
final _that = this;
switch (_that) {
case ProjectDetailInitial() when initial != null:
return initial(_that);case ProjectDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that);case ProjectDetailOperationFailure() when operationFailure != null:
return operationFailure(_that);case ProjectDetailLoadInProgress() when loadInProgress != null:
return loadInProgress(_that);case ProjectDetailLoadSuccess() when loadSuccess != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( String message)?  operationSuccess,TResult Function( ProjectDetailError errorDetails)?  operationFailure,TResult Function()?  loadInProgress,TResult Function( Project project)?  loadSuccess,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProjectDetailInitial() when initial != null:
return initial();case ProjectDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that.message);case ProjectDetailOperationFailure() when operationFailure != null:
return operationFailure(_that.errorDetails);case ProjectDetailLoadInProgress() when loadInProgress != null:
return loadInProgress();case ProjectDetailLoadSuccess() when loadSuccess != null:
return loadSuccess(_that.project);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( String message)  operationSuccess,required TResult Function( ProjectDetailError errorDetails)  operationFailure,required TResult Function()  loadInProgress,required TResult Function( Project project)  loadSuccess,}) {final _that = this;
switch (_that) {
case ProjectDetailInitial():
return initial();case ProjectDetailOperationSuccess():
return operationSuccess(_that.message);case ProjectDetailOperationFailure():
return operationFailure(_that.errorDetails);case ProjectDetailLoadInProgress():
return loadInProgress();case ProjectDetailLoadSuccess():
return loadSuccess(_that.project);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( String message)?  operationSuccess,TResult? Function( ProjectDetailError errorDetails)?  operationFailure,TResult? Function()?  loadInProgress,TResult? Function( Project project)?  loadSuccess,}) {final _that = this;
switch (_that) {
case ProjectDetailInitial() when initial != null:
return initial();case ProjectDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that.message);case ProjectDetailOperationFailure() when operationFailure != null:
return operationFailure(_that.errorDetails);case ProjectDetailLoadInProgress() when loadInProgress != null:
return loadInProgress();case ProjectDetailLoadSuccess() when loadSuccess != null:
return loadSuccess(_that.project);case _:
  return null;

}
}

}

/// @nodoc


class ProjectDetailInitial implements ProjectDetailState {
  const ProjectDetailInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDetailInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectDetailState.initial()';
}


}




/// @nodoc


class ProjectDetailOperationSuccess implements ProjectDetailState {
  const ProjectDetailOperationSuccess({required this.message});
  

 final  String message;

/// Create a copy of ProjectDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectDetailOperationSuccessCopyWith<ProjectDetailOperationSuccess> get copyWith => _$ProjectDetailOperationSuccessCopyWithImpl<ProjectDetailOperationSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDetailOperationSuccess&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ProjectDetailState.operationSuccess(message: $message)';
}


}

/// @nodoc
abstract mixin class $ProjectDetailOperationSuccessCopyWith<$Res> implements $ProjectDetailStateCopyWith<$Res> {
  factory $ProjectDetailOperationSuccessCopyWith(ProjectDetailOperationSuccess value, $Res Function(ProjectDetailOperationSuccess) _then) = _$ProjectDetailOperationSuccessCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ProjectDetailOperationSuccessCopyWithImpl<$Res>
    implements $ProjectDetailOperationSuccessCopyWith<$Res> {
  _$ProjectDetailOperationSuccessCopyWithImpl(this._self, this._then);

  final ProjectDetailOperationSuccess _self;
  final $Res Function(ProjectDetailOperationSuccess) _then;

/// Create a copy of ProjectDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ProjectDetailOperationSuccess(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ProjectDetailOperationFailure implements ProjectDetailState {
  const ProjectDetailOperationFailure({required this.errorDetails});
  

 final  ProjectDetailError errorDetails;

/// Create a copy of ProjectDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectDetailOperationFailureCopyWith<ProjectDetailOperationFailure> get copyWith => _$ProjectDetailOperationFailureCopyWithImpl<ProjectDetailOperationFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDetailOperationFailure&&(identical(other.errorDetails, errorDetails) || other.errorDetails == errorDetails));
}


@override
int get hashCode => Object.hash(runtimeType,errorDetails);

@override
String toString() {
  return 'ProjectDetailState.operationFailure(errorDetails: $errorDetails)';
}


}

/// @nodoc
abstract mixin class $ProjectDetailOperationFailureCopyWith<$Res> implements $ProjectDetailStateCopyWith<$Res> {
  factory $ProjectDetailOperationFailureCopyWith(ProjectDetailOperationFailure value, $Res Function(ProjectDetailOperationFailure) _then) = _$ProjectDetailOperationFailureCopyWithImpl;
@useResult
$Res call({
 ProjectDetailError errorDetails
});


$ProjectDetailErrorCopyWith<$Res> get errorDetails;

}
/// @nodoc
class _$ProjectDetailOperationFailureCopyWithImpl<$Res>
    implements $ProjectDetailOperationFailureCopyWith<$Res> {
  _$ProjectDetailOperationFailureCopyWithImpl(this._self, this._then);

  final ProjectDetailOperationFailure _self;
  final $Res Function(ProjectDetailOperationFailure) _then;

/// Create a copy of ProjectDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorDetails = null,}) {
  return _then(ProjectDetailOperationFailure(
errorDetails: null == errorDetails ? _self.errorDetails : errorDetails // ignore: cast_nullable_to_non_nullable
as ProjectDetailError,
  ));
}

/// Create a copy of ProjectDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectDetailErrorCopyWith<$Res> get errorDetails {
  
  return $ProjectDetailErrorCopyWith<$Res>(_self.errorDetails, (value) {
    return _then(_self.copyWith(errorDetails: value));
  });
}
}

/// @nodoc


class ProjectDetailLoadInProgress implements ProjectDetailState {
  const ProjectDetailLoadInProgress();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDetailLoadInProgress);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectDetailState.loadInProgress()';
}


}




/// @nodoc


class ProjectDetailLoadSuccess implements ProjectDetailState {
  const ProjectDetailLoadSuccess({required this.project});
  

 final  Project project;

/// Create a copy of ProjectDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectDetailLoadSuccessCopyWith<ProjectDetailLoadSuccess> get copyWith => _$ProjectDetailLoadSuccessCopyWithImpl<ProjectDetailLoadSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDetailLoadSuccess&&(identical(other.project, project) || other.project == project));
}


@override
int get hashCode => Object.hash(runtimeType,project);

@override
String toString() {
  return 'ProjectDetailState.loadSuccess(project: $project)';
}


}

/// @nodoc
abstract mixin class $ProjectDetailLoadSuccessCopyWith<$Res> implements $ProjectDetailStateCopyWith<$Res> {
  factory $ProjectDetailLoadSuccessCopyWith(ProjectDetailLoadSuccess value, $Res Function(ProjectDetailLoadSuccess) _then) = _$ProjectDetailLoadSuccessCopyWithImpl;
@useResult
$Res call({
 Project project
});




}
/// @nodoc
class _$ProjectDetailLoadSuccessCopyWithImpl<$Res>
    implements $ProjectDetailLoadSuccessCopyWith<$Res> {
  _$ProjectDetailLoadSuccessCopyWithImpl(this._self, this._then);

  final ProjectDetailLoadSuccess _self;
  final $Res Function(ProjectDetailLoadSuccess) _then;

/// Create a copy of ProjectDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? project = null,}) {
  return _then(ProjectDetailLoadSuccess(
project: null == project ? _self.project : project // ignore: cast_nullable_to_non_nullable
as Project,
  ));
}


}

// dart format on
