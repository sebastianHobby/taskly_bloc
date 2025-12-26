// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_action.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReviewAction {

 ReviewActionType get type; Map<String, dynamic>? get updateData; String? get notes;
/// Create a copy of ReviewAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewActionCopyWith<ReviewAction> get copyWith => _$ReviewActionCopyWithImpl<ReviewAction>(this as ReviewAction, _$identity);

  /// Serializes this ReviewAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewAction&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.updateData, updateData)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(updateData),notes);

@override
String toString() {
  return 'ReviewAction(type: $type, updateData: $updateData, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $ReviewActionCopyWith<$Res>  {
  factory $ReviewActionCopyWith(ReviewAction value, $Res Function(ReviewAction) _then) = _$ReviewActionCopyWithImpl;
@useResult
$Res call({
 ReviewActionType type, Map<String, dynamic>? updateData, String? notes
});




}
/// @nodoc
class _$ReviewActionCopyWithImpl<$Res>
    implements $ReviewActionCopyWith<$Res> {
  _$ReviewActionCopyWithImpl(this._self, this._then);

  final ReviewAction _self;
  final $Res Function(ReviewAction) _then;

/// Create a copy of ReviewAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? updateData = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ReviewActionType,updateData: freezed == updateData ? _self.updateData : updateData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReviewAction].
extension ReviewActionPatterns on ReviewAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewAction value)  $default,){
final _that = this;
switch (_that) {
case _ReviewAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewAction value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ReviewActionType type,  Map<String, dynamic>? updateData,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewAction() when $default != null:
return $default(_that.type,_that.updateData,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ReviewActionType type,  Map<String, dynamic>? updateData,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _ReviewAction():
return $default(_that.type,_that.updateData,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ReviewActionType type,  Map<String, dynamic>? updateData,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _ReviewAction() when $default != null:
return $default(_that.type,_that.updateData,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReviewAction implements ReviewAction {
  const _ReviewAction({required this.type, final  Map<String, dynamic>? updateData, this.notes}): _updateData = updateData;
  factory _ReviewAction.fromJson(Map<String, dynamic> json) => _$ReviewActionFromJson(json);

@override final  ReviewActionType type;
 final  Map<String, dynamic>? _updateData;
@override Map<String, dynamic>? get updateData {
  final value = _updateData;
  if (value == null) return null;
  if (_updateData is EqualUnmodifiableMapView) return _updateData;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? notes;

/// Create a copy of ReviewAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewActionCopyWith<_ReviewAction> get copyWith => __$ReviewActionCopyWithImpl<_ReviewAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReviewActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewAction&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._updateData, _updateData)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(_updateData),notes);

@override
String toString() {
  return 'ReviewAction(type: $type, updateData: $updateData, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$ReviewActionCopyWith<$Res> implements $ReviewActionCopyWith<$Res> {
  factory _$ReviewActionCopyWith(_ReviewAction value, $Res Function(_ReviewAction) _then) = __$ReviewActionCopyWithImpl;
@override @useResult
$Res call({
 ReviewActionType type, Map<String, dynamic>? updateData, String? notes
});




}
/// @nodoc
class __$ReviewActionCopyWithImpl<$Res>
    implements _$ReviewActionCopyWith<$Res> {
  __$ReviewActionCopyWithImpl(this._self, this._then);

  final _ReviewAction _self;
  final $Res Function(_ReviewAction) _then;

/// Create a copy of ReviewAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? updateData = freezed,Object? notes = freezed,}) {
  return _then(_ReviewAction(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ReviewActionType,updateData: freezed == updateData ? _self._updateData : updateData // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
