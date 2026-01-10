// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'screen_definition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScreenDefinition {

 String get id; String get screenKey; String get name;/// Audit fields
 DateTime get createdAt; DateTime get updatedAt;/// Sections that make up the screen.
 List<SectionRef> get sections;/// Optional screen-level gate. When active, the screen renders only the
/// gate's full-screen section instead of [sections].
 ScreenGateConfig? get gate;/// Source of this screen definition (system template vs user-defined)
 ScreenSource get screenSource;/// UI chrome configuration (icon, badges, app bar actions, FAB, etc.).
 ScreenChrome get chrome;
/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScreenDefinitionCopyWith<ScreenDefinition> get copyWith => _$ScreenDefinitionCopyWithImpl<ScreenDefinition>(this as ScreenDefinition, _$identity);

  /// Serializes this ScreenDefinition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScreenDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.screenKey, screenKey) || other.screenKey == screenKey)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.sections, sections)&&(identical(other.gate, gate) || other.gate == gate)&&(identical(other.screenSource, screenSource) || other.screenSource == screenSource)&&(identical(other.chrome, chrome) || other.chrome == chrome));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,screenKey,name,createdAt,updatedAt,const DeepCollectionEquality().hash(sections),gate,screenSource,chrome);

@override
String toString() {
  return 'ScreenDefinition(id: $id, screenKey: $screenKey, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, sections: $sections, gate: $gate, screenSource: $screenSource, chrome: $chrome)';
}


}

/// @nodoc
abstract mixin class $ScreenDefinitionCopyWith<$Res>  {
  factory $ScreenDefinitionCopyWith(ScreenDefinition value, $Res Function(ScreenDefinition) _then) = _$ScreenDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, String screenKey, String name, DateTime createdAt, DateTime updatedAt, List<SectionRef> sections, ScreenGateConfig? gate, ScreenSource screenSource, ScreenChrome chrome
});


$ScreenGateConfigCopyWith<$Res>? get gate;$ScreenChromeCopyWith<$Res> get chrome;

}
/// @nodoc
class _$ScreenDefinitionCopyWithImpl<$Res>
    implements $ScreenDefinitionCopyWith<$Res> {
  _$ScreenDefinitionCopyWithImpl(this._self, this._then);

  final ScreenDefinition _self;
  final $Res Function(ScreenDefinition) _then;

/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? screenKey = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? sections = null,Object? gate = freezed,Object? screenSource = null,Object? chrome = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,screenKey: null == screenKey ? _self.screenKey : screenKey // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<SectionRef>,gate: freezed == gate ? _self.gate : gate // ignore: cast_nullable_to_non_nullable
as ScreenGateConfig?,screenSource: null == screenSource ? _self.screenSource : screenSource // ignore: cast_nullable_to_non_nullable
as ScreenSource,chrome: null == chrome ? _self.chrome : chrome // ignore: cast_nullable_to_non_nullable
as ScreenChrome,
  ));
}
/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScreenGateConfigCopyWith<$Res>? get gate {
    if (_self.gate == null) {
    return null;
  }

  return $ScreenGateConfigCopyWith<$Res>(_self.gate!, (value) {
    return _then(_self.copyWith(gate: value));
  });
}/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScreenChromeCopyWith<$Res> get chrome {
  
  return $ScreenChromeCopyWith<$Res>(_self.chrome, (value) {
    return _then(_self.copyWith(chrome: value));
  });
}
}


/// Adds pattern-matching-related methods to [ScreenDefinition].
extension ScreenDefinitionPatterns on ScreenDefinition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScreenDefinition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScreenDefinition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScreenDefinition value)  $default,){
final _that = this;
switch (_that) {
case _ScreenDefinition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScreenDefinition value)?  $default,){
final _that = this;
switch (_that) {
case _ScreenDefinition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String screenKey,  String name,  DateTime createdAt,  DateTime updatedAt,  List<SectionRef> sections,  ScreenGateConfig? gate,  ScreenSource screenSource,  ScreenChrome chrome)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScreenDefinition() when $default != null:
return $default(_that.id,_that.screenKey,_that.name,_that.createdAt,_that.updatedAt,_that.sections,_that.gate,_that.screenSource,_that.chrome);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String screenKey,  String name,  DateTime createdAt,  DateTime updatedAt,  List<SectionRef> sections,  ScreenGateConfig? gate,  ScreenSource screenSource,  ScreenChrome chrome)  $default,) {final _that = this;
switch (_that) {
case _ScreenDefinition():
return $default(_that.id,_that.screenKey,_that.name,_that.createdAt,_that.updatedAt,_that.sections,_that.gate,_that.screenSource,_that.chrome);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String screenKey,  String name,  DateTime createdAt,  DateTime updatedAt,  List<SectionRef> sections,  ScreenGateConfig? gate,  ScreenSource screenSource,  ScreenChrome chrome)?  $default,) {final _that = this;
switch (_that) {
case _ScreenDefinition() when $default != null:
return $default(_that.id,_that.screenKey,_that.name,_that.createdAt,_that.updatedAt,_that.sections,_that.gate,_that.screenSource,_that.chrome);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScreenDefinition extends ScreenDefinition {
  const _ScreenDefinition({required this.id, required this.screenKey, required this.name, required this.createdAt, required this.updatedAt, final  List<SectionRef> sections = const <SectionRef>[], this.gate, this.screenSource = ScreenSource.userDefined, this.chrome = ScreenChrome.empty}): _sections = sections,super._();
  factory _ScreenDefinition.fromJson(Map<String, dynamic> json) => _$ScreenDefinitionFromJson(json);

@override final  String id;
@override final  String screenKey;
@override final  String name;
/// Audit fields
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
/// Sections that make up the screen.
 final  List<SectionRef> _sections;
/// Sections that make up the screen.
@override@JsonKey() List<SectionRef> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

/// Optional screen-level gate. When active, the screen renders only the
/// gate's full-screen section instead of [sections].
@override final  ScreenGateConfig? gate;
/// Source of this screen definition (system template vs user-defined)
@override@JsonKey() final  ScreenSource screenSource;
/// UI chrome configuration (icon, badges, app bar actions, FAB, etc.).
@override@JsonKey() final  ScreenChrome chrome;

/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScreenDefinitionCopyWith<_ScreenDefinition> get copyWith => __$ScreenDefinitionCopyWithImpl<_ScreenDefinition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScreenDefinitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScreenDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.screenKey, screenKey) || other.screenKey == screenKey)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._sections, _sections)&&(identical(other.gate, gate) || other.gate == gate)&&(identical(other.screenSource, screenSource) || other.screenSource == screenSource)&&(identical(other.chrome, chrome) || other.chrome == chrome));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,screenKey,name,createdAt,updatedAt,const DeepCollectionEquality().hash(_sections),gate,screenSource,chrome);

@override
String toString() {
  return 'ScreenDefinition(id: $id, screenKey: $screenKey, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, sections: $sections, gate: $gate, screenSource: $screenSource, chrome: $chrome)';
}


}

/// @nodoc
abstract mixin class _$ScreenDefinitionCopyWith<$Res> implements $ScreenDefinitionCopyWith<$Res> {
  factory _$ScreenDefinitionCopyWith(_ScreenDefinition value, $Res Function(_ScreenDefinition) _then) = __$ScreenDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String screenKey, String name, DateTime createdAt, DateTime updatedAt, List<SectionRef> sections, ScreenGateConfig? gate, ScreenSource screenSource, ScreenChrome chrome
});


@override $ScreenGateConfigCopyWith<$Res>? get gate;@override $ScreenChromeCopyWith<$Res> get chrome;

}
/// @nodoc
class __$ScreenDefinitionCopyWithImpl<$Res>
    implements _$ScreenDefinitionCopyWith<$Res> {
  __$ScreenDefinitionCopyWithImpl(this._self, this._then);

  final _ScreenDefinition _self;
  final $Res Function(_ScreenDefinition) _then;

/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? screenKey = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? sections = null,Object? gate = freezed,Object? screenSource = null,Object? chrome = null,}) {
  return _then(_ScreenDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,screenKey: null == screenKey ? _self.screenKey : screenKey // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<SectionRef>,gate: freezed == gate ? _self.gate : gate // ignore: cast_nullable_to_non_nullable
as ScreenGateConfig?,screenSource: null == screenSource ? _self.screenSource : screenSource // ignore: cast_nullable_to_non_nullable
as ScreenSource,chrome: null == chrome ? _self.chrome : chrome // ignore: cast_nullable_to_non_nullable
as ScreenChrome,
  ));
}

/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScreenGateConfigCopyWith<$Res>? get gate {
    if (_self.gate == null) {
    return null;
  }

  return $ScreenGateConfigCopyWith<$Res>(_self.gate!, (value) {
    return _then(_self.copyWith(gate: value));
  });
}/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ScreenChromeCopyWith<$Res> get chrome {
  
  return $ScreenChromeCopyWith<$Res>(_self.chrome, (value) {
    return _then(_self.copyWith(chrome: value));
  });
}
}

// dart format on
