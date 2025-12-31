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

 List<AllocatedTask> get allocatedTasks; AllocationReasoning get reasoning; List<ExcludedTask> get excludedTasks; List<AllocationWarning> get warnings;
/// Create a copy of AllocationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AllocationResultCopyWith<AllocationResult> get copyWith => _$AllocationResultCopyWithImpl<AllocationResult>(this as AllocationResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AllocationResult&&const DeepCollectionEquality().equals(other.allocatedTasks, allocatedTasks)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&const DeepCollectionEquality().equals(other.excludedTasks, excludedTasks)&&const DeepCollectionEquality().equals(other.warnings, warnings));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(allocatedTasks),reasoning,const DeepCollectionEquality().hash(excludedTasks),const DeepCollectionEquality().hash(warnings));

@override
String toString() {
  return 'AllocationResult(allocatedTasks: $allocatedTasks, reasoning: $reasoning, excludedTasks: $excludedTasks, warnings: $warnings)';
}


}

/// @nodoc
abstract mixin class $AllocationResultCopyWith<$Res>  {
  factory $AllocationResultCopyWith(AllocationResult value, $Res Function(AllocationResult) _then) = _$AllocationResultCopyWithImpl;
@useResult
$Res call({
 List<AllocatedTask> allocatedTasks, AllocationReasoning reasoning, List<ExcludedTask> excludedTasks, List<AllocationWarning> warnings
});


$AllocationReasoningCopyWith<$Res> get reasoning;

}
/// @nodoc
class _$AllocationResultCopyWithImpl<$Res>
    implements $AllocationResultCopyWith<$Res> {
  _$AllocationResultCopyWithImpl(this._self, this._then);

  final AllocationResult _self;
  final $Res Function(AllocationResult) _then;

/// Create a copy of AllocationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? allocatedTasks = null,Object? reasoning = null,Object? excludedTasks = null,Object? warnings = null,}) {
  return _then(_self.copyWith(
allocatedTasks: null == allocatedTasks ? _self.allocatedTasks : allocatedTasks // ignore: cast_nullable_to_non_nullable
as List<AllocatedTask>,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as AllocationReasoning,excludedTasks: null == excludedTasks ? _self.excludedTasks : excludedTasks // ignore: cast_nullable_to_non_nullable
as List<ExcludedTask>,warnings: null == warnings ? _self.warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<AllocationWarning>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AllocatedTask> allocatedTasks,  AllocationReasoning reasoning,  List<ExcludedTask> excludedTasks,  List<AllocationWarning> warnings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AllocationResult() when $default != null:
return $default(_that.allocatedTasks,_that.reasoning,_that.excludedTasks,_that.warnings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AllocatedTask> allocatedTasks,  AllocationReasoning reasoning,  List<ExcludedTask> excludedTasks,  List<AllocationWarning> warnings)  $default,) {final _that = this;
switch (_that) {
case _AllocationResult():
return $default(_that.allocatedTasks,_that.reasoning,_that.excludedTasks,_that.warnings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AllocatedTask> allocatedTasks,  AllocationReasoning reasoning,  List<ExcludedTask> excludedTasks,  List<AllocationWarning> warnings)?  $default,) {final _that = this;
switch (_that) {
case _AllocationResult() when $default != null:
return $default(_that.allocatedTasks,_that.reasoning,_that.excludedTasks,_that.warnings);case _:
  return null;

}
}

}

/// @nodoc


class _AllocationResult implements AllocationResult {
  const _AllocationResult({required final  List<AllocatedTask> allocatedTasks, required this.reasoning, required final  List<ExcludedTask> excludedTasks, final  List<AllocationWarning> warnings = const []}): _allocatedTasks = allocatedTasks,_excludedTasks = excludedTasks,_warnings = warnings;
  

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

 final  List<AllocationWarning> _warnings;
@override@JsonKey() List<AllocationWarning> get warnings {
  if (_warnings is EqualUnmodifiableListView) return _warnings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_warnings);
}


/// Create a copy of AllocationResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AllocationResultCopyWith<_AllocationResult> get copyWith => __$AllocationResultCopyWithImpl<_AllocationResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AllocationResult&&const DeepCollectionEquality().equals(other._allocatedTasks, _allocatedTasks)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&const DeepCollectionEquality().equals(other._excludedTasks, _excludedTasks)&&const DeepCollectionEquality().equals(other._warnings, _warnings));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_allocatedTasks),reasoning,const DeepCollectionEquality().hash(_excludedTasks),const DeepCollectionEquality().hash(_warnings));

@override
String toString() {
  return 'AllocationResult(allocatedTasks: $allocatedTasks, reasoning: $reasoning, excludedTasks: $excludedTasks, warnings: $warnings)';
}


}

/// @nodoc
abstract mixin class _$AllocationResultCopyWith<$Res> implements $AllocationResultCopyWith<$Res> {
  factory _$AllocationResultCopyWith(_AllocationResult value, $Res Function(_AllocationResult) _then) = __$AllocationResultCopyWithImpl;
@override @useResult
$Res call({
 List<AllocatedTask> allocatedTasks, AllocationReasoning reasoning, List<ExcludedTask> excludedTasks, List<AllocationWarning> warnings
});


@override $AllocationReasoningCopyWith<$Res> get reasoning;

}
/// @nodoc
class __$AllocationResultCopyWithImpl<$Res>
    implements _$AllocationResultCopyWith<$Res> {
  __$AllocationResultCopyWithImpl(this._self, this._then);

  final _AllocationResult _self;
  final $Res Function(_AllocationResult) _then;

/// Create a copy of AllocationResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? allocatedTasks = null,Object? reasoning = null,Object? excludedTasks = null,Object? warnings = null,}) {
  return _then(_AllocationResult(
allocatedTasks: null == allocatedTasks ? _self._allocatedTasks : allocatedTasks // ignore: cast_nullable_to_non_nullable
as List<AllocatedTask>,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as AllocationReasoning,excludedTasks: null == excludedTasks ? _self._excludedTasks : excludedTasks // ignore: cast_nullable_to_non_nullable
as List<ExcludedTask>,warnings: null == warnings ? _self._warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<AllocationWarning>,
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
}
}

/// @nodoc
mixin _$AllocatedTask {

 Task get task; String get qualifyingValueId;// Value that qualified this task
 double get allocationScore;
/// Create a copy of AllocatedTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AllocatedTaskCopyWith<AllocatedTask> get copyWith => _$AllocatedTaskCopyWithImpl<AllocatedTask>(this as AllocatedTask, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AllocatedTask&&(identical(other.task, task) || other.task == task)&&(identical(other.qualifyingValueId, qualifyingValueId) || other.qualifyingValueId == qualifyingValueId)&&(identical(other.allocationScore, allocationScore) || other.allocationScore == allocationScore));
}


@override
int get hashCode => Object.hash(runtimeType,task,qualifyingValueId,allocationScore);

@override
String toString() {
  return 'AllocatedTask(task: $task, qualifyingValueId: $qualifyingValueId, allocationScore: $allocationScore)';
}


}

/// @nodoc
abstract mixin class $AllocatedTaskCopyWith<$Res>  {
  factory $AllocatedTaskCopyWith(AllocatedTask value, $Res Function(AllocatedTask) _then) = _$AllocatedTaskCopyWithImpl;
@useResult
$Res call({
 Task task, String qualifyingValueId, double allocationScore
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
@pragma('vm:prefer-inline') @override $Res call({Object? task = null,Object? qualifyingValueId = null,Object? allocationScore = null,}) {
  return _then(_self.copyWith(
task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as Task,qualifyingValueId: null == qualifyingValueId ? _self.qualifyingValueId : qualifyingValueId // ignore: cast_nullable_to_non_nullable
as String,allocationScore: null == allocationScore ? _self.allocationScore : allocationScore // ignore: cast_nullable_to_non_nullable
as double,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Task task,  String qualifyingValueId,  double allocationScore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AllocatedTask() when $default != null:
return $default(_that.task,_that.qualifyingValueId,_that.allocationScore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Task task,  String qualifyingValueId,  double allocationScore)  $default,) {final _that = this;
switch (_that) {
case _AllocatedTask():
return $default(_that.task,_that.qualifyingValueId,_that.allocationScore);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Task task,  String qualifyingValueId,  double allocationScore)?  $default,) {final _that = this;
switch (_that) {
case _AllocatedTask() when $default != null:
return $default(_that.task,_that.qualifyingValueId,_that.allocationScore);case _:
  return null;

}
}

}

/// @nodoc


class _AllocatedTask implements AllocatedTask {
  const _AllocatedTask({required this.task, required this.qualifyingValueId, required this.allocationScore});
  

@override final  Task task;
@override final  String qualifyingValueId;
// Value that qualified this task
@override final  double allocationScore;

/// Create a copy of AllocatedTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AllocatedTaskCopyWith<_AllocatedTask> get copyWith => __$AllocatedTaskCopyWithImpl<_AllocatedTask>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AllocatedTask&&(identical(other.task, task) || other.task == task)&&(identical(other.qualifyingValueId, qualifyingValueId) || other.qualifyingValueId == qualifyingValueId)&&(identical(other.allocationScore, allocationScore) || other.allocationScore == allocationScore));
}


@override
int get hashCode => Object.hash(runtimeType,task,qualifyingValueId,allocationScore);

@override
String toString() {
  return 'AllocatedTask(task: $task, qualifyingValueId: $qualifyingValueId, allocationScore: $allocationScore)';
}


}

/// @nodoc
abstract mixin class _$AllocatedTaskCopyWith<$Res> implements $AllocatedTaskCopyWith<$Res> {
  factory _$AllocatedTaskCopyWith(_AllocatedTask value, $Res Function(_AllocatedTask) _then) = __$AllocatedTaskCopyWithImpl;
@override @useResult
$Res call({
 Task task, String qualifyingValueId, double allocationScore
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
@override @pragma('vm:prefer-inline') $Res call({Object? task = null,Object? qualifyingValueId = null,Object? allocationScore = null,}) {
  return _then(_AllocatedTask(
task: null == task ? _self.task : task // ignore: cast_nullable_to_non_nullable
as Task,qualifyingValueId: null == qualifyingValueId ? _self.qualifyingValueId : qualifyingValueId // ignore: cast_nullable_to_non_nullable
as String,allocationScore: null == allocationScore ? _self.allocationScore : allocationScore // ignore: cast_nullable_to_non_nullable
as double,
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
mixin _$AllocationWarning {

 WarningType get type; String get message; String get suggestedAction; List<String>? get affectedTaskIds;
/// Create a copy of AllocationWarning
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AllocationWarningCopyWith<AllocationWarning> get copyWith => _$AllocationWarningCopyWithImpl<AllocationWarning>(this as AllocationWarning, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AllocationWarning&&(identical(other.type, type) || other.type == type)&&(identical(other.message, message) || other.message == message)&&(identical(other.suggestedAction, suggestedAction) || other.suggestedAction == suggestedAction)&&const DeepCollectionEquality().equals(other.affectedTaskIds, affectedTaskIds));
}


@override
int get hashCode => Object.hash(runtimeType,type,message,suggestedAction,const DeepCollectionEquality().hash(affectedTaskIds));

@override
String toString() {
  return 'AllocationWarning(type: $type, message: $message, suggestedAction: $suggestedAction, affectedTaskIds: $affectedTaskIds)';
}


}

/// @nodoc
abstract mixin class $AllocationWarningCopyWith<$Res>  {
  factory $AllocationWarningCopyWith(AllocationWarning value, $Res Function(AllocationWarning) _then) = _$AllocationWarningCopyWithImpl;
@useResult
$Res call({
 WarningType type, String message, String suggestedAction, List<String>? affectedTaskIds
});




}
/// @nodoc
class _$AllocationWarningCopyWithImpl<$Res>
    implements $AllocationWarningCopyWith<$Res> {
  _$AllocationWarningCopyWithImpl(this._self, this._then);

  final AllocationWarning _self;
  final $Res Function(AllocationWarning) _then;

/// Create a copy of AllocationWarning
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? message = null,Object? suggestedAction = null,Object? affectedTaskIds = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as WarningType,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,suggestedAction: null == suggestedAction ? _self.suggestedAction : suggestedAction // ignore: cast_nullable_to_non_nullable
as String,affectedTaskIds: freezed == affectedTaskIds ? _self.affectedTaskIds : affectedTaskIds // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [AllocationWarning].
extension AllocationWarningPatterns on AllocationWarning {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AllocationWarning value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AllocationWarning() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AllocationWarning value)  $default,){
final _that = this;
switch (_that) {
case _AllocationWarning():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AllocationWarning value)?  $default,){
final _that = this;
switch (_that) {
case _AllocationWarning() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WarningType type,  String message,  String suggestedAction,  List<String>? affectedTaskIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AllocationWarning() when $default != null:
return $default(_that.type,_that.message,_that.suggestedAction,_that.affectedTaskIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WarningType type,  String message,  String suggestedAction,  List<String>? affectedTaskIds)  $default,) {final _that = this;
switch (_that) {
case _AllocationWarning():
return $default(_that.type,_that.message,_that.suggestedAction,_that.affectedTaskIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WarningType type,  String message,  String suggestedAction,  List<String>? affectedTaskIds)?  $default,) {final _that = this;
switch (_that) {
case _AllocationWarning() when $default != null:
return $default(_that.type,_that.message,_that.suggestedAction,_that.affectedTaskIds);case _:
  return null;

}
}

}

/// @nodoc


class _AllocationWarning implements AllocationWarning {
  const _AllocationWarning({required this.type, required this.message, required this.suggestedAction, final  List<String>? affectedTaskIds}): _affectedTaskIds = affectedTaskIds;
  

@override final  WarningType type;
@override final  String message;
@override final  String suggestedAction;
 final  List<String>? _affectedTaskIds;
@override List<String>? get affectedTaskIds {
  final value = _affectedTaskIds;
  if (value == null) return null;
  if (_affectedTaskIds is EqualUnmodifiableListView) return _affectedTaskIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of AllocationWarning
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AllocationWarningCopyWith<_AllocationWarning> get copyWith => __$AllocationWarningCopyWithImpl<_AllocationWarning>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AllocationWarning&&(identical(other.type, type) || other.type == type)&&(identical(other.message, message) || other.message == message)&&(identical(other.suggestedAction, suggestedAction) || other.suggestedAction == suggestedAction)&&const DeepCollectionEquality().equals(other._affectedTaskIds, _affectedTaskIds));
}


@override
int get hashCode => Object.hash(runtimeType,type,message,suggestedAction,const DeepCollectionEquality().hash(_affectedTaskIds));

@override
String toString() {
  return 'AllocationWarning(type: $type, message: $message, suggestedAction: $suggestedAction, affectedTaskIds: $affectedTaskIds)';
}


}

/// @nodoc
abstract mixin class _$AllocationWarningCopyWith<$Res> implements $AllocationWarningCopyWith<$Res> {
  factory _$AllocationWarningCopyWith(_AllocationWarning value, $Res Function(_AllocationWarning) _then) = __$AllocationWarningCopyWithImpl;
@override @useResult
$Res call({
 WarningType type, String message, String suggestedAction, List<String>? affectedTaskIds
});




}
/// @nodoc
class __$AllocationWarningCopyWithImpl<$Res>
    implements _$AllocationWarningCopyWith<$Res> {
  __$AllocationWarningCopyWithImpl(this._self, this._then);

  final _AllocationWarning _self;
  final $Res Function(_AllocationWarning) _then;

/// Create a copy of AllocationWarning
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? message = null,Object? suggestedAction = null,Object? affectedTaskIds = freezed,}) {
  return _then(_AllocationWarning(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as WarningType,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,suggestedAction: null == suggestedAction ? _self.suggestedAction : suggestedAction // ignore: cast_nullable_to_non_nullable
as String,affectedTaskIds: freezed == affectedTaskIds ? _self._affectedTaskIds : affectedTaskIds // ignore: cast_nullable_to_non_nullable
as List<String>?,
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
