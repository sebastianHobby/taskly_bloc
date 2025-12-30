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
ScreenDefinition _$ScreenDefinitionFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'collection':
          return CollectionScreen.fromJson(
            json
          );
                case 'workflow':
          return WorkflowScreen.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'ScreenDefinition',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$ScreenDefinition {

 String get id; String get userId; String get screenId;// Unique like 'today', 'inbox'
 String get name; EntitySelector get selector; DisplayConfig get display; DateTime get createdAt; DateTime get updatedAt; String? get iconName; bool get isSystem; bool get isActive; int get sortOrder;
/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScreenDefinitionCopyWith<ScreenDefinition> get copyWith => _$ScreenDefinitionCopyWithImpl<ScreenDefinition>(this as ScreenDefinition, _$identity);

  /// Serializes this ScreenDefinition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScreenDefinition&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.screenId, screenId) || other.screenId == screenId)&&(identical(other.name, name) || other.name == name)&&(identical(other.selector, selector) || other.selector == selector)&&(identical(other.display, display) || other.display == display)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,screenId,name,selector,display,createdAt,updatedAt,iconName,isSystem,isActive,sortOrder);

@override
String toString() {
  return 'ScreenDefinition(id: $id, userId: $userId, screenId: $screenId, name: $name, selector: $selector, display: $display, createdAt: $createdAt, updatedAt: $updatedAt, iconName: $iconName, isSystem: $isSystem, isActive: $isActive, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $ScreenDefinitionCopyWith<$Res>  {
  factory $ScreenDefinitionCopyWith(ScreenDefinition value, $Res Function(ScreenDefinition) _then) = _$ScreenDefinitionCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String screenId, String name, EntitySelector selector, DisplayConfig display, DateTime createdAt, DateTime updatedAt, String? iconName, bool isSystem, bool isActive, int sortOrder
});


$EntitySelectorCopyWith<$Res> get selector;$DisplayConfigCopyWith<$Res> get display;

}
/// @nodoc
class _$ScreenDefinitionCopyWithImpl<$Res>
    implements $ScreenDefinitionCopyWith<$Res> {
  _$ScreenDefinitionCopyWithImpl(this._self, this._then);

  final ScreenDefinition _self;
  final $Res Function(ScreenDefinition) _then;

/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? screenId = null,Object? name = null,Object? selector = null,Object? display = null,Object? createdAt = null,Object? updatedAt = null,Object? iconName = freezed,Object? isSystem = null,Object? isActive = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,screenId: null == screenId ? _self.screenId : screenId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,selector: null == selector ? _self.selector : selector // ignore: cast_nullable_to_non_nullable
as EntitySelector,display: null == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as DisplayConfig,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EntitySelectorCopyWith<$Res> get selector {
  
  return $EntitySelectorCopyWith<$Res>(_self.selector, (value) {
    return _then(_self.copyWith(selector: value));
  });
}/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DisplayConfigCopyWith<$Res> get display {
  
  return $DisplayConfigCopyWith<$Res>(_self.display, (value) {
    return _then(_self.copyWith(display: value));
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CollectionScreen value)?  collection,TResult Function( WorkflowScreen value)?  workflow,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CollectionScreen() when collection != null:
return collection(_that);case WorkflowScreen() when workflow != null:
return workflow(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CollectionScreen value)  collection,required TResult Function( WorkflowScreen value)  workflow,}){
final _that = this;
switch (_that) {
case CollectionScreen():
return collection(_that);case WorkflowScreen():
return workflow(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CollectionScreen value)?  collection,TResult? Function( WorkflowScreen value)?  workflow,}){
final _that = this;
switch (_that) {
case CollectionScreen() when collection != null:
return collection(_that);case WorkflowScreen() when workflow != null:
return workflow(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String userId,  String screenId,  String name,  EntitySelector selector,  DisplayConfig display,  DateTime createdAt,  DateTime updatedAt,  String? iconName,  bool isSystem,  bool isActive,  int sortOrder)?  collection,TResult Function( String id,  String userId,  String screenId,  String name,  EntitySelector selector,  DisplayConfig display,  DateTime createdAt,  DateTime updatedAt,  String? iconName,  bool isSystem,  bool isActive,  int sortOrder,  TriggerConfig? trigger,  CompletionCriteria? completionCriteria)?  workflow,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CollectionScreen() when collection != null:
return collection(_that.id,_that.userId,_that.screenId,_that.name,_that.selector,_that.display,_that.createdAt,_that.updatedAt,_that.iconName,_that.isSystem,_that.isActive,_that.sortOrder);case WorkflowScreen() when workflow != null:
return workflow(_that.id,_that.userId,_that.screenId,_that.name,_that.selector,_that.display,_that.createdAt,_that.updatedAt,_that.iconName,_that.isSystem,_that.isActive,_that.sortOrder,_that.trigger,_that.completionCriteria);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String userId,  String screenId,  String name,  EntitySelector selector,  DisplayConfig display,  DateTime createdAt,  DateTime updatedAt,  String? iconName,  bool isSystem,  bool isActive,  int sortOrder)  collection,required TResult Function( String id,  String userId,  String screenId,  String name,  EntitySelector selector,  DisplayConfig display,  DateTime createdAt,  DateTime updatedAt,  String? iconName,  bool isSystem,  bool isActive,  int sortOrder,  TriggerConfig? trigger,  CompletionCriteria? completionCriteria)  workflow,}) {final _that = this;
switch (_that) {
case CollectionScreen():
return collection(_that.id,_that.userId,_that.screenId,_that.name,_that.selector,_that.display,_that.createdAt,_that.updatedAt,_that.iconName,_that.isSystem,_that.isActive,_that.sortOrder);case WorkflowScreen():
return workflow(_that.id,_that.userId,_that.screenId,_that.name,_that.selector,_that.display,_that.createdAt,_that.updatedAt,_that.iconName,_that.isSystem,_that.isActive,_that.sortOrder,_that.trigger,_that.completionCriteria);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String userId,  String screenId,  String name,  EntitySelector selector,  DisplayConfig display,  DateTime createdAt,  DateTime updatedAt,  String? iconName,  bool isSystem,  bool isActive,  int sortOrder)?  collection,TResult? Function( String id,  String userId,  String screenId,  String name,  EntitySelector selector,  DisplayConfig display,  DateTime createdAt,  DateTime updatedAt,  String? iconName,  bool isSystem,  bool isActive,  int sortOrder,  TriggerConfig? trigger,  CompletionCriteria? completionCriteria)?  workflow,}) {final _that = this;
switch (_that) {
case CollectionScreen() when collection != null:
return collection(_that.id,_that.userId,_that.screenId,_that.name,_that.selector,_that.display,_that.createdAt,_that.updatedAt,_that.iconName,_that.isSystem,_that.isActive,_that.sortOrder);case WorkflowScreen() when workflow != null:
return workflow(_that.id,_that.userId,_that.screenId,_that.name,_that.selector,_that.display,_that.createdAt,_that.updatedAt,_that.iconName,_that.isSystem,_that.isActive,_that.sortOrder,_that.trigger,_that.completionCriteria);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class CollectionScreen implements ScreenDefinition {
  const CollectionScreen({required this.id, required this.userId, required this.screenId, required this.name, required this.selector, required this.display, required this.createdAt, required this.updatedAt, this.iconName, this.isSystem = false, this.isActive = true, this.sortOrder = 0, final  String? $type}): $type = $type ?? 'collection';
  factory CollectionScreen.fromJson(Map<String, dynamic> json) => _$CollectionScreenFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String screenId;
// Unique like 'today', 'inbox'
@override final  String name;
@override final  EntitySelector selector;
@override final  DisplayConfig display;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? iconName;
@override@JsonKey() final  bool isSystem;
@override@JsonKey() final  bool isActive;
@override@JsonKey() final  int sortOrder;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CollectionScreenCopyWith<CollectionScreen> get copyWith => _$CollectionScreenCopyWithImpl<CollectionScreen>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CollectionScreenToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CollectionScreen&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.screenId, screenId) || other.screenId == screenId)&&(identical(other.name, name) || other.name == name)&&(identical(other.selector, selector) || other.selector == selector)&&(identical(other.display, display) || other.display == display)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,screenId,name,selector,display,createdAt,updatedAt,iconName,isSystem,isActive,sortOrder);

@override
String toString() {
  return 'ScreenDefinition.collection(id: $id, userId: $userId, screenId: $screenId, name: $name, selector: $selector, display: $display, createdAt: $createdAt, updatedAt: $updatedAt, iconName: $iconName, isSystem: $isSystem, isActive: $isActive, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $CollectionScreenCopyWith<$Res> implements $ScreenDefinitionCopyWith<$Res> {
  factory $CollectionScreenCopyWith(CollectionScreen value, $Res Function(CollectionScreen) _then) = _$CollectionScreenCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String screenId, String name, EntitySelector selector, DisplayConfig display, DateTime createdAt, DateTime updatedAt, String? iconName, bool isSystem, bool isActive, int sortOrder
});


@override $EntitySelectorCopyWith<$Res> get selector;@override $DisplayConfigCopyWith<$Res> get display;

}
/// @nodoc
class _$CollectionScreenCopyWithImpl<$Res>
    implements $CollectionScreenCopyWith<$Res> {
  _$CollectionScreenCopyWithImpl(this._self, this._then);

  final CollectionScreen _self;
  final $Res Function(CollectionScreen) _then;

/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? screenId = null,Object? name = null,Object? selector = null,Object? display = null,Object? createdAt = null,Object? updatedAt = null,Object? iconName = freezed,Object? isSystem = null,Object? isActive = null,Object? sortOrder = null,}) {
  return _then(CollectionScreen(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,screenId: null == screenId ? _self.screenId : screenId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,selector: null == selector ? _self.selector : selector // ignore: cast_nullable_to_non_nullable
as EntitySelector,display: null == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as DisplayConfig,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EntitySelectorCopyWith<$Res> get selector {
  
  return $EntitySelectorCopyWith<$Res>(_self.selector, (value) {
    return _then(_self.copyWith(selector: value));
  });
}/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DisplayConfigCopyWith<$Res> get display {
  
  return $DisplayConfigCopyWith<$Res>(_self.display, (value) {
    return _then(_self.copyWith(display: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class WorkflowScreen implements ScreenDefinition {
  const WorkflowScreen({required this.id, required this.userId, required this.screenId, required this.name, required this.selector, required this.display, required this.createdAt, required this.updatedAt, this.iconName, this.isSystem = false, this.isActive = true, this.sortOrder = 0, this.trigger, this.completionCriteria, final  String? $type}): $type = $type ?? 'workflow';
  factory WorkflowScreen.fromJson(Map<String, dynamic> json) => _$WorkflowScreenFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String screenId;
@override final  String name;
@override final  EntitySelector selector;
@override final  DisplayConfig display;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  String? iconName;
@override@JsonKey() final  bool isSystem;
@override@JsonKey() final  bool isActive;
@override@JsonKey() final  int sortOrder;
 final  TriggerConfig? trigger;
 final  CompletionCriteria? completionCriteria;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkflowScreenCopyWith<WorkflowScreen> get copyWith => _$WorkflowScreenCopyWithImpl<WorkflowScreen>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkflowScreenToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowScreen&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.screenId, screenId) || other.screenId == screenId)&&(identical(other.name, name) || other.name == name)&&(identical(other.selector, selector) || other.selector == selector)&&(identical(other.display, display) || other.display == display)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.iconName, iconName) || other.iconName == iconName)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.trigger, trigger) || other.trigger == trigger)&&(identical(other.completionCriteria, completionCriteria) || other.completionCriteria == completionCriteria));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,screenId,name,selector,display,createdAt,updatedAt,iconName,isSystem,isActive,sortOrder,trigger,completionCriteria);

@override
String toString() {
  return 'ScreenDefinition.workflow(id: $id, userId: $userId, screenId: $screenId, name: $name, selector: $selector, display: $display, createdAt: $createdAt, updatedAt: $updatedAt, iconName: $iconName, isSystem: $isSystem, isActive: $isActive, sortOrder: $sortOrder, trigger: $trigger, completionCriteria: $completionCriteria)';
}


}

/// @nodoc
abstract mixin class $WorkflowScreenCopyWith<$Res> implements $ScreenDefinitionCopyWith<$Res> {
  factory $WorkflowScreenCopyWith(WorkflowScreen value, $Res Function(WorkflowScreen) _then) = _$WorkflowScreenCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String screenId, String name, EntitySelector selector, DisplayConfig display, DateTime createdAt, DateTime updatedAt, String? iconName, bool isSystem, bool isActive, int sortOrder, TriggerConfig? trigger, CompletionCriteria? completionCriteria
});


@override $EntitySelectorCopyWith<$Res> get selector;@override $DisplayConfigCopyWith<$Res> get display;$TriggerConfigCopyWith<$Res>? get trigger;$CompletionCriteriaCopyWith<$Res>? get completionCriteria;

}
/// @nodoc
class _$WorkflowScreenCopyWithImpl<$Res>
    implements $WorkflowScreenCopyWith<$Res> {
  _$WorkflowScreenCopyWithImpl(this._self, this._then);

  final WorkflowScreen _self;
  final $Res Function(WorkflowScreen) _then;

/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? screenId = null,Object? name = null,Object? selector = null,Object? display = null,Object? createdAt = null,Object? updatedAt = null,Object? iconName = freezed,Object? isSystem = null,Object? isActive = null,Object? sortOrder = null,Object? trigger = freezed,Object? completionCriteria = freezed,}) {
  return _then(WorkflowScreen(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,screenId: null == screenId ? _self.screenId : screenId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,selector: null == selector ? _self.selector : selector // ignore: cast_nullable_to_non_nullable
as EntitySelector,display: null == display ? _self.display : display // ignore: cast_nullable_to_non_nullable
as DisplayConfig,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,iconName: freezed == iconName ? _self.iconName : iconName // ignore: cast_nullable_to_non_nullable
as String?,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,trigger: freezed == trigger ? _self.trigger : trigger // ignore: cast_nullable_to_non_nullable
as TriggerConfig?,completionCriteria: freezed == completionCriteria ? _self.completionCriteria : completionCriteria // ignore: cast_nullable_to_non_nullable
as CompletionCriteria?,
  ));
}

/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EntitySelectorCopyWith<$Res> get selector {
  
  return $EntitySelectorCopyWith<$Res>(_self.selector, (value) {
    return _then(_self.copyWith(selector: value));
  });
}/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DisplayConfigCopyWith<$Res> get display {
  
  return $DisplayConfigCopyWith<$Res>(_self.display, (value) {
    return _then(_self.copyWith(display: value));
  });
}/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TriggerConfigCopyWith<$Res>? get trigger {
    if (_self.trigger == null) {
    return null;
  }

  return $TriggerConfigCopyWith<$Res>(_self.trigger!, (value) {
    return _then(_self.copyWith(trigger: value));
  });
}/// Create a copy of ScreenDefinition
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompletionCriteriaCopyWith<$Res>? get completionCriteria {
    if (_self.completionCriteria == null) {
    return null;
  }

  return $CompletionCriteriaCopyWith<$Res>(_self.completionCriteria!, (value) {
    return _then(_self.copyWith(completionCriteria: value));
  });
}
}

// dart format on
