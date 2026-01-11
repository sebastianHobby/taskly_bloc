// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tracker_management_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TrackerManagementEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackerManagementEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TrackerManagementEvent()';
}


}

/// @nodoc
class $TrackerManagementEventCopyWith<$Res>  {
$TrackerManagementEventCopyWith(TrackerManagementEvent _, $Res Function(TrackerManagementEvent) __);
}


/// Adds pattern-matching-related methods to [TrackerManagementEvent].
extension TrackerManagementEventPatterns on TrackerManagementEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _LoadTrackers value)?  loadTrackers,TResult Function( _SaveTracker value)?  saveTracker,TResult Function( _DeleteTracker value)?  deleteTracker,TResult Function( _ReorderTrackers value)?  reorderTrackers,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoadTrackers() when loadTrackers != null:
return loadTrackers(_that);case _SaveTracker() when saveTracker != null:
return saveTracker(_that);case _DeleteTracker() when deleteTracker != null:
return deleteTracker(_that);case _ReorderTrackers() when reorderTrackers != null:
return reorderTrackers(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _LoadTrackers value)  loadTrackers,required TResult Function( _SaveTracker value)  saveTracker,required TResult Function( _DeleteTracker value)  deleteTracker,required TResult Function( _ReorderTrackers value)  reorderTrackers,}){
final _that = this;
switch (_that) {
case _LoadTrackers():
return loadTrackers(_that);case _SaveTracker():
return saveTracker(_that);case _DeleteTracker():
return deleteTracker(_that);case _ReorderTrackers():
return reorderTrackers(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _LoadTrackers value)?  loadTrackers,TResult? Function( _SaveTracker value)?  saveTracker,TResult? Function( _DeleteTracker value)?  deleteTracker,TResult? Function( _ReorderTrackers value)?  reorderTrackers,}){
final _that = this;
switch (_that) {
case _LoadTrackers() when loadTrackers != null:
return loadTrackers(_that);case _SaveTracker() when saveTracker != null:
return saveTracker(_that);case _DeleteTracker() when deleteTracker != null:
return deleteTracker(_that);case _ReorderTrackers() when reorderTrackers != null:
return reorderTrackers(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadTrackers,TResult Function( Tracker tracker)?  saveTracker,TResult Function( String trackerId)?  deleteTracker,TResult Function( List<String> trackerIds)?  reorderTrackers,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoadTrackers() when loadTrackers != null:
return loadTrackers();case _SaveTracker() when saveTracker != null:
return saveTracker(_that.tracker);case _DeleteTracker() when deleteTracker != null:
return deleteTracker(_that.trackerId);case _ReorderTrackers() when reorderTrackers != null:
return reorderTrackers(_that.trackerIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadTrackers,required TResult Function( Tracker tracker)  saveTracker,required TResult Function( String trackerId)  deleteTracker,required TResult Function( List<String> trackerIds)  reorderTrackers,}) {final _that = this;
switch (_that) {
case _LoadTrackers():
return loadTrackers();case _SaveTracker():
return saveTracker(_that.tracker);case _DeleteTracker():
return deleteTracker(_that.trackerId);case _ReorderTrackers():
return reorderTrackers(_that.trackerIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadTrackers,TResult? Function( Tracker tracker)?  saveTracker,TResult? Function( String trackerId)?  deleteTracker,TResult? Function( List<String> trackerIds)?  reorderTrackers,}) {final _that = this;
switch (_that) {
case _LoadTrackers() when loadTrackers != null:
return loadTrackers();case _SaveTracker() when saveTracker != null:
return saveTracker(_that.tracker);case _DeleteTracker() when deleteTracker != null:
return deleteTracker(_that.trackerId);case _ReorderTrackers() when reorderTrackers != null:
return reorderTrackers(_that.trackerIds);case _:
  return null;

}
}

}

/// @nodoc


class _LoadTrackers implements TrackerManagementEvent {
  const _LoadTrackers();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadTrackers);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TrackerManagementEvent.loadTrackers()';
}


}




/// @nodoc


class _SaveTracker implements TrackerManagementEvent {
  const _SaveTracker(this.tracker);
  

 final  Tracker tracker;

/// Create a copy of TrackerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SaveTrackerCopyWith<_SaveTracker> get copyWith => __$SaveTrackerCopyWithImpl<_SaveTracker>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SaveTracker&&(identical(other.tracker, tracker) || other.tracker == tracker));
}


@override
int get hashCode => Object.hash(runtimeType,tracker);

@override
String toString() {
  return 'TrackerManagementEvent.saveTracker(tracker: $tracker)';
}


}

/// @nodoc
abstract mixin class _$SaveTrackerCopyWith<$Res> implements $TrackerManagementEventCopyWith<$Res> {
  factory _$SaveTrackerCopyWith(_SaveTracker value, $Res Function(_SaveTracker) _then) = __$SaveTrackerCopyWithImpl;
@useResult
$Res call({
 Tracker tracker
});


$TrackerCopyWith<$Res> get tracker;

}
/// @nodoc
class __$SaveTrackerCopyWithImpl<$Res>
    implements _$SaveTrackerCopyWith<$Res> {
  __$SaveTrackerCopyWithImpl(this._self, this._then);

  final _SaveTracker _self;
  final $Res Function(_SaveTracker) _then;

/// Create a copy of TrackerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tracker = null,}) {
  return _then(_SaveTracker(
null == tracker ? _self.tracker : tracker // ignore: cast_nullable_to_non_nullable
as Tracker,
  ));
}

/// Create a copy of TrackerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrackerCopyWith<$Res> get tracker {
  
  return $TrackerCopyWith<$Res>(_self.tracker, (value) {
    return _then(_self.copyWith(tracker: value));
  });
}
}

/// @nodoc


class _DeleteTracker implements TrackerManagementEvent {
  const _DeleteTracker(this.trackerId);
  

 final  String trackerId;

/// Create a copy of TrackerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeleteTrackerCopyWith<_DeleteTracker> get copyWith => __$DeleteTrackerCopyWithImpl<_DeleteTracker>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeleteTracker&&(identical(other.trackerId, trackerId) || other.trackerId == trackerId));
}


@override
int get hashCode => Object.hash(runtimeType,trackerId);

@override
String toString() {
  return 'TrackerManagementEvent.deleteTracker(trackerId: $trackerId)';
}


}

/// @nodoc
abstract mixin class _$DeleteTrackerCopyWith<$Res> implements $TrackerManagementEventCopyWith<$Res> {
  factory _$DeleteTrackerCopyWith(_DeleteTracker value, $Res Function(_DeleteTracker) _then) = __$DeleteTrackerCopyWithImpl;
@useResult
$Res call({
 String trackerId
});




}
/// @nodoc
class __$DeleteTrackerCopyWithImpl<$Res>
    implements _$DeleteTrackerCopyWith<$Res> {
  __$DeleteTrackerCopyWithImpl(this._self, this._then);

  final _DeleteTracker _self;
  final $Res Function(_DeleteTracker) _then;

/// Create a copy of TrackerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? trackerId = null,}) {
  return _then(_DeleteTracker(
null == trackerId ? _self.trackerId : trackerId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ReorderTrackers implements TrackerManagementEvent {
  const _ReorderTrackers(final  List<String> trackerIds): _trackerIds = trackerIds;
  

 final  List<String> _trackerIds;
 List<String> get trackerIds {
  if (_trackerIds is EqualUnmodifiableListView) return _trackerIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_trackerIds);
}


/// Create a copy of TrackerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReorderTrackersCopyWith<_ReorderTrackers> get copyWith => __$ReorderTrackersCopyWithImpl<_ReorderTrackers>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReorderTrackers&&const DeepCollectionEquality().equals(other._trackerIds, _trackerIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_trackerIds));

@override
String toString() {
  return 'TrackerManagementEvent.reorderTrackers(trackerIds: $trackerIds)';
}


}

/// @nodoc
abstract mixin class _$ReorderTrackersCopyWith<$Res> implements $TrackerManagementEventCopyWith<$Res> {
  factory _$ReorderTrackersCopyWith(_ReorderTrackers value, $Res Function(_ReorderTrackers) _then) = __$ReorderTrackersCopyWithImpl;
@useResult
$Res call({
 List<String> trackerIds
});




}
/// @nodoc
class __$ReorderTrackersCopyWithImpl<$Res>
    implements _$ReorderTrackersCopyWith<$Res> {
  __$ReorderTrackersCopyWithImpl(this._self, this._then);

  final _ReorderTrackers _self;
  final $Res Function(_ReorderTrackers) _then;

/// Create a copy of TrackerManagementEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? trackerIds = null,}) {
  return _then(_ReorderTrackers(
null == trackerIds ? _self._trackerIds : trackerIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$TrackerManagementState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackerManagementState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TrackerManagementState()';
}


}

/// @nodoc
class $TrackerManagementStateCopyWith<$Res>  {
$TrackerManagementStateCopyWith(TrackerManagementState _, $Res Function(TrackerManagementState) __);
}


/// Adds pattern-matching-related methods to [TrackerManagementState].
extension TrackerManagementStatePatterns on TrackerManagementState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _Loaded value)?  loaded,TResult Function( _Saved value)?  saved,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _Saved() when saved != null:
return saved(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _Loaded value)  loaded,required TResult Function( _Saved value)  saved,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _Loaded():
return loaded(_that);case _Saved():
return saved(_that);case _Error():
return error(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _Loaded value)?  loaded,TResult? Function( _Saved value)?  saved,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _Saved() when saved != null:
return saved(_that);case _Error() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Tracker> trackers)?  loaded,TResult Function()?  saved,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.trackers);case _Saved() when saved != null:
return saved();case _Error() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Tracker> trackers)  loaded,required TResult Function()  saved,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.trackers);case _Saved():
return saved();case _Error():
return error(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Tracker> trackers)?  loaded,TResult? Function()?  saved,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.trackers);case _Saved() when saved != null:
return saved();case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements TrackerManagementState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TrackerManagementState.initial()';
}


}




/// @nodoc


class _Loading implements TrackerManagementState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TrackerManagementState.loading()';
}


}




/// @nodoc


class _Loaded implements TrackerManagementState {
  const _Loaded(final  List<Tracker> trackers): _trackers = trackers;
  

 final  List<Tracker> _trackers;
 List<Tracker> get trackers {
  if (_trackers is EqualUnmodifiableListView) return _trackers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_trackers);
}


/// Create a copy of TrackerManagementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other._trackers, _trackers));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_trackers));

@override
String toString() {
  return 'TrackerManagementState.loaded(trackers: $trackers)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $TrackerManagementStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 List<Tracker> trackers
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of TrackerManagementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? trackers = null,}) {
  return _then(_Loaded(
null == trackers ? _self._trackers : trackers // ignore: cast_nullable_to_non_nullable
as List<Tracker>,
  ));
}


}

/// @nodoc


class _Saved implements TrackerManagementState {
  const _Saved();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Saved);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TrackerManagementState.saved()';
}


}




/// @nodoc


class _Error implements TrackerManagementState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of TrackerManagementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorCopyWith<_Error> get copyWith => __$ErrorCopyWithImpl<_Error>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Error&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'TrackerManagementState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $TrackerManagementStateCopyWith<$Res> {
  factory _$ErrorCopyWith(_Error value, $Res Function(_Error) _then) = __$ErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$ErrorCopyWithImpl<$Res>
    implements _$ErrorCopyWith<$Res> {
  __$ErrorCopyWithImpl(this._self, this._then);

  final _Error _self;
  final $Res Function(_Error) _then;

/// Create a copy of TrackerManagementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
