// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_query.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReviewQuery {

 EntityType get entityType; List<String>? get projectIds; List<String>? get labelIds; List<String>? get valueIds; bool? get includeCompleted; DateTime? get completedBefore; DateTime? get completedAfter; DateTime? get createdBefore; DateTime? get createdAfter;
/// Create a copy of ReviewQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewQueryCopyWith<ReviewQuery> get copyWith => _$ReviewQueryCopyWithImpl<ReviewQuery>(this as ReviewQuery, _$identity);

  /// Serializes this ReviewQuery to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewQuery&&(identical(other.entityType, entityType) || other.entityType == entityType)&&const DeepCollectionEquality().equals(other.projectIds, projectIds)&&const DeepCollectionEquality().equals(other.labelIds, labelIds)&&const DeepCollectionEquality().equals(other.valueIds, valueIds)&&(identical(other.includeCompleted, includeCompleted) || other.includeCompleted == includeCompleted)&&(identical(other.completedBefore, completedBefore) || other.completedBefore == completedBefore)&&(identical(other.completedAfter, completedAfter) || other.completedAfter == completedAfter)&&(identical(other.createdBefore, createdBefore) || other.createdBefore == createdBefore)&&(identical(other.createdAfter, createdAfter) || other.createdAfter == createdAfter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,entityType,const DeepCollectionEquality().hash(projectIds),const DeepCollectionEquality().hash(labelIds),const DeepCollectionEquality().hash(valueIds),includeCompleted,completedBefore,completedAfter,createdBefore,createdAfter);

@override
String toString() {
  return 'ReviewQuery(entityType: $entityType, projectIds: $projectIds, labelIds: $labelIds, valueIds: $valueIds, includeCompleted: $includeCompleted, completedBefore: $completedBefore, completedAfter: $completedAfter, createdBefore: $createdBefore, createdAfter: $createdAfter)';
}


}

/// @nodoc
abstract mixin class $ReviewQueryCopyWith<$Res>  {
  factory $ReviewQueryCopyWith(ReviewQuery value, $Res Function(ReviewQuery) _then) = _$ReviewQueryCopyWithImpl;
@useResult
$Res call({
 EntityType entityType, List<String>? projectIds, List<String>? labelIds, List<String>? valueIds, bool? includeCompleted, DateTime? completedBefore, DateTime? completedAfter, DateTime? createdBefore, DateTime? createdAfter
});




}
/// @nodoc
class _$ReviewQueryCopyWithImpl<$Res>
    implements $ReviewQueryCopyWith<$Res> {
  _$ReviewQueryCopyWithImpl(this._self, this._then);

  final ReviewQuery _self;
  final $Res Function(ReviewQuery) _then;

/// Create a copy of ReviewQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entityType = null,Object? projectIds = freezed,Object? labelIds = freezed,Object? valueIds = freezed,Object? includeCompleted = freezed,Object? completedBefore = freezed,Object? completedAfter = freezed,Object? createdBefore = freezed,Object? createdAfter = freezed,}) {
  return _then(_self.copyWith(
entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,projectIds: freezed == projectIds ? _self.projectIds : projectIds // ignore: cast_nullable_to_non_nullable
as List<String>?,labelIds: freezed == labelIds ? _self.labelIds : labelIds // ignore: cast_nullable_to_non_nullable
as List<String>?,valueIds: freezed == valueIds ? _self.valueIds : valueIds // ignore: cast_nullable_to_non_nullable
as List<String>?,includeCompleted: freezed == includeCompleted ? _self.includeCompleted : includeCompleted // ignore: cast_nullable_to_non_nullable
as bool?,completedBefore: freezed == completedBefore ? _self.completedBefore : completedBefore // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAfter: freezed == completedAfter ? _self.completedAfter : completedAfter // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBefore: freezed == createdBefore ? _self.createdBefore : createdBefore // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAfter: freezed == createdAfter ? _self.createdAfter : createdAfter // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReviewQuery].
extension ReviewQueryPatterns on ReviewQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewQuery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewQuery value)  $default,){
final _that = this;
switch (_that) {
case _ReviewQuery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewQuery value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewQuery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EntityType entityType,  List<String>? projectIds,  List<String>? labelIds,  List<String>? valueIds,  bool? includeCompleted,  DateTime? completedBefore,  DateTime? completedAfter,  DateTime? createdBefore,  DateTime? createdAfter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewQuery() when $default != null:
return $default(_that.entityType,_that.projectIds,_that.labelIds,_that.valueIds,_that.includeCompleted,_that.completedBefore,_that.completedAfter,_that.createdBefore,_that.createdAfter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EntityType entityType,  List<String>? projectIds,  List<String>? labelIds,  List<String>? valueIds,  bool? includeCompleted,  DateTime? completedBefore,  DateTime? completedAfter,  DateTime? createdBefore,  DateTime? createdAfter)  $default,) {final _that = this;
switch (_that) {
case _ReviewQuery():
return $default(_that.entityType,_that.projectIds,_that.labelIds,_that.valueIds,_that.includeCompleted,_that.completedBefore,_that.completedAfter,_that.createdBefore,_that.createdAfter);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EntityType entityType,  List<String>? projectIds,  List<String>? labelIds,  List<String>? valueIds,  bool? includeCompleted,  DateTime? completedBefore,  DateTime? completedAfter,  DateTime? createdBefore,  DateTime? createdAfter)?  $default,) {final _that = this;
switch (_that) {
case _ReviewQuery() when $default != null:
return $default(_that.entityType,_that.projectIds,_that.labelIds,_that.valueIds,_that.includeCompleted,_that.completedBefore,_that.completedAfter,_that.createdBefore,_that.createdAfter);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReviewQuery implements ReviewQuery {
  const _ReviewQuery({required this.entityType, final  List<String>? projectIds, final  List<String>? labelIds, final  List<String>? valueIds, this.includeCompleted, this.completedBefore, this.completedAfter, this.createdBefore, this.createdAfter}): _projectIds = projectIds,_labelIds = labelIds,_valueIds = valueIds;
  factory _ReviewQuery.fromJson(Map<String, dynamic> json) => _$ReviewQueryFromJson(json);

@override final  EntityType entityType;
 final  List<String>? _projectIds;
@override List<String>? get projectIds {
  final value = _projectIds;
  if (value == null) return null;
  if (_projectIds is EqualUnmodifiableListView) return _projectIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _labelIds;
@override List<String>? get labelIds {
  final value = _labelIds;
  if (value == null) return null;
  if (_labelIds is EqualUnmodifiableListView) return _labelIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<String>? _valueIds;
@override List<String>? get valueIds {
  final value = _valueIds;
  if (value == null) return null;
  if (_valueIds is EqualUnmodifiableListView) return _valueIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  bool? includeCompleted;
@override final  DateTime? completedBefore;
@override final  DateTime? completedAfter;
@override final  DateTime? createdBefore;
@override final  DateTime? createdAfter;

/// Create a copy of ReviewQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewQueryCopyWith<_ReviewQuery> get copyWith => __$ReviewQueryCopyWithImpl<_ReviewQuery>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReviewQueryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewQuery&&(identical(other.entityType, entityType) || other.entityType == entityType)&&const DeepCollectionEquality().equals(other._projectIds, _projectIds)&&const DeepCollectionEquality().equals(other._labelIds, _labelIds)&&const DeepCollectionEquality().equals(other._valueIds, _valueIds)&&(identical(other.includeCompleted, includeCompleted) || other.includeCompleted == includeCompleted)&&(identical(other.completedBefore, completedBefore) || other.completedBefore == completedBefore)&&(identical(other.completedAfter, completedAfter) || other.completedAfter == completedAfter)&&(identical(other.createdBefore, createdBefore) || other.createdBefore == createdBefore)&&(identical(other.createdAfter, createdAfter) || other.createdAfter == createdAfter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,entityType,const DeepCollectionEquality().hash(_projectIds),const DeepCollectionEquality().hash(_labelIds),const DeepCollectionEquality().hash(_valueIds),includeCompleted,completedBefore,completedAfter,createdBefore,createdAfter);

@override
String toString() {
  return 'ReviewQuery(entityType: $entityType, projectIds: $projectIds, labelIds: $labelIds, valueIds: $valueIds, includeCompleted: $includeCompleted, completedBefore: $completedBefore, completedAfter: $completedAfter, createdBefore: $createdBefore, createdAfter: $createdAfter)';
}


}

/// @nodoc
abstract mixin class _$ReviewQueryCopyWith<$Res> implements $ReviewQueryCopyWith<$Res> {
  factory _$ReviewQueryCopyWith(_ReviewQuery value, $Res Function(_ReviewQuery) _then) = __$ReviewQueryCopyWithImpl;
@override @useResult
$Res call({
 EntityType entityType, List<String>? projectIds, List<String>? labelIds, List<String>? valueIds, bool? includeCompleted, DateTime? completedBefore, DateTime? completedAfter, DateTime? createdBefore, DateTime? createdAfter
});




}
/// @nodoc
class __$ReviewQueryCopyWithImpl<$Res>
    implements _$ReviewQueryCopyWith<$Res> {
  __$ReviewQueryCopyWithImpl(this._self, this._then);

  final _ReviewQuery _self;
  final $Res Function(_ReviewQuery) _then;

/// Create a copy of ReviewQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entityType = null,Object? projectIds = freezed,Object? labelIds = freezed,Object? valueIds = freezed,Object? includeCompleted = freezed,Object? completedBefore = freezed,Object? completedAfter = freezed,Object? createdBefore = freezed,Object? createdAfter = freezed,}) {
  return _then(_ReviewQuery(
entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,projectIds: freezed == projectIds ? _self._projectIds : projectIds // ignore: cast_nullable_to_non_nullable
as List<String>?,labelIds: freezed == labelIds ? _self._labelIds : labelIds // ignore: cast_nullable_to_non_nullable
as List<String>?,valueIds: freezed == valueIds ? _self._valueIds : valueIds // ignore: cast_nullable_to_non_nullable
as List<String>?,includeCompleted: freezed == includeCompleted ? _self.includeCompleted : includeCompleted // ignore: cast_nullable_to_non_nullable
as bool?,completedBefore: freezed == completedBefore ? _self.completedBefore : completedBefore // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAfter: freezed == completedAfter ? _self.completedAfter : completedAfter // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBefore: freezed == createdBefore ? _self.createdBefore : createdBefore // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAfter: freezed == createdAfter ? _self.createdAfter : createdAfter // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
