// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tracker_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrackerResponse {

 String get id; String get journalEntryId; String get trackerId; TrackerResponseValue get value; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of TrackerResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackerResponseCopyWith<TrackerResponse> get copyWith => _$TrackerResponseCopyWithImpl<TrackerResponse>(this as TrackerResponse, _$identity);

  /// Serializes this TrackerResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackerResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.journalEntryId, journalEntryId) || other.journalEntryId == journalEntryId)&&(identical(other.trackerId, trackerId) || other.trackerId == trackerId)&&(identical(other.value, value) || other.value == value)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,journalEntryId,trackerId,value,createdAt,updatedAt);

@override
String toString() {
  return 'TrackerResponse(id: $id, journalEntryId: $journalEntryId, trackerId: $trackerId, value: $value, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TrackerResponseCopyWith<$Res>  {
  factory $TrackerResponseCopyWith(TrackerResponse value, $Res Function(TrackerResponse) _then) = _$TrackerResponseCopyWithImpl;
@useResult
$Res call({
 String id, String journalEntryId, String trackerId, TrackerResponseValue value, DateTime createdAt, DateTime updatedAt
});


$TrackerResponseValueCopyWith<$Res> get value;

}
/// @nodoc
class _$TrackerResponseCopyWithImpl<$Res>
    implements $TrackerResponseCopyWith<$Res> {
  _$TrackerResponseCopyWithImpl(this._self, this._then);

  final TrackerResponse _self;
  final $Res Function(TrackerResponse) _then;

/// Create a copy of TrackerResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? journalEntryId = null,Object? trackerId = null,Object? value = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,journalEntryId: null == journalEntryId ? _self.journalEntryId : journalEntryId // ignore: cast_nullable_to_non_nullable
as String,trackerId: null == trackerId ? _self.trackerId : trackerId // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TrackerResponseValue,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of TrackerResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackerResponseValueCopyWith<$Res> get value {
  
  return $TrackerResponseValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}


/// Adds pattern-matching-related methods to [TrackerResponse].
extension TrackerResponsePatterns on TrackerResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackerResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackerResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackerResponse value)  $default,){
final _that = this;
switch (_that) {
case _TrackerResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackerResponse value)?  $default,){
final _that = this;
switch (_that) {
case _TrackerResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String journalEntryId,  String trackerId,  TrackerResponseValue value,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackerResponse() when $default != null:
return $default(_that.id,_that.journalEntryId,_that.trackerId,_that.value,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String journalEntryId,  String trackerId,  TrackerResponseValue value,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TrackerResponse():
return $default(_that.id,_that.journalEntryId,_that.trackerId,_that.value,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String journalEntryId,  String trackerId,  TrackerResponseValue value,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TrackerResponse() when $default != null:
return $default(_that.id,_that.journalEntryId,_that.trackerId,_that.value,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrackerResponse implements TrackerResponse {
  const _TrackerResponse({required this.id, required this.journalEntryId, required this.trackerId, required this.value, required this.createdAt, required this.updatedAt});
  factory _TrackerResponse.fromJson(Map<String, dynamic> json) => _$TrackerResponseFromJson(json);

@override final  String id;
@override final  String journalEntryId;
@override final  String trackerId;
@override final  TrackerResponseValue value;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of TrackerResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackerResponseCopyWith<_TrackerResponse> get copyWith => __$TrackerResponseCopyWithImpl<_TrackerResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackerResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackerResponse&&(identical(other.id, id) || other.id == id)&&(identical(other.journalEntryId, journalEntryId) || other.journalEntryId == journalEntryId)&&(identical(other.trackerId, trackerId) || other.trackerId == trackerId)&&(identical(other.value, value) || other.value == value)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,journalEntryId,trackerId,value,createdAt,updatedAt);

@override
String toString() {
  return 'TrackerResponse(id: $id, journalEntryId: $journalEntryId, trackerId: $trackerId, value: $value, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TrackerResponseCopyWith<$Res> implements $TrackerResponseCopyWith<$Res> {
  factory _$TrackerResponseCopyWith(_TrackerResponse value, $Res Function(_TrackerResponse) _then) = __$TrackerResponseCopyWithImpl;
@override @useResult
$Res call({
 String id, String journalEntryId, String trackerId, TrackerResponseValue value, DateTime createdAt, DateTime updatedAt
});


@override $TrackerResponseValueCopyWith<$Res> get value;

}
/// @nodoc
class __$TrackerResponseCopyWithImpl<$Res>
    implements _$TrackerResponseCopyWith<$Res> {
  __$TrackerResponseCopyWithImpl(this._self, this._then);

  final _TrackerResponse _self;
  final $Res Function(_TrackerResponse) _then;

/// Create a copy of TrackerResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? journalEntryId = null,Object? trackerId = null,Object? value = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_TrackerResponse(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,journalEntryId: null == journalEntryId ? _self.journalEntryId : journalEntryId // ignore: cast_nullable_to_non_nullable
as String,trackerId: null == trackerId ? _self.trackerId : trackerId // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as TrackerResponseValue,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of TrackerResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackerResponseValueCopyWith<$Res> get value {
  
  return $TrackerResponseValueCopyWith<$Res>(_self.value, (value) {
    return _then(_self.copyWith(value: value));
  });
}
}

TrackerResponseValue _$TrackerResponseValueFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'choice':
          return ChoiceValue.fromJson(
            json
          );
                case 'scale':
          return ScaleValue.fromJson(
            json
          );
                case 'yesNo':
          return YesNoValue.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'TrackerResponseValue',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$TrackerResponseValue {



  /// Serializes this TrackerResponseValue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackerResponseValue);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TrackerResponseValue()';
}


}

/// @nodoc
class $TrackerResponseValueCopyWith<$Res>  {
$TrackerResponseValueCopyWith(TrackerResponseValue _, $Res Function(TrackerResponseValue) __);
}


/// Adds pattern-matching-related methods to [TrackerResponseValue].
extension TrackerResponseValuePatterns on TrackerResponseValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChoiceValue value)?  choice,TResult Function( ScaleValue value)?  scale,TResult Function( YesNoValue value)?  yesNo,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChoiceValue() when choice != null:
return choice(_that);case ScaleValue() when scale != null:
return scale(_that);case YesNoValue() when yesNo != null:
return yesNo(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChoiceValue value)  choice,required TResult Function( ScaleValue value)  scale,required TResult Function( YesNoValue value)  yesNo,}){
final _that = this;
switch (_that) {
case ChoiceValue():
return choice(_that);case ScaleValue():
return scale(_that);case YesNoValue():
return yesNo(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChoiceValue value)?  choice,TResult? Function( ScaleValue value)?  scale,TResult? Function( YesNoValue value)?  yesNo,}){
final _that = this;
switch (_that) {
case ChoiceValue() when choice != null:
return choice(_that);case ScaleValue() when scale != null:
return scale(_that);case YesNoValue() when yesNo != null:
return yesNo(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String selected)?  choice,TResult Function( int value)?  scale,TResult Function( bool value)?  yesNo,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChoiceValue() when choice != null:
return choice(_that.selected);case ScaleValue() when scale != null:
return scale(_that.value);case YesNoValue() when yesNo != null:
return yesNo(_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String selected)  choice,required TResult Function( int value)  scale,required TResult Function( bool value)  yesNo,}) {final _that = this;
switch (_that) {
case ChoiceValue():
return choice(_that.selected);case ScaleValue():
return scale(_that.value);case YesNoValue():
return yesNo(_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String selected)?  choice,TResult? Function( int value)?  scale,TResult? Function( bool value)?  yesNo,}) {final _that = this;
switch (_that) {
case ChoiceValue() when choice != null:
return choice(_that.selected);case ScaleValue() when scale != null:
return scale(_that.value);case YesNoValue() when yesNo != null:
return yesNo(_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class ChoiceValue implements TrackerResponseValue {
  const ChoiceValue({required this.selected, final  String? $type}): $type = $type ?? 'choice';
  factory ChoiceValue.fromJson(Map<String, dynamic> json) => _$ChoiceValueFromJson(json);

 final  String selected;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of TrackerResponseValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChoiceValueCopyWith<ChoiceValue> get copyWith => _$ChoiceValueCopyWithImpl<ChoiceValue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChoiceValueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChoiceValue&&(identical(other.selected, selected) || other.selected == selected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,selected);

@override
String toString() {
  return 'TrackerResponseValue.choice(selected: $selected)';
}


}

/// @nodoc
abstract mixin class $ChoiceValueCopyWith<$Res> implements $TrackerResponseValueCopyWith<$Res> {
  factory $ChoiceValueCopyWith(ChoiceValue value, $Res Function(ChoiceValue) _then) = _$ChoiceValueCopyWithImpl;
@useResult
$Res call({
 String selected
});




}
/// @nodoc
class _$ChoiceValueCopyWithImpl<$Res>
    implements $ChoiceValueCopyWith<$Res> {
  _$ChoiceValueCopyWithImpl(this._self, this._then);

  final ChoiceValue _self;
  final $Res Function(ChoiceValue) _then;

/// Create a copy of TrackerResponseValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? selected = null,}) {
  return _then(ChoiceValue(
selected: null == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ScaleValue implements TrackerResponseValue {
  const ScaleValue({required this.value, final  String? $type}): $type = $type ?? 'scale';
  factory ScaleValue.fromJson(Map<String, dynamic> json) => _$ScaleValueFromJson(json);

 final  int value;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of TrackerResponseValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScaleValueCopyWith<ScaleValue> get copyWith => _$ScaleValueCopyWithImpl<ScaleValue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScaleValueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScaleValue&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'TrackerResponseValue.scale(value: $value)';
}


}

/// @nodoc
abstract mixin class $ScaleValueCopyWith<$Res> implements $TrackerResponseValueCopyWith<$Res> {
  factory $ScaleValueCopyWith(ScaleValue value, $Res Function(ScaleValue) _then) = _$ScaleValueCopyWithImpl;
@useResult
$Res call({
 int value
});




}
/// @nodoc
class _$ScaleValueCopyWithImpl<$Res>
    implements $ScaleValueCopyWith<$Res> {
  _$ScaleValueCopyWithImpl(this._self, this._then);

  final ScaleValue _self;
  final $Res Function(ScaleValue) _then;

/// Create a copy of TrackerResponseValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(ScaleValue(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class YesNoValue implements TrackerResponseValue {
  const YesNoValue({required this.value, final  String? $type}): $type = $type ?? 'yesNo';
  factory YesNoValue.fromJson(Map<String, dynamic> json) => _$YesNoValueFromJson(json);

 final  bool value;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of TrackerResponseValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YesNoValueCopyWith<YesNoValue> get copyWith => _$YesNoValueCopyWithImpl<YesNoValue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$YesNoValueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YesNoValue&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'TrackerResponseValue.yesNo(value: $value)';
}


}

/// @nodoc
abstract mixin class $YesNoValueCopyWith<$Res> implements $TrackerResponseValueCopyWith<$Res> {
  factory $YesNoValueCopyWith(YesNoValue value, $Res Function(YesNoValue) _then) = _$YesNoValueCopyWithImpl;
@useResult
$Res call({
 bool value
});




}
/// @nodoc
class _$YesNoValueCopyWithImpl<$Res>
    implements $YesNoValueCopyWith<$Res> {
  _$YesNoValueCopyWithImpl(this._self, this._then);

  final YesNoValue _self;
  final $Res Function(YesNoValue) _then;

/// Create a copy of TrackerResponseValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(YesNoValue(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
