// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'priority_ranking.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PriorityRanking {

 String get id; String get userId; RankingType get rankingType; List<RankedItem> get items; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of PriorityRanking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriorityRankingCopyWith<PriorityRanking> get copyWith => _$PriorityRankingCopyWithImpl<PriorityRanking>(this as PriorityRanking, _$identity);

  /// Serializes this PriorityRanking to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriorityRanking&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.rankingType, rankingType) || other.rankingType == rankingType)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,rankingType,const DeepCollectionEquality().hash(items),createdAt,updatedAt);

@override
String toString() {
  return 'PriorityRanking(id: $id, userId: $userId, rankingType: $rankingType, items: $items, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PriorityRankingCopyWith<$Res>  {
  factory $PriorityRankingCopyWith(PriorityRanking value, $Res Function(PriorityRanking) _then) = _$PriorityRankingCopyWithImpl;
@useResult
$Res call({
 String id, String userId, RankingType rankingType, List<RankedItem> items, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$PriorityRankingCopyWithImpl<$Res>
    implements $PriorityRankingCopyWith<$Res> {
  _$PriorityRankingCopyWithImpl(this._self, this._then);

  final PriorityRanking _self;
  final $Res Function(PriorityRanking) _then;

/// Create a copy of PriorityRanking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? rankingType = null,Object? items = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,rankingType: null == rankingType ? _self.rankingType : rankingType // ignore: cast_nullable_to_non_nullable
as RankingType,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<RankedItem>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [PriorityRanking].
extension PriorityRankingPatterns on PriorityRanking {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PriorityRanking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PriorityRanking() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PriorityRanking value)  $default,){
final _that = this;
switch (_that) {
case _PriorityRanking():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PriorityRanking value)?  $default,){
final _that = this;
switch (_that) {
case _PriorityRanking() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  RankingType rankingType,  List<RankedItem> items,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PriorityRanking() when $default != null:
return $default(_that.id,_that.userId,_that.rankingType,_that.items,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  RankingType rankingType,  List<RankedItem> items,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PriorityRanking():
return $default(_that.id,_that.userId,_that.rankingType,_that.items,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  RankingType rankingType,  List<RankedItem> items,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PriorityRanking() when $default != null:
return $default(_that.id,_that.userId,_that.rankingType,_that.items,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PriorityRanking implements PriorityRanking {
  const _PriorityRanking({required this.id, required this.userId, required this.rankingType, required final  List<RankedItem> items, required this.createdAt, required this.updatedAt}): _items = items;
  factory _PriorityRanking.fromJson(Map<String, dynamic> json) => _$PriorityRankingFromJson(json);

@override final  String id;
@override final  String userId;
@override final  RankingType rankingType;
 final  List<RankedItem> _items;
@override List<RankedItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of PriorityRanking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriorityRankingCopyWith<_PriorityRanking> get copyWith => __$PriorityRankingCopyWithImpl<_PriorityRanking>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PriorityRankingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PriorityRanking&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.rankingType, rankingType) || other.rankingType == rankingType)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,rankingType,const DeepCollectionEquality().hash(_items),createdAt,updatedAt);

@override
String toString() {
  return 'PriorityRanking(id: $id, userId: $userId, rankingType: $rankingType, items: $items, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PriorityRankingCopyWith<$Res> implements $PriorityRankingCopyWith<$Res> {
  factory _$PriorityRankingCopyWith(_PriorityRanking value, $Res Function(_PriorityRanking) _then) = __$PriorityRankingCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, RankingType rankingType, List<RankedItem> items, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$PriorityRankingCopyWithImpl<$Res>
    implements _$PriorityRankingCopyWith<$Res> {
  __$PriorityRankingCopyWithImpl(this._self, this._then);

  final _PriorityRanking _self;
  final $Res Function(_PriorityRanking) _then;

/// Create a copy of PriorityRanking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? rankingType = null,Object? items = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_PriorityRanking(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,rankingType: null == rankingType ? _self.rankingType : rankingType // ignore: cast_nullable_to_non_nullable
as RankingType,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<RankedItem>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$RankedItem {

 String get id; String get rankingId; String get entityId; RankedEntityType get entityType; int get weight;// 1-10 scale
 int get sortOrder;// Display order
 String get userId; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of RankedItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RankedItemCopyWith<RankedItem> get copyWith => _$RankedItemCopyWithImpl<RankedItem>(this as RankedItem, _$identity);

  /// Serializes this RankedItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RankedItem&&(identical(other.id, id) || other.id == id)&&(identical(other.rankingId, rankingId) || other.rankingId == rankingId)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,rankingId,entityId,entityType,weight,sortOrder,userId,createdAt,updatedAt);

@override
String toString() {
  return 'RankedItem(id: $id, rankingId: $rankingId, entityId: $entityId, entityType: $entityType, weight: $weight, sortOrder: $sortOrder, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $RankedItemCopyWith<$Res>  {
  factory $RankedItemCopyWith(RankedItem value, $Res Function(RankedItem) _then) = _$RankedItemCopyWithImpl;
@useResult
$Res call({
 String id, String rankingId, String entityId, RankedEntityType entityType, int weight, int sortOrder, String userId, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$RankedItemCopyWithImpl<$Res>
    implements $RankedItemCopyWith<$Res> {
  _$RankedItemCopyWithImpl(this._self, this._then);

  final RankedItem _self;
  final $Res Function(RankedItem) _then;

/// Create a copy of RankedItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? rankingId = null,Object? entityId = null,Object? entityType = null,Object? weight = null,Object? sortOrder = null,Object? userId = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rankingId: null == rankingId ? _self.rankingId : rankingId // ignore: cast_nullable_to_non_nullable
as String,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as RankedEntityType,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [RankedItem].
extension RankedItemPatterns on RankedItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RankedItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RankedItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RankedItem value)  $default,){
final _that = this;
switch (_that) {
case _RankedItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RankedItem value)?  $default,){
final _that = this;
switch (_that) {
case _RankedItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String rankingId,  String entityId,  RankedEntityType entityType,  int weight,  int sortOrder,  String userId,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RankedItem() when $default != null:
return $default(_that.id,_that.rankingId,_that.entityId,_that.entityType,_that.weight,_that.sortOrder,_that.userId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String rankingId,  String entityId,  RankedEntityType entityType,  int weight,  int sortOrder,  String userId,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _RankedItem():
return $default(_that.id,_that.rankingId,_that.entityId,_that.entityType,_that.weight,_that.sortOrder,_that.userId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String rankingId,  String entityId,  RankedEntityType entityType,  int weight,  int sortOrder,  String userId,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _RankedItem() when $default != null:
return $default(_that.id,_that.rankingId,_that.entityId,_that.entityType,_that.weight,_that.sortOrder,_that.userId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RankedItem implements RankedItem {
  const _RankedItem({required this.id, required this.rankingId, required this.entityId, required this.entityType, required this.weight, required this.sortOrder, required this.userId, required this.createdAt, required this.updatedAt});
  factory _RankedItem.fromJson(Map<String, dynamic> json) => _$RankedItemFromJson(json);

@override final  String id;
@override final  String rankingId;
@override final  String entityId;
@override final  RankedEntityType entityType;
@override final  int weight;
// 1-10 scale
@override final  int sortOrder;
// Display order
@override final  String userId;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of RankedItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RankedItemCopyWith<_RankedItem> get copyWith => __$RankedItemCopyWithImpl<_RankedItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RankedItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RankedItem&&(identical(other.id, id) || other.id == id)&&(identical(other.rankingId, rankingId) || other.rankingId == rankingId)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,rankingId,entityId,entityType,weight,sortOrder,userId,createdAt,updatedAt);

@override
String toString() {
  return 'RankedItem(id: $id, rankingId: $rankingId, entityId: $entityId, entityType: $entityType, weight: $weight, sortOrder: $sortOrder, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RankedItemCopyWith<$Res> implements $RankedItemCopyWith<$Res> {
  factory _$RankedItemCopyWith(_RankedItem value, $Res Function(_RankedItem) _then) = __$RankedItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String rankingId, String entityId, RankedEntityType entityType, int weight, int sortOrder, String userId, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$RankedItemCopyWithImpl<$Res>
    implements _$RankedItemCopyWith<$Res> {
  __$RankedItemCopyWithImpl(this._self, this._then);

  final _RankedItem _self;
  final $Res Function(_RankedItem) _then;

/// Create a copy of RankedItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? rankingId = null,Object? entityId = null,Object? entityType = null,Object? weight = null,Object? sortOrder = null,Object? userId = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_RankedItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rankingId: null == rankingId ? _self.rankingId : rankingId // ignore: cast_nullable_to_non_nullable
as String,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as RankedEntityType,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as int,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
