// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'entity_selector.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EntitySelector {

 EntityType get entityType;@TaskQueryFilterConverter() QueryFilter<TaskPredicate>? get taskFilter;@ProjectQueryFilterConverter() QueryFilter<ProjectPredicate>? get projectFilter; List<String>? get specificIds;
/// Create a copy of EntitySelector
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntitySelectorCopyWith<EntitySelector> get copyWith => _$EntitySelectorCopyWithImpl<EntitySelector>(this as EntitySelector, _$identity);

  /// Serializes this EntitySelector to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntitySelector&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.taskFilter, taskFilter) || other.taskFilter == taskFilter)&&(identical(other.projectFilter, projectFilter) || other.projectFilter == projectFilter)&&const DeepCollectionEquality().equals(other.specificIds, specificIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,entityType,taskFilter,projectFilter,const DeepCollectionEquality().hash(specificIds));

@override
String toString() {
  return 'EntitySelector(entityType: $entityType, taskFilter: $taskFilter, projectFilter: $projectFilter, specificIds: $specificIds)';
}


}

/// @nodoc
abstract mixin class $EntitySelectorCopyWith<$Res>  {
  factory $EntitySelectorCopyWith(EntitySelector value, $Res Function(EntitySelector) _then) = _$EntitySelectorCopyWithImpl;
@useResult
$Res call({
 EntityType entityType,@TaskQueryFilterConverter() QueryFilter<TaskPredicate>? taskFilter,@ProjectQueryFilterConverter() QueryFilter<ProjectPredicate>? projectFilter, List<String>? specificIds
});




}
/// @nodoc
class _$EntitySelectorCopyWithImpl<$Res>
    implements $EntitySelectorCopyWith<$Res> {
  _$EntitySelectorCopyWithImpl(this._self, this._then);

  final EntitySelector _self;
  final $Res Function(EntitySelector) _then;

/// Create a copy of EntitySelector
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entityType = null,Object? taskFilter = freezed,Object? projectFilter = freezed,Object? specificIds = freezed,}) {
  return _then(_self.copyWith(
entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,taskFilter: freezed == taskFilter ? _self.taskFilter : taskFilter // ignore: cast_nullable_to_non_nullable
as QueryFilter<TaskPredicate>?,projectFilter: freezed == projectFilter ? _self.projectFilter : projectFilter // ignore: cast_nullable_to_non_nullable
as QueryFilter<ProjectPredicate>?,specificIds: freezed == specificIds ? _self.specificIds : specificIds // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [EntitySelector].
extension EntitySelectorPatterns on EntitySelector {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EntitySelector value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EntitySelector() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EntitySelector value)  $default,){
final _that = this;
switch (_that) {
case _EntitySelector():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EntitySelector value)?  $default,){
final _that = this;
switch (_that) {
case _EntitySelector() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EntityType entityType, @TaskQueryFilterConverter()  QueryFilter<TaskPredicate>? taskFilter, @ProjectQueryFilterConverter()  QueryFilter<ProjectPredicate>? projectFilter,  List<String>? specificIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EntitySelector() when $default != null:
return $default(_that.entityType,_that.taskFilter,_that.projectFilter,_that.specificIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EntityType entityType, @TaskQueryFilterConverter()  QueryFilter<TaskPredicate>? taskFilter, @ProjectQueryFilterConverter()  QueryFilter<ProjectPredicate>? projectFilter,  List<String>? specificIds)  $default,) {final _that = this;
switch (_that) {
case _EntitySelector():
return $default(_that.entityType,_that.taskFilter,_that.projectFilter,_that.specificIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EntityType entityType, @TaskQueryFilterConverter()  QueryFilter<TaskPredicate>? taskFilter, @ProjectQueryFilterConverter()  QueryFilter<ProjectPredicate>? projectFilter,  List<String>? specificIds)?  $default,) {final _that = this;
switch (_that) {
case _EntitySelector() when $default != null:
return $default(_that.entityType,_that.taskFilter,_that.projectFilter,_that.specificIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EntitySelector implements EntitySelector {
  const _EntitySelector({required this.entityType, @TaskQueryFilterConverter() this.taskFilter, @ProjectQueryFilterConverter() this.projectFilter, final  List<String>? specificIds}): _specificIds = specificIds;
  factory _EntitySelector.fromJson(Map<String, dynamic> json) => _$EntitySelectorFromJson(json);

@override final  EntityType entityType;
@override@TaskQueryFilterConverter() final  QueryFilter<TaskPredicate>? taskFilter;
@override@ProjectQueryFilterConverter() final  QueryFilter<ProjectPredicate>? projectFilter;
 final  List<String>? _specificIds;
@override List<String>? get specificIds {
  final value = _specificIds;
  if (value == null) return null;
  if (_specificIds is EqualUnmodifiableListView) return _specificIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of EntitySelector
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EntitySelectorCopyWith<_EntitySelector> get copyWith => __$EntitySelectorCopyWithImpl<_EntitySelector>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EntitySelectorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EntitySelector&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.taskFilter, taskFilter) || other.taskFilter == taskFilter)&&(identical(other.projectFilter, projectFilter) || other.projectFilter == projectFilter)&&const DeepCollectionEquality().equals(other._specificIds, _specificIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,entityType,taskFilter,projectFilter,const DeepCollectionEquality().hash(_specificIds));

@override
String toString() {
  return 'EntitySelector(entityType: $entityType, taskFilter: $taskFilter, projectFilter: $projectFilter, specificIds: $specificIds)';
}


}

/// @nodoc
abstract mixin class _$EntitySelectorCopyWith<$Res> implements $EntitySelectorCopyWith<$Res> {
  factory _$EntitySelectorCopyWith(_EntitySelector value, $Res Function(_EntitySelector) _then) = __$EntitySelectorCopyWithImpl;
@override @useResult
$Res call({
 EntityType entityType,@TaskQueryFilterConverter() QueryFilter<TaskPredicate>? taskFilter,@ProjectQueryFilterConverter() QueryFilter<ProjectPredicate>? projectFilter, List<String>? specificIds
});




}
/// @nodoc
class __$EntitySelectorCopyWithImpl<$Res>
    implements _$EntitySelectorCopyWith<$Res> {
  __$EntitySelectorCopyWithImpl(this._self, this._then);

  final _EntitySelector _self;
  final $Res Function(_EntitySelector) _then;

/// Create a copy of EntitySelector
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entityType = null,Object? taskFilter = freezed,Object? projectFilter = freezed,Object? specificIds = freezed,}) {
  return _then(_EntitySelector(
entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,taskFilter: freezed == taskFilter ? _self.taskFilter : taskFilter // ignore: cast_nullable_to_non_nullable
as QueryFilter<TaskPredicate>?,projectFilter: freezed == projectFilter ? _self.projectFilter : projectFilter // ignore: cast_nullable_to_non_nullable
as QueryFilter<ProjectPredicate>?,specificIds: freezed == specificIds ? _self._specificIds : specificIds // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}

// dart format on
