// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analytics_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnalyticsSnapshot {

 String get id; String get entityType; DateTime get snapshotDate; Map<String, dynamic> get metrics; String? get entityId;
/// Create a copy of AnalyticsSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalyticsSnapshotCopyWith<AnalyticsSnapshot> get copyWith => _$AnalyticsSnapshotCopyWithImpl<AnalyticsSnapshot>(this as AnalyticsSnapshot, _$identity);

  /// Serializes this AnalyticsSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalyticsSnapshot&&(identical(other.id, id) || other.id == id)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.snapshotDate, snapshotDate) || other.snapshotDate == snapshotDate)&&const DeepCollectionEquality().equals(other.metrics, metrics)&&(identical(other.entityId, entityId) || other.entityId == entityId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,entityType,snapshotDate,const DeepCollectionEquality().hash(metrics),entityId);

@override
String toString() {
  return 'AnalyticsSnapshot(id: $id, entityType: $entityType, snapshotDate: $snapshotDate, metrics: $metrics, entityId: $entityId)';
}


}

/// @nodoc
abstract mixin class $AnalyticsSnapshotCopyWith<$Res>  {
  factory $AnalyticsSnapshotCopyWith(AnalyticsSnapshot value, $Res Function(AnalyticsSnapshot) _then) = _$AnalyticsSnapshotCopyWithImpl;
@useResult
$Res call({
 String id, String entityType, DateTime snapshotDate, Map<String, dynamic> metrics, String? entityId
});




}
/// @nodoc
class _$AnalyticsSnapshotCopyWithImpl<$Res>
    implements $AnalyticsSnapshotCopyWith<$Res> {
  _$AnalyticsSnapshotCopyWithImpl(this._self, this._then);

  final AnalyticsSnapshot _self;
  final $Res Function(AnalyticsSnapshot) _then;

/// Create a copy of AnalyticsSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? entityType = null,Object? snapshotDate = null,Object? metrics = null,Object? entityId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String,snapshotDate: null == snapshotDate ? _self.snapshotDate : snapshotDate // ignore: cast_nullable_to_non_nullable
as DateTime,metrics: null == metrics ? _self.metrics : metrics // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,entityId: freezed == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalyticsSnapshot].
extension AnalyticsSnapshotPatterns on AnalyticsSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalyticsSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalyticsSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalyticsSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _AnalyticsSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalyticsSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _AnalyticsSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String entityType,  DateTime snapshotDate,  Map<String, dynamic> metrics,  String? entityId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalyticsSnapshot() when $default != null:
return $default(_that.id,_that.entityType,_that.snapshotDate,_that.metrics,_that.entityId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String entityType,  DateTime snapshotDate,  Map<String, dynamic> metrics,  String? entityId)  $default,) {final _that = this;
switch (_that) {
case _AnalyticsSnapshot():
return $default(_that.id,_that.entityType,_that.snapshotDate,_that.metrics,_that.entityId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String entityType,  DateTime snapshotDate,  Map<String, dynamic> metrics,  String? entityId)?  $default,) {final _that = this;
switch (_that) {
case _AnalyticsSnapshot() when $default != null:
return $default(_that.id,_that.entityType,_that.snapshotDate,_that.metrics,_that.entityId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnalyticsSnapshot implements AnalyticsSnapshot {
  const _AnalyticsSnapshot({required this.id, required this.entityType, required this.snapshotDate, required final  Map<String, dynamic> metrics, this.entityId}): _metrics = metrics;
  factory _AnalyticsSnapshot.fromJson(Map<String, dynamic> json) => _$AnalyticsSnapshotFromJson(json);

@override final  String id;
@override final  String entityType;
@override final  DateTime snapshotDate;
 final  Map<String, dynamic> _metrics;
@override Map<String, dynamic> get metrics {
  if (_metrics is EqualUnmodifiableMapView) return _metrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_metrics);
}

@override final  String? entityId;

/// Create a copy of AnalyticsSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalyticsSnapshotCopyWith<_AnalyticsSnapshot> get copyWith => __$AnalyticsSnapshotCopyWithImpl<_AnalyticsSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnalyticsSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalyticsSnapshot&&(identical(other.id, id) || other.id == id)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.snapshotDate, snapshotDate) || other.snapshotDate == snapshotDate)&&const DeepCollectionEquality().equals(other._metrics, _metrics)&&(identical(other.entityId, entityId) || other.entityId == entityId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,entityType,snapshotDate,const DeepCollectionEquality().hash(_metrics),entityId);

@override
String toString() {
  return 'AnalyticsSnapshot(id: $id, entityType: $entityType, snapshotDate: $snapshotDate, metrics: $metrics, entityId: $entityId)';
}


}

/// @nodoc
abstract mixin class _$AnalyticsSnapshotCopyWith<$Res> implements $AnalyticsSnapshotCopyWith<$Res> {
  factory _$AnalyticsSnapshotCopyWith(_AnalyticsSnapshot value, $Res Function(_AnalyticsSnapshot) _then) = __$AnalyticsSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String id, String entityType, DateTime snapshotDate, Map<String, dynamic> metrics, String? entityId
});




}
/// @nodoc
class __$AnalyticsSnapshotCopyWithImpl<$Res>
    implements _$AnalyticsSnapshotCopyWith<$Res> {
  __$AnalyticsSnapshotCopyWithImpl(this._self, this._then);

  final _AnalyticsSnapshot _self;
  final $Res Function(_AnalyticsSnapshot) _then;

/// Create a copy of AnalyticsSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? entityType = null,Object? snapshotDate = null,Object? metrics = null,Object? entityId = freezed,}) {
  return _then(_AnalyticsSnapshot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String,snapshotDate: null == snapshotDate ? _self.snapshotDate : snapshotDate // ignore: cast_nullable_to_non_nullable
as DateTime,metrics: null == metrics ? _self._metrics : metrics // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,entityId: freezed == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
