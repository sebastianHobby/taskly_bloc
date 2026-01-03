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
        switch (json['type']) {
                  case 'workflowProgress':
          return WorkflowProgressBlock.fromJson(
            json
          );
                case 'quickActions':
          return QuickActionsBlock.fromJson(
            json
          );
                case 'contextSummary':
          return ContextSummaryBlock.fromJson(
            json
          );
                case 'relatedEntities':
          return RelatedEntitiesBlock.fromJson(
            json
          );
                case 'stats':
          return StatsBlock.fromJson(
            json
          );
                case 'problemSummary':
          return ProblemSummaryBlock.fromJson(
            json
          );
                case 'emptyState':
          return EmptyStateBlock.fromJson(
            json
          );
                case 'entityHeader':
          return EntityHeaderBlock.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'SupportBlock',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$SupportBlock {

 int get order;
/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportBlockCopyWith<SupportBlock> get copyWith => _$SupportBlockCopyWithImpl<SupportBlock>(this as SupportBlock, _$identity);

  /// Serializes this SupportBlock to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportBlock&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,order);

@override
String toString() {
  return 'SupportBlock(order: $order)';
}


}

/// @nodoc
abstract mixin class $SupportBlockCopyWith<$Res>  {
  factory $SupportBlockCopyWith(SupportBlock value, $Res Function(SupportBlock) _then) = _$SupportBlockCopyWithImpl;
@useResult
$Res call({
 int order
});




}
/// @nodoc
class _$SupportBlockCopyWithImpl<$Res>
    implements $SupportBlockCopyWith<$Res> {
  _$SupportBlockCopyWithImpl(this._self, this._then);

  final SupportBlock _self;
  final $Res Function(SupportBlock) _then;

/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? order = null,}) {
  return _then(_self.copyWith(
order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WorkflowProgressBlock value)?  workflowProgress,TResult Function( QuickActionsBlock value)?  quickActions,TResult Function( ContextSummaryBlock value)?  contextSummary,TResult Function( RelatedEntitiesBlock value)?  relatedEntities,TResult Function( StatsBlock value)?  stats,TResult Function( ProblemSummaryBlock value)?  problemSummary,TResult Function( EmptyStateBlock value)?  emptyState,TResult Function( EntityHeaderBlock value)?  entityHeader,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WorkflowProgressBlock() when workflowProgress != null:
return workflowProgress(_that);case QuickActionsBlock() when quickActions != null:
return quickActions(_that);case ContextSummaryBlock() when contextSummary != null:
return contextSummary(_that);case RelatedEntitiesBlock() when relatedEntities != null:
return relatedEntities(_that);case StatsBlock() when stats != null:
return stats(_that);case ProblemSummaryBlock() when problemSummary != null:
return problemSummary(_that);case EmptyStateBlock() when emptyState != null:
return emptyState(_that);case EntityHeaderBlock() when entityHeader != null:
return entityHeader(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WorkflowProgressBlock value)  workflowProgress,required TResult Function( QuickActionsBlock value)  quickActions,required TResult Function( ContextSummaryBlock value)  contextSummary,required TResult Function( RelatedEntitiesBlock value)  relatedEntities,required TResult Function( StatsBlock value)  stats,required TResult Function( ProblemSummaryBlock value)  problemSummary,required TResult Function( EmptyStateBlock value)  emptyState,required TResult Function( EntityHeaderBlock value)  entityHeader,}){
final _that = this;
switch (_that) {
case WorkflowProgressBlock():
return workflowProgress(_that);case QuickActionsBlock():
return quickActions(_that);case ContextSummaryBlock():
return contextSummary(_that);case RelatedEntitiesBlock():
return relatedEntities(_that);case StatsBlock():
return stats(_that);case ProblemSummaryBlock():
return problemSummary(_that);case EmptyStateBlock():
return emptyState(_that);case EntityHeaderBlock():
return entityHeader(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WorkflowProgressBlock value)?  workflowProgress,TResult? Function( QuickActionsBlock value)?  quickActions,TResult? Function( ContextSummaryBlock value)?  contextSummary,TResult? Function( RelatedEntitiesBlock value)?  relatedEntities,TResult? Function( StatsBlock value)?  stats,TResult? Function( ProblemSummaryBlock value)?  problemSummary,TResult? Function( EmptyStateBlock value)?  emptyState,TResult? Function( EntityHeaderBlock value)?  entityHeader,}){
final _that = this;
switch (_that) {
case WorkflowProgressBlock() when workflowProgress != null:
return workflowProgress(_that);case QuickActionsBlock() when quickActions != null:
return quickActions(_that);case ContextSummaryBlock() when contextSummary != null:
return contextSummary(_that);case RelatedEntitiesBlock() when relatedEntities != null:
return relatedEntities(_that);case StatsBlock() when stats != null:
return stats(_that);case ProblemSummaryBlock() when problemSummary != null:
return problemSummary(_that);case EmptyStateBlock() when emptyState != null:
return emptyState(_that);case EntityHeaderBlock() when entityHeader != null:
return entityHeader(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int order)?  workflowProgress,TResult Function( List<QuickAction> actions,  int order)?  quickActions,TResult Function( String? title,  bool showDescription,  bool showMetadata,  int order)?  contextSummary,TResult Function( List<String> entityTypes,  int maxItems,  int order)?  relatedEntities,TResult Function( List<StatConfig> stats,  int order)?  stats,TResult Function( List<String>? problemTypes,  bool showCount,  bool showList,  int maxListItems,  String? title,  int order)?  problemSummary,TResult Function( String message,  String? icon,  String? actionLabel,  String? actionRoute,  int order)?  emptyState,TResult Function( String entityType,  String entityId,  bool showCheckbox,  bool showMetadata,  int order)?  entityHeader,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WorkflowProgressBlock() when workflowProgress != null:
return workflowProgress(_that.order);case QuickActionsBlock() when quickActions != null:
return quickActions(_that.actions,_that.order);case ContextSummaryBlock() when contextSummary != null:
return contextSummary(_that.title,_that.showDescription,_that.showMetadata,_that.order);case RelatedEntitiesBlock() when relatedEntities != null:
return relatedEntities(_that.entityTypes,_that.maxItems,_that.order);case StatsBlock() when stats != null:
return stats(_that.stats,_that.order);case ProblemSummaryBlock() when problemSummary != null:
return problemSummary(_that.problemTypes,_that.showCount,_that.showList,_that.maxListItems,_that.title,_that.order);case EmptyStateBlock() when emptyState != null:
return emptyState(_that.message,_that.icon,_that.actionLabel,_that.actionRoute,_that.order);case EntityHeaderBlock() when entityHeader != null:
return entityHeader(_that.entityType,_that.entityId,_that.showCheckbox,_that.showMetadata,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int order)  workflowProgress,required TResult Function( List<QuickAction> actions,  int order)  quickActions,required TResult Function( String? title,  bool showDescription,  bool showMetadata,  int order)  contextSummary,required TResult Function( List<String> entityTypes,  int maxItems,  int order)  relatedEntities,required TResult Function( List<StatConfig> stats,  int order)  stats,required TResult Function( List<String>? problemTypes,  bool showCount,  bool showList,  int maxListItems,  String? title,  int order)  problemSummary,required TResult Function( String message,  String? icon,  String? actionLabel,  String? actionRoute,  int order)  emptyState,required TResult Function( String entityType,  String entityId,  bool showCheckbox,  bool showMetadata,  int order)  entityHeader,}) {final _that = this;
switch (_that) {
case WorkflowProgressBlock():
return workflowProgress(_that.order);case QuickActionsBlock():
return quickActions(_that.actions,_that.order);case ContextSummaryBlock():
return contextSummary(_that.title,_that.showDescription,_that.showMetadata,_that.order);case RelatedEntitiesBlock():
return relatedEntities(_that.entityTypes,_that.maxItems,_that.order);case StatsBlock():
return stats(_that.stats,_that.order);case ProblemSummaryBlock():
return problemSummary(_that.problemTypes,_that.showCount,_that.showList,_that.maxListItems,_that.title,_that.order);case EmptyStateBlock():
return emptyState(_that.message,_that.icon,_that.actionLabel,_that.actionRoute,_that.order);case EntityHeaderBlock():
return entityHeader(_that.entityType,_that.entityId,_that.showCheckbox,_that.showMetadata,_that.order);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int order)?  workflowProgress,TResult? Function( List<QuickAction> actions,  int order)?  quickActions,TResult? Function( String? title,  bool showDescription,  bool showMetadata,  int order)?  contextSummary,TResult? Function( List<String> entityTypes,  int maxItems,  int order)?  relatedEntities,TResult? Function( List<StatConfig> stats,  int order)?  stats,TResult? Function( List<String>? problemTypes,  bool showCount,  bool showList,  int maxListItems,  String? title,  int order)?  problemSummary,TResult? Function( String message,  String? icon,  String? actionLabel,  String? actionRoute,  int order)?  emptyState,TResult? Function( String entityType,  String entityId,  bool showCheckbox,  bool showMetadata,  int order)?  entityHeader,}) {final _that = this;
switch (_that) {
case WorkflowProgressBlock() when workflowProgress != null:
return workflowProgress(_that.order);case QuickActionsBlock() when quickActions != null:
return quickActions(_that.actions,_that.order);case ContextSummaryBlock() when contextSummary != null:
return contextSummary(_that.title,_that.showDescription,_that.showMetadata,_that.order);case RelatedEntitiesBlock() when relatedEntities != null:
return relatedEntities(_that.entityTypes,_that.maxItems,_that.order);case StatsBlock() when stats != null:
return stats(_that.stats,_that.order);case ProblemSummaryBlock() when problemSummary != null:
return problemSummary(_that.problemTypes,_that.showCount,_that.showList,_that.maxListItems,_that.title,_that.order);case EmptyStateBlock() when emptyState != null:
return emptyState(_that.message,_that.icon,_that.actionLabel,_that.actionRoute,_that.order);case EntityHeaderBlock() when entityHeader != null:
return entityHeader(_that.entityType,_that.entityId,_that.showCheckbox,_that.showMetadata,_that.order);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class WorkflowProgressBlock implements SupportBlock {
  const WorkflowProgressBlock({this.order = 0, final  String? $type}): $type = $type ?? 'workflowProgress';
  factory WorkflowProgressBlock.fromJson(Map<String, dynamic> json) => _$WorkflowProgressBlockFromJson(json);

@override@JsonKey() final  int order;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkflowProgressBlockCopyWith<WorkflowProgressBlock> get copyWith => _$WorkflowProgressBlockCopyWithImpl<WorkflowProgressBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkflowProgressBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowProgressBlock&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,order);

@override
String toString() {
  return 'SupportBlock.workflowProgress(order: $order)';
}


}

/// @nodoc
abstract mixin class $WorkflowProgressBlockCopyWith<$Res> implements $SupportBlockCopyWith<$Res> {
  factory $WorkflowProgressBlockCopyWith(WorkflowProgressBlock value, $Res Function(WorkflowProgressBlock) _then) = _$WorkflowProgressBlockCopyWithImpl;
@override @useResult
$Res call({
 int order
});




}
/// @nodoc
class _$WorkflowProgressBlockCopyWithImpl<$Res>
    implements $WorkflowProgressBlockCopyWith<$Res> {
  _$WorkflowProgressBlockCopyWithImpl(this._self, this._then);

  final WorkflowProgressBlock _self;
  final $Res Function(WorkflowProgressBlock) _then;

/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? order = null,}) {
  return _then(WorkflowProgressBlock(
order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class QuickActionsBlock implements SupportBlock {
  const QuickActionsBlock({required final  List<QuickAction> actions, this.order = 0, final  String? $type}): _actions = actions,$type = $type ?? 'quickActions';
  factory QuickActionsBlock.fromJson(Map<String, dynamic> json) => _$QuickActionsBlockFromJson(json);

 final  List<QuickAction> _actions;
 List<QuickAction> get actions {
  if (_actions is EqualUnmodifiableListView) return _actions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_actions);
}

@override@JsonKey() final  int order;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuickActionsBlockCopyWith<QuickActionsBlock> get copyWith => _$QuickActionsBlockCopyWithImpl<QuickActionsBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuickActionsBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuickActionsBlock&&const DeepCollectionEquality().equals(other._actions, _actions)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_actions),order);

@override
String toString() {
  return 'SupportBlock.quickActions(actions: $actions, order: $order)';
}


}

/// @nodoc
abstract mixin class $QuickActionsBlockCopyWith<$Res> implements $SupportBlockCopyWith<$Res> {
  factory $QuickActionsBlockCopyWith(QuickActionsBlock value, $Res Function(QuickActionsBlock) _then) = _$QuickActionsBlockCopyWithImpl;
@override @useResult
$Res call({
 List<QuickAction> actions, int order
});




}
/// @nodoc
class _$QuickActionsBlockCopyWithImpl<$Res>
    implements $QuickActionsBlockCopyWith<$Res> {
  _$QuickActionsBlockCopyWithImpl(this._self, this._then);

  final QuickActionsBlock _self;
  final $Res Function(QuickActionsBlock) _then;

/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? actions = null,Object? order = null,}) {
  return _then(QuickActionsBlock(
actions: null == actions ? _self._actions : actions // ignore: cast_nullable_to_non_nullable
as List<QuickAction>,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ContextSummaryBlock implements SupportBlock {
  const ContextSummaryBlock({this.title, this.showDescription = true, this.showMetadata = true, this.order = 0, final  String? $type}): $type = $type ?? 'contextSummary';
  factory ContextSummaryBlock.fromJson(Map<String, dynamic> json) => _$ContextSummaryBlockFromJson(json);

 final  String? title;
@JsonKey() final  bool showDescription;
@JsonKey() final  bool showMetadata;
@override@JsonKey() final  int order;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ContextSummaryBlockCopyWith<ContextSummaryBlock> get copyWith => _$ContextSummaryBlockCopyWithImpl<ContextSummaryBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ContextSummaryBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ContextSummaryBlock&&(identical(other.title, title) || other.title == title)&&(identical(other.showDescription, showDescription) || other.showDescription == showDescription)&&(identical(other.showMetadata, showMetadata) || other.showMetadata == showMetadata)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,showDescription,showMetadata,order);

@override
String toString() {
  return 'SupportBlock.contextSummary(title: $title, showDescription: $showDescription, showMetadata: $showMetadata, order: $order)';
}


}

/// @nodoc
abstract mixin class $ContextSummaryBlockCopyWith<$Res> implements $SupportBlockCopyWith<$Res> {
  factory $ContextSummaryBlockCopyWith(ContextSummaryBlock value, $Res Function(ContextSummaryBlock) _then) = _$ContextSummaryBlockCopyWithImpl;
@override @useResult
$Res call({
 String? title, bool showDescription, bool showMetadata, int order
});




}
/// @nodoc
class _$ContextSummaryBlockCopyWithImpl<$Res>
    implements $ContextSummaryBlockCopyWith<$Res> {
  _$ContextSummaryBlockCopyWithImpl(this._self, this._then);

  final ContextSummaryBlock _self;
  final $Res Function(ContextSummaryBlock) _then;

/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? showDescription = null,Object? showMetadata = null,Object? order = null,}) {
  return _then(ContextSummaryBlock(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,showDescription: null == showDescription ? _self.showDescription : showDescription // ignore: cast_nullable_to_non_nullable
as bool,showMetadata: null == showMetadata ? _self.showMetadata : showMetadata // ignore: cast_nullable_to_non_nullable
as bool,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class RelatedEntitiesBlock implements SupportBlock {
  const RelatedEntitiesBlock({required final  List<String> entityTypes, this.maxItems = 5, this.order = 0, final  String? $type}): _entityTypes = entityTypes,$type = $type ?? 'relatedEntities';
  factory RelatedEntitiesBlock.fromJson(Map<String, dynamic> json) => _$RelatedEntitiesBlockFromJson(json);

 final  List<String> _entityTypes;
 List<String> get entityTypes {
  if (_entityTypes is EqualUnmodifiableListView) return _entityTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entityTypes);
}

@JsonKey() final  int maxItems;
@override@JsonKey() final  int order;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelatedEntitiesBlockCopyWith<RelatedEntitiesBlock> get copyWith => _$RelatedEntitiesBlockCopyWithImpl<RelatedEntitiesBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RelatedEntitiesBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelatedEntitiesBlock&&const DeepCollectionEquality().equals(other._entityTypes, _entityTypes)&&(identical(other.maxItems, maxItems) || other.maxItems == maxItems)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_entityTypes),maxItems,order);

@override
String toString() {
  return 'SupportBlock.relatedEntities(entityTypes: $entityTypes, maxItems: $maxItems, order: $order)';
}


}

/// @nodoc
abstract mixin class $RelatedEntitiesBlockCopyWith<$Res> implements $SupportBlockCopyWith<$Res> {
  factory $RelatedEntitiesBlockCopyWith(RelatedEntitiesBlock value, $Res Function(RelatedEntitiesBlock) _then) = _$RelatedEntitiesBlockCopyWithImpl;
@override @useResult
$Res call({
 List<String> entityTypes, int maxItems, int order
});




}
/// @nodoc
class _$RelatedEntitiesBlockCopyWithImpl<$Res>
    implements $RelatedEntitiesBlockCopyWith<$Res> {
  _$RelatedEntitiesBlockCopyWithImpl(this._self, this._then);

  final RelatedEntitiesBlock _self;
  final $Res Function(RelatedEntitiesBlock) _then;

/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entityTypes = null,Object? maxItems = null,Object? order = null,}) {
  return _then(RelatedEntitiesBlock(
entityTypes: null == entityTypes ? _self._entityTypes : entityTypes // ignore: cast_nullable_to_non_nullable
as List<String>,maxItems: null == maxItems ? _self.maxItems : maxItems // ignore: cast_nullable_to_non_nullable
as int,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class StatsBlock implements SupportBlock {
  const StatsBlock({required final  List<StatConfig> stats, this.order = 0, final  String? $type}): _stats = stats,$type = $type ?? 'stats';
  factory StatsBlock.fromJson(Map<String, dynamic> json) => _$StatsBlockFromJson(json);

 final  List<StatConfig> _stats;
 List<StatConfig> get stats {
  if (_stats is EqualUnmodifiableListView) return _stats;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stats);
}

@override@JsonKey() final  int order;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatsBlockCopyWith<StatsBlock> get copyWith => _$StatsBlockCopyWithImpl<StatsBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatsBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatsBlock&&const DeepCollectionEquality().equals(other._stats, _stats)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_stats),order);

@override
String toString() {
  return 'SupportBlock.stats(stats: $stats, order: $order)';
}


}

/// @nodoc
abstract mixin class $StatsBlockCopyWith<$Res> implements $SupportBlockCopyWith<$Res> {
  factory $StatsBlockCopyWith(StatsBlock value, $Res Function(StatsBlock) _then) = _$StatsBlockCopyWithImpl;
@override @useResult
$Res call({
 List<StatConfig> stats, int order
});




}
/// @nodoc
class _$StatsBlockCopyWithImpl<$Res>
    implements $StatsBlockCopyWith<$Res> {
  _$StatsBlockCopyWithImpl(this._self, this._then);

  final StatsBlock _self;
  final $Res Function(StatsBlock) _then;

/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stats = null,Object? order = null,}) {
  return _then(StatsBlock(
stats: null == stats ? _self._stats : stats // ignore: cast_nullable_to_non_nullable
as List<StatConfig>,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ProblemSummaryBlock implements SupportBlock {
  const ProblemSummaryBlock({final  List<String>? problemTypes, this.showCount = true, this.showList = false, this.maxListItems = 5, this.title, this.order = 0, final  String? $type}): _problemTypes = problemTypes,$type = $type ?? 'problemSummary';
  factory ProblemSummaryBlock.fromJson(Map<String, dynamic> json) => _$ProblemSummaryBlockFromJson(json);

 final  List<String>? _problemTypes;
 List<String>? get problemTypes {
  final value = _problemTypes;
  if (value == null) return null;
  if (_problemTypes is EqualUnmodifiableListView) return _problemTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@JsonKey() final  bool showCount;
@JsonKey() final  bool showList;
@JsonKey() final  int maxListItems;
 final  String? title;
@override@JsonKey() final  int order;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProblemSummaryBlockCopyWith<ProblemSummaryBlock> get copyWith => _$ProblemSummaryBlockCopyWithImpl<ProblemSummaryBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProblemSummaryBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProblemSummaryBlock&&const DeepCollectionEquality().equals(other._problemTypes, _problemTypes)&&(identical(other.showCount, showCount) || other.showCount == showCount)&&(identical(other.showList, showList) || other.showList == showList)&&(identical(other.maxListItems, maxListItems) || other.maxListItems == maxListItems)&&(identical(other.title, title) || other.title == title)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_problemTypes),showCount,showList,maxListItems,title,order);

@override
String toString() {
  return 'SupportBlock.problemSummary(problemTypes: $problemTypes, showCount: $showCount, showList: $showList, maxListItems: $maxListItems, title: $title, order: $order)';
}


}

/// @nodoc
abstract mixin class $ProblemSummaryBlockCopyWith<$Res> implements $SupportBlockCopyWith<$Res> {
  factory $ProblemSummaryBlockCopyWith(ProblemSummaryBlock value, $Res Function(ProblemSummaryBlock) _then) = _$ProblemSummaryBlockCopyWithImpl;
@override @useResult
$Res call({
 List<String>? problemTypes, bool showCount, bool showList, int maxListItems, String? title, int order
});




}
/// @nodoc
class _$ProblemSummaryBlockCopyWithImpl<$Res>
    implements $ProblemSummaryBlockCopyWith<$Res> {
  _$ProblemSummaryBlockCopyWithImpl(this._self, this._then);

  final ProblemSummaryBlock _self;
  final $Res Function(ProblemSummaryBlock) _then;

/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? problemTypes = freezed,Object? showCount = null,Object? showList = null,Object? maxListItems = null,Object? title = freezed,Object? order = null,}) {
  return _then(ProblemSummaryBlock(
problemTypes: freezed == problemTypes ? _self._problemTypes : problemTypes // ignore: cast_nullable_to_non_nullable
as List<String>?,showCount: null == showCount ? _self.showCount : showCount // ignore: cast_nullable_to_non_nullable
as bool,showList: null == showList ? _self.showList : showList // ignore: cast_nullable_to_non_nullable
as bool,maxListItems: null == maxListItems ? _self.maxListItems : maxListItems // ignore: cast_nullable_to_non_nullable
as int,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class EmptyStateBlock implements SupportBlock {
  const EmptyStateBlock({required this.message, this.icon, this.actionLabel, this.actionRoute, this.order = 0, final  String? $type}): $type = $type ?? 'emptyState';
  factory EmptyStateBlock.fromJson(Map<String, dynamic> json) => _$EmptyStateBlockFromJson(json);

 final  String message;
 final  String? icon;
 final  String? actionLabel;
 final  String? actionRoute;
@override@JsonKey() final  int order;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmptyStateBlockCopyWith<EmptyStateBlock> get copyWith => _$EmptyStateBlockCopyWithImpl<EmptyStateBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EmptyStateBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmptyStateBlock&&(identical(other.message, message) || other.message == message)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.actionLabel, actionLabel) || other.actionLabel == actionLabel)&&(identical(other.actionRoute, actionRoute) || other.actionRoute == actionRoute)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message,icon,actionLabel,actionRoute,order);

@override
String toString() {
  return 'SupportBlock.emptyState(message: $message, icon: $icon, actionLabel: $actionLabel, actionRoute: $actionRoute, order: $order)';
}


}

/// @nodoc
abstract mixin class $EmptyStateBlockCopyWith<$Res> implements $SupportBlockCopyWith<$Res> {
  factory $EmptyStateBlockCopyWith(EmptyStateBlock value, $Res Function(EmptyStateBlock) _then) = _$EmptyStateBlockCopyWithImpl;
@override @useResult
$Res call({
 String message, String? icon, String? actionLabel, String? actionRoute, int order
});




}
/// @nodoc
class _$EmptyStateBlockCopyWithImpl<$Res>
    implements $EmptyStateBlockCopyWith<$Res> {
  _$EmptyStateBlockCopyWithImpl(this._self, this._then);

  final EmptyStateBlock _self;
  final $Res Function(EmptyStateBlock) _then;

/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? icon = freezed,Object? actionLabel = freezed,Object? actionRoute = freezed,Object? order = null,}) {
  return _then(EmptyStateBlock(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,actionLabel: freezed == actionLabel ? _self.actionLabel : actionLabel // ignore: cast_nullable_to_non_nullable
as String?,actionRoute: freezed == actionRoute ? _self.actionRoute : actionRoute // ignore: cast_nullable_to_non_nullable
as String?,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class EntityHeaderBlock implements SupportBlock {
  const EntityHeaderBlock({required this.entityType, required this.entityId, this.showCheckbox = true, this.showMetadata = true, this.order = 0, final  String? $type}): $type = $type ?? 'entityHeader';
  factory EntityHeaderBlock.fromJson(Map<String, dynamic> json) => _$EntityHeaderBlockFromJson(json);

 final  String entityType;
 final  String entityId;
@JsonKey() final  bool showCheckbox;
@JsonKey() final  bool showMetadata;
@override@JsonKey() final  int order;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EntityHeaderBlockCopyWith<EntityHeaderBlock> get copyWith => _$EntityHeaderBlockCopyWithImpl<EntityHeaderBlock>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EntityHeaderBlockToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EntityHeaderBlock&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.showCheckbox, showCheckbox) || other.showCheckbox == showCheckbox)&&(identical(other.showMetadata, showMetadata) || other.showMetadata == showMetadata)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,entityType,entityId,showCheckbox,showMetadata,order);

@override
String toString() {
  return 'SupportBlock.entityHeader(entityType: $entityType, entityId: $entityId, showCheckbox: $showCheckbox, showMetadata: $showMetadata, order: $order)';
}


}

/// @nodoc
abstract mixin class $EntityHeaderBlockCopyWith<$Res> implements $SupportBlockCopyWith<$Res> {
  factory $EntityHeaderBlockCopyWith(EntityHeaderBlock value, $Res Function(EntityHeaderBlock) _then) = _$EntityHeaderBlockCopyWithImpl;
@override @useResult
$Res call({
 String entityType, String entityId, bool showCheckbox, bool showMetadata, int order
});




}
/// @nodoc
class _$EntityHeaderBlockCopyWithImpl<$Res>
    implements $EntityHeaderBlockCopyWith<$Res> {
  _$EntityHeaderBlockCopyWithImpl(this._self, this._then);

  final EntityHeaderBlock _self;
  final $Res Function(EntityHeaderBlock) _then;

/// Create a copy of SupportBlock
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entityType = null,Object? entityId = null,Object? showCheckbox = null,Object? showMetadata = null,Object? order = null,}) {
  return _then(EntityHeaderBlock(
entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as String,entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,showCheckbox: null == showCheckbox ? _self.showCheckbox : showCheckbox // ignore: cast_nullable_to_non_nullable
as bool,showMetadata: null == showMetadata ? _self.showMetadata : showMetadata // ignore: cast_nullable_to_non_nullable
as bool,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$QuickAction {

 String get label; String get actionId; String? get icon; Map<String, dynamic>? get params;
/// Create a copy of QuickAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuickActionCopyWith<QuickAction> get copyWith => _$QuickActionCopyWithImpl<QuickAction>(this as QuickAction, _$identity);

  /// Serializes this QuickAction to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuickAction&&(identical(other.label, label) || other.label == label)&&(identical(other.actionId, actionId) || other.actionId == actionId)&&(identical(other.icon, icon) || other.icon == icon)&&const DeepCollectionEquality().equals(other.params, params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,actionId,icon,const DeepCollectionEquality().hash(params));

@override
String toString() {
  return 'QuickAction(label: $label, actionId: $actionId, icon: $icon, params: $params)';
}


}

/// @nodoc
abstract mixin class $QuickActionCopyWith<$Res>  {
  factory $QuickActionCopyWith(QuickAction value, $Res Function(QuickAction) _then) = _$QuickActionCopyWithImpl;
@useResult
$Res call({
 String label, String actionId, String? icon, Map<String, dynamic>? params
});




}
/// @nodoc
class _$QuickActionCopyWithImpl<$Res>
    implements $QuickActionCopyWith<$Res> {
  _$QuickActionCopyWithImpl(this._self, this._then);

  final QuickAction _self;
  final $Res Function(QuickAction) _then;

/// Create a copy of QuickAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? actionId = null,Object? icon = freezed,Object? params = freezed,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,actionId: null == actionId ? _self.actionId : actionId // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,params: freezed == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuickAction].
extension QuickActionPatterns on QuickAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuickAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuickAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuickAction value)  $default,){
final _that = this;
switch (_that) {
case _QuickAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuickAction value)?  $default,){
final _that = this;
switch (_that) {
case _QuickAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String actionId,  String? icon,  Map<String, dynamic>? params)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuickAction() when $default != null:
return $default(_that.label,_that.actionId,_that.icon,_that.params);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String actionId,  String? icon,  Map<String, dynamic>? params)  $default,) {final _that = this;
switch (_that) {
case _QuickAction():
return $default(_that.label,_that.actionId,_that.icon,_that.params);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String actionId,  String? icon,  Map<String, dynamic>? params)?  $default,) {final _that = this;
switch (_that) {
case _QuickAction() when $default != null:
return $default(_that.label,_that.actionId,_that.icon,_that.params);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuickAction implements QuickAction {
  const _QuickAction({required this.label, required this.actionId, this.icon, final  Map<String, dynamic>? params}): _params = params;
  factory _QuickAction.fromJson(Map<String, dynamic> json) => _$QuickActionFromJson(json);

@override final  String label;
@override final  String actionId;
@override final  String? icon;
 final  Map<String, dynamic>? _params;
@override Map<String, dynamic>? get params {
  final value = _params;
  if (value == null) return null;
  if (_params is EqualUnmodifiableMapView) return _params;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of QuickAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuickActionCopyWith<_QuickAction> get copyWith => __$QuickActionCopyWithImpl<_QuickAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuickActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuickAction&&(identical(other.label, label) || other.label == label)&&(identical(other.actionId, actionId) || other.actionId == actionId)&&(identical(other.icon, icon) || other.icon == icon)&&const DeepCollectionEquality().equals(other._params, _params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,actionId,icon,const DeepCollectionEquality().hash(_params));

@override
String toString() {
  return 'QuickAction(label: $label, actionId: $actionId, icon: $icon, params: $params)';
}


}

/// @nodoc
abstract mixin class _$QuickActionCopyWith<$Res> implements $QuickActionCopyWith<$Res> {
  factory _$QuickActionCopyWith(_QuickAction value, $Res Function(_QuickAction) _then) = __$QuickActionCopyWithImpl;
@override @useResult
$Res call({
 String label, String actionId, String? icon, Map<String, dynamic>? params
});




}
/// @nodoc
class __$QuickActionCopyWithImpl<$Res>
    implements _$QuickActionCopyWith<$Res> {
  __$QuickActionCopyWithImpl(this._self, this._then);

  final _QuickAction _self;
  final $Res Function(_QuickAction) _then;

/// Create a copy of QuickAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? actionId = null,Object? icon = freezed,Object? params = freezed,}) {
  return _then(_QuickAction(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,actionId: null == actionId ? _self.actionId : actionId // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,params: freezed == params ? _self._params : params // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$StatConfig {

 String get label; String get metricId; String? get format; String? get icon;
/// Create a copy of StatConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatConfigCopyWith<StatConfig> get copyWith => _$StatConfigCopyWithImpl<StatConfig>(this as StatConfig, _$identity);

  /// Serializes this StatConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatConfig&&(identical(other.label, label) || other.label == label)&&(identical(other.metricId, metricId) || other.metricId == metricId)&&(identical(other.format, format) || other.format == format)&&(identical(other.icon, icon) || other.icon == icon));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,metricId,format,icon);

@override
String toString() {
  return 'StatConfig(label: $label, metricId: $metricId, format: $format, icon: $icon)';
}


}

/// @nodoc
abstract mixin class $StatConfigCopyWith<$Res>  {
  factory $StatConfigCopyWith(StatConfig value, $Res Function(StatConfig) _then) = _$StatConfigCopyWithImpl;
@useResult
$Res call({
 String label, String metricId, String? format, String? icon
});




}
/// @nodoc
class _$StatConfigCopyWithImpl<$Res>
    implements $StatConfigCopyWith<$Res> {
  _$StatConfigCopyWithImpl(this._self, this._then);

  final StatConfig _self;
  final $Res Function(StatConfig) _then;

/// Create a copy of StatConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? metricId = null,Object? format = freezed,Object? icon = freezed,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,metricId: null == metricId ? _self.metricId : metricId // ignore: cast_nullable_to_non_nullable
as String,format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StatConfig].
extension StatConfigPatterns on StatConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatConfig value)  $default,){
final _that = this;
switch (_that) {
case _StatConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatConfig value)?  $default,){
final _that = this;
switch (_that) {
case _StatConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String metricId,  String? format,  String? icon)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatConfig() when $default != null:
return $default(_that.label,_that.metricId,_that.format,_that.icon);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String metricId,  String? format,  String? icon)  $default,) {final _that = this;
switch (_that) {
case _StatConfig():
return $default(_that.label,_that.metricId,_that.format,_that.icon);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String metricId,  String? format,  String? icon)?  $default,) {final _that = this;
switch (_that) {
case _StatConfig() when $default != null:
return $default(_that.label,_that.metricId,_that.format,_that.icon);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatConfig implements StatConfig {
  const _StatConfig({required this.label, required this.metricId, this.format, this.icon});
  factory _StatConfig.fromJson(Map<String, dynamic> json) => _$StatConfigFromJson(json);

@override final  String label;
@override final  String metricId;
@override final  String? format;
@override final  String? icon;

/// Create a copy of StatConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatConfigCopyWith<_StatConfig> get copyWith => __$StatConfigCopyWithImpl<_StatConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatConfig&&(identical(other.label, label) || other.label == label)&&(identical(other.metricId, metricId) || other.metricId == metricId)&&(identical(other.format, format) || other.format == format)&&(identical(other.icon, icon) || other.icon == icon));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,metricId,format,icon);

@override
String toString() {
  return 'StatConfig(label: $label, metricId: $metricId, format: $format, icon: $icon)';
}


}

/// @nodoc
abstract mixin class _$StatConfigCopyWith<$Res> implements $StatConfigCopyWith<$Res> {
  factory _$StatConfigCopyWith(_StatConfig value, $Res Function(_StatConfig) _then) = __$StatConfigCopyWithImpl;
@override @useResult
$Res call({
 String label, String metricId, String? format, String? icon
});




}
/// @nodoc
class __$StatConfigCopyWithImpl<$Res>
    implements _$StatConfigCopyWith<$Res> {
  __$StatConfigCopyWithImpl(this._self, this._then);

  final _StatConfig _self;
  final $Res Function(_StatConfig) _then;

/// Create a copy of StatConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? metricId = null,Object? format = freezed,Object? icon = freezed,}) {
  return _then(_StatConfig(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,metricId: null == metricId ? _self.metricId : metricId // ignore: cast_nullable_to_non_nullable
as String,format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
