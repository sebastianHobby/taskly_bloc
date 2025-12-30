// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'support_block.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
SupportBlock _$SupportBlockFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'taskStats':
          return TaskStatsBlock.fromJson(
            json
          );
                case 'workflowProgress':
          return WorkflowProgressBlock.fromJson(
            json
          );
                case 'breakdown':
          return BreakdownBlock.fromJson(
            json
          );
                case 'filteredList':
          return FilteredListBlock.fromJson(
            json
          );
                case 'moodCorrelation':
          return MoodCorrelationBlock.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'SupportBlock',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$SupportBlock {



  /// Serializes this SupportBlock to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportBlock);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SupportBlock()';
}


}

/// @nodoc
class $SupportBlockCopyWith<$Res>  {
$SupportBlockCopyWith(SupportBlock _, $Res Function(SupportBlock) __);
}


/// Adds pattern-matching-related methods to [SupportBlock].
extension SupportBlockPatterns on SupportBlock {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TaskStatsBlock value)?  taskStats,TResult Function( WorkflowProgressBlock value)?  workflowProgress,TResult Function( BreakdownBlock value)?  breakdown,TResult Function( FilteredListBlock value)?  filteredList,TResult Function( MoodCorrelationBlock value)?  moodCorrelation,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TaskStatsBlock() when taskStats != null:
return taskStats(_that);case WorkflowProgressBlock() when workflowProgress != null:
return workflowProgress(_that);case BreakdownBlock() when breakdown != null:
return breakdown(_that);case FilteredListBlock() when filteredList != null:
return filteredList(_that);case MoodCorrelationBlock() when moodCorrelation != null:
return moodCorrelation(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TaskStatsBlock value)  taskStats,required TResult Function( WorkflowProgressBlock value)  workflowProgress,required TResult Function( BreakdownBlock value)  breakdown,required TResult Function( FilteredListBlock value)  filteredList,required TResult Function( MoodCorrelationBlock value)  moodCorrelation,}){
final _that = this;
switch (_that) {
case TaskStatsBlock():
return taskStats(_that);case WorkflowProgressBlock():
return workflowProgress(_that);case BreakdownBlock():
return breakdown(_that);case FilteredListBlock():
return filteredList(_that);case MoodCorrelationBlock():
return moodCorrelation(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TaskStatsBlock value)?  taskStats,TResult? Function( WorkflowProgressBlock value)?  workflowProgress,TResult? Function( BreakdownBlock value)?  breakdown,TResult? Function( FilteredListBlock value)?  filteredList,TResult? Function( MoodCorrelationBlock value)?  moodCorrelation,}){
final _that = this;
switch (_that) {
case TaskStatsBlock() when taskStats != null:
return taskStats(_that);case WorkflowProgressBlock() when workflowProgress != null:
return workflowProgress(_that);case BreakdownBlock() when breakdown != null:
return breakdown(_that);case FilteredListBlock() when filteredList != null:
return filteredList(_that);case MoodCorrelationBlock() when moodCorrelation != null:
return moodCorrelation(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( TaskStatType statType,  DateRange? range)?  taskStats,TResult Function()?  workflowProgress,TResult Function( TaskStatType statType,  BreakdownDimension dimension,  DateRange? range,  int maxItems)?  breakdown,TResult Function( String title,  String entityType,  Map<String, dynamic> filterJson,  int maxItems)?  filteredList,TResult Function( TaskStatType statType,  DateRange? range)?  moodCorrelation,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TaskStatsBlock() when taskStats != null:
return taskStats(_that.statType,_that.range);case WorkflowProgressBlock() when workflowProgress != null:
return workflowProgress();case BreakdownBlock() when breakdown != null:
return breakdown(_that.statType,_that.dimension,_that.range,_that.maxItems);case FilteredListBlock() when filteredList != null:
return filteredList(_that.title,_that.entityType,_that.filterJson,_that.maxItems);case MoodCorrelationBlock() when moodCorrelation != null:
return moodCorrelation(_that.statType,_that.range);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( TaskStatType statType,  DateRange? range)  taskStats,required TResult Function()  workflowProgress,required TResult Function( TaskStatType statType,  BreakdownDimension dimension,  DateRange? range,  int maxItems)  breakdown,required TResult Function( String title,  String entityType,  Map<String, dynamic> filterJson,  int maxItems)  filteredList,required TResult Function( TaskStatType statType,  DateRange? range)  moodCorrelation,}) {final _that = this;
switch (_that) {
case TaskStatsBlock():
return taskStats(_that.statType,_that.range);case WorkflowProgressBlock():
return workflowProgress();case BreakdownBlock():
return breakdown(_that.statType,_that.dimension,_that.range,_that.maxItems);case FilteredListBlock():
return filteredList(_that.title,_that.entityType,_that.filterJson,_that.maxItems);case MoodCorrelationBlock():
return moodCorrelation(_that.statType,_that.range);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( TaskStatType statType,  DateRange? range)?  taskStats,TResult? Function()?  workflowProgress,TResult? Function( TaskStatType statType,  BreakdownDimension dimension,  DateRange? range,  int maxItems)?  breakdown,TResult? Function( String title,  String entityType,  Map<String, dynamic> filterJson,  int maxItems)?  filteredList,TResult? Function( TaskStatType statType,  DateRange? range)?  moodCorrelation,}) {final _that = this;
switch (_that) {
case TaskStatsBlock() when taskStats != null:
return taskStats(_that.statType,_that.range);case WorkflowProgressBlock() when workflowProgress != null:
return workflowProgress();case BreakdownBlock() when breakdown != null:
return breakdown(_that.statType,_that.dimension,_that.range,_that.maxItems);case FilteredListBlock() when filteredList != null:
return filteredList(_that.title,_that.entityType,_that.filterJson,_that.maxItems);case MoodCorrelationBlock() when moodCorrelation != null:
return moodCorrelation(_that.statType,_that.range);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class TaskStatsBlock implements SupportBlock {
  const TaskStatsBlock({required this.statType, this.range, final  String? $type}): $type = $type ?? 'taskStats';
  factory TaskStatsBlock.fromJson(Map<String, dynamic> json) => _$TaskStatsBlockFromJson(json);

 final  TaskStatType statType;
 final  DateRange? range;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskStatsBlockCopyWith<TaskStatsBlock> get copyWith => _$TaskStatsBlockCopyWithImpl<TaskStatsBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskStatsBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskStatsBlock&&(identical(other.statType, statType) || other.statType == statType)&&(identical(other.range, range) || other.range == range));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,statType,range);

@override
String toString() {
  return 'SupportBlock.taskStats(statType: $statType, range: $range)';
}


}

/// @nodoc
abstract mixin class $TaskStatsBlockCopyWith<$Res> implements $SupportBlockCopyWith<$Res> {
  factory $TaskStatsBlockCopyWith(TaskStatsBlock value, $Res Function(TaskStatsBlock) _then) = _$TaskStatsBlockCopyWithImpl;
@useResult
$Res call({
 TaskStatType statType, DateRange? range
});


$DateRangeCopyWith<$Res>? get range;

}
/// @nodoc
class _$TaskStatsBlockCopyWithImpl<$Res>
    implements $TaskStatsBlockCopyWith<$Res> {
  _$TaskStatsBlockCopyWithImpl(this._self, this._then);

  final TaskStatsBlock _self;
  final $Res Function(TaskStatsBlock) _then;

/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? statType = null,Object? range = freezed,}) {
  return _then(TaskStatsBlock(
statType: null == statType ? _self.statType : statType // ignore: cast_nullable_to_non_nullable
as TaskStatType,range: freezed == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as DateRange?,
  ));
}

/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DateRangeCopyWith<$Res>? get range {
    if (_self.range == null) {
    return null;
  }

  return $DateRangeCopyWith<$Res>(_self.range!, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class WorkflowProgressBlock implements SupportBlock {
  const WorkflowProgressBlock({final  String? $type}): $type = $type ?? 'workflowProgress';
  factory WorkflowProgressBlock.fromJson(Map<String, dynamic> json) => _$WorkflowProgressBlockFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$WorkflowProgressBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowProgressBlock);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SupportBlock.workflowProgress()';
}


}




/// @nodoc
@JsonSerializable()

class BreakdownBlock implements SupportBlock {
  const BreakdownBlock({required this.statType, required this.dimension, this.range, this.maxItems = 10, final  String? $type}): $type = $type ?? 'breakdown';
  factory BreakdownBlock.fromJson(Map<String, dynamic> json) => _$BreakdownBlockFromJson(json);

 final  TaskStatType statType;
 final  BreakdownDimension dimension;
 final  DateRange? range;
@JsonKey() final  int maxItems;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BreakdownBlockCopyWith<BreakdownBlock> get copyWith => _$BreakdownBlockCopyWithImpl<BreakdownBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BreakdownBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BreakdownBlock&&(identical(other.statType, statType) || other.statType == statType)&&(identical(other.dimension, dimension) || other.dimension == dimension)&&(identical(other.range, range) || other.range == range)&&(identical(other.maxItems, maxItems) || other.maxItems == maxItems));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,statType,dimension,range,maxItems);

@override
String toString() {
  return 'SupportBlock.breakdown(statType: $statType, dimension: $dimension, range: $range, maxItems: $maxItems)';
}


}

/// @nodoc
abstract mixin class $BreakdownBlockCopyWith<$Res> implements $SupportBlockCopyWith<$Res> {
  factory $BreakdownBlockCopyWith(BreakdownBlock value, $Res Function(BreakdownBlock) _then) = _$BreakdownBlockCopyWithImpl;
@useResult
$Res call({
 TaskStatType statType, BreakdownDimension dimension, DateRange? range, int maxItems
});


$DateRangeCopyWith<$Res>? get range;

}
/// @nodoc
class _$BreakdownBlockCopyWithImpl<$Res>
    implements $BreakdownBlockCopyWith<$Res> {
  _$BreakdownBlockCopyWithImpl(this._self, this._then);

  final BreakdownBlock _self;
  final $Res Function(BreakdownBlock) _then;

/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? statType = null,Object? dimension = null,Object? range = freezed,Object? maxItems = null,}) {
  return _then(BreakdownBlock(
statType: null == statType ? _self.statType : statType // ignore: cast_nullable_to_non_nullable
as TaskStatType,dimension: null == dimension ? _self.dimension : dimension // ignore: cast_nullable_to_non_nullable
as BreakdownDimension,range: freezed == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as DateRange?,maxItems: null == maxItems ? _self.maxItems : maxItems // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DateRangeCopyWith<$Res>? get range {
    if (_self.range == null) {
    return null;
  }

  return $DateRangeCopyWith<$Res>(_self.range!, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class FilteredListBlock implements SupportBlock {
  const FilteredListBlock({required this.title, required this.entityType, required final  Map<String, dynamic> filterJson, this.maxItems = 5, final  String? $type}): _filterJson = filterJson,$type = $type ?? 'filteredList';
  factory FilteredListBlock.fromJson(Map<String, dynamic> json) => _$FilteredListBlockFromJson(json);

 final  String title;
 final  String entityType;
 final  Map<String, dynamic> _filterJson;
 Map<String, dynamic> get filterJson {
  if (_filterJson is EqualUnmodifiableMapView) return _filterJson;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_filterJson);
}

@JsonKey() final  int maxItems;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FilteredListBlockCopyWith<FilteredListBlock> get copyWith => _$FilteredListBlockCopyWithImpl<FilteredListBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FilteredListBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FilteredListBlock&&(identical(other.title, title) || other.title == title)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&const DeepCollectionEquality().equals(other._filterJson, _filterJson)&&(identical(other.maxItems, maxItems) || other.maxItems == maxItems));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,entityType,const DeepCollectionEquality().hash(_filterJson),maxItems);

@override
String toString() {
  return 'SupportBlock.filteredList(title: $title, entityType: $entityType, filterJson: $filterJson, maxItems: $maxItems)';
}


}

/// @nodoc
abstract mixin class $FilteredListBlockCopyWith<$Res> implements $SupportBlockCopyWith<$Res> {
  factory $FilteredListBlockCopyWith(FilteredListBlock value, $Res Function(FilteredListBlock) _then) = _$FilteredListBlockCopyWithImpl;
@useResult
$Res call({
 String title, String entityType, Map<String, dynamic> filterJson, int maxItems
});




}
/// @nodoc
class _$FilteredListBlockCopyWithImpl<$Res>
    implements $FilteredListBlockCopyWith<$Res> {
  _$FilteredListBlockCopyWithImpl(this._self, this._then);

  final FilteredListBlock _self;
  final $Res Function(FilteredListBlock) _then;

/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? title = null,Object? entityType = null,Object? filterJson = null,Object? maxItems = null,}) {
  return _then(FilteredListBlock(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String,filterJson: null == filterJson ? _self._filterJson : filterJson // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,maxItems: null == maxItems ? _self.maxItems : maxItems // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class MoodCorrelationBlock implements SupportBlock {
  const MoodCorrelationBlock({required this.statType, this.range, final  String? $type}): $type = $type ?? 'moodCorrelation';
  factory MoodCorrelationBlock.fromJson(Map<String, dynamic> json) => _$MoodCorrelationBlockFromJson(json);

 final  TaskStatType statType;
 final  DateRange? range;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoodCorrelationBlockCopyWith<MoodCorrelationBlock> get copyWith => _$MoodCorrelationBlockCopyWithImpl<MoodCorrelationBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MoodCorrelationBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoodCorrelationBlock&&(identical(other.statType, statType) || other.statType == statType)&&(identical(other.range, range) || other.range == range));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,statType,range);

@override
String toString() {
  return 'SupportBlock.moodCorrelation(statType: $statType, range: $range)';
}


}

/// @nodoc
abstract mixin class $MoodCorrelationBlockCopyWith<$Res> implements $SupportBlockCopyWith<$Res> {
  factory $MoodCorrelationBlockCopyWith(MoodCorrelationBlock value, $Res Function(MoodCorrelationBlock) _then) = _$MoodCorrelationBlockCopyWithImpl;
@useResult
$Res call({
 TaskStatType statType, DateRange? range
});


$DateRangeCopyWith<$Res>? get range;

}
/// @nodoc
class _$MoodCorrelationBlockCopyWithImpl<$Res>
    implements $MoodCorrelationBlockCopyWith<$Res> {
  _$MoodCorrelationBlockCopyWithImpl(this._self, this._then);

  final MoodCorrelationBlock _self;
  final $Res Function(MoodCorrelationBlock) _then;

/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? statType = null,Object? range = freezed,}) {
  return _then(MoodCorrelationBlock(
statType: null == statType ? _self.statType : statType // ignore: cast_nullable_to_non_nullable
as TaskStatType,range: freezed == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as DateRange?,
  ));
}

/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DateRangeCopyWith<$Res>? get range {
    if (_self.range == null) {
    return null;
  }

  return $DateRangeCopyWith<$Res>(_self.range!, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}

// dart format on
