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

 String get id; String get screenKey; String get name; ScreenType get screenType;/// Audit fields
 DateTime get createdAt; DateTime get updatedAt;/// Sections that make up the screen (DR-017)
 List<Section> get sections;/// Support blocks (problem indicators, navigation, etc.)
 List<SupportBlock> get supportBlocks;/// Icon for display in navigation
 String? get iconName;/// Whether this is a system-provided screen
 bool get isSystem;/// Whether the screen is active/visible
 bool get isActive;/// Display order in navigation
 int get sortOrder;/// Screen category
 ScreenCategory get category;/// Screen-level trigger (workflows only)
 TriggerConfig? get triggerConfig;
/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScreenDefinitionCopyWith<ScreenDefinition> get copyWith => _$ScreenDefinitionCopyWithImpl<ScreenDefinition>(this as ScreenDefinition, _$identity);

  /// Serializes this ScreenDefinition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScreenDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.screenKey, screenKey) || other.screenKey == screenKey)&&(identical(other.name, name) || other.name == name)&&(identical(other.screenType, screenType) || other.screenType == screenType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.sections, sections)&&const DeepCollectionEquality().equals(other.supportBlocks, supportBlocks)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.category, category) || other.category == category)&&(identical(other.triggerConfig, triggerConfig) || other.triggerConfig == triggerConfig));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,screenKey,name,screenType,createdAt,updatedAt,const DeepCollectionEquality().hash(sections),const DeepCollectionEquality().hash(supportBlocks),iconName,isSystem,isActive,sortOrder,category,triggerConfig);

@override
String toString() {
  return 'ScreenDefinition(id: $id, screenKey: $screenKey, name: $name, screenType: $screenType, createdAt: $createdAt, updatedAt: $updatedAt, sections: $sections, supportBlocks: $supportBlocks, iconName: $iconName, isSystem: $isSystem, isActive: $isActive, sortOrder: $sortOrder, category: $category, triggerConfig: $triggerConfig)';
}


}

/// @nodoc
abstract mixin class $ScreenDefinitionCopyWith<$Res>  {
  factory $ScreenDefinitionCopyWith(ScreenDefinition value, $Res Function(ScreenDefinition) _then) = _$ScreenDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, String screenKey, String name, ScreenType screenType, DateTime createdAt, DateTime updatedAt, List<Section> sections, List<SupportBlock> supportBlocks, String? iconName, bool isSystem, bool isActive, int sortOrder, ScreenCategory category, TriggerConfig? triggerConfig
});


$TriggerConfigCopyWith<$Res>? get triggerConfig;

}
/// @nodoc
class _$ScreenDefinitionCopyWithImpl<$Res>
    implements $ScreenDefinitionCopyWith<$Res> {
  _$ScreenDefinitionCopyWithImpl(this._self, this._then);

  final ScreenDefinition _self;
  final $Res Function(ScreenDefinition) _then;

/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? screenKey = null,Object? name = null,Object? screenType = null,Object? createdAt = null,Object? updatedAt = null,Object? sections = null,Object? supportBlocks = null,Object? iconName = freezed,Object? isSystem = null,Object? isActive = null,Object? sortOrder = null,Object? category = null,Object? triggerConfig = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,screenKey: null == screenKey ? _self.screenKey : screenKey // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,screenType: null == screenType ? _self.screenType : screenType // ignore: cast_nullable_to_non_nullable
as ScreenType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<Section>,supportBlocks: null == supportBlocks ? _self.supportBlocks : supportBlocks // ignore: cast_nullable_to_non_nullable
as List<SupportBlock>,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ScreenCategory,triggerConfig: freezed == triggerConfig ? _self.triggerConfig : triggerConfig // ignore: cast_nullable_to_non_nullable
as TriggerConfig?,
  ));
}
/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TriggerConfigCopyWith<$Res>? get triggerConfig {
    if (_self.triggerConfig == null) {
    return null;
  }

  return $TriggerConfigCopyWith<$Res>(_self.triggerConfig!, (value) {
    return _then(_self.copyWith(triggerConfig: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String screenKey,  String name,  ScreenType screenType,  DateTime createdAt,  DateTime updatedAt,  List<Section> sections,  List<SupportBlock> supportBlocks,  String? iconName,  bool isSystem,  bool isActive,  int sortOrder,  ScreenCategory category,  TriggerConfig? triggerConfig)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScreenDefinition() when $default != null:
return $default(_that.id,_that.screenKey,_that.name,_that.screenType,_that.createdAt,_that.updatedAt,_that.sections,_that.supportBlocks,_that.iconName,_that.isSystem,_that.isActive,_that.sortOrder,_that.category,_that.triggerConfig);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String screenKey,  String name,  ScreenType screenType,  DateTime createdAt,  DateTime updatedAt,  List<Section> sections,  List<SupportBlock> supportBlocks,  String? iconName,  bool isSystem,  bool isActive,  int sortOrder,  ScreenCategory category,  TriggerConfig? triggerConfig)  $default,) {final _that = this;
switch (_that) {
case _ScreenDefinition():
return $default(_that.id,_that.screenKey,_that.name,_that.screenType,_that.createdAt,_that.updatedAt,_that.sections,_that.supportBlocks,_that.iconName,_that.isSystem,_that.isActive,_that.sortOrder,_that.category,_that.triggerConfig);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String screenKey,  String name,  ScreenType screenType,  DateTime createdAt,  DateTime updatedAt,  List<Section> sections,  List<SupportBlock> supportBlocks,  String? iconName,  bool isSystem,  bool isActive,  int sortOrder,  ScreenCategory category,  TriggerConfig? triggerConfig)?  $default,) {final _that = this;
switch (_that) {
case _ScreenDefinition() when $default != null:
return $default(_that.id,_that.screenKey,_that.name,_that.screenType,_that.createdAt,_that.updatedAt,_that.sections,_that.supportBlocks,_that.iconName,_that.isSystem,_that.isActive,_that.sortOrder,_that.category,_that.triggerConfig);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScreenDefinition implements ScreenDefinition {
  const _ScreenDefinition({required this.id, required this.screenKey, required this.name, required this.screenType, required this.createdAt, required this.updatedAt, final  List<Section> sections = const [], final  List<SupportBlock> supportBlocks = const [], this.iconName, this.isSystem = false, this.isActive = true, this.sortOrder = 0, this.category = ScreenCategory.workspace, this.triggerConfig}): _sections = sections,_supportBlocks = supportBlocks;
  factory _ScreenDefinition.fromJson(Map<String, dynamic> json) => _$ScreenDefinitionFromJson(json);

@override final  String id;
@override final  String screenKey;
@override final  String name;
@override final  ScreenType screenType;
/// Audit fields
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
/// Sections that make up the screen (DR-017)
 final  List<Section> _sections;
/// Sections that make up the screen (DR-017)
@override@JsonKey() List<Section> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

/// Support blocks (problem indicators, navigation, etc.)
 final  List<SupportBlock> _supportBlocks;
/// Support blocks (problem indicators, navigation, etc.)
@override@JsonKey() List<SupportBlock> get supportBlocks {
  if (_supportBlocks is EqualUnmodifiableListView) return _supportBlocks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_supportBlocks);
}

/// Icon for display in navigation
@override final  String? iconName;
/// Whether this is a system-provided screen
@override@JsonKey() final  bool isSystem;
/// Whether the screen is active/visible
@override@JsonKey() final  bool isActive;
/// Display order in navigation
@override@JsonKey() final  int sortOrder;
/// Screen category
@override@JsonKey() final  ScreenCategory category;
/// Screen-level trigger (workflows only)
@override final  TriggerConfig? triggerConfig;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScreenDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.screenKey, screenKey) || other.screenKey == screenKey)&&(identical(other.name, name) || other.name == name)&&(identical(other.screenType, screenType) || other.screenType == screenType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._sections, _sections)&&const DeepCollectionEquality().equals(other._supportBlocks, _supportBlocks)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.category, category) || other.category == category)&&(identical(other.triggerConfig, triggerConfig) || other.triggerConfig == triggerConfig));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,screenKey,name,screenType,createdAt,updatedAt,const DeepCollectionEquality().hash(_sections),const DeepCollectionEquality().hash(_supportBlocks),iconName,isSystem,isActive,sortOrder,category,triggerConfig);

@override
String toString() {
  return 'ScreenDefinition(id: $id, screenKey: $screenKey, name: $name, screenType: $screenType, createdAt: $createdAt, updatedAt: $updatedAt, sections: $sections, supportBlocks: $supportBlocks, iconName: $iconName, isSystem: $isSystem, isActive: $isActive, sortOrder: $sortOrder, category: $category, triggerConfig: $triggerConfig)';
}


}

/// @nodoc
abstract mixin class _$ScreenDefinitionCopyWith<$Res> implements $ScreenDefinitionCopyWith<$Res> {
  factory _$ScreenDefinitionCopyWith(_ScreenDefinition value, $Res Function(_ScreenDefinition) _then) = __$ScreenDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String screenKey, String name, ScreenType screenType, DateTime createdAt, DateTime updatedAt, List<Section> sections, List<SupportBlock> supportBlocks, String? iconName, bool isSystem, bool isActive, int sortOrder, ScreenCategory category, TriggerConfig? triggerConfig
});


@override $TriggerConfigCopyWith<$Res>? get triggerConfig;

}
/// @nodoc
class __$ScreenDefinitionCopyWithImpl<$Res>
    implements _$ScreenDefinitionCopyWith<$Res> {
  __$ScreenDefinitionCopyWithImpl(this._self, this._then);

  final _ScreenDefinition _self;
  final $Res Function(_ScreenDefinition) _then;

/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? screenKey = null,Object? name = null,Object? screenType = null,Object? createdAt = null,Object? updatedAt = null,Object? sections = null,Object? supportBlocks = null,Object? iconName = freezed,Object? isSystem = null,Object? isActive = null,Object? sortOrder = null,Object? category = null,Object? triggerConfig = freezed,}) {
  return _then(_ScreenDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,screenKey: null == screenKey ? _self.screenKey : screenKey // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,screenType: null == screenType ? _self.screenType : screenType // ignore: cast_nullable_to_non_nullable
as ScreenType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<Section>,supportBlocks: null == supportBlocks ? _self._supportBlocks : supportBlocks // ignore: cast_nullable_to_non_nullable
as List<SupportBlock>,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ScreenCategory,triggerConfig: freezed == triggerConfig ? _self.triggerConfig : triggerConfig // ignore: cast_nullable_to_non_nullable
as TriggerConfig?,
  ));
}

/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TriggerConfigCopyWith<$Res>? get triggerConfig {
    if (_self.triggerConfig == null) {
    return null;
  }

  return $TriggerConfigCopyWith<$Res>(_self.triggerConfig!, (value) {
    return _then(_self.copyWith(triggerConfig: value));
  });
}
}

// dart format on
