// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'screen_definition_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScreenDefinitionEvent {

 String get screenId;
/// Create a copy of ScreenDefinitionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScreenDefinitionEventCopyWith<ScreenDefinitionEvent> get copyWith => _$ScreenDefinitionEventCopyWithImpl<ScreenDefinitionEvent>(this as ScreenDefinitionEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScreenDefinitionEvent&&(identical(other.screenId, screenId) || other.screenId == screenId));
}


@override
int get hashCode => Object.hash(runtimeType,screenId);

@override
String toString() {
  return 'ScreenDefinitionEvent(screenId: $screenId)';
}


}

/// @nodoc
abstract mixin class $ScreenDefinitionEventCopyWith<$Res>  {
  factory $ScreenDefinitionEventCopyWith(ScreenDefinitionEvent value, $Res Function(ScreenDefinitionEvent) _then) = _$ScreenDefinitionEventCopyWithImpl;
@useResult
$Res call({
 String screenId
});




}
/// @nodoc
class _$ScreenDefinitionEventCopyWithImpl<$Res>
    implements $ScreenDefinitionEventCopyWith<$Res> {
  _$ScreenDefinitionEventCopyWithImpl(this._self, this._then);

  final ScreenDefinitionEvent _self;
  final $Res Function(ScreenDefinitionEvent) _then;

/// Create a copy of ScreenDefinitionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? screenId = null,}) {
  return _then(_self.copyWith(
screenId: null == screenId ? _self.screenId : screenId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ScreenDefinitionEvent].
extension ScreenDefinitionEventPatterns on ScreenDefinitionEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _SubscriptionRequested value)?  subscriptionRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _SubscriptionRequested value)  subscriptionRequested,}){
final _that = this;
switch (_that) {
case _SubscriptionRequested():
return subscriptionRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _SubscriptionRequested value)?  subscriptionRequested,}){
final _that = this;
switch (_that) {
case _SubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String screenId)?  subscriptionRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested(_that.screenId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String screenId)  subscriptionRequested,}) {final _that = this;
switch (_that) {
case _SubscriptionRequested():
return subscriptionRequested(_that.screenId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String screenId)?  subscriptionRequested,}) {final _that = this;
switch (_that) {
case _SubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested(_that.screenId);case _:
  return null;

}
}

}

/// @nodoc


class _SubscriptionRequested implements ScreenDefinitionEvent {
  const _SubscriptionRequested({required this.screenId});
  

@override final  String screenId;

/// Create a copy of ScreenDefinitionEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionRequestedCopyWith<_SubscriptionRequested> get copyWith => __$SubscriptionRequestedCopyWithImpl<_SubscriptionRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionRequested&&(identical(other.screenId, screenId) || other.screenId == screenId));
}


@override
int get hashCode => Object.hash(runtimeType,screenId);

@override
String toString() {
  return 'ScreenDefinitionEvent.subscriptionRequested(screenId: $screenId)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionRequestedCopyWith<$Res> implements $ScreenDefinitionEventCopyWith<$Res> {
  factory _$SubscriptionRequestedCopyWith(_SubscriptionRequested value, $Res Function(_SubscriptionRequested) _then) = __$SubscriptionRequestedCopyWithImpl;
@override @useResult
$Res call({
 String screenId
});




}
/// @nodoc
class __$SubscriptionRequestedCopyWithImpl<$Res>
    implements _$SubscriptionRequestedCopyWith<$Res> {
  __$SubscriptionRequestedCopyWithImpl(this._self, this._then);

  final _SubscriptionRequested _self;
  final $Res Function(_SubscriptionRequested) _then;

/// Create a copy of ScreenDefinitionEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? screenId = null,}) {
  return _then(_SubscriptionRequested(
screenId: null == screenId ? _self.screenId : screenId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ScreenDefinitionState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScreenDefinitionState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ScreenDefinitionState()';
}


}

/// @nodoc
class $ScreenDefinitionStateCopyWith<$Res>  {
$ScreenDefinitionStateCopyWith(ScreenDefinitionState _, $Res Function(ScreenDefinitionState) __);
}


/// Adds pattern-matching-related methods to [ScreenDefinitionState].
extension ScreenDefinitionStatePatterns on ScreenDefinitionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Loading value)?  loading,TResult Function( _Loaded value)?  loaded,TResult Function( _NotFound value)?  notFound,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _NotFound() when notFound != null:
return notFound(_that);case _Error() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Loading value)  loading,required TResult Function( _Loaded value)  loaded,required TResult Function( _NotFound value)  notFound,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Loading():
return loading(_that);case _Loaded():
return loaded(_that);case _NotFound():
return notFound(_that);case _Error():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Loading value)?  loading,TResult? Function( _Loaded value)?  loaded,TResult? Function( _NotFound value)?  notFound,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _NotFound() when notFound != null:
return notFound(_that);case _Error() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( ScreenDefinition screen)?  loaded,TResult Function()?  notFound,TResult Function( Object error,  StackTrace stackTrace)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.screen);case _NotFound() when notFound != null:
return notFound();case _Error() when error != null:
return error(_that.error,_that.stackTrace);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( ScreenDefinition screen)  loaded,required TResult Function()  notFound,required TResult Function( Object error,  StackTrace stackTrace)  error,}) {final _that = this;
switch (_that) {
case _Loading():
return loading();case _Loaded():
return loaded(_that.screen);case _NotFound():
return notFound();case _Error():
return error(_that.error,_that.stackTrace);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( ScreenDefinition screen)?  loaded,TResult? Function()?  notFound,TResult? Function( Object error,  StackTrace stackTrace)?  error,}) {final _that = this;
switch (_that) {
case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.screen);case _NotFound() when notFound != null:
return notFound();case _Error() when error != null:
return error(_that.error,_that.stackTrace);case _:
  return null;

}
}

}

/// @nodoc


class _Loading implements ScreenDefinitionState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ScreenDefinitionState.loading()';
}


}




/// @nodoc


class _Loaded implements ScreenDefinitionState {
  const _Loaded({required this.screen});
  

 final  ScreenDefinition screen;

/// Create a copy of ScreenDefinitionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&(identical(other.screen, screen) || other.screen == screen));
}


@override
int get hashCode => Object.hash(runtimeType,screen);

@override
String toString() {
  return 'ScreenDefinitionState.loaded(screen: $screen)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $ScreenDefinitionStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 ScreenDefinition screen
});


$ScreenDefinitionCopyWith<$Res> get screen;

}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of ScreenDefinitionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? screen = null,}) {
  return _then(_Loaded(
screen: null == screen ? _self.screen : screen // ignore: cast_nullable_to_non_nullable
as ScreenDefinition,
  ));
}

/// Create a copy of ScreenDefinitionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScreenDefinitionCopyWith<$Res> get screen {
  
  return $ScreenDefinitionCopyWith<$Res>(_self.screen, (value) {
    return _then(_self.copyWith(screen: value));
  });
}
}

/// @nodoc


class _NotFound implements ScreenDefinitionState {
  const _NotFound();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotFound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ScreenDefinitionState.notFound()';
}


}




/// @nodoc


class _Error implements ScreenDefinitionState {
  const _Error({required this.error, required this.stackTrace});
  

 final  Object error;
 final  StackTrace stackTrace;

/// Create a copy of ScreenDefinitionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stackTrace);

@override
String toString() {
  return 'ScreenDefinitionState.error(error: $error, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $ScreenDefinitionStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace stackTrace
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of ScreenDefinitionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stackTrace = null,}) {
  return _then(_Error(
error: null == error ? _self.error : error ,stackTrace: null == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

// dart format on
