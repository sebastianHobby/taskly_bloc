// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'value_detail_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ValueDetailEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValueDetailEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ValueDetailEvent()';
}


}

/// @nodoc
class $ValueDetailEventCopyWith<$Res>  {
$ValueDetailEventCopyWith(ValueDetailEvent _, $Res Function(ValueDetailEvent) __);
}


/// Adds pattern-matching-related methods to [ValueDetailEvent].
extension ValueDetailEventPatterns on ValueDetailEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _ValueDetailUpdate value)?  update,TResult Function( _ValueDetailDelete value)?  delete,TResult Function( _ValueDetailCreate value)?  create,TResult Function( _ValueDetailGet value)?  get,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ValueDetailUpdate() when update != null:
return update(_that);case _ValueDetailDelete() when delete != null:
return delete(_that);case _ValueDetailCreate() when create != null:
return create(_that);case _ValueDetailGet() when get != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _ValueDetailUpdate value)  update,required TResult Function( _ValueDetailDelete value)  delete,required TResult Function( _ValueDetailCreate value)  create,required TResult Function( _ValueDetailGet value)  get,}){
final _that = this;
switch (_that) {
case _ValueDetailUpdate():
return update(_that);case _ValueDetailDelete():
return delete(_that);case _ValueDetailCreate():
return create(_that);case _ValueDetailGet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _ValueDetailUpdate value)?  update,TResult? Function( _ValueDetailDelete value)?  delete,TResult? Function( _ValueDetailCreate value)?  create,TResult? Function( _ValueDetailGet value)?  get,}){
final _that = this;
switch (_that) {
case _ValueDetailUpdate() when update != null:
return update(_that);case _ValueDetailDelete() when delete != null:
return delete(_that);case _ValueDetailCreate() when create != null:
return create(_that);case _ValueDetailGet() when get != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String name)?  update,TResult Function( String id)?  delete,TResult Function( String name)?  create,TResult Function( String valueId)?  get,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ValueDetailUpdate() when update != null:
return update(_that.id,_that.name);case _ValueDetailDelete() when delete != null:
return delete(_that.id);case _ValueDetailCreate() when create != null:
return create(_that.name);case _ValueDetailGet() when get != null:
return get(_that.valueId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String name)  update,required TResult Function( String id)  delete,required TResult Function( String name)  create,required TResult Function( String valueId)  get,}) {final _that = this;
switch (_that) {
case _ValueDetailUpdate():
return update(_that.id,_that.name);case _ValueDetailDelete():
return delete(_that.id);case _ValueDetailCreate():
return create(_that.name);case _ValueDetailGet():
return get(_that.valueId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String name)?  update,TResult? Function( String id)?  delete,TResult? Function( String name)?  create,TResult? Function( String valueId)?  get,}) {final _that = this;
switch (_that) {
case _ValueDetailUpdate() when update != null:
return update(_that.id,_that.name);case _ValueDetailDelete() when delete != null:
return delete(_that.id);case _ValueDetailCreate() when create != null:
return create(_that.name);case _ValueDetailGet() when get != null:
return get(_that.valueId);case _:
  return null;

}
}

}

/// @nodoc


class _ValueDetailUpdate implements ValueDetailEvent {
  const _ValueDetailUpdate({required this.id, required this.name});
  

 final  String id;
 final  String name;

/// Create a copy of ValueDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ValueDetailUpdateCopyWith<_ValueDetailUpdate> get copyWith => __$ValueDetailUpdateCopyWithImpl<_ValueDetailUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ValueDetailUpdate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ValueDetailEvent.update(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$ValueDetailUpdateCopyWith<$Res> implements $ValueDetailEventCopyWith<$Res> {
  factory _$ValueDetailUpdateCopyWith(_ValueDetailUpdate value, $Res Function(_ValueDetailUpdate) _then) = __$ValueDetailUpdateCopyWithImpl;
@useResult
$Res call({
 String id, String name
});




}
/// @nodoc
class __$ValueDetailUpdateCopyWithImpl<$Res>
    implements _$ValueDetailUpdateCopyWith<$Res> {
  __$ValueDetailUpdateCopyWithImpl(this._self, this._then);

  final _ValueDetailUpdate _self;
  final $Res Function(_ValueDetailUpdate) _then;

/// Create a copy of ValueDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_ValueDetailUpdate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ValueDetailDelete implements ValueDetailEvent {
  const _ValueDetailDelete({required this.id});
  

 final  String id;

/// Create a copy of ValueDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ValueDetailDeleteCopyWith<_ValueDetailDelete> get copyWith => __$ValueDetailDeleteCopyWithImpl<_ValueDetailDelete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ValueDetailDelete&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ValueDetailEvent.delete(id: $id)';
}


}

/// @nodoc
abstract mixin class _$ValueDetailDeleteCopyWith<$Res> implements $ValueDetailEventCopyWith<$Res> {
  factory _$ValueDetailDeleteCopyWith(_ValueDetailDelete value, $Res Function(_ValueDetailDelete) _then) = __$ValueDetailDeleteCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class __$ValueDetailDeleteCopyWithImpl<$Res>
    implements _$ValueDetailDeleteCopyWith<$Res> {
  __$ValueDetailDeleteCopyWithImpl(this._self, this._then);

  final _ValueDetailDelete _self;
  final $Res Function(_ValueDetailDelete) _then;

/// Create a copy of ValueDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_ValueDetailDelete(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ValueDetailCreate implements ValueDetailEvent {
  const _ValueDetailCreate({required this.name});
  

 final  String name;

/// Create a copy of ValueDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ValueDetailCreateCopyWith<_ValueDetailCreate> get copyWith => __$ValueDetailCreateCopyWithImpl<_ValueDetailCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ValueDetailCreate&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'ValueDetailEvent.create(name: $name)';
}


}

/// @nodoc
abstract mixin class _$ValueDetailCreateCopyWith<$Res> implements $ValueDetailEventCopyWith<$Res> {
  factory _$ValueDetailCreateCopyWith(_ValueDetailCreate value, $Res Function(_ValueDetailCreate) _then) = __$ValueDetailCreateCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class __$ValueDetailCreateCopyWithImpl<$Res>
    implements _$ValueDetailCreateCopyWith<$Res> {
  __$ValueDetailCreateCopyWithImpl(this._self, this._then);

  final _ValueDetailCreate _self;
  final $Res Function(_ValueDetailCreate) _then;

/// Create a copy of ValueDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(_ValueDetailCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ValueDetailGet implements ValueDetailEvent {
  const _ValueDetailGet({required this.valueId});
  

 final  String valueId;

/// Create a copy of ValueDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ValueDetailGetCopyWith<_ValueDetailGet> get copyWith => __$ValueDetailGetCopyWithImpl<_ValueDetailGet>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ValueDetailGet&&(identical(other.valueId, valueId) || other.valueId == valueId));
}


@override
int get hashCode => Object.hash(runtimeType,valueId);

@override
String toString() {
  return 'ValueDetailEvent.get(valueId: $valueId)';
}


}

/// @nodoc
abstract mixin class _$ValueDetailGetCopyWith<$Res> implements $ValueDetailEventCopyWith<$Res> {
  factory _$ValueDetailGetCopyWith(_ValueDetailGet value, $Res Function(_ValueDetailGet) _then) = __$ValueDetailGetCopyWithImpl;
@useResult
$Res call({
 String valueId
});




}
/// @nodoc
class __$ValueDetailGetCopyWithImpl<$Res>
    implements _$ValueDetailGetCopyWith<$Res> {
  __$ValueDetailGetCopyWithImpl(this._self, this._then);

  final _ValueDetailGet _self;
  final $Res Function(_ValueDetailGet) _then;

/// Create a copy of ValueDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? valueId = null,}) {
  return _then(_ValueDetailGet(
valueId: null == valueId ? _self.valueId : valueId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ValueDetailError {

 String get message; StackTrace? get stackTrace;
/// Create a copy of ValueDetailError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValueDetailErrorCopyWith<ValueDetailError> get copyWith => _$ValueDetailErrorCopyWithImpl<ValueDetailError>(this as ValueDetailError, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValueDetailError&&(identical(other.message, message) || other.message == message)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}


@override
int get hashCode => Object.hash(runtimeType,message,stackTrace);

@override
String toString() {
  return 'ValueDetailError(message: $message, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class $ValueDetailErrorCopyWith<$Res>  {
  factory $ValueDetailErrorCopyWith(ValueDetailError value, $Res Function(ValueDetailError) _then) = _$ValueDetailErrorCopyWithImpl;
@useResult
$Res call({
 String message, StackTrace? stackTrace
});




}
/// @nodoc
class _$ValueDetailErrorCopyWithImpl<$Res>
    implements $ValueDetailErrorCopyWith<$Res> {
  _$ValueDetailErrorCopyWithImpl(this._self, this._then);

  final ValueDetailError _self;
  final $Res Function(ValueDetailError) _then;

/// Create a copy of ValueDetailError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,Object? stackTrace = freezed,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace?,
  ));
}

}


/// Adds pattern-matching-related methods to [ValueDetailError].
extension ValueDetailErrorPatterns on ValueDetailError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ValueDetailError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ValueDetailError() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ValueDetailError value)  $default,){
final _that = this;
switch (_that) {
case _ValueDetailError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ValueDetailError value)?  $default,){
final _that = this;
switch (_that) {
case _ValueDetailError() when $default != null:
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
case _ValueDetailError() when $default != null:
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
case _ValueDetailError():
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
case _ValueDetailError() when $default != null:
return $default(_that.message,_that.stackTrace);case _:
  return null;

}
}

}

/// @nodoc


class _ValueDetailError implements ValueDetailError {
  const _ValueDetailError({required this.message, this.stackTrace});
  

@override final  String message;
@override final  StackTrace? stackTrace;

/// Create a copy of ValueDetailError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ValueDetailErrorCopyWith<_ValueDetailError> get copyWith => __$ValueDetailErrorCopyWithImpl<_ValueDetailError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ValueDetailError&&(identical(other.message, message) || other.message == message)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}


@override
int get hashCode => Object.hash(runtimeType,message,stackTrace);

@override
String toString() {
  return 'ValueDetailError(message: $message, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class _$ValueDetailErrorCopyWith<$Res> implements $ValueDetailErrorCopyWith<$Res> {
  factory _$ValueDetailErrorCopyWith(_ValueDetailError value, $Res Function(_ValueDetailError) _then) = __$ValueDetailErrorCopyWithImpl;
@override @useResult
$Res call({
 String message, StackTrace? stackTrace
});




}
/// @nodoc
class __$ValueDetailErrorCopyWithImpl<$Res>
    implements _$ValueDetailErrorCopyWith<$Res> {
  __$ValueDetailErrorCopyWithImpl(this._self, this._then);

  final _ValueDetailError _self;
  final $Res Function(_ValueDetailError) _then;

/// Create a copy of ValueDetailError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? stackTrace = freezed,}) {
  return _then(_ValueDetailError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace?,
  ));
}


}

/// @nodoc
mixin _$ValueDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValueDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ValueDetailState()';
}


}

/// @nodoc
class $ValueDetailStateCopyWith<$Res>  {
$ValueDetailStateCopyWith(ValueDetailState _, $Res Function(ValueDetailState) __);
}


/// Adds pattern-matching-related methods to [ValueDetailState].
extension ValueDetailStatePatterns on ValueDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ValueDetailInitial value)?  initial,TResult Function( ValueDetailOperationSuccess value)?  operationSuccess,TResult Function( ValueDetailOperationFailure value)?  operationFailure,TResult Function( ValueDetailLoadInProgress value)?  loadInProgress,TResult Function( ValueDetailLoadSuccess value)?  loadSuccess,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ValueDetailInitial() when initial != null:
return initial(_that);case ValueDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that);case ValueDetailOperationFailure() when operationFailure != null:
return operationFailure(_that);case ValueDetailLoadInProgress() when loadInProgress != null:
return loadInProgress(_that);case ValueDetailLoadSuccess() when loadSuccess != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ValueDetailInitial value)  initial,required TResult Function( ValueDetailOperationSuccess value)  operationSuccess,required TResult Function( ValueDetailOperationFailure value)  operationFailure,required TResult Function( ValueDetailLoadInProgress value)  loadInProgress,required TResult Function( ValueDetailLoadSuccess value)  loadSuccess,}){
final _that = this;
switch (_that) {
case ValueDetailInitial():
return initial(_that);case ValueDetailOperationSuccess():
return operationSuccess(_that);case ValueDetailOperationFailure():
return operationFailure(_that);case ValueDetailLoadInProgress():
return loadInProgress(_that);case ValueDetailLoadSuccess():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ValueDetailInitial value)?  initial,TResult? Function( ValueDetailOperationSuccess value)?  operationSuccess,TResult? Function( ValueDetailOperationFailure value)?  operationFailure,TResult? Function( ValueDetailLoadInProgress value)?  loadInProgress,TResult? Function( ValueDetailLoadSuccess value)?  loadSuccess,}){
final _that = this;
switch (_that) {
case ValueDetailInitial() when initial != null:
return initial(_that);case ValueDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that);case ValueDetailOperationFailure() when operationFailure != null:
return operationFailure(_that);case ValueDetailLoadInProgress() when loadInProgress != null:
return loadInProgress(_that);case ValueDetailLoadSuccess() when loadSuccess != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( String message)?  operationSuccess,TResult Function( ValueDetailError errorDetails)?  operationFailure,TResult Function()?  loadInProgress,TResult Function( ValueTableData value)?  loadSuccess,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ValueDetailInitial() when initial != null:
return initial();case ValueDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that.message);case ValueDetailOperationFailure() when operationFailure != null:
return operationFailure(_that.errorDetails);case ValueDetailLoadInProgress() when loadInProgress != null:
return loadInProgress();case ValueDetailLoadSuccess() when loadSuccess != null:
return loadSuccess(_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( String message)  operationSuccess,required TResult Function( ValueDetailError errorDetails)  operationFailure,required TResult Function()  loadInProgress,required TResult Function( ValueTableData value)  loadSuccess,}) {final _that = this;
switch (_that) {
case ValueDetailInitial():
return initial();case ValueDetailOperationSuccess():
return operationSuccess(_that.message);case ValueDetailOperationFailure():
return operationFailure(_that.errorDetails);case ValueDetailLoadInProgress():
return loadInProgress();case ValueDetailLoadSuccess():
return loadSuccess(_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( String message)?  operationSuccess,TResult? Function( ValueDetailError errorDetails)?  operationFailure,TResult? Function()?  loadInProgress,TResult? Function( ValueTableData value)?  loadSuccess,}) {final _that = this;
switch (_that) {
case ValueDetailInitial() when initial != null:
return initial();case ValueDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that.message);case ValueDetailOperationFailure() when operationFailure != null:
return operationFailure(_that.errorDetails);case ValueDetailLoadInProgress() when loadInProgress != null:
return loadInProgress();case ValueDetailLoadSuccess() when loadSuccess != null:
return loadSuccess(_that.value);case _:
  return null;

}
}

}

/// @nodoc


class ValueDetailInitial implements ValueDetailState {
  const ValueDetailInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValueDetailInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ValueDetailState.initial()';
}


}




/// @nodoc


class ValueDetailOperationSuccess implements ValueDetailState {
  const ValueDetailOperationSuccess({required this.message});
  

 final  String message;

/// Create a copy of ValueDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValueDetailOperationSuccessCopyWith<ValueDetailOperationSuccess> get copyWith => _$ValueDetailOperationSuccessCopyWithImpl<ValueDetailOperationSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValueDetailOperationSuccess&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ValueDetailState.operationSuccess(message: $message)';
}


}

/// @nodoc
abstract mixin class $ValueDetailOperationSuccessCopyWith<$Res> implements $ValueDetailStateCopyWith<$Res> {
  factory $ValueDetailOperationSuccessCopyWith(ValueDetailOperationSuccess value, $Res Function(ValueDetailOperationSuccess) _then) = _$ValueDetailOperationSuccessCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ValueDetailOperationSuccessCopyWithImpl<$Res>
    implements $ValueDetailOperationSuccessCopyWith<$Res> {
  _$ValueDetailOperationSuccessCopyWithImpl(this._self, this._then);

  final ValueDetailOperationSuccess _self;
  final $Res Function(ValueDetailOperationSuccess) _then;

/// Create a copy of ValueDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ValueDetailOperationSuccess(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ValueDetailOperationFailure implements ValueDetailState {
  const ValueDetailOperationFailure({required this.errorDetails});
  

 final  ValueDetailError errorDetails;

/// Create a copy of ValueDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValueDetailOperationFailureCopyWith<ValueDetailOperationFailure> get copyWith => _$ValueDetailOperationFailureCopyWithImpl<ValueDetailOperationFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValueDetailOperationFailure&&(identical(other.errorDetails, errorDetails) || other.errorDetails == errorDetails));
}


@override
int get hashCode => Object.hash(runtimeType,errorDetails);

@override
String toString() {
  return 'ValueDetailState.operationFailure(errorDetails: $errorDetails)';
}


}

/// @nodoc
abstract mixin class $ValueDetailOperationFailureCopyWith<$Res> implements $ValueDetailStateCopyWith<$Res> {
  factory $ValueDetailOperationFailureCopyWith(ValueDetailOperationFailure value, $Res Function(ValueDetailOperationFailure) _then) = _$ValueDetailOperationFailureCopyWithImpl;
@useResult
$Res call({
 ValueDetailError errorDetails
});


$ValueDetailErrorCopyWith<$Res> get errorDetails;

}
/// @nodoc
class _$ValueDetailOperationFailureCopyWithImpl<$Res>
    implements $ValueDetailOperationFailureCopyWith<$Res> {
  _$ValueDetailOperationFailureCopyWithImpl(this._self, this._then);

  final ValueDetailOperationFailure _self;
  final $Res Function(ValueDetailOperationFailure) _then;

/// Create a copy of ValueDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorDetails = null,}) {
  return _then(ValueDetailOperationFailure(
errorDetails: null == errorDetails ? _self.errorDetails : errorDetails // ignore: cast_nullable_to_non_nullable
as ValueDetailError,
  ));
}

/// Create a copy of ValueDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ValueDetailErrorCopyWith<$Res> get errorDetails {
  
  return $ValueDetailErrorCopyWith<$Res>(_self.errorDetails, (value) {
    return _then(_self.copyWith(errorDetails: value));
  });
}
}

/// @nodoc


class ValueDetailLoadInProgress implements ValueDetailState {
  const ValueDetailLoadInProgress();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValueDetailLoadInProgress);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ValueDetailState.loadInProgress()';
}


}




/// @nodoc


class ValueDetailLoadSuccess implements ValueDetailState {
  const ValueDetailLoadSuccess({required this.value});
  

 final  ValueTableData value;

/// Create a copy of ValueDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValueDetailLoadSuccessCopyWith<ValueDetailLoadSuccess> get copyWith => _$ValueDetailLoadSuccessCopyWithImpl<ValueDetailLoadSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValueDetailLoadSuccess&&const DeepCollectionEquality().equals(other.value, value));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(value));

@override
String toString() {
  return 'ValueDetailState.loadSuccess(value: $value)';
}


}

/// @nodoc
abstract mixin class $ValueDetailLoadSuccessCopyWith<$Res> implements $ValueDetailStateCopyWith<$Res> {
  factory $ValueDetailLoadSuccessCopyWith(ValueDetailLoadSuccess value, $Res Function(ValueDetailLoadSuccess) _then) = _$ValueDetailLoadSuccessCopyWithImpl;
@useResult
$Res call({
 ValueTableData value
});




}
/// @nodoc
class _$ValueDetailLoadSuccessCopyWithImpl<$Res>
    implements $ValueDetailLoadSuccessCopyWith<$Res> {
  _$ValueDetailLoadSuccessCopyWithImpl(this._self, this._then);

  final ValueDetailLoadSuccess _self;
  final $Res Function(ValueDetailLoadSuccess) _then;

/// Create a copy of ValueDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = freezed,}) {
  return _then(ValueDetailLoadSuccess(
value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as ValueTableData,
  ));
}


}

// dart format on
