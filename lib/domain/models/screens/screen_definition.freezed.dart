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
 DateTime get createdAt; DateTime get updatedAt;/// Icon for display in navigation
 String? get iconName;/// Source of this screen definition (system template vs user-defined)
 ScreenSource get screenSource;/// Screen category
 ScreenCategory get category;
/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScreenDefinitionCopyWith<ScreenDefinition> get copyWith => _$ScreenDefinitionCopyWithImpl<ScreenDefinition>(this as ScreenDefinition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScreenDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.screenKey, screenKey) || other.screenKey == screenKey)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.screenSource, screenSource) || other.screenSource == screenSource)&&(identical(other.category, category) || other.category == category));
}


@override
int get hashCode => Object.hash(runtimeType,id,screenKey,name,createdAt,updatedAt,iconName,screenSource,category);

@override
String toString() {
  return 'ScreenDefinition(id: $id, screenKey: $screenKey, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, iconName: $iconName, screenSource: $screenSource, category: $category)';
}


}

/// @nodoc
abstract mixin class $ScreenDefinitionCopyWith<$Res>  {
  factory $ScreenDefinitionCopyWith(ScreenDefinition value, $Res Function(ScreenDefinition) _then) = _$ScreenDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, String screenKey, String name, DateTime createdAt, DateTime updatedAt, String? iconName, ScreenSource screenSource, ScreenCategory category
});




}
/// @nodoc
class _$ScreenDefinitionCopyWithImpl<$Res>
    implements $ScreenDefinitionCopyWith<$Res> {
  _$ScreenDefinitionCopyWithImpl(this._self, this._then);

  final ScreenDefinition _self;
  final $Res Function(ScreenDefinition) _then;

/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? screenKey = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? iconName = freezed,Object? screenSource = null,Object? category = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,screenKey: null == screenKey ? _self.screenKey : screenKey // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,screenSource: null == screenSource ? _self.screenSource : screenSource // ignore: cast_nullable_to_non_nullable
as ScreenSource,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ScreenCategory,
  ));
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DataDrivenScreenDefinition value)?  dataDriven,TResult Function( NavigationOnlyScreenDefinition value)?  navigationOnly,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DataDrivenScreenDefinition() when dataDriven != null:
return dataDriven(_that);case NavigationOnlyScreenDefinition() when navigationOnly != null:
return navigationOnly(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DataDrivenScreenDefinition value)  dataDriven,required TResult Function( NavigationOnlyScreenDefinition value)  navigationOnly,}){
final _that = this;
switch (_that) {
case DataDrivenScreenDefinition():
return dataDriven(_that);case NavigationOnlyScreenDefinition():
return navigationOnly(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DataDrivenScreenDefinition value)?  dataDriven,TResult? Function( NavigationOnlyScreenDefinition value)?  navigationOnly,}){
final _that = this;
switch (_that) {
case DataDrivenScreenDefinition() when dataDriven != null:
return dataDriven(_that);case NavigationOnlyScreenDefinition() when navigationOnly != null:
return navigationOnly(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String screenKey,  String name,  ScreenType screenType,  DateTime createdAt,  DateTime updatedAt,  List<Section> sections,  List<SupportBlock> supportBlocks,  String? iconName,  ScreenSource screenSource,  ScreenCategory category,  TriggerConfig? triggerConfig,  List<FabOperation> fabOperations,  List<AppBarAction> appBarActions,  String? settingsRoute)?  dataDriven,TResult Function( String id,  String screenKey,  String name,  DateTime createdAt,  DateTime updatedAt,  String? iconName,  ScreenSource screenSource,  ScreenCategory category)?  navigationOnly,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DataDrivenScreenDefinition() when dataDriven != null:
return dataDriven(_that.id,_that.screenKey,_that.name,_that.screenType,_that.createdAt,_that.updatedAt,_that.sections,_that.supportBlocks,_that.iconName,_that.screenSource,_that.category,_that.triggerConfig,_that.fabOperations,_that.appBarActions,_that.settingsRoute);case NavigationOnlyScreenDefinition() when navigationOnly != null:
return navigationOnly(_that.id,_that.screenKey,_that.name,_that.createdAt,_that.updatedAt,_that.iconName,_that.screenSource,_that.category);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String screenKey,  String name,  ScreenType screenType,  DateTime createdAt,  DateTime updatedAt,  List<Section> sections,  List<SupportBlock> supportBlocks,  String? iconName,  ScreenSource screenSource,  ScreenCategory category,  TriggerConfig? triggerConfig,  List<FabOperation> fabOperations,  List<AppBarAction> appBarActions,  String? settingsRoute)  dataDriven,required TResult Function( String id,  String screenKey,  String name,  DateTime createdAt,  DateTime updatedAt,  String? iconName,  ScreenSource screenSource,  ScreenCategory category)  navigationOnly,}) {final _that = this;
switch (_that) {
case DataDrivenScreenDefinition():
return dataDriven(_that.id,_that.screenKey,_that.name,_that.screenType,_that.createdAt,_that.updatedAt,_that.sections,_that.supportBlocks,_that.iconName,_that.screenSource,_that.category,_that.triggerConfig,_that.fabOperations,_that.appBarActions,_that.settingsRoute);case NavigationOnlyScreenDefinition():
return navigationOnly(_that.id,_that.screenKey,_that.name,_that.createdAt,_that.updatedAt,_that.iconName,_that.screenSource,_that.category);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String screenKey,  String name,  ScreenType screenType,  DateTime createdAt,  DateTime updatedAt,  List<Section> sections,  List<SupportBlock> supportBlocks,  String? iconName,  ScreenSource screenSource,  ScreenCategory category,  TriggerConfig? triggerConfig,  List<FabOperation> fabOperations,  List<AppBarAction> appBarActions,  String? settingsRoute)?  dataDriven,TResult? Function( String id,  String screenKey,  String name,  DateTime createdAt,  DateTime updatedAt,  String? iconName,  ScreenSource screenSource,  ScreenCategory category)?  navigationOnly,}) {final _that = this;
switch (_that) {
case DataDrivenScreenDefinition() when dataDriven != null:
return dataDriven(_that.id,_that.screenKey,_that.name,_that.screenType,_that.createdAt,_that.updatedAt,_that.sections,_that.supportBlocks,_that.iconName,_that.screenSource,_that.category,_that.triggerConfig,_that.fabOperations,_that.appBarActions,_that.settingsRoute);case NavigationOnlyScreenDefinition() when navigationOnly != null:
return navigationOnly(_that.id,_that.screenKey,_that.name,_that.createdAt,_that.updatedAt,_that.iconName,_that.screenSource,_that.category);case _:
  return null;

}
}

}

/// @nodoc


class DataDrivenScreenDefinition extends ScreenDefinition {
  const DataDrivenScreenDefinition({required this.id, required this.screenKey, required this.name, required this.screenType, required this.createdAt, required this.updatedAt, final  List<Section> sections = const [], final  List<SupportBlock> supportBlocks = const [], this.iconName, this.screenSource = ScreenSource.userDefined, this.category = ScreenCategory.workspace, this.triggerConfig, final  List<FabOperation> fabOperations = const [], final  List<AppBarAction> appBarActions = const [], this.settingsRoute}): _sections = sections,_supportBlocks = supportBlocks,_fabOperations = fabOperations,_appBarActions = appBarActions,super._();
  

@override final  String id;
@override final  String screenKey;
@override final  String name;
 final  ScreenType screenType;
/// Audit fields
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
/// Sections that make up the screen (DR-017)
 final  List<Section> _sections;
/// Sections that make up the screen (DR-017)
@JsonKey() List<Section> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

/// Support blocks (problem indicators, navigation, etc.)
 final  List<SupportBlock> _supportBlocks;
/// Support blocks (problem indicators, navigation, etc.)
@JsonKey() List<SupportBlock> get supportBlocks {
  if (_supportBlocks is EqualUnmodifiableListView) return _supportBlocks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_supportBlocks);
}

/// Icon for display in navigation
@override final  String? iconName;
/// Source of this screen definition (system template vs user-defined)
@override@JsonKey() final  ScreenSource screenSource;
/// Screen category
@override@JsonKey() final  ScreenCategory category;
/// Screen-level trigger (workflows only)
 final  TriggerConfig? triggerConfig;
/// FAB operations available on this screen.
 final  List<FabOperation> _fabOperations;
/// FAB operations available on this screen.
@JsonKey() List<FabOperation> get fabOperations {
  if (_fabOperations is EqualUnmodifiableListView) return _fabOperations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fabOperations);
}

/// AppBar actions available on this screen.
 final  List<AppBarAction> _appBarActions;
/// AppBar actions available on this screen.
@JsonKey() List<AppBarAction> get appBarActions {
  if (_appBarActions is EqualUnmodifiableListView) return _appBarActions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_appBarActions);
}

/// Route for settings link action (when appBarActions contains settingsLink).
 final  String? settingsRoute;

/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DataDrivenScreenDefinitionCopyWith<DataDrivenScreenDefinition> get copyWith => _$DataDrivenScreenDefinitionCopyWithImpl<DataDrivenScreenDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DataDrivenScreenDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.screenKey, screenKey) || other.screenKey == screenKey)&&(identical(other.name, name) || other.name == name)&&(identical(other.screenType, screenType) || other.screenType == screenType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._sections, _sections)&&const DeepCollectionEquality().equals(other._supportBlocks, _supportBlocks)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.screenSource, screenSource) || other.screenSource == screenSource)&&(identical(other.category, category) || other.category == category)&&(identical(other.triggerConfig, triggerConfig) || other.triggerConfig == triggerConfig)&&const DeepCollectionEquality().equals(other._fabOperations, _fabOperations)&&const DeepCollectionEquality().equals(other._appBarActions, _appBarActions)&&(identical(other.settingsRoute, settingsRoute) || other.settingsRoute == settingsRoute));
}


@override
int get hashCode => Object.hash(runtimeType,id,screenKey,name,screenType,createdAt,updatedAt,const DeepCollectionEquality().hash(_sections),const DeepCollectionEquality().hash(_supportBlocks),iconName,screenSource,category,triggerConfig,const DeepCollectionEquality().hash(_fabOperations),const DeepCollectionEquality().hash(_appBarActions),settingsRoute);

@override
String toString() {
  return 'ScreenDefinition.dataDriven(id: $id, screenKey: $screenKey, name: $name, screenType: $screenType, createdAt: $createdAt, updatedAt: $updatedAt, sections: $sections, supportBlocks: $supportBlocks, iconName: $iconName, screenSource: $screenSource, category: $category, triggerConfig: $triggerConfig, fabOperations: $fabOperations, appBarActions: $appBarActions, settingsRoute: $settingsRoute)';
}


}

/// @nodoc
abstract mixin class $DataDrivenScreenDefinitionCopyWith<$Res> implements $ScreenDefinitionCopyWith<$Res> {
  factory $DataDrivenScreenDefinitionCopyWith(DataDrivenScreenDefinition value, $Res Function(DataDrivenScreenDefinition) _then) = _$DataDrivenScreenDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String screenKey, String name, ScreenType screenType, DateTime createdAt, DateTime updatedAt, List<Section> sections, List<SupportBlock> supportBlocks, String? iconName, ScreenSource screenSource, ScreenCategory category, TriggerConfig? triggerConfig, List<FabOperation> fabOperations, List<AppBarAction> appBarActions, String? settingsRoute
});


$TriggerConfigCopyWith<$Res>? get triggerConfig;

}
/// @nodoc
class _$DataDrivenScreenDefinitionCopyWithImpl<$Res>
    implements $DataDrivenScreenDefinitionCopyWith<$Res> {
  _$DataDrivenScreenDefinitionCopyWithImpl(this._self, this._then);

  final DataDrivenScreenDefinition _self;
  final $Res Function(DataDrivenScreenDefinition) _then;

/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? screenKey = null,Object? name = null,Object? screenType = null,Object? createdAt = null,Object? updatedAt = null,Object? sections = null,Object? supportBlocks = null,Object? iconName = freezed,Object? screenSource = null,Object? category = null,Object? triggerConfig = freezed,Object? fabOperations = null,Object? appBarActions = null,Object? settingsRoute = freezed,}) {
  return _then(DataDrivenScreenDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,screenKey: null == screenKey ? _self.screenKey : screenKey // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,screenType: null == screenType ? _self.screenType : screenType // ignore: cast_nullable_to_non_nullable
as ScreenType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<Section>,supportBlocks: null == supportBlocks ? _self._supportBlocks : supportBlocks // ignore: cast_nullable_to_non_nullable
as List<SupportBlock>,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,screenSource: null == screenSource ? _self.screenSource : screenSource // ignore: cast_nullable_to_non_nullable
as ScreenSource,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ScreenCategory,triggerConfig: freezed == triggerConfig ? _self.triggerConfig : triggerConfig // ignore: cast_nullable_to_non_nullable
as TriggerConfig?,fabOperations: null == fabOperations ? _self._fabOperations : fabOperations // ignore: cast_nullable_to_non_nullable
as List<FabOperation>,appBarActions: null == appBarActions ? _self._appBarActions : appBarActions // ignore: cast_nullable_to_non_nullable
as List<AppBarAction>,settingsRoute: freezed == settingsRoute ? _self.settingsRoute : settingsRoute // ignore: cast_nullable_to_non_nullable
as String?,
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

/// @nodoc


class NavigationOnlyScreenDefinition extends ScreenDefinition {
  const NavigationOnlyScreenDefinition({required this.id, required this.screenKey, required this.name, required this.createdAt, required this.updatedAt, this.iconName, this.screenSource = ScreenSource.userDefined, this.category = ScreenCategory.workspace}): super._();
  

@override final  String id;
@override final  String screenKey;
@override final  String name;
/// Audit fields
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
/// Icon for display in navigation
@override final  String? iconName;
/// Source of this screen definition (system template vs user-defined)
@override@JsonKey() final  ScreenSource screenSource;
/// Screen category
@override@JsonKey() final  ScreenCategory category;

/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NavigationOnlyScreenDefinitionCopyWith<NavigationOnlyScreenDefinition> get copyWith => _$NavigationOnlyScreenDefinitionCopyWithImpl<NavigationOnlyScreenDefinition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NavigationOnlyScreenDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.screenKey, screenKey) || other.screenKey == screenKey)&&(identical(other.name, name) || other.name == name)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.screenSource, screenSource) || other.screenSource == screenSource)&&(identical(other.category, category) || other.category == category));
}


@override
int get hashCode => Object.hash(runtimeType,id,screenKey,name,createdAt,updatedAt,iconName,screenSource,category);

@override
String toString() {
  return 'ScreenDefinition.navigationOnly(id: $id, screenKey: $screenKey, name: $name, createdAt: $createdAt, updatedAt: $updatedAt, iconName: $iconName, screenSource: $screenSource, category: $category)';
}


}

/// @nodoc
abstract mixin class $NavigationOnlyScreenDefinitionCopyWith<$Res> implements $ScreenDefinitionCopyWith<$Res> {
  factory $NavigationOnlyScreenDefinitionCopyWith(NavigationOnlyScreenDefinition value, $Res Function(NavigationOnlyScreenDefinition) _then) = _$NavigationOnlyScreenDefinitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String screenKey, String name, DateTime createdAt, DateTime updatedAt, String? iconName, ScreenSource screenSource, ScreenCategory category
});




}
/// @nodoc
class _$NavigationOnlyScreenDefinitionCopyWithImpl<$Res>
    implements $NavigationOnlyScreenDefinitionCopyWith<$Res> {
  _$NavigationOnlyScreenDefinitionCopyWithImpl(this._self, this._then);

  final NavigationOnlyScreenDefinition _self;
  final $Res Function(NavigationOnlyScreenDefinition) _then;

/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? screenKey = null,Object? name = null,Object? createdAt = null,Object? updatedAt = null,Object? iconName = freezed,Object? screenSource = null,Object? category = null,}) {
  return _then(NavigationOnlyScreenDefinition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,screenKey: null == screenKey ? _self.screenKey : screenKey // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,screenSource: null == screenSource ? _self.screenSource : screenSource // ignore: cast_nullable_to_non_nullable
as ScreenSource,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ScreenCategory,
  ));
}


}

// dart format on
