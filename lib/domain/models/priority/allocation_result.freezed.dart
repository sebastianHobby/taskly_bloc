// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'allocation_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AllocationResult {

 List<AllocatedTask> get allocatedTasks; AllocationReasoning get reasoning; List<ExcludedTask> get excludedTasks;/// Evaluated alerts for excluded tasks
 AlertEvaluationResult? get alertResult;/// The focus mode used for this allocation
 FocusMode? get activeFocusMode;/// True if allocation cannot proceed because user has no values defined.
/// When true, the UI should show a gateway prompting value setup.
 bool get requiresValueSetup;
/// Create a copy of AllocationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AllocationResultCopyWith<AllocationResult> get copyWith => _$AllocationResultCopyWithImpl<AllocationResult>(this as AllocationResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AllocationResult&&const DeepCollectionEquality().equals(other.allocatedTasks, allocatedTasks)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&const DeepCollectionEquality().equals(other.excludedTasks, excludedTasks)&&(identical(other.alertResult, alertResult) || other.alertResult == alertResult)&&(identical(other.activeFocusMode, activeFocusMode) || other.activeFocusMode == activeFocusMode)&&(identical(other.requiresValueSetup, requiresValueSetup) || other.requiresValueSetup == requiresValueSetup));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(allocatedTasks),reasoning,const DeepCollectionEquality().hash(excludedTasks),alertResult,activeFocusMode,requiresValueSetup);

@override
String toString() {
  return 'AllocationResult(allocatedTasks: $allocatedTasks, reasoning: $reasoning, excludedTasks: $excludedTasks, alertResult: $alertResult, activeFocusMode: $activeFocusMode, requiresValueSetup: $requiresValueSetup)';
}


}

/// @nodoc
abstract mixin class $AllocationResultCopyWith<$Res>  {
  factory $AllocationResultCopyWith(AllocationResult value, $Res Function(AllocationResult) _then) = _$AllocationResultCopyWithImpl;
@useResult
$Res call({
 List<AllocatedTask> allocatedTasks, AllocationReasoning reasoning, List<ExcludedTask> excludedTasks, AlertEvaluationResult? alertResult, FocusMode? activeFocusMode, bool requiresValueSetup
});


$AllocationReasoningCopyWith<$Res> get reasoning;$AlertEvaluationResultCopyWith<$Res>? get alertResult;

}
/// @nodoc
class _$AllocationResultCopyWithImpl<$Res>
    implements $AllocationResultCopyWith<$Res> {
  _$AllocationResultCopyWithImpl(this._self, this._then);

  final AllocationResult _self;
  final $Res Function(AllocationResult) _then;

/// Create a copy of AllocationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? allocatedTasks = null,Object? reasoning = null,Object? excludedTasks = null,Object? alertResult = freezed,Object? activeFocusMode = freezed,Object? requiresValueSetup = null,}) {
  return _then(_self.copyWith(
allocatedTasks: null == allocatedTasks ? _self.allocatedTasks : allocatedTasks // ignore: cast_nullable_to_non_nullable
as List<AllocatedTask>,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as AllocationReasoning,excludedTasks: null == excludedTasks ? _self.excludedTasks : excludedTasks // ignore: cast_nullable_to_non_nullable
as List<ExcludedTask>,alertResult: freezed == alertResult ? _self.alertResult : alertResult // ignore: cast_nullable_to_non_nullable
as AlertEvaluationResult?,activeFocusMode: freezed == activeFocusMode ? _self.activeFocusMode : activeFocusMode // ignore: cast_nullable_to_non_nullable
as FocusMode?,requiresValueSetup: null == requiresValueSetup ? _self.requiresValueSetup : requiresValueSetup // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of AllocationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AllocationReasoningCopyWith<$Res> get reasoning {
  
  return $AllocationReasoningCopyWith<$Res>(_self.reasoning, (value) {
    return _then(_self.copyWith(reasoning: value));
  });
}/// Create a copy of AllocationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AlertEvaluationResultCopyWith<$Res>? get alertResult {
    if (_self.alertResult == null) {
    return null;
  }

  return $AlertEvaluationResultCopyWith<$Res>(_self.alertResult!, (value) {
    return _then(_self.copyWith(alertResult: value));
  });
}
}


/// Adds pattern-matching-related methods to [AllocationResult].
extension AllocationResultPatterns on AllocationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AllocationResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AllocationResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AllocationResult value)  $default,){
final _that = this;
switch (_that) {
case _AllocationResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AllocationResult value)?  $default,){
final _that = this;
switch (_that) {
case _AllocationResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AllocatedTask> allocatedTasks,  AllocationReasoning reasoning,  List<ExcludedTask> excludedTasks,  AlertEvaluationResult? alertResult,  FocusMode? activeFocusMode,  bool requiresValueSetup)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AllocationResult() when $default != null:
return $default(_that.allocatedTasks,_that.reasoning,_that.excludedTasks,_that.alertResult,_that.activeFocusMode,_that.requiresValueSetup);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AllocatedTask> allocatedTasks,  AllocationReasoning reasoning,  List<ExcludedTask> excludedTasks,  AlertEvaluationResult? alertResult,  FocusMode? activeFocusMode,  bool requiresValueSetup)  $default,) {final _that = this;
switch (_that) {
case _AllocationResult():
return $default(_that.allocatedTasks,_that.reasoning,_that.excludedTasks,_that.alertResult,_that.activeFocusMode,_that.requiresValueSetup);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AllocatedTask> allocatedTasks,  AllocationReasoning reasoning,  List<ExcludedTask> excludedTasks,  AlertEvaluationResult? alertResult,  FocusMode? activeFocusMode,  bool requiresValueSetup)?  $default,) {final _that = this;
switch (_that) {
case _AllocationResult() when $default != null:
return $default(_that.allocatedTasks,_that.reasoning,_that.excludedTasks,_that.alertResult,_that.activeFocusMode,_that.requiresValueSetup);case _:
  return null;

}
}

}

/// @nodoc


class _AllocationResult implements AllocationResult {
  const _AllocationResult({required final  List<AllocatedTask> allocatedTasks, required this.reasoning, required final  List<ExcludedTask> excludedTasks, this.alertResult, this.activeFocusMode, this.requiresValueSetup = false}): _allocatedTasks = allocatedTasks,_excludedTasks = excludedTasks;
  

 final  List<AllocatedTask> _allocatedTasks;
@override List<AllocatedTask> get allocatedTasks {
  if (_allocatedTasks is EqualUnmodifiableListView) return _allocatedTasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allocatedTasks);
}

@override final  AllocationReasoning reasoning;
 final  List<ExcludedTask> _excludedTasks;
@override List<ExcludedTask> get excludedTasks {
  if (_excludedTasks is EqualUnmodifiableListView) return _excludedTasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_excludedTasks);
}

/// Evaluated alerts for excluded tasks
@override final  AlertEvaluationResult? alertResult;
/// The focus mode used for this allocation
@override final  FocusMode? activeFocusMode;
/// True if allocation cannot proceed because user has no values defined.
/// When true, the UI should show a gateway prompting value setup.
@override@JsonKey() final  bool requiresValueSetup;

/// Create a copy of AllocationResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AllocationResultCopyWith<_AllocationResult> get copyWith => __$AllocationResultCopyWithImpl<_AllocationResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AllocationResult&&const DeepCollectionEquality().equals(other._allocatedTasks, _allocatedTasks)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&const DeepCollectionEquality().equals(other._excludedTasks, _excludedTasks)&&(identical(other.alertResult, alertResult) || other.alertResult == alertResult)&&(identical(other.activeFocusMode, activeFocusMode) || other.activeFocusMode == activeFocusMode)&&(identical(other.requiresValueSetup, requiresValueSetup) || other.requiresValueSetup == requiresValueSetup));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_allocatedTasks),reasoning,const DeepCollectionEquality().hash(_excludedTasks),alertResult,activeFocusMode,requiresValueSetup);

@override
String toString() {
  return 'AllocationResult(allocatedTasks: $allocatedTasks, reasoning: $reasoning, excludedTasks: $excludedTasks, alertResult: $alertResult, activeFocusMode: $activeFocusMode, requiresValueSetup: $requiresValueSetup)';
}


}

/// @nodoc
abstract mixin class _$AllocationResultCopyWith<$Res> implements $AllocationResultCopyWith<$Res> {
  factory _$AllocationResultCopyWith(_AllocationResult value, $Res Function(_AllocationResult) _then) = __$AllocationResultCopyWithImpl;
@override @useResult
$Res call({
 List<AllocatedTask> allocatedTasks, AllocationReasoning reasoning, List<ExcludedTask> excludedTasks, AlertEvaluationResult? alertResult, FocusMode? activeFocusMode, bool requiresValueSetup
});


@override $AllocationReasoningCopyWith<$Res> get reasoning;@override $AlertEvaluationResultCopyWith<$Res>? get alertResult;

}
/// @nodoc
class __$AllocationResultCopyWithImpl<$Res>
    implements _$AllocationResultCopyWith<$Res> {
  __$AllocationResultCopyWithImpl(this._self, this._then);

  final _AllocationResult _self;
  final $Res Function(_AllocationResult) _then;

/// Create a copy of AllocationResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? allocatedTasks = null,Object? reasoning = null,Object? excludedTasks = null,Object? alertResult = freezed,Object? activeFocusMode = freezed,Object? requiresValueSetup = null,}) {
  return _then(_AllocationResult(
allocatedTasks: null == allocatedTasks ? _self._allocatedTasks : allocatedTasks // ignore: cast_nullable_to_non_nullable
as List<AllocatedTask>,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as AllocationReasoning,excludedTasks: null == excludedTasks ? _self._excludedTasks : excludedTasks // ignore: cast_nullable_to_non_nullable
as List<ExcludedTask>,alertResult: freezed == alertResult ? _self.alertResult : alertResult // ignore: cast_nullable_to_non_nullable
as AlertEvaluationResult?,activeFocusMode: freezed == activeFocusMode ? _self.activeFocusMode : activeFocusMode // ignore: cast_nullable_to_non_nullable
as FocusMode?,requiresValueSetup: null == requiresValueSetup ? _self.requiresValueSetup : requiresValueSetup // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of AllocationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AllocationReasoningCopyWith<$Res> get reasoning {
  
  return $AllocationReasoningCopyWith<$Res>(_self.reasoning, (value) {
    return _then(_self.copyWith(reasoning: value));
  });
}/// Create a copy of AllocationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AlertEvaluationResultCopyWith<$Res>? get alertResult {
    if (_self.alertResult == null) {
    return null;
  }

  return $AlertEvaluationResultCopyWith<$Res>(_self.alertResult!, (value) {
    return _then(_self.copyWith(alertResult: value));
  });
}
}

/// @nodoc
mixin _$AllocatedTask {

 Task get task; String get qualifyingValueId;// Value that qualified this task
 double get allocationScore;/// True if this task was included due to urgency override (Firefighter mode)
/// rather than value-based allocation.
 bool get isUrgentOverride;
/// Create a copy of AllocatedTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AllocatedTaskCopyWith<AllocatedTask> get copyWith => _$AllocatedTaskCopyWithImpl<AllocatedTask>(this as AllocatedTask, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AllocatedTask&&(identical(other.task, task) || other.task == task)&&(identical(other.qualifyingValueId, qualifyingValueId) || other.qualifyingValueId == qualifyingValueId)&&(identical(other.allocationScore, allocationScore) || other.allocationScore == allocationScore)&&(identical(other.isUrgentOverride, isUrgentOverride) || other.isUrgentOverride == isUrgentOverride));
}


@override
int get hashCode => Object.hash(runtimeType,task,qualifyingValueId,allocationScore,isUrgentOverride);

@override
String toString() {
  return 'AllocatedTask(task: $task, qualifyingValueId: $qualifyingValueId, allocationScore: $allocationScore, isUrgentOverride: $isUrgentOverride)';
}


}

/// @nodoc
abstract mixin class $AllocatedTaskCopyWith<$Res>  {
  factory $AllocatedTaskCopyWith(AllocatedTask value, $Res Function(AllocatedTask) _then) = _$AllocatedTaskCopyWithImpl;
@useResult
$Res call({
 Task task, String qualifyingValueId, double allocationScore, bool isUrgentOverride
});




}
/// @nodoc
class _$AllocatedTaskCopyWithImpl<$Res>
    implements $AllocatedTaskCopyWith<$Res> {
  _$AllocatedTaskCopyWithImpl(this._self, this._then);

  final AllocatedTask _self;
  final $Res Function(AllocatedTask) _then;

/// Create a copy of AllocatedTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? task = null,Object? qualifyingValueId = null,Object? allocationScore = null,Object? isUrgentOverride = null,}) {
  return _then(_self.copyWith(
task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as Task,qualifyingValueId: null == qualifyingValueId ? _self.qualifyingValueId : qualifyingValueId // ignore: cast_nullable_to_non_nullable
as String,allocationScore: null == allocationScore ? _self.allocationScore : allocationScore // ignore: cast_nullable_to_non_nullable
as double,isUrgentOverride: null == isUrgentOverride ? _self.isUrgentOverride : isUrgentOverride // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AllocatedTask].
extension AllocatedTaskPatterns on AllocatedTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AllocatedTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AllocatedTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AllocatedTask value)  $default,){
final _that = this;
switch (_that) {
case _AllocatedTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AllocatedTask value)?  $default,){
final _that = this;
switch (_that) {
case _AllocatedTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Task task,  String qualifyingValueId,  double allocationScore,  bool isUrgentOverride)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AllocatedTask() when $default != null:
return $default(_that.task,_that.qualifyingValueId,_that.allocationScore,_that.isUrgentOverride);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Task task,  String qualifyingValueId,  double allocationScore,  bool isUrgentOverride)  $default,) {final _that = this;
switch (_that) {
case _AllocatedTask():
return $default(_that.task,_that.qualifyingValueId,_that.allocationScore,_that.isUrgentOverride);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Task task,  String qualifyingValueId,  double allocationScore,  bool isUrgentOverride)?  $default,) {final _that = this;
switch (_that) {
case _AllocatedTask() when $default != null:
return $default(_that.task,_that.qualifyingValueId,_that.allocationScore,_that.isUrgentOverride);case _:
  return null;

}
}

}

/// @nodoc


class _AllocatedTask implements AllocatedTask {
  const _AllocatedTask({required this.task, required this.qualifyingValueId, required this.allocationScore, this.isUrgentOverride = false});
  

@override final  Task task;
@override final  String qualifyingValueId;
// Value that qualified this task
@override final  double allocationScore;
/// True if this task was included due to urgency override (Firefighter mode)
/// rather than value-based allocation.
@override@JsonKey() final  bool isUrgentOverride;

/// Create a copy of AllocatedTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AllocatedTaskCopyWith<_AllocatedTask> get copyWith => __$AllocatedTaskCopyWithImpl<_AllocatedTask>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AllocatedTask&&(identical(other.task, task) || other.task == task)&&(identical(other.qualifyingValueId, qualifyingValueId) || other.qualifyingValueId == qualifyingValueId)&&(identical(other.allocationScore, allocationScore) || other.allocationScore == allocationScore)&&(identical(other.isUrgentOverride, isUrgentOverride) || other.isUrgentOverride == isUrgentOverride));
}


@override
int get hashCode => Object.hash(runtimeType,task,qualifyingValueId,allocationScore,isUrgentOverride);

@override
String toString() {
  return 'AllocatedTask(task: $task, qualifyingValueId: $qualifyingValueId, allocationScore: $allocationScore, isUrgentOverride: $isUrgentOverride)';
}


}

/// @nodoc
abstract mixin class _$AllocatedTaskCopyWith<$Res> implements $AllocatedTaskCopyWith<$Res> {
  factory _$AllocatedTaskCopyWith(_AllocatedTask value, $Res Function(_AllocatedTask) _then) = __$AllocatedTaskCopyWithImpl;
@override @useResult
$Res call({
 Task task, String qualifyingValueId, double allocationScore, bool isUrgentOverride
});




}
/// @nodoc
class __$AllocatedTaskCopyWithImpl<$Res>
    implements _$AllocatedTaskCopyWith<$Res> {
  __$AllocatedTaskCopyWithImpl(this._self, this._then);

  final _AllocatedTask _self;
  final $Res Function(_AllocatedTask) _then;

/// Create a copy of AllocatedTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? task = null,Object? qualifyingValueId = null,Object? allocationScore = null,Object? isUrgentOverride = null,}) {
  return _then(_AllocatedTask(
task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as Task,qualifyingValueId: null == qualifyingValueId ? _self.qualifyingValueId : qualifyingValueId // ignore: cast_nullable_to_non_nullable
as String,allocationScore: null == allocationScore ? _self.allocationScore : allocationScore // ignore: cast_nullable_to_non_nullable
as double,isUrgentOverride: null == isUrgentOverride ? _self.isUrgentOverride : isUrgentOverride // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$ExcludedTask {

 Task get task; String get reason; ExclusionType get exclusionType; bool? get isUrgent;
/// Create a copy of ExcludedTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExcludedTaskCopyWith<ExcludedTask> get copyWith => _$ExcludedTaskCopyWithImpl<ExcludedTask>(this as ExcludedTask, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExcludedTask&&(identical(other.task, task) || other.task == task)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.exclusionType, exclusionType) || other.exclusionType == exclusionType)&&(identical(other.isUrgent, isUrgent) || other.isUrgent == isUrgent));
}


@override
int get hashCode => Object.hash(runtimeType,task,reason,exclusionType,isUrgent);

@override
String toString() {
  return 'ExcludedTask(task: $task, reason: $reason, exclusionType: $exclusionType, isUrgent: $isUrgent)';
}


}

/// @nodoc
abstract mixin class $ExcludedTaskCopyWith<$Res>  {
  factory $ExcludedTaskCopyWith(ExcludedTask value, $Res Function(ExcludedTask) _then) = _$ExcludedTaskCopyWithImpl;
@useResult
$Res call({
 Task task, String reason, ExclusionType exclusionType, bool? isUrgent
});




}
/// @nodoc
class _$ExcludedTaskCopyWithImpl<$Res>
    implements $ExcludedTaskCopyWith<$Res> {
  _$ExcludedTaskCopyWithImpl(this._self, this._then);

  final ExcludedTask _self;
  final $Res Function(ExcludedTask) _then;

/// Create a copy of ExcludedTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? task = null,Object? reason = null,Object? exclusionType = null,Object? isUrgent = freezed,}) {
  return _then(_self.copyWith(
task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as Task,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,exclusionType: null == exclusionType ? _self.exclusionType : exclusionType // ignore: cast_nullable_to_non_nullable
as ExclusionType,isUrgent: freezed == isUrgent ? _self.isUrgent : isUrgent // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExcludedTask].
extension ExcludedTaskPatterns on ExcludedTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExcludedTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExcludedTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExcludedTask value)  $default,){
final _that = this;
switch (_that) {
case _ExcludedTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExcludedTask value)?  $default,){
final _that = this;
switch (_that) {
case _ExcludedTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Task task,  String reason,  ExclusionType exclusionType,  bool? isUrgent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExcludedTask() when $default != null:
return $default(_that.task,_that.reason,_that.exclusionType,_that.isUrgent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Task task,  String reason,  ExclusionType exclusionType,  bool? isUrgent)  $default,) {final _that = this;
switch (_that) {
case _ExcludedTask():
return $default(_that.task,_that.reason,_that.exclusionType,_that.isUrgent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Task task,  String reason,  ExclusionType exclusionType,  bool? isUrgent)?  $default,) {final _that = this;
switch (_that) {
case _ExcludedTask() when $default != null:
return $default(_that.task,_that.reason,_that.exclusionType,_that.isUrgent);case _:
  return null;

}
}

}

/// @nodoc


class _ExcludedTask implements ExcludedTask {
  const _ExcludedTask({required this.task, required this.reason, required this.exclusionType, this.isUrgent});
  

@override final  Task task;
@override final  String reason;
@override final  ExclusionType exclusionType;
@override final  bool? isUrgent;

/// Create a copy of ExcludedTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExcludedTaskCopyWith<_ExcludedTask> get copyWith => __$ExcludedTaskCopyWithImpl<_ExcludedTask>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExcludedTask&&(identical(other.task, task) || other.task == task)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.exclusionType, exclusionType) || other.exclusionType == exclusionType)&&(identical(other.isUrgent, isUrgent) || other.isUrgent == isUrgent));
}


@override
int get hashCode => Object.hash(runtimeType,task,reason,exclusionType,isUrgent);

@override
String toString() {
  return 'ExcludedTask(task: $task, reason: $reason, exclusionType: $exclusionType, isUrgent: $isUrgent)';
}


}

/// @nodoc
abstract mixin class _$ExcludedTaskCopyWith<$Res> implements $ExcludedTaskCopyWith<$Res> {
  factory _$ExcludedTaskCopyWith(_ExcludedTask value, $Res Function(_ExcludedTask) _then) = __$ExcludedTaskCopyWithImpl;
@override @useResult
$Res call({
 Task task, String reason, ExclusionType exclusionType, bool? isUrgent
});




}
/// @nodoc
class __$ExcludedTaskCopyWithImpl<$Res>
    implements _$ExcludedTaskCopyWith<$Res> {
  __$ExcludedTaskCopyWithImpl(this._self, this._then);

  final _ExcludedTask _self;
  final $Res Function(_ExcludedTask) _then;

/// Create a copy of ExcludedTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? task = null,Object? reason = null,Object? exclusionType = null,Object? isUrgent = freezed,}) {
  return _then(_ExcludedTask(
task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as Task,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,exclusionType: null == exclusionType ? _self.exclusionType : exclusionType // ignore: cast_nullable_to_non_nullable
as ExclusionType,isUrgent: freezed == isUrgent ? _self.isUrgent : isUrgent // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

/// @nodoc
mixin _$AllocationReasoning {

 String get strategyUsed; Map<String, int> get categoryAllocations;// categoryId -> count
 Map<String, double> get categoryWeights;// categoryId -> weight
 double? get urgencyInfluence; String? get explanation;
/// Create a copy of AllocationReasoning
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AllocationReasoningCopyWith<AllocationReasoning> get copyWith => _$AllocationReasoningCopyWithImpl<AllocationReasoning>(this as AllocationReasoning, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AllocationReasoning&&(identical(other.strategyUsed, strategyUsed) || other.strategyUsed == strategyUsed)&&const DeepCollectionEquality().equals(other.categoryAllocations, categoryAllocations)&&const DeepCollectionEquality().equals(other.categoryWeights, categoryWeights)&&(identical(other.urgencyInfluence, urgencyInfluence) || other.urgencyInfluence == urgencyInfluence)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}


@override
int get hashCode => Object.hash(runtimeType,strategyUsed,const DeepCollectionEquality().hash(categoryAllocations),const DeepCollectionEquality().hash(categoryWeights),urgencyInfluence,explanation);

@override
String toString() {
  return 'AllocationReasoning(strategyUsed: $strategyUsed, categoryAllocations: $categoryAllocations, categoryWeights: $categoryWeights, urgencyInfluence: $urgencyInfluence, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class $AllocationReasoningCopyWith<$Res>  {
  factory $AllocationReasoningCopyWith(AllocationReasoning value, $Res Function(AllocationReasoning) _then) = _$AllocationReasoningCopyWithImpl;
@useResult
$Res call({
 String strategyUsed, Map<String, int> categoryAllocations, Map<String, double> categoryWeights, double? urgencyInfluence, String? explanation
});




}
/// @nodoc
class _$AllocationReasoningCopyWithImpl<$Res>
    implements $AllocationReasoningCopyWith<$Res> {
  _$AllocationReasoningCopyWithImpl(this._self, this._then);

  final AllocationReasoning _self;
  final $Res Function(AllocationReasoning) _then;

/// Create a copy of AllocationReasoning
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? strategyUsed = null,Object? categoryAllocations = null,Object? categoryWeights = null,Object? urgencyInfluence = freezed,Object? explanation = freezed,}) {
  return _then(_self.copyWith(
strategyUsed: null == strategyUsed ? _self.strategyUsed : strategyUsed // ignore: cast_nullable_to_non_nullable
as String,categoryAllocations: null == categoryAllocations ? _self.categoryAllocations : categoryAllocations // ignore: cast_nullable_to_non_nullable
as Map<String, int>,categoryWeights: null == categoryWeights ? _self.categoryWeights : categoryWeights // ignore: cast_nullable_to_non_nullable
as Map<String, double>,urgencyInfluence: freezed == urgencyInfluence ? _self.urgencyInfluence : urgencyInfluence // ignore: cast_nullable_to_non_nullable
as double?,explanation: freezed == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AllocationReasoning].
extension AllocationReasoningPatterns on AllocationReasoning {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AllocationReasoning value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AllocationReasoning() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AllocationReasoning value)  $default,){
final _that = this;
switch (_that) {
case _AllocationReasoning():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AllocationReasoning value)?  $default,){
final _that = this;
switch (_that) {
case _AllocationReasoning() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String strategyUsed,  Map<String, int> categoryAllocations,  Map<String, double> categoryWeights,  double? urgencyInfluence,  String? explanation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AllocationReasoning() when $default != null:
return $default(_that.strategyUsed,_that.categoryAllocations,_that.categoryWeights,_that.urgencyInfluence,_that.explanation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String strategyUsed,  Map<String, int> categoryAllocations,  Map<String, double> categoryWeights,  double? urgencyInfluence,  String? explanation)  $default,) {final _that = this;
switch (_that) {
case _AllocationReasoning():
return $default(_that.strategyUsed,_that.categoryAllocations,_that.categoryWeights,_that.urgencyInfluence,_that.explanation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String strategyUsed,  Map<String, int> categoryAllocations,  Map<String, double> categoryWeights,  double? urgencyInfluence,  String? explanation)?  $default,) {final _that = this;
switch (_that) {
case _AllocationReasoning() when $default != null:
return $default(_that.strategyUsed,_that.categoryAllocations,_that.categoryWeights,_that.urgencyInfluence,_that.explanation);case _:
  return null;

}
}

}

/// @nodoc


class _AllocationReasoning implements AllocationReasoning {
  const _AllocationReasoning({required this.strategyUsed, required final  Map<String, int> categoryAllocations, required final  Map<String, double> categoryWeights, this.urgencyInfluence, this.explanation}): _categoryAllocations = categoryAllocations,_categoryWeights = categoryWeights;
  

@override final  String strategyUsed;
 final  Map<String, int> _categoryAllocations;
@override Map<String, int> get categoryAllocations {
  if (_categoryAllocations is EqualUnmodifiableMapView) return _categoryAllocations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categoryAllocations);
}

// categoryId -> count
 final  Map<String, double> _categoryWeights;
// categoryId -> count
@override Map<String, double> get categoryWeights {
  if (_categoryWeights is EqualUnmodifiableMapView) return _categoryWeights;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_categoryWeights);
}

// categoryId -> weight
@override final  double? urgencyInfluence;
@override final  String? explanation;

/// Create a copy of AllocationReasoning
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AllocationReasoningCopyWith<_AllocationReasoning> get copyWith => __$AllocationReasoningCopyWithImpl<_AllocationReasoning>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AllocationReasoning&&(identical(other.strategyUsed, strategyUsed) || other.strategyUsed == strategyUsed)&&const DeepCollectionEquality().equals(other._categoryAllocations, _categoryAllocations)&&const DeepCollectionEquality().equals(other._categoryWeights, _categoryWeights)&&(identical(other.urgencyInfluence, urgencyInfluence) || other.urgencyInfluence == urgencyInfluence)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}


@override
int get hashCode => Object.hash(runtimeType,strategyUsed,const DeepCollectionEquality().hash(_categoryAllocations),const DeepCollectionEquality().hash(_categoryWeights),urgencyInfluence,explanation);

@override
String toString() {
  return 'AllocationReasoning(strategyUsed: $strategyUsed, categoryAllocations: $categoryAllocations, categoryWeights: $categoryWeights, urgencyInfluence: $urgencyInfluence, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class _$AllocationReasoningCopyWith<$Res> implements $AllocationReasoningCopyWith<$Res> {
  factory _$AllocationReasoningCopyWith(_AllocationReasoning value, $Res Function(_AllocationReasoning) _then) = __$AllocationReasoningCopyWithImpl;
@override @useResult
$Res call({
 String strategyUsed, Map<String, int> categoryAllocations, Map<String, double> categoryWeights, double? urgencyInfluence, String? explanation
});




}
/// @nodoc
class __$AllocationReasoningCopyWithImpl<$Res>
    implements _$AllocationReasoningCopyWith<$Res> {
  __$AllocationReasoningCopyWithImpl(this._self, this._then);

  final _AllocationReasoning _self;
  final $Res Function(_AllocationReasoning) _then;

/// Create a copy of AllocationReasoning
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? strategyUsed = null,Object? categoryAllocations = null,Object? categoryWeights = null,Object? urgencyInfluence = freezed,Object? explanation = freezed,}) {
  return _then(_AllocationReasoning(
strategyUsed: null == strategyUsed ? _self.strategyUsed : strategyUsed // ignore: cast_nullable_to_non_nullable
as String,categoryAllocations: null == categoryAllocations ? _self._categoryAllocations : categoryAllocations // ignore: cast_nullable_to_non_nullable
as Map<String, int>,categoryWeights: null == categoryWeights ? _self._categoryWeights : categoryWeights // ignore: cast_nullable_to_non_nullable
as Map<String, double>,urgencyInfluence: freezed == urgencyInfluence ? _self.urgencyInfluence : urgencyInfluence // ignore: cast_nullable_to_non_nullable
as double?,explanation: freezed == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
