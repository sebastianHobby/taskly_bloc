// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'label_detail_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LabelDetailEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabelDetailEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LabelDetailEvent()';
}


}

/// @nodoc
class $LabelDetailEventCopyWith<$Res>  {
$LabelDetailEventCopyWith(LabelDetailEvent _, $Res Function(LabelDetailEvent) __);
}


/// Adds pattern-matching-related methods to [LabelDetailEvent].
extension LabelDetailEventPatterns on LabelDetailEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _LabelDetailUpdate value)?  update,TResult Function( _LabelDetailDelete value)?  delete,TResult Function( _LabelDetailCreate value)?  create,TResult Function( _LabelDetailGet value)?  get,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LabelDetailUpdate() when update != null:
return update(_that);case _LabelDetailDelete() when delete != null:
return delete(_that);case _LabelDetailCreate() when create != null:
return create(_that);case _LabelDetailGet() when get != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _LabelDetailUpdate value)  update,required TResult Function( _LabelDetailDelete value)  delete,required TResult Function( _LabelDetailCreate value)  create,required TResult Function( _LabelDetailGet value)  get,}){
final _that = this;
switch (_that) {
case _LabelDetailUpdate():
return update(_that);case _LabelDetailDelete():
return delete(_that);case _LabelDetailCreate():
return create(_that);case _LabelDetailGet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _LabelDetailUpdate value)?  update,TResult? Function( _LabelDetailDelete value)?  delete,TResult? Function( _LabelDetailCreate value)?  create,TResult? Function( _LabelDetailGet value)?  get,}){
final _that = this;
switch (_that) {
case _LabelDetailUpdate() when update != null:
return update(_that);case _LabelDetailDelete() when delete != null:
return delete(_that);case _LabelDetailCreate() when create != null:
return create(_that);case _LabelDetailGet() when get != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String name)?  update,TResult Function( String id)?  delete,TResult Function( String name)?  create,TResult Function( String labelId)?  get,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LabelDetailUpdate() when update != null:
return update(_that.id,_that.name);case _LabelDetailDelete() when delete != null:
return delete(_that.id);case _LabelDetailCreate() when create != null:
return create(_that.name);case _LabelDetailGet() when get != null:
return get(_that.labelId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String name)  update,required TResult Function( String id)  delete,required TResult Function( String name)  create,required TResult Function( String labelId)  get,}) {final _that = this;
switch (_that) {
case _LabelDetailUpdate():
return update(_that.id,_that.name);case _LabelDetailDelete():
return delete(_that.id);case _LabelDetailCreate():
return create(_that.name);case _LabelDetailGet():
return get(_that.labelId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String name)?  update,TResult? Function( String id)?  delete,TResult? Function( String name)?  create,TResult? Function( String labelId)?  get,}) {final _that = this;
switch (_that) {
case _LabelDetailUpdate() when update != null:
return update(_that.id,_that.name);case _LabelDetailDelete() when delete != null:
return delete(_that.id);case _LabelDetailCreate() when create != null:
return create(_that.name);case _LabelDetailGet() when get != null:
return get(_that.labelId);case _:
  return null;

}
}

}

/// @nodoc


class _LabelDetailUpdate implements LabelDetailEvent {
  const _LabelDetailUpdate({required this.id, required this.name});
  

 final  String id;
 final  String name;

/// Create a copy of LabelDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LabelDetailUpdateCopyWith<_LabelDetailUpdate> get copyWith => __$LabelDetailUpdateCopyWithImpl<_LabelDetailUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LabelDetailUpdate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'LabelDetailEvent.update(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$LabelDetailUpdateCopyWith<$Res> implements $LabelDetailEventCopyWith<$Res> {
  factory _$LabelDetailUpdateCopyWith(_LabelDetailUpdate value, $Res Function(_LabelDetailUpdate) _then) = __$LabelDetailUpdateCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$LabelDetailUpdateCopyWithImpl<$Res>
    implements _$LabelDetailUpdateCopyWith<$Res> {
  __$LabelDetailUpdateCopyWithImpl(this._self, this._then);

  final _LabelDetailUpdate _self;
  final $Res Function(_LabelDetailUpdate) _then;

/// Create a copy of LabelDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_LabelDetailUpdate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _LabelDetailDelete implements LabelDetailEvent {
  const _LabelDetailDelete({required this.id});
  

 final  String id;

/// Create a copy of LabelDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LabelDetailDeleteCopyWith<_LabelDetailDelete> get copyWith => __$LabelDetailDeleteCopyWithImpl<_LabelDetailDelete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LabelDetailDelete&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'LabelDetailEvent.delete(id: $id)';
}


}

/// @nodoc
abstract mixin class _$LabelDetailDeleteCopyWith<$Res> implements $LabelDetailEventCopyWith<$Res> {
  factory _$LabelDetailDeleteCopyWith(_LabelDetailDelete value, $Res Function(_LabelDetailDelete) _then) = __$LabelDetailDeleteCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class __$LabelDetailDeleteCopyWithImpl<$Res>
    implements _$LabelDetailDeleteCopyWith<$Res> {
  __$LabelDetailDeleteCopyWithImpl(this._self, this._then);

  final _LabelDetailDelete _self;
  final $Res Function(_LabelDetailDelete) _then;

/// Create a copy of LabelDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_LabelDetailDelete(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _LabelDetailCreate implements LabelDetailEvent {
  const _LabelDetailCreate({required this.name});
  

 final  String name;

/// Create a copy of LabelDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LabelDetailCreateCopyWith<_LabelDetailCreate> get copyWith => __$LabelDetailCreateCopyWithImpl<_LabelDetailCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LabelDetailCreate&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'LabelDetailEvent.create(name: $name)';
}


}

/// @nodoc
abstract mixin class _$LabelDetailCreateCopyWith<$Res> implements $LabelDetailEventCopyWith<$Res> {
  factory _$LabelDetailCreateCopyWith(_LabelDetailCreate value, $Res Function(_LabelDetailCreate) _then) = __$LabelDetailCreateCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class __$LabelDetailCreateCopyWithImpl<$Res>
    implements _$LabelDetailCreateCopyWith<$Res> {
  __$LabelDetailCreateCopyWithImpl(this._self, this._then);

  final _LabelDetailCreate _self;
  final $Res Function(_LabelDetailCreate) _then;

/// Create a copy of LabelDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(_LabelDetailCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _LabelDetailGet implements LabelDetailEvent {
  const _LabelDetailGet({required this.labelId});
  

 final  String labelId;

/// Create a copy of LabelDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LabelDetailGetCopyWith<_LabelDetailGet> get copyWith => __$LabelDetailGetCopyWithImpl<_LabelDetailGet>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LabelDetailGet&&(identical(other.labelId, labelId) || other.labelId == labelId));
}


@override
int get hashCode => Object.hash(runtimeType,labelId);

@override
String toString() {
  return 'LabelDetailEvent.get(labelId: $labelId)';
}


}

/// @nodoc
abstract mixin class _$LabelDetailGetCopyWith<$Res> implements $LabelDetailEventCopyWith<$Res> {
  factory _$LabelDetailGetCopyWith(_LabelDetailGet value, $Res Function(_LabelDetailGet) _then) = __$LabelDetailGetCopyWithImpl;
@useResult
$Res call({
 String labelId
});




}
/// @nodoc
class __$LabelDetailGetCopyWithImpl<$Res>
    implements _$LabelDetailGetCopyWith<$Res> {
  __$LabelDetailGetCopyWithImpl(this._self, this._then);

  final _LabelDetailGet _self;
  final $Res Function(_LabelDetailGet) _then;

/// Create a copy of LabelDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? labelId = null,}) {
  return _then(_LabelDetailGet(
labelId: null == labelId ? _self.labelId : labelId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$LabelDetailError {

 Object get error; StackTrace? get stackTrace;
/// Create a copy of LabelDetailError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LabelDetailErrorCopyWith<LabelDetailError> get copyWith => _$LabelDetailErrorCopyWithImpl<LabelDetailError>(this as LabelDetailError, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabelDetailError&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stackTrace);

@override
String toString() {
  return 'LabelDetailError(error: $error, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class $LabelDetailErrorCopyWith<$Res>  {
  factory $LabelDetailErrorCopyWith(LabelDetailError value, $Res Function(LabelDetailError) _then) = _$LabelDetailErrorCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace? stackTrace
});




}
/// @nodoc
class _$LabelDetailErrorCopyWithImpl<$Res>
    implements $LabelDetailErrorCopyWith<$Res> {
  _$LabelDetailErrorCopyWithImpl(this._self, this._then);

  final LabelDetailError _self;
  final $Res Function(LabelDetailError) _then;

/// Create a copy of LabelDetailError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? error = null,Object? stackTrace = freezed,}) {
  return _then(_self.copyWith(
error: null == error ? _self.error : error ,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace?,
  ));
}

}


/// Adds pattern-matching-related methods to [LabelDetailError].
extension LabelDetailErrorPatterns on LabelDetailError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LabelDetailError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LabelDetailError() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LabelDetailError value)  $default,){
final _that = this;
switch (_that) {
case _LabelDetailError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LabelDetailError value)?  $default,){
final _that = this;
switch (_that) {
case _LabelDetailError() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Object error,  StackTrace? stackTrace)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LabelDetailError() when $default != null:
return $default(_that.error,_that.stackTrace);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Object error,  StackTrace? stackTrace)  $default,) {final _that = this;
switch (_that) {
case _LabelDetailError():
return $default(_that.error,_that.stackTrace);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Object error,  StackTrace? stackTrace)?  $default,) {final _that = this;
switch (_that) {
case _LabelDetailError() when $default != null:
return $default(_that.error,_that.stackTrace);case _:
  return null;

}
}

}

/// @nodoc


class _LabelDetailError implements LabelDetailError {
  const _LabelDetailError({required this.error, this.stackTrace});
  

@override final  Object error;
@override final  StackTrace? stackTrace;

/// Create a copy of LabelDetailError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LabelDetailErrorCopyWith<_LabelDetailError> get copyWith => __$LabelDetailErrorCopyWithImpl<_LabelDetailError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LabelDetailError&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stackTrace);

@override
String toString() {
  return 'LabelDetailError(error: $error, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class _$LabelDetailErrorCopyWith<$Res> implements $LabelDetailErrorCopyWith<$Res> {
  factory _$LabelDetailErrorCopyWith(_LabelDetailError value, $Res Function(_LabelDetailError) _then) = __$LabelDetailErrorCopyWithImpl;
@override @useResult
$Res call({
 Object error, StackTrace? stackTrace
});




}
/// @nodoc
class __$LabelDetailErrorCopyWithImpl<$Res>
    implements _$LabelDetailErrorCopyWith<$Res> {
  __$LabelDetailErrorCopyWithImpl(this._self, this._then);

  final _LabelDetailError _self;
  final $Res Function(_LabelDetailError) _then;

/// Create a copy of LabelDetailError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stackTrace = freezed,}) {
  return _then(_LabelDetailError(
error: null == error ? _self.error : error ,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace?,
  ));
}


}

/// @nodoc
mixin _$LabelDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabelDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LabelDetailState()';
}


}

/// @nodoc
class $LabelDetailStateCopyWith<$Res>  {
$LabelDetailStateCopyWith(LabelDetailState _, $Res Function(LabelDetailState) __);
}


/// Adds pattern-matching-related methods to [LabelDetailState].
extension LabelDetailStatePatterns on LabelDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LabelDetailInitial value)?  initial,TResult Function( LabelDetailOperationSuccess value)?  operationSuccess,TResult Function( LabelDetailOperationFailure value)?  operationFailure,TResult Function( LabelDetailLoadInProgress value)?  loadInProgress,TResult Function( LabelDetailLoadSuccess value)?  loadSuccess,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LabelDetailInitial() when initial != null:
return initial(_that);case LabelDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that);case LabelDetailOperationFailure() when operationFailure != null:
return operationFailure(_that);case LabelDetailLoadInProgress() when loadInProgress != null:
return loadInProgress(_that);case LabelDetailLoadSuccess() when loadSuccess != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LabelDetailInitial value)  initial,required TResult Function( LabelDetailOperationSuccess value)  operationSuccess,required TResult Function( LabelDetailOperationFailure value)  operationFailure,required TResult Function( LabelDetailLoadInProgress value)  loadInProgress,required TResult Function( LabelDetailLoadSuccess value)  loadSuccess,}){
final _that = this;
switch (_that) {
case LabelDetailInitial():
return initial(_that);case LabelDetailOperationSuccess():
return operationSuccess(_that);case LabelDetailOperationFailure():
return operationFailure(_that);case LabelDetailLoadInProgress():
return loadInProgress(_that);case LabelDetailLoadSuccess():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LabelDetailInitial value)?  initial,TResult? Function( LabelDetailOperationSuccess value)?  operationSuccess,TResult? Function( LabelDetailOperationFailure value)?  operationFailure,TResult? Function( LabelDetailLoadInProgress value)?  loadInProgress,TResult? Function( LabelDetailLoadSuccess value)?  loadSuccess,}){
final _that = this;
switch (_that) {
case LabelDetailInitial() when initial != null:
return initial(_that);case LabelDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that);case LabelDetailOperationFailure() when operationFailure != null:
return operationFailure(_that);case LabelDetailLoadInProgress() when loadInProgress != null:
return loadInProgress(_that);case LabelDetailLoadSuccess() when loadSuccess != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( String message)?  operationSuccess,TResult Function( LabelDetailError errorDetails)?  operationFailure,TResult Function()?  loadInProgress,TResult Function( Label label)?  loadSuccess,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LabelDetailInitial() when initial != null:
return initial();case LabelDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that.message);case LabelDetailOperationFailure() when operationFailure != null:
return operationFailure(_that.errorDetails);case LabelDetailLoadInProgress() when loadInProgress != null:
return loadInProgress();case LabelDetailLoadSuccess() when loadSuccess != null:
return loadSuccess(_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( String message)  operationSuccess,required TResult Function( LabelDetailError errorDetails)  operationFailure,required TResult Function()  loadInProgress,required TResult Function( Label label)  loadSuccess,}) {final _that = this;
switch (_that) {
case LabelDetailInitial():
return initial();case LabelDetailOperationSuccess():
return operationSuccess(_that.message);case LabelDetailOperationFailure():
return operationFailure(_that.errorDetails);case LabelDetailLoadInProgress():
return loadInProgress();case LabelDetailLoadSuccess():
return loadSuccess(_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( String message)?  operationSuccess,TResult? Function( LabelDetailError errorDetails)?  operationFailure,TResult? Function()?  loadInProgress,TResult? Function( Label label)?  loadSuccess,}) {final _that = this;
switch (_that) {
case LabelDetailInitial() when initial != null:
return initial();case LabelDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that.message);case LabelDetailOperationFailure() when operationFailure != null:
return operationFailure(_that.errorDetails);case LabelDetailLoadInProgress() when loadInProgress != null:
return loadInProgress();case LabelDetailLoadSuccess() when loadSuccess != null:
return loadSuccess(_that.label);case _:
  return null;

}
}

}

/// @nodoc


class LabelDetailInitial implements LabelDetailState {
  const LabelDetailInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabelDetailInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LabelDetailState.initial()';
}


}




/// @nodoc


class LabelDetailOperationSuccess implements LabelDetailState {
  const LabelDetailOperationSuccess({required this.message});
  

 final  String message;

/// Create a copy of LabelDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LabelDetailOperationSuccessCopyWith<LabelDetailOperationSuccess> get copyWith => _$LabelDetailOperationSuccessCopyWithImpl<LabelDetailOperationSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabelDetailOperationSuccess&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'LabelDetailState.operationSuccess(message: $message)';
}


}

/// @nodoc
abstract mixin class $LabelDetailOperationSuccessCopyWith<$Res> implements $LabelDetailStateCopyWith<$Res> {
  factory $LabelDetailOperationSuccessCopyWith(LabelDetailOperationSuccess value, $Res Function(LabelDetailOperationSuccess) _then) = _$LabelDetailOperationSuccessCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$LabelDetailOperationSuccessCopyWithImpl<$Res>
    implements $LabelDetailOperationSuccessCopyWith<$Res> {
  _$LabelDetailOperationSuccessCopyWithImpl(this._self, this._then);

  final LabelDetailOperationSuccess _self;
  final $Res Function(LabelDetailOperationSuccess) _then;

/// Create a copy of LabelDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(LabelDetailOperationSuccess(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class LabelDetailOperationFailure implements LabelDetailState {
  const LabelDetailOperationFailure({required this.errorDetails});
  

 final  LabelDetailError errorDetails;

/// Create a copy of LabelDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LabelDetailOperationFailureCopyWith<LabelDetailOperationFailure> get copyWith => _$LabelDetailOperationFailureCopyWithImpl<LabelDetailOperationFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabelDetailOperationFailure&&(identical(other.errorDetails, errorDetails) || other.errorDetails == errorDetails));
}


@override
int get hashCode => Object.hash(runtimeType,errorDetails);

@override
String toString() {
  return 'LabelDetailState.operationFailure(errorDetails: $errorDetails)';
}


}

/// @nodoc
abstract mixin class $LabelDetailOperationFailureCopyWith<$Res> implements $LabelDetailStateCopyWith<$Res> {
  factory $LabelDetailOperationFailureCopyWith(LabelDetailOperationFailure value, $Res Function(LabelDetailOperationFailure) _then) = _$LabelDetailOperationFailureCopyWithImpl;
@useResult
$Res call({
 LabelDetailError errorDetails
});


$LabelDetailErrorCopyWith<$Res> get errorDetails;

}
/// @nodoc
class _$LabelDetailOperationFailureCopyWithImpl<$Res>
    implements $LabelDetailOperationFailureCopyWith<$Res> {
  _$LabelDetailOperationFailureCopyWithImpl(this._self, this._then);

  final LabelDetailOperationFailure _self;
  final $Res Function(LabelDetailOperationFailure) _then;

/// Create a copy of LabelDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorDetails = null,}) {
  return _then(LabelDetailOperationFailure(
errorDetails: null == errorDetails ? _self.errorDetails : errorDetails // ignore: cast_nullable_to_non_nullable
as LabelDetailError,
  ));
}

/// Create a copy of LabelDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LabelDetailErrorCopyWith<$Res> get errorDetails {
  
  return $LabelDetailErrorCopyWith<$Res>(_self.errorDetails, (value) {
    return _then(_self.copyWith(errorDetails: value));
  });
}
}

/// @nodoc


class LabelDetailLoadInProgress implements LabelDetailState {
  const LabelDetailLoadInProgress();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabelDetailLoadInProgress);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LabelDetailState.loadInProgress()';
}


}




/// @nodoc


class LabelDetailLoadSuccess implements LabelDetailState {
  const LabelDetailLoadSuccess({required this.label});
  

 final  Label label;

/// Create a copy of LabelDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LabelDetailLoadSuccessCopyWith<LabelDetailLoadSuccess> get copyWith => _$LabelDetailLoadSuccessCopyWithImpl<LabelDetailLoadSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabelDetailLoadSuccess&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,label);

@override
String toString() {
  return 'LabelDetailState.loadSuccess(label: $label)';
}


}

/// @nodoc
abstract mixin class $LabelDetailLoadSuccessCopyWith<$Res> implements $LabelDetailStateCopyWith<$Res> {
  factory $LabelDetailLoadSuccessCopyWith(LabelDetailLoadSuccess value, $Res Function(LabelDetailLoadSuccess) _then) = _$LabelDetailLoadSuccessCopyWithImpl;
@useResult
$Res call({
 Label label
});




}
/// @nodoc
class _$LabelDetailLoadSuccessCopyWithImpl<$Res>
    implements $LabelDetailLoadSuccessCopyWith<$Res> {
  _$LabelDetailLoadSuccessCopyWithImpl(this._self, this._then);

  final LabelDetailLoadSuccess _self;
  final $Res Function(LabelDetailLoadSuccess) _then;

/// Create a copy of LabelDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? label = null,}) {
  return _then(LabelDetailLoadSuccess(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as Label,
  ));
}


}

// dart format on
