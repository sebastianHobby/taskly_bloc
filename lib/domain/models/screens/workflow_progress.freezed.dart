// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workflow_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkflowProgress {

 int get total; int get completed; int get skipped; int get pending;
/// Create a copy of WorkflowProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkflowProgressCopyWith<WorkflowProgress> get copyWith => _$WorkflowProgressCopyWithImpl<WorkflowProgress>(this as WorkflowProgress, _$identity);

  /// Serializes this WorkflowProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkflowProgress&&(identical(other.total, total) || other.total == total)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.skipped, skipped) || other.skipped == skipped)&&(identical(other.pending, pending) || other.pending == pending));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,completed,skipped,pending);

@override
String toString() {
  return 'WorkflowProgress(total: $total, completed: $completed, skipped: $skipped, pending: $pending)';
}


}

/// @nodoc
abstract mixin class $WorkflowProgressCopyWith<$Res>  {
  factory $WorkflowProgressCopyWith(WorkflowProgress value, $Res Function(WorkflowProgress) _then) = _$WorkflowProgressCopyWithImpl;
@useResult
$Res call({
 int total, int completed, int skipped, int pending
});




}
/// @nodoc
class _$WorkflowProgressCopyWithImpl<$Res>
    implements $WorkflowProgressCopyWith<$Res> {
  _$WorkflowProgressCopyWithImpl(this._self, this._then);

  final WorkflowProgress _self;
  final $Res Function(WorkflowProgress) _then;

/// Create a copy of WorkflowProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? completed = null,Object? skipped = null,Object? pending = null,}) {
  return _then(_self.copyWith(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int,skipped: null == skipped ? _self.skipped : skipped // ignore: cast_nullable_to_non_nullable
as int,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkflowProgress].
extension WorkflowProgressPatterns on WorkflowProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkflowProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkflowProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkflowProgress value)  $default,){
final _that = this;
switch (_that) {
case _WorkflowProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkflowProgress value)?  $default,){
final _that = this;
switch (_that) {
case _WorkflowProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int total,  int completed,  int skipped,  int pending)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkflowProgress() when $default != null:
return $default(_that.total,_that.completed,_that.skipped,_that.pending);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int total,  int completed,  int skipped,  int pending)  $default,) {final _that = this;
switch (_that) {
case _WorkflowProgress():
return $default(_that.total,_that.completed,_that.skipped,_that.pending);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int total,  int completed,  int skipped,  int pending)?  $default,) {final _that = this;
switch (_that) {
case _WorkflowProgress() when $default != null:
return $default(_that.total,_that.completed,_that.skipped,_that.pending);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkflowProgress implements WorkflowProgress {
  const _WorkflowProgress({this.total = 0, this.completed = 0, this.skipped = 0, this.pending = 0});
  factory _WorkflowProgress.fromJson(Map<String, dynamic> json) => _$WorkflowProgressFromJson(json);

@override@JsonKey() final  int total;
@override@JsonKey() final  int completed;
@override@JsonKey() final  int skipped;
@override@JsonKey() final  int pending;

/// Create a copy of WorkflowProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkflowProgressCopyWith<_WorkflowProgress> get copyWith => __$WorkflowProgressCopyWithImpl<_WorkflowProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkflowProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkflowProgress&&(identical(other.total, total) || other.total == total)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.skipped, skipped) || other.skipped == skipped)&&(identical(other.pending, pending) || other.pending == pending));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,completed,skipped,pending);

@override
String toString() {
  return 'WorkflowProgress(total: $total, completed: $completed, skipped: $skipped, pending: $pending)';
}


}

/// @nodoc
abstract mixin class _$WorkflowProgressCopyWith<$Res> implements $WorkflowProgressCopyWith<$Res> {
  factory _$WorkflowProgressCopyWith(_WorkflowProgress value, $Res Function(_WorkflowProgress) _then) = __$WorkflowProgressCopyWithImpl;
@override @useResult
$Res call({
 int total, int completed, int skipped, int pending
});




}
/// @nodoc
class __$WorkflowProgressCopyWithImpl<$Res>
    implements _$WorkflowProgressCopyWith<$Res> {
  __$WorkflowProgressCopyWithImpl(this._self, this._then);

  final _WorkflowProgress _self;
  final $Res Function(_WorkflowProgress) _then;

/// Create a copy of WorkflowProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? completed = null,Object? skipped = null,Object? pending = null,}) {
  return _then(_WorkflowProgress(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as int,skipped: null == skipped ? _self.skipped : skipped // ignore: cast_nullable_to_non_nullable
as int,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
