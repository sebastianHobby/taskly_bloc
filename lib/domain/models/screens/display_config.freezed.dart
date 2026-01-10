// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'display_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SortCriterion {

 SortField get field; SortDirection get direction;
/// Create a copy of SortCriterion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SortCriterionCopyWith<SortCriterion> get copyWith => _$SortCriterionCopyWithImpl<SortCriterion>(this as SortCriterion, _$identity);

  /// Serializes this SortCriterion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SortCriterion&&(identical(other.field, field) || other.field == field)&&(identical(other.direction, direction) || other.direction == direction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,field,direction);

@override
String toString() {
  return 'SortCriterion(field: $field, direction: $direction)';
}


}

/// @nodoc
abstract mixin class $SortCriterionCopyWith<$Res>  {
  factory $SortCriterionCopyWith(SortCriterion value, $Res Function(SortCriterion) _then) = _$SortCriterionCopyWithImpl;
@useResult
$Res call({
 SortField field, SortDirection direction
});




}
/// @nodoc
class _$SortCriterionCopyWithImpl<$Res>
    implements $SortCriterionCopyWith<$Res> {
  _$SortCriterionCopyWithImpl(this._self, this._then);

  final SortCriterion _self;
  final $Res Function(SortCriterion) _then;

/// Create a copy of SortCriterion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? field = null,Object? direction = null,}) {
  return _then(_self.copyWith(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as SortField,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as SortDirection,
  ));
}

}


/// Adds pattern-matching-related methods to [SortCriterion].
extension SortCriterionPatterns on SortCriterion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SortCriterion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SortCriterion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SortCriterion value)  $default,){
final _that = this;
switch (_that) {
case _SortCriterion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SortCriterion value)?  $default,){
final _that = this;
switch (_that) {
case _SortCriterion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SortField field,  SortDirection direction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SortCriterion() when $default != null:
return $default(_that.field,_that.direction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SortField field,  SortDirection direction)  $default,) {final _that = this;
switch (_that) {
case _SortCriterion():
return $default(_that.field,_that.direction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SortField field,  SortDirection direction)?  $default,) {final _that = this;
switch (_that) {
case _SortCriterion() when $default != null:
return $default(_that.field,_that.direction);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SortCriterion implements SortCriterion {
  const _SortCriterion({required this.field, this.direction = SortDirection.asc});
  factory _SortCriterion.fromJson(Map<String, dynamic> json) => _$SortCriterionFromJson(json);

@override final  SortField field;
@override@JsonKey() final  SortDirection direction;

/// Create a copy of SortCriterion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SortCriterionCopyWith<_SortCriterion> get copyWith => __$SortCriterionCopyWithImpl<_SortCriterion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SortCriterionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SortCriterion&&(identical(other.field, field) || other.field == field)&&(identical(other.direction, direction) || other.direction == direction));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,field,direction);

@override
String toString() {
  return 'SortCriterion(field: $field, direction: $direction)';
}


}

/// @nodoc
abstract mixin class _$SortCriterionCopyWith<$Res> implements $SortCriterionCopyWith<$Res> {
  factory _$SortCriterionCopyWith(_SortCriterion value, $Res Function(_SortCriterion) _then) = __$SortCriterionCopyWithImpl;
@override @useResult
$Res call({
 SortField field, SortDirection direction
});




}
/// @nodoc
class __$SortCriterionCopyWithImpl<$Res>
    implements _$SortCriterionCopyWith<$Res> {
  __$SortCriterionCopyWithImpl(this._self, this._then);

  final _SortCriterion _self;
  final $Res Function(_SortCriterion) _then;

/// Create a copy of SortCriterion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field = null,Object? direction = null,}) {
  return _then(_SortCriterion(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as SortField,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as SortDirection,
  ));
}


}


/// @nodoc
mixin _$DisplayConfig {

 GroupByField get groupBy; List<SortCriterion> get sorting; List<ProblemType> get problemsToDetect; bool get showCompleted; bool get showArchived;/// Whether list tiles should use a compact (2-row) layout.
///
/// If false, tiles use the full (3-row) layout.
 bool get compactTiles;/// Whether to group tasks by completion status (active vs completed)
 bool get groupByCompletion;/// Whether completed section is collapsed by default
 bool get completedCollapsed;/// Whether to enable swipe-to-delete on list items
 bool get enableSwipeToDelete;
/// Create a copy of DisplayConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DisplayConfigCopyWith<DisplayConfig> get copyWith => _$DisplayConfigCopyWithImpl<DisplayConfig>(this as DisplayConfig, _$identity);

  /// Serializes this DisplayConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DisplayConfig&&(identical(other.groupBy, groupBy) || other.groupBy == groupBy)&&const DeepCollectionEquality().equals(other.sorting, sorting)&&const DeepCollectionEquality().equals(other.problemsToDetect, problemsToDetect)&&(identical(other.showCompleted, showCompleted) || other.showCompleted == showCompleted)&&(identical(other.showArchived, showArchived) || other.showArchived == showArchived)&&(identical(other.compactTiles, compactTiles) || other.compactTiles == compactTiles)&&(identical(other.groupByCompletion, groupByCompletion) || other.groupByCompletion == groupByCompletion)&&(identical(other.completedCollapsed, completedCollapsed) || other.completedCollapsed == completedCollapsed)&&(identical(other.enableSwipeToDelete, enableSwipeToDelete) || other.enableSwipeToDelete == enableSwipeToDelete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,groupBy,const DeepCollectionEquality().hash(sorting),const DeepCollectionEquality().hash(problemsToDetect),showCompleted,showArchived,compactTiles,groupByCompletion,completedCollapsed,enableSwipeToDelete);

@override
String toString() {
  return 'DisplayConfig(groupBy: $groupBy, sorting: $sorting, problemsToDetect: $problemsToDetect, showCompleted: $showCompleted, showArchived: $showArchived, compactTiles: $compactTiles, groupByCompletion: $groupByCompletion, completedCollapsed: $completedCollapsed, enableSwipeToDelete: $enableSwipeToDelete)';
}


}

/// @nodoc
abstract mixin class $DisplayConfigCopyWith<$Res>  {
  factory $DisplayConfigCopyWith(DisplayConfig value, $Res Function(DisplayConfig) _then) = _$DisplayConfigCopyWithImpl;
@useResult
$Res call({
 GroupByField groupBy, List<SortCriterion> sorting, List<ProblemType> problemsToDetect, bool showCompleted, bool showArchived, bool compactTiles, bool groupByCompletion, bool completedCollapsed, bool enableSwipeToDelete
});




}
/// @nodoc
class _$DisplayConfigCopyWithImpl<$Res>
    implements $DisplayConfigCopyWith<$Res> {
  _$DisplayConfigCopyWithImpl(this._self, this._then);

  final DisplayConfig _self;
  final $Res Function(DisplayConfig) _then;

/// Create a copy of DisplayConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? groupBy = null,Object? sorting = null,Object? problemsToDetect = null,Object? showCompleted = null,Object? showArchived = null,Object? compactTiles = null,Object? groupByCompletion = null,Object? completedCollapsed = null,Object? enableSwipeToDelete = null,}) {
  return _then(_self.copyWith(
groupBy: null == groupBy ? _self.groupBy : groupBy // ignore: cast_nullable_to_non_nullable
as GroupByField,sorting: null == sorting ? _self.sorting : sorting // ignore: cast_nullable_to_non_nullable
as List<SortCriterion>,problemsToDetect: null == problemsToDetect ? _self.problemsToDetect : problemsToDetect // ignore: cast_nullable_to_non_nullable
as List<ProblemType>,showCompleted: null == showCompleted ? _self.showCompleted : showCompleted // ignore: cast_nullable_to_non_nullable
as bool,showArchived: null == showArchived ? _self.showArchived : showArchived // ignore: cast_nullable_to_non_nullable
as bool,compactTiles: null == compactTiles ? _self.compactTiles : compactTiles // ignore: cast_nullable_to_non_nullable
as bool,groupByCompletion: null == groupByCompletion ? _self.groupByCompletion : groupByCompletion // ignore: cast_nullable_to_non_nullable
as bool,completedCollapsed: null == completedCollapsed ? _self.completedCollapsed : completedCollapsed // ignore: cast_nullable_to_non_nullable
as bool,enableSwipeToDelete: null == enableSwipeToDelete ? _self.enableSwipeToDelete : enableSwipeToDelete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DisplayConfig].
extension DisplayConfigPatterns on DisplayConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DisplayConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DisplayConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DisplayConfig value)  $default,){
final _that = this;
switch (_that) {
case _DisplayConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DisplayConfig value)?  $default,){
final _that = this;
switch (_that) {
case _DisplayConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GroupByField groupBy,  List<SortCriterion> sorting,  List<ProblemType> problemsToDetect,  bool showCompleted,  bool showArchived,  bool compactTiles,  bool groupByCompletion,  bool completedCollapsed,  bool enableSwipeToDelete)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DisplayConfig() when $default != null:
return $default(_that.groupBy,_that.sorting,_that.problemsToDetect,_that.showCompleted,_that.showArchived,_that.compactTiles,_that.groupByCompletion,_that.completedCollapsed,_that.enableSwipeToDelete);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GroupByField groupBy,  List<SortCriterion> sorting,  List<ProblemType> problemsToDetect,  bool showCompleted,  bool showArchived,  bool compactTiles,  bool groupByCompletion,  bool completedCollapsed,  bool enableSwipeToDelete)  $default,) {final _that = this;
switch (_that) {
case _DisplayConfig():
return $default(_that.groupBy,_that.sorting,_that.problemsToDetect,_that.showCompleted,_that.showArchived,_that.compactTiles,_that.groupByCompletion,_that.completedCollapsed,_that.enableSwipeToDelete);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GroupByField groupBy,  List<SortCriterion> sorting,  List<ProblemType> problemsToDetect,  bool showCompleted,  bool showArchived,  bool compactTiles,  bool groupByCompletion,  bool completedCollapsed,  bool enableSwipeToDelete)?  $default,) {final _that = this;
switch (_that) {
case _DisplayConfig() when $default != null:
return $default(_that.groupBy,_that.sorting,_that.problemsToDetect,_that.showCompleted,_that.showArchived,_that.compactTiles,_that.groupByCompletion,_that.completedCollapsed,_that.enableSwipeToDelete);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DisplayConfig implements DisplayConfig {
  const _DisplayConfig({this.groupBy = GroupByField.none, final  List<SortCriterion> sorting = const [], final  List<ProblemType> problemsToDetect = const [], this.showCompleted = true, this.showArchived = false, this.compactTiles = false, this.groupByCompletion = false, this.completedCollapsed = true, this.enableSwipeToDelete = false}): _sorting = sorting,_problemsToDetect = problemsToDetect;
  factory _DisplayConfig.fromJson(Map<String, dynamic> json) => _$DisplayConfigFromJson(json);

@override@JsonKey() final  GroupByField groupBy;
 final  List<SortCriterion> _sorting;
@override@JsonKey() List<SortCriterion> get sorting {
  if (_sorting is EqualUnmodifiableListView) return _sorting;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sorting);
}

 final  List<ProblemType> _problemsToDetect;
@override@JsonKey() List<ProblemType> get problemsToDetect {
  if (_problemsToDetect is EqualUnmodifiableListView) return _problemsToDetect;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_problemsToDetect);
}

@override@JsonKey() final  bool showCompleted;
@override@JsonKey() final  bool showArchived;
/// Whether list tiles should use a compact (2-row) layout.
///
/// If false, tiles use the full (3-row) layout.
@override@JsonKey() final  bool compactTiles;
/// Whether to group tasks by completion status (active vs completed)
@override@JsonKey() final  bool groupByCompletion;
/// Whether completed section is collapsed by default
@override@JsonKey() final  bool completedCollapsed;
/// Whether to enable swipe-to-delete on list items
@override@JsonKey() final  bool enableSwipeToDelete;

/// Create a copy of DisplayConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DisplayConfigCopyWith<_DisplayConfig> get copyWith => __$DisplayConfigCopyWithImpl<_DisplayConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DisplayConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DisplayConfig&&(identical(other.groupBy, groupBy) || other.groupBy == groupBy)&&const DeepCollectionEquality().equals(other._sorting, _sorting)&&const DeepCollectionEquality().equals(other._problemsToDetect, _problemsToDetect)&&(identical(other.showCompleted, showCompleted) || other.showCompleted == showCompleted)&&(identical(other.showArchived, showArchived) || other.showArchived == showArchived)&&(identical(other.compactTiles, compactTiles) || other.compactTiles == compactTiles)&&(identical(other.groupByCompletion, groupByCompletion) || other.groupByCompletion == groupByCompletion)&&(identical(other.completedCollapsed, completedCollapsed) || other.completedCollapsed == completedCollapsed)&&(identical(other.enableSwipeToDelete, enableSwipeToDelete) || other.enableSwipeToDelete == enableSwipeToDelete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,groupBy,const DeepCollectionEquality().hash(_sorting),const DeepCollectionEquality().hash(_problemsToDetect),showCompleted,showArchived,compactTiles,groupByCompletion,completedCollapsed,enableSwipeToDelete);

@override
String toString() {
  return 'DisplayConfig(groupBy: $groupBy, sorting: $sorting, problemsToDetect: $problemsToDetect, showCompleted: $showCompleted, showArchived: $showArchived, compactTiles: $compactTiles, groupByCompletion: $groupByCompletion, completedCollapsed: $completedCollapsed, enableSwipeToDelete: $enableSwipeToDelete)';
}


}

/// @nodoc
abstract mixin class _$DisplayConfigCopyWith<$Res> implements $DisplayConfigCopyWith<$Res> {
  factory _$DisplayConfigCopyWith(_DisplayConfig value, $Res Function(_DisplayConfig) _then) = __$DisplayConfigCopyWithImpl;
@override @useResult
$Res call({
 GroupByField groupBy, List<SortCriterion> sorting, List<ProblemType> problemsToDetect, bool showCompleted, bool showArchived, bool compactTiles, bool groupByCompletion, bool completedCollapsed, bool enableSwipeToDelete
});




}
/// @nodoc
class __$DisplayConfigCopyWithImpl<$Res>
    implements _$DisplayConfigCopyWith<$Res> {
  __$DisplayConfigCopyWithImpl(this._self, this._then);

  final _DisplayConfig _self;
  final $Res Function(_DisplayConfig) _then;

/// Create a copy of DisplayConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? groupBy = null,Object? sorting = null,Object? problemsToDetect = null,Object? showCompleted = null,Object? showArchived = null,Object? compactTiles = null,Object? groupByCompletion = null,Object? completedCollapsed = null,Object? enableSwipeToDelete = null,}) {
  return _then(_DisplayConfig(
groupBy: null == groupBy ? _self.groupBy : groupBy // ignore: cast_nullable_to_non_nullable
as GroupByField,sorting: null == sorting ? _self._sorting : sorting // ignore: cast_nullable_to_non_nullable
as List<SortCriterion>,problemsToDetect: null == problemsToDetect ? _self._problemsToDetect : problemsToDetect // ignore: cast_nullable_to_non_nullable
as List<ProblemType>,showCompleted: null == showCompleted ? _self.showCompleted : showCompleted // ignore: cast_nullable_to_non_nullable
as bool,showArchived: null == showArchived ? _self.showArchived : showArchived // ignore: cast_nullable_to_non_nullable
as bool,compactTiles: null == compactTiles ? _self.compactTiles : compactTiles // ignore: cast_nullable_to_non_nullable
as bool,groupByCompletion: null == groupByCompletion ? _self.groupByCompletion : groupByCompletion // ignore: cast_nullable_to_non_nullable
as bool,completedCollapsed: null == completedCollapsed ? _self.completedCollapsed : completedCollapsed // ignore: cast_nullable_to_non_nullable
as bool,enableSwipeToDelete: null == enableSwipeToDelete ? _self.enableSwipeToDelete : enableSwipeToDelete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
