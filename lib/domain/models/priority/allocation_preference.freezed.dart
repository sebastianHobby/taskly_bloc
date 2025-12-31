// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'allocation_preference.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AllocationPreference {

 String get id; String get userId; DateTime get createdAt; DateTime get updatedAt; AllocationStrategyType get strategyType; double get urgencyInfluence;// For urgency_weighted (0-1)
 int get minimumTasksPerCategory;// For minimum_viable
 int get topNCategories;// For top_categories
 int get dailyTaskLimit;// Maximum focus tasks per day
 bool get showExcludedUrgentWarning;// Show urgent task warnings
 int get urgencyThresholdDays;
/// Create a copy of AllocationPreference
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AllocationPreferenceCopyWith<AllocationPreference> get copyWith => _$AllocationPreferenceCopyWithImpl<AllocationPreference>(this as AllocationPreference, _$identity);

  /// Serializes this AllocationPreference to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AllocationPreference&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.strategyType, strategyType) || other.strategyType == strategyType)&&(identical(other.urgencyInfluence, urgencyInfluence) || other.urgencyInfluence == urgencyInfluence)&&(identical(other.minimumTasksPerCategory, minimumTasksPerCategory) || other.minimumTasksPerCategory == minimumTasksPerCategory)&&(identical(other.topNCategories, topNCategories) || other.topNCategories == topNCategories)&&(identical(other.dailyTaskLimit, dailyTaskLimit) || other.dailyTaskLimit == dailyTaskLimit)&&(identical(other.showExcludedUrgentWarning, showExcludedUrgentWarning) || other.showExcludedUrgentWarning == showExcludedUrgentWarning)&&(identical(other.urgencyThresholdDays, urgencyThresholdDays) || other.urgencyThresholdDays == urgencyThresholdDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,createdAt,updatedAt,strategyType,urgencyInfluence,minimumTasksPerCategory,topNCategories,dailyTaskLimit,showExcludedUrgentWarning,urgencyThresholdDays);

@override
String toString() {
  return 'AllocationPreference(id: $id, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, strategyType: $strategyType, urgencyInfluence: $urgencyInfluence, minimumTasksPerCategory: $minimumTasksPerCategory, topNCategories: $topNCategories, dailyTaskLimit: $dailyTaskLimit, showExcludedUrgentWarning: $showExcludedUrgentWarning, urgencyThresholdDays: $urgencyThresholdDays)';
}


}

/// @nodoc
abstract mixin class $AllocationPreferenceCopyWith<$Res>  {
  factory $AllocationPreferenceCopyWith(AllocationPreference value, $Res Function(AllocationPreference) _then) = _$AllocationPreferenceCopyWithImpl;
@useResult
$Res call({
 String id, String userId, DateTime createdAt, DateTime updatedAt, AllocationStrategyType strategyType, double urgencyInfluence, int minimumTasksPerCategory, int topNCategories, int dailyTaskLimit, bool showExcludedUrgentWarning, int urgencyThresholdDays
});




}
/// @nodoc
class _$AllocationPreferenceCopyWithImpl<$Res>
    implements $AllocationPreferenceCopyWith<$Res> {
  _$AllocationPreferenceCopyWithImpl(this._self, this._then);

  final AllocationPreference _self;
  final $Res Function(AllocationPreference) _then;

/// Create a copy of AllocationPreference
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? createdAt = null,Object? updatedAt = null,Object? strategyType = null,Object? urgencyInfluence = null,Object? minimumTasksPerCategory = null,Object? topNCategories = null,Object? dailyTaskLimit = null,Object? showExcludedUrgentWarning = null,Object? urgencyThresholdDays = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,strategyType: null == strategyType ? _self.strategyType : strategyType // ignore: cast_nullable_to_non_nullable
as AllocationStrategyType,urgencyInfluence: null == urgencyInfluence ? _self.urgencyInfluence : urgencyInfluence // ignore: cast_nullable_to_non_nullable
as double,minimumTasksPerCategory: null == minimumTasksPerCategory ? _self.minimumTasksPerCategory : minimumTasksPerCategory // ignore: cast_nullable_to_non_nullable
as int,topNCategories: null == topNCategories ? _self.topNCategories : topNCategories // ignore: cast_nullable_to_non_nullable
as int,dailyTaskLimit: null == dailyTaskLimit ? _self.dailyTaskLimit : dailyTaskLimit // ignore: cast_nullable_to_non_nullable
as int,showExcludedUrgentWarning: null == showExcludedUrgentWarning ? _self.showExcludedUrgentWarning : showExcludedUrgentWarning // ignore: cast_nullable_to_non_nullable
as bool,urgencyThresholdDays: null == urgencyThresholdDays ? _self.urgencyThresholdDays : urgencyThresholdDays // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AllocationPreference].
extension AllocationPreferencePatterns on AllocationPreference {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AllocationPreference value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AllocationPreference() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AllocationPreference value)  $default,){
final _that = this;
switch (_that) {
case _AllocationPreference():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AllocationPreference value)?  $default,){
final _that = this;
switch (_that) {
case _AllocationPreference() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  DateTime createdAt,  DateTime updatedAt,  AllocationStrategyType strategyType,  double urgencyInfluence,  int minimumTasksPerCategory,  int topNCategories,  int dailyTaskLimit,  bool showExcludedUrgentWarning,  int urgencyThresholdDays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AllocationPreference() when $default != null:
return $default(_that.id,_that.userId,_that.createdAt,_that.updatedAt,_that.strategyType,_that.urgencyInfluence,_that.minimumTasksPerCategory,_that.topNCategories,_that.dailyTaskLimit,_that.showExcludedUrgentWarning,_that.urgencyThresholdDays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  DateTime createdAt,  DateTime updatedAt,  AllocationStrategyType strategyType,  double urgencyInfluence,  int minimumTasksPerCategory,  int topNCategories,  int dailyTaskLimit,  bool showExcludedUrgentWarning,  int urgencyThresholdDays)  $default,) {final _that = this;
switch (_that) {
case _AllocationPreference():
return $default(_that.id,_that.userId,_that.createdAt,_that.updatedAt,_that.strategyType,_that.urgencyInfluence,_that.minimumTasksPerCategory,_that.topNCategories,_that.dailyTaskLimit,_that.showExcludedUrgentWarning,_that.urgencyThresholdDays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  DateTime createdAt,  DateTime updatedAt,  AllocationStrategyType strategyType,  double urgencyInfluence,  int minimumTasksPerCategory,  int topNCategories,  int dailyTaskLimit,  bool showExcludedUrgentWarning,  int urgencyThresholdDays)?  $default,) {final _that = this;
switch (_that) {
case _AllocationPreference() when $default != null:
return $default(_that.id,_that.userId,_that.createdAt,_that.updatedAt,_that.strategyType,_that.urgencyInfluence,_that.minimumTasksPerCategory,_that.topNCategories,_that.dailyTaskLimit,_that.showExcludedUrgentWarning,_that.urgencyThresholdDays);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AllocationPreference implements AllocationPreference {
  const _AllocationPreference({required this.id, required this.userId, required this.createdAt, required this.updatedAt, this.strategyType = AllocationStrategyType.proportional, this.urgencyInfluence = 0.4, this.minimumTasksPerCategory = 1, this.topNCategories = 3, this.dailyTaskLimit = 10, this.showExcludedUrgentWarning = true, this.urgencyThresholdDays = 3});
  factory _AllocationPreference.fromJson(Map<String, dynamic> json) => _$AllocationPreferenceFromJson(json);

@override final  String id;
@override final  String userId;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override@JsonKey() final  AllocationStrategyType strategyType;
@override@JsonKey() final  double urgencyInfluence;
// For urgency_weighted (0-1)
@override@JsonKey() final  int minimumTasksPerCategory;
// For minimum_viable
@override@JsonKey() final  int topNCategories;
// For top_categories
@override@JsonKey() final  int dailyTaskLimit;
// Maximum focus tasks per day
@override@JsonKey() final  bool showExcludedUrgentWarning;
// Show urgent task warnings
@override@JsonKey() final  int urgencyThresholdDays;

/// Create a copy of AllocationPreference
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AllocationPreferenceCopyWith<_AllocationPreference> get copyWith => __$AllocationPreferenceCopyWithImpl<_AllocationPreference>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AllocationPreferenceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AllocationPreference&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.strategyType, strategyType) || other.strategyType == strategyType)&&(identical(other.urgencyInfluence, urgencyInfluence) || other.urgencyInfluence == urgencyInfluence)&&(identical(other.minimumTasksPerCategory, minimumTasksPerCategory) || other.minimumTasksPerCategory == minimumTasksPerCategory)&&(identical(other.topNCategories, topNCategories) || other.topNCategories == topNCategories)&&(identical(other.dailyTaskLimit, dailyTaskLimit) || other.dailyTaskLimit == dailyTaskLimit)&&(identical(other.showExcludedUrgentWarning, showExcludedUrgentWarning) || other.showExcludedUrgentWarning == showExcludedUrgentWarning)&&(identical(other.urgencyThresholdDays, urgencyThresholdDays) || other.urgencyThresholdDays == urgencyThresholdDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,createdAt,updatedAt,strategyType,urgencyInfluence,minimumTasksPerCategory,topNCategories,dailyTaskLimit,showExcludedUrgentWarning,urgencyThresholdDays);

@override
String toString() {
  return 'AllocationPreference(id: $id, userId: $userId, createdAt: $createdAt, updatedAt: $updatedAt, strategyType: $strategyType, urgencyInfluence: $urgencyInfluence, minimumTasksPerCategory: $minimumTasksPerCategory, topNCategories: $topNCategories, dailyTaskLimit: $dailyTaskLimit, showExcludedUrgentWarning: $showExcludedUrgentWarning, urgencyThresholdDays: $urgencyThresholdDays)';
}


}

/// @nodoc
abstract mixin class _$AllocationPreferenceCopyWith<$Res> implements $AllocationPreferenceCopyWith<$Res> {
  factory _$AllocationPreferenceCopyWith(_AllocationPreference value, $Res Function(_AllocationPreference) _then) = __$AllocationPreferenceCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, DateTime createdAt, DateTime updatedAt, AllocationStrategyType strategyType, double urgencyInfluence, int minimumTasksPerCategory, int topNCategories, int dailyTaskLimit, bool showExcludedUrgentWarning, int urgencyThresholdDays
});




}
/// @nodoc
class __$AllocationPreferenceCopyWithImpl<$Res>
    implements _$AllocationPreferenceCopyWith<$Res> {
  __$AllocationPreferenceCopyWithImpl(this._self, this._then);

  final _AllocationPreference _self;
  final $Res Function(_AllocationPreference) _then;

/// Create a copy of AllocationPreference
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? createdAt = null,Object? updatedAt = null,Object? strategyType = null,Object? urgencyInfluence = null,Object? minimumTasksPerCategory = null,Object? topNCategories = null,Object? dailyTaskLimit = null,Object? showExcludedUrgentWarning = null,Object? urgencyThresholdDays = null,}) {
  return _then(_AllocationPreference(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,strategyType: null == strategyType ? _self.strategyType : strategyType // ignore: cast_nullable_to_non_nullable
as AllocationStrategyType,urgencyInfluence: null == urgencyInfluence ? _self.urgencyInfluence : urgencyInfluence // ignore: cast_nullable_to_non_nullable
as double,minimumTasksPerCategory: null == minimumTasksPerCategory ? _self.minimumTasksPerCategory : minimumTasksPerCategory // ignore: cast_nullable_to_non_nullable
as int,topNCategories: null == topNCategories ? _self.topNCategories : topNCategories // ignore: cast_nullable_to_non_nullable
as int,dailyTaskLimit: null == dailyTaskLimit ? _self.dailyTaskLimit : dailyTaskLimit // ignore: cast_nullable_to_non_nullable
as int,showExcludedUrgentWarning: null == showExcludedUrgentWarning ? _self.showExcludedUrgentWarning : showExcludedUrgentWarning // ignore: cast_nullable_to_non_nullable
as bool,urgencyThresholdDays: null == urgencyThresholdDays ? _self.urgencyThresholdDays : urgencyThresholdDays // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
