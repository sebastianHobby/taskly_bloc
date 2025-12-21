// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'value_list_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ValueOverviewEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValueOverviewEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ValueOverviewEvent()';
}


}

/// @nodoc
class $ValueOverviewEventCopyWith<$Res>  {
$ValueOverviewEventCopyWith(ValueOverviewEvent _, $Res Function(ValueOverviewEvent) __);
}


/// Adds pattern-matching-related methods to [ValueOverviewEvent].
extension ValueOverviewEventPatterns on ValueOverviewEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ValuesSubscriptionRequested value)?  valuesSubscriptionRequested,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ValuesSubscriptionRequested() when valuesSubscriptionRequested != null:
return valuesSubscriptionRequested(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ValuesSubscriptionRequested value)  valuesSubscriptionRequested,}){
final _that = this;
switch (_that) {
case ValuesSubscriptionRequested():
return valuesSubscriptionRequested(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ValuesSubscriptionRequested value)?  valuesSubscriptionRequested,}){
final _that = this;
switch (_that) {
case ValuesSubscriptionRequested() when valuesSubscriptionRequested != null:
return valuesSubscriptionRequested(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  valuesSubscriptionRequested,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ValuesSubscriptionRequested() when valuesSubscriptionRequested != null:
return valuesSubscriptionRequested();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  valuesSubscriptionRequested,}) {final _that = this;
switch (_that) {
case ValuesSubscriptionRequested():
return valuesSubscriptionRequested();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  valuesSubscriptionRequested,}) {final _that = this;
switch (_that) {
case ValuesSubscriptionRequested() when valuesSubscriptionRequested != null:
return valuesSubscriptionRequested();case _:
  return null;

}
}

}

/// @nodoc


class ValuesSubscriptionRequested implements ValueOverviewEvent {
  const ValuesSubscriptionRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValuesSubscriptionRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ValueOverviewEvent.valuesSubscriptionRequested()';
}


}




/// @nodoc
mixin _$ValueOverviewState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValueOverviewState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ValueOverviewState()';
}


}

/// @nodoc
class $ValueOverviewStateCopyWith<$Res>  {
$ValueOverviewStateCopyWith(ValueOverviewState _, $Res Function(ValueOverviewState) __);
}


/// Adds pattern-matching-related methods to [ValueOverviewState].
extension ValueOverviewStatePatterns on ValueOverviewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ValueOverviewInitial value)?  initial,TResult Function( ValueOverviewLoading value)?  loading,TResult Function( ValueOverviewLoaded value)?  loaded,TResult Function( ValueOverviewError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ValueOverviewInitial() when initial != null:
return initial(_that);case ValueOverviewLoading() when loading != null:
return loading(_that);case ValueOverviewLoaded() when loaded != null:
return loaded(_that);case ValueOverviewError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ValueOverviewInitial value)  initial,required TResult Function( ValueOverviewLoading value)  loading,required TResult Function( ValueOverviewLoaded value)  loaded,required TResult Function( ValueOverviewError value)  error,}){
final _that = this;
switch (_that) {
case ValueOverviewInitial():
return initial(_that);case ValueOverviewLoading():
return loading(_that);case ValueOverviewLoaded():
return loaded(_that);case ValueOverviewError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ValueOverviewInitial value)?  initial,TResult? Function( ValueOverviewLoading value)?  loading,TResult? Function( ValueOverviewLoaded value)?  loaded,TResult? Function( ValueOverviewError value)?  error,}){
final _that = this;
switch (_that) {
case ValueOverviewInitial() when initial != null:
return initial(_that);case ValueOverviewLoading() when loading != null:
return loading(_that);case ValueOverviewLoaded() when loaded != null:
return loaded(_that);case ValueOverviewError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<ValueModel> values)?  loaded,TResult Function( Object error)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ValueOverviewInitial() when initial != null:
return initial();case ValueOverviewLoading() when loading != null:
return loading();case ValueOverviewLoaded() when loaded != null:
return loaded(_that.values);case ValueOverviewError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<ValueModel> values)  loaded,required TResult Function( Object error)  error,}) {final _that = this;
switch (_that) {
case ValueOverviewInitial():
return initial();case ValueOverviewLoading():
return loading();case ValueOverviewLoaded():
return loaded(_that.values);case ValueOverviewError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<ValueModel> values)?  loaded,TResult? Function( Object error)?  error,}) {final _that = this;
switch (_that) {
case ValueOverviewInitial() when initial != null:
return initial();case ValueOverviewLoading() when loading != null:
return loading();case ValueOverviewLoaded() when loaded != null:
return loaded(_that.values);case ValueOverviewError() when error != null:
return error(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class ValueOverviewInitial implements ValueOverviewState {
  const ValueOverviewInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValueOverviewInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ValueOverviewState.initial()';
}


}




/// @nodoc


class ValueOverviewLoading implements ValueOverviewState {
  const ValueOverviewLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValueOverviewLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ValueOverviewState.loading()';
}


}




/// @nodoc


class ValueOverviewLoaded implements ValueOverviewState {
  const ValueOverviewLoaded({required final  List<ValueModel> values}): _values = values;
  

 final  List<ValueModel> _values;
 List<ValueModel> get values {
  if (_values is EqualUnmodifiableListView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_values);
}


/// Create a copy of ValueOverviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValueOverviewLoadedCopyWith<ValueOverviewLoaded> get copyWith => _$ValueOverviewLoadedCopyWithImpl<ValueOverviewLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValueOverviewLoaded&&const DeepCollectionEquality().equals(other._values, _values));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_values));

@override
String toString() {
  return 'ValueOverviewState.loaded(values: $values)';
}


}

/// @nodoc
abstract mixin class $ValueOverviewLoadedCopyWith<$Res> implements $ValueOverviewStateCopyWith<$Res> {
  factory $ValueOverviewLoadedCopyWith(ValueOverviewLoaded value, $Res Function(ValueOverviewLoaded) _then) = _$ValueOverviewLoadedCopyWithImpl;
@useResult
$Res call({
 List<ValueModel> values
});




}
/// @nodoc
class _$ValueOverviewLoadedCopyWithImpl<$Res>
    implements $ValueOverviewLoadedCopyWith<$Res> {
  _$ValueOverviewLoadedCopyWithImpl(this._self, this._then);

  final ValueOverviewLoaded _self;
  final $Res Function(ValueOverviewLoaded) _then;

/// Create a copy of ValueOverviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? values = null,}) {
  return _then(ValueOverviewLoaded(
values: null == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as List<ValueModel>,
  ));
}


}

/// @nodoc


class ValueOverviewError implements ValueOverviewState {
  const ValueOverviewError({required this.error});
  

 final  Object error;

/// Create a copy of ValueOverviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ValueOverviewErrorCopyWith<ValueOverviewError> get copyWith => _$ValueOverviewErrorCopyWithImpl<ValueOverviewError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ValueOverviewError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'ValueOverviewState.error(error: $error)';
}


}

/// @nodoc
abstract mixin class $ValueOverviewErrorCopyWith<$Res> implements $ValueOverviewStateCopyWith<$Res> {
  factory $ValueOverviewErrorCopyWith(ValueOverviewError value, $Res Function(ValueOverviewError) _then) = _$ValueOverviewErrorCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$ValueOverviewErrorCopyWithImpl<$Res>
    implements $ValueOverviewErrorCopyWith<$Res> {
  _$ValueOverviewErrorCopyWithImpl(this._self, this._then);

  final ValueOverviewError _self;
  final $Res Function(ValueOverviewError) _then;

/// Create a copy of ValueOverviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(ValueOverviewError(
error: null == error ? _self.error : error ,
  ));
}


}

// dart format on
