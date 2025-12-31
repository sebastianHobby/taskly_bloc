// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'allocation_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AllocationState {

 AllocationStatus get status; List<AllocatedTask> get pinnedTasks; Map<String, AllocationGroup> get tasksByValue; List<ExcludedTask> get excludedUrgent; int get excludedCount; int get unrankedCount; AllocationReasoning? get reasoning; DateTime? get lastRefreshed; String? get errorMessage; bool get showExcludedWarning;
/// Create a copy of AllocationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AllocationStateCopyWith<AllocationState> get copyWith => _$AllocationStateCopyWithImpl<AllocationState>(this as AllocationState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AllocationState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.pinnedTasks, pinnedTasks)&&const DeepCollectionEquality().equals(other.tasksByValue, tasksByValue)&&const DeepCollectionEquality().equals(other.excludedUrgent, excludedUrgent)&&(identical(other.excludedCount, excludedCount) || other.excludedCount == excludedCount)&&(identical(other.unrankedCount, unrankedCount) || other.unrankedCount == unrankedCount)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.lastRefreshed, lastRefreshed) || other.lastRefreshed == lastRefreshed)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.showExcludedWarning, showExcludedWarning) || other.showExcludedWarning == showExcludedWarning));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(pinnedTasks),const DeepCollectionEquality().hash(tasksByValue),const DeepCollectionEquality().hash(excludedUrgent),excludedCount,unrankedCount,reasoning,lastRefreshed,errorMessage,showExcludedWarning);

@override
String toString() {
  return 'AllocationState(status: $status, pinnedTasks: $pinnedTasks, tasksByValue: $tasksByValue, excludedUrgent: $excludedUrgent, excludedCount: $excludedCount, unrankedCount: $unrankedCount, reasoning: $reasoning, lastRefreshed: $lastRefreshed, errorMessage: $errorMessage, showExcludedWarning: $showExcludedWarning)';
}


}

/// @nodoc
abstract mixin class $AllocationStateCopyWith<$Res>  {
  factory $AllocationStateCopyWith(AllocationState value, $Res Function(AllocationState) _then) = _$AllocationStateCopyWithImpl;
@useResult
$Res call({
 AllocationStatus status, List<AllocatedTask> pinnedTasks, Map<String, AllocationGroup> tasksByValue, List<ExcludedTask> excludedUrgent, int excludedCount, int unrankedCount, AllocationReasoning? reasoning, DateTime? lastRefreshed, String? errorMessage, bool showExcludedWarning
});


$AllocationReasoningCopyWith<$Res>? get reasoning;

}
/// @nodoc
class _$AllocationStateCopyWithImpl<$Res>
    implements $AllocationStateCopyWith<$Res> {
  _$AllocationStateCopyWithImpl(this._self, this._then);

  final AllocationState _self;
  final $Res Function(AllocationState) _then;

/// Create a copy of AllocationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? pinnedTasks = null,Object? tasksByValue = null,Object? excludedUrgent = null,Object? excludedCount = null,Object? unrankedCount = null,Object? reasoning = freezed,Object? lastRefreshed = freezed,Object? errorMessage = freezed,Object? showExcludedWarning = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AllocationStatus,pinnedTasks: null == pinnedTasks ? _self.pinnedTasks : pinnedTasks // ignore: cast_nullable_to_non_nullable
as List<AllocatedTask>,tasksByValue: null == tasksByValue ? _self.tasksByValue : tasksByValue // ignore: cast_nullable_to_non_nullable
as Map<String, AllocationGroup>,excludedUrgent: null == excludedUrgent ? _self.excludedUrgent : excludedUrgent // ignore: cast_nullable_to_non_nullable
as List<ExcludedTask>,excludedCount: null == excludedCount ? _self.excludedCount : excludedCount // ignore: cast_nullable_to_non_nullable
as int,unrankedCount: null == unrankedCount ? _self.unrankedCount : unrankedCount // ignore: cast_nullable_to_non_nullable
as int,reasoning: freezed == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as AllocationReasoning?,lastRefreshed: freezed == lastRefreshed ? _self.lastRefreshed : lastRefreshed // ignore: cast_nullable_to_non_nullable
as DateTime?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,showExcludedWarning: null == showExcludedWarning ? _self.showExcludedWarning : showExcludedWarning // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of AllocationState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AllocationReasoningCopyWith<$Res>? get reasoning {
    if (_self.reasoning == null) {
    return null;
  }

  return $AllocationReasoningCopyWith<$Res>(_self.reasoning!, (value) {
    return _then(_self.copyWith(reasoning: value));
  });
}
}


/// Adds pattern-matching-related methods to [AllocationState].
extension AllocationStatePatterns on AllocationState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AllocationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AllocationState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AllocationState value)  $default,){
final _that = this;
switch (_that) {
case _AllocationState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AllocationState value)?  $default,){
final _that = this;
switch (_that) {
case _AllocationState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AllocationStatus status,  List<AllocatedTask> pinnedTasks,  Map<String, AllocationGroup> tasksByValue,  List<ExcludedTask> excludedUrgent,  int excludedCount,  int unrankedCount,  AllocationReasoning? reasoning,  DateTime? lastRefreshed,  String? errorMessage,  bool showExcludedWarning)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AllocationState() when $default != null:
return $default(_that.status,_that.pinnedTasks,_that.tasksByValue,_that.excludedUrgent,_that.excludedCount,_that.unrankedCount,_that.reasoning,_that.lastRefreshed,_that.errorMessage,_that.showExcludedWarning);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AllocationStatus status,  List<AllocatedTask> pinnedTasks,  Map<String, AllocationGroup> tasksByValue,  List<ExcludedTask> excludedUrgent,  int excludedCount,  int unrankedCount,  AllocationReasoning? reasoning,  DateTime? lastRefreshed,  String? errorMessage,  bool showExcludedWarning)  $default,) {final _that = this;
switch (_that) {
case _AllocationState():
return $default(_that.status,_that.pinnedTasks,_that.tasksByValue,_that.excludedUrgent,_that.excludedCount,_that.unrankedCount,_that.reasoning,_that.lastRefreshed,_that.errorMessage,_that.showExcludedWarning);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AllocationStatus status,  List<AllocatedTask> pinnedTasks,  Map<String, AllocationGroup> tasksByValue,  List<ExcludedTask> excludedUrgent,  int excludedCount,  int unrankedCount,  AllocationReasoning? reasoning,  DateTime? lastRefreshed,  String? errorMessage,  bool showExcludedWarning)?  $default,) {final _that = this;
switch (_that) {
case _AllocationState() when $default != null:
return $default(_that.status,_that.pinnedTasks,_that.tasksByValue,_that.excludedUrgent,_that.excludedCount,_that.unrankedCount,_that.reasoning,_that.lastRefreshed,_that.errorMessage,_that.showExcludedWarning);case _:
  return null;

}
}

}

/// @nodoc


class _AllocationState extends AllocationState {
  const _AllocationState({this.status = AllocationStatus.initial, final  List<AllocatedTask> pinnedTasks = const [], final  Map<String, AllocationGroup> tasksByValue = const {}, final  List<ExcludedTask> excludedUrgent = const [], this.excludedCount = 0, this.unrankedCount = 0, this.reasoning, this.lastRefreshed, this.errorMessage, this.showExcludedWarning = false}): _pinnedTasks = pinnedTasks,_tasksByValue = tasksByValue,_excludedUrgent = excludedUrgent,super._();
  

@override@JsonKey() final  AllocationStatus status;
 final  List<AllocatedTask> _pinnedTasks;
@override@JsonKey() List<AllocatedTask> get pinnedTasks {
  if (_pinnedTasks is EqualUnmodifiableListView) return _pinnedTasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pinnedTasks);
}

 final  Map<String, AllocationGroup> _tasksByValue;
@override@JsonKey() Map<String, AllocationGroup> get tasksByValue {
  if (_tasksByValue is EqualUnmodifiableMapView) return _tasksByValue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_tasksByValue);
}

 final  List<ExcludedTask> _excludedUrgent;
@override@JsonKey() List<ExcludedTask> get excludedUrgent {
  if (_excludedUrgent is EqualUnmodifiableListView) return _excludedUrgent;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_excludedUrgent);
}

@override@JsonKey() final  int excludedCount;
@override@JsonKey() final  int unrankedCount;
@override final  AllocationReasoning? reasoning;
@override final  DateTime? lastRefreshed;
@override final  String? errorMessage;
@override@JsonKey() final  bool showExcludedWarning;

/// Create a copy of AllocationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AllocationStateCopyWith<_AllocationState> get copyWith => __$AllocationStateCopyWithImpl<_AllocationState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AllocationState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._pinnedTasks, _pinnedTasks)&&const DeepCollectionEquality().equals(other._tasksByValue, _tasksByValue)&&const DeepCollectionEquality().equals(other._excludedUrgent, _excludedUrgent)&&(identical(other.excludedCount, excludedCount) || other.excludedCount == excludedCount)&&(identical(other.unrankedCount, unrankedCount) || other.unrankedCount == unrankedCount)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning)&&(identical(other.lastRefreshed, lastRefreshed) || other.lastRefreshed == lastRefreshed)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.showExcludedWarning, showExcludedWarning) || other.showExcludedWarning == showExcludedWarning));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_pinnedTasks),const DeepCollectionEquality().hash(_tasksByValue),const DeepCollectionEquality().hash(_excludedUrgent),excludedCount,unrankedCount,reasoning,lastRefreshed,errorMessage,showExcludedWarning);

@override
String toString() {
  return 'AllocationState(status: $status, pinnedTasks: $pinnedTasks, tasksByValue: $tasksByValue, excludedUrgent: $excludedUrgent, excludedCount: $excludedCount, unrankedCount: $unrankedCount, reasoning: $reasoning, lastRefreshed: $lastRefreshed, errorMessage: $errorMessage, showExcludedWarning: $showExcludedWarning)';
}


}

/// @nodoc
abstract mixin class _$AllocationStateCopyWith<$Res> implements $AllocationStateCopyWith<$Res> {
  factory _$AllocationStateCopyWith(_AllocationState value, $Res Function(_AllocationState) _then) = __$AllocationStateCopyWithImpl;
@override @useResult
$Res call({
 AllocationStatus status, List<AllocatedTask> pinnedTasks, Map<String, AllocationGroup> tasksByValue, List<ExcludedTask> excludedUrgent, int excludedCount, int unrankedCount, AllocationReasoning? reasoning, DateTime? lastRefreshed, String? errorMessage, bool showExcludedWarning
});


@override $AllocationReasoningCopyWith<$Res>? get reasoning;

}
/// @nodoc
class __$AllocationStateCopyWithImpl<$Res>
    implements _$AllocationStateCopyWith<$Res> {
  __$AllocationStateCopyWithImpl(this._self, this._then);

  final _AllocationState _self;
  final $Res Function(_AllocationState) _then;

/// Create a copy of AllocationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? pinnedTasks = null,Object? tasksByValue = null,Object? excludedUrgent = null,Object? excludedCount = null,Object? unrankedCount = null,Object? reasoning = freezed,Object? lastRefreshed = freezed,Object? errorMessage = freezed,Object? showExcludedWarning = null,}) {
  return _then(_AllocationState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AllocationStatus,pinnedTasks: null == pinnedTasks ? _self._pinnedTasks : pinnedTasks // ignore: cast_nullable_to_non_nullable
as List<AllocatedTask>,tasksByValue: null == tasksByValue ? _self._tasksByValue : tasksByValue // ignore: cast_nullable_to_non_nullable
as Map<String, AllocationGroup>,excludedUrgent: null == excludedUrgent ? _self._excludedUrgent : excludedUrgent // ignore: cast_nullable_to_non_nullable
as List<ExcludedTask>,excludedCount: null == excludedCount ? _self.excludedCount : excludedCount // ignore: cast_nullable_to_non_nullable
as int,unrankedCount: null == unrankedCount ? _self.unrankedCount : unrankedCount // ignore: cast_nullable_to_non_nullable
as int,reasoning: freezed == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as AllocationReasoning?,lastRefreshed: freezed == lastRefreshed ? _self.lastRefreshed : lastRefreshed // ignore: cast_nullable_to_non_nullable
as DateTime?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,showExcludedWarning: null == showExcludedWarning ? _self.showExcludedWarning : showExcludedWarning // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of AllocationState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AllocationReasoningCopyWith<$Res>? get reasoning {
    if (_self.reasoning == null) {
    return null;
  }

  return $AllocationReasoningCopyWith<$Res>(_self.reasoning!, (value) {
    return _then(_self.copyWith(reasoning: value));
  });
}
}

/// @nodoc
mixin _$AllocationGroup {

 String get valueId; String get valueName; List<AllocatedTask> get tasks; double get weight; int get quota; String? get color;
/// Create a copy of AllocationGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AllocationGroupCopyWith<AllocationGroup> get copyWith => _$AllocationGroupCopyWithImpl<AllocationGroup>(this as AllocationGroup, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AllocationGroup&&(identical(other.valueId, valueId) || other.valueId == valueId)&&(identical(other.valueName, valueName) || other.valueName == valueName)&&const DeepCollectionEquality().equals(other.tasks, tasks)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.quota, quota) || other.quota == quota)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,valueId,valueName,const DeepCollectionEquality().hash(tasks),weight,quota,color);

@override
String toString() {
  return 'AllocationGroup(valueId: $valueId, valueName: $valueName, tasks: $tasks, weight: $weight, quota: $quota, color: $color)';
}


}

/// @nodoc
abstract mixin class $AllocationGroupCopyWith<$Res>  {
  factory $AllocationGroupCopyWith(AllocationGroup value, $Res Function(AllocationGroup) _then) = _$AllocationGroupCopyWithImpl;
@useResult
$Res call({
 String valueId, String valueName, List<AllocatedTask> tasks, double weight, int quota, String? color
});




}
/// @nodoc
class _$AllocationGroupCopyWithImpl<$Res>
    implements $AllocationGroupCopyWith<$Res> {
  _$AllocationGroupCopyWithImpl(this._self, this._then);

  final AllocationGroup _self;
  final $Res Function(AllocationGroup) _then;

/// Create a copy of AllocationGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? valueId = null,Object? valueName = null,Object? tasks = null,Object? weight = null,Object? quota = null,Object? color = freezed,}) {
  return _then(_self.copyWith(
valueId: null == valueId ? _self.valueId : valueId // ignore: cast_nullable_to_non_nullable
as String,valueName: null == valueName ? _self.valueName : valueName // ignore: cast_nullable_to_non_nullable
as String,tasks: null == tasks ? _self.tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<AllocatedTask>,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,quota: null == quota ? _self.quota : quota // ignore: cast_nullable_to_non_nullable
as int,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AllocationGroup].
extension AllocationGroupPatterns on AllocationGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AllocationGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AllocationGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AllocationGroup value)  $default,){
final _that = this;
switch (_that) {
case _AllocationGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AllocationGroup value)?  $default,){
final _that = this;
switch (_that) {
case _AllocationGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String valueId,  String valueName,  List<AllocatedTask> tasks,  double weight,  int quota,  String? color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AllocationGroup() when $default != null:
return $default(_that.valueId,_that.valueName,_that.tasks,_that.weight,_that.quota,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String valueId,  String valueName,  List<AllocatedTask> tasks,  double weight,  int quota,  String? color)  $default,) {final _that = this;
switch (_that) {
case _AllocationGroup():
return $default(_that.valueId,_that.valueName,_that.tasks,_that.weight,_that.quota,_that.color);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String valueId,  String valueName,  List<AllocatedTask> tasks,  double weight,  int quota,  String? color)?  $default,) {final _that = this;
switch (_that) {
case _AllocationGroup() when $default != null:
return $default(_that.valueId,_that.valueName,_that.tasks,_that.weight,_that.quota,_that.color);case _:
  return null;

}
}

}

/// @nodoc


class _AllocationGroup implements AllocationGroup {
  const _AllocationGroup({required this.valueId, required this.valueName, required final  List<AllocatedTask> tasks, required this.weight, required this.quota, this.color}): _tasks = tasks;
  

@override final  String valueId;
@override final  String valueName;
 final  List<AllocatedTask> _tasks;
@override List<AllocatedTask> get tasks {
  if (_tasks is EqualUnmodifiableListView) return _tasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tasks);
}

@override final  double weight;
@override final  int quota;
@override final  String? color;

/// Create a copy of AllocationGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AllocationGroupCopyWith<_AllocationGroup> get copyWith => __$AllocationGroupCopyWithImpl<_AllocationGroup>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AllocationGroup&&(identical(other.valueId, valueId) || other.valueId == valueId)&&(identical(other.valueName, valueName) || other.valueName == valueName)&&const DeepCollectionEquality().equals(other._tasks, _tasks)&&(identical(other.weight, weight) || other.weight == weight)&&(identical(other.quota, quota) || other.quota == quota)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,valueId,valueName,const DeepCollectionEquality().hash(_tasks),weight,quota,color);

@override
String toString() {
  return 'AllocationGroup(valueId: $valueId, valueName: $valueName, tasks: $tasks, weight: $weight, quota: $quota, color: $color)';
}


}

/// @nodoc
abstract mixin class _$AllocationGroupCopyWith<$Res> implements $AllocationGroupCopyWith<$Res> {
  factory _$AllocationGroupCopyWith(_AllocationGroup value, $Res Function(_AllocationGroup) _then) = __$AllocationGroupCopyWithImpl;
@override @useResult
$Res call({
 String valueId, String valueName, List<AllocatedTask> tasks, double weight, int quota, String? color
});




}
/// @nodoc
class __$AllocationGroupCopyWithImpl<$Res>
    implements _$AllocationGroupCopyWith<$Res> {
  __$AllocationGroupCopyWithImpl(this._self, this._then);

  final _AllocationGroup _self;
  final $Res Function(_AllocationGroup) _then;

/// Create a copy of AllocationGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? valueId = null,Object? valueName = null,Object? tasks = null,Object? weight = null,Object? quota = null,Object? color = freezed,}) {
  return _then(_AllocationGroup(
valueId: null == valueId ? _self.valueId : valueId // ignore: cast_nullable_to_non_nullable
as String,valueName: null == valueName ? _self.valueName : valueName // ignore: cast_nullable_to_non_nullable
as String,tasks: null == tasks ? _self._tasks : tasks // ignore: cast_nullable_to_non_nullable
as List<AllocatedTask>,weight: null == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double,quota: null == quota ? _self.quota : quota // ignore: cast_nullable_to_non_nullable
as int,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
