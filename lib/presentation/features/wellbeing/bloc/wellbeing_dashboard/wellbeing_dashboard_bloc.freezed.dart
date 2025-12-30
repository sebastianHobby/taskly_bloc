// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wellbeing_dashboard_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WellbeingDashboardEvent {

 DateRange get dateRange;
/// Create a copy of WellbeingDashboardEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WellbeingDashboardEventCopyWith<WellbeingDashboardEvent> get copyWith => _$WellbeingDashboardEventCopyWithImpl<WellbeingDashboardEvent>(this as WellbeingDashboardEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WellbeingDashboardEvent&&(identical(other.dateRange, dateRange) || other.dateRange == dateRange));
}


@override
int get hashCode => Object.hash(runtimeType,dateRange);

@override
String toString() {
  return 'WellbeingDashboardEvent(dateRange: $dateRange)';
}


}

/// @nodoc
abstract mixin class $WellbeingDashboardEventCopyWith<$Res>  {
  factory $WellbeingDashboardEventCopyWith(WellbeingDashboardEvent value, $Res Function(WellbeingDashboardEvent) _then) = _$WellbeingDashboardEventCopyWithImpl;
@useResult
$Res call({
 DateRange dateRange
});


$DateRangeCopyWith<$Res> get dateRange;

}
/// @nodoc
class _$WellbeingDashboardEventCopyWithImpl<$Res>
    implements $WellbeingDashboardEventCopyWith<$Res> {
  _$WellbeingDashboardEventCopyWithImpl(this._self, this._then);

  final WellbeingDashboardEvent _self;
  final $Res Function(WellbeingDashboardEvent) _then;

/// Create a copy of WellbeingDashboardEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dateRange = null,}) {
  return _then(_self.copyWith(
dateRange: null == dateRange ? _self.dateRange : dateRange // ignore: cast_nullable_to_non_nullable
as DateRange,
  ));
}
/// Create a copy of WellbeingDashboardEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DateRangeCopyWith<$Res> get dateRange {
  
  return $DateRangeCopyWith<$Res>(_self.dateRange, (value) {
    return _then(_self.copyWith(dateRange: value));
  });
}
}


/// Adds pattern-matching-related methods to [WellbeingDashboardEvent].
extension WellbeingDashboardEventPatterns on WellbeingDashboardEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Load value)?  load,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Load() when load != null:
return load(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Load value)  load,}){
final _that = this;
switch (_that) {
case _Load():
return load(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Load value)?  load,}){
final _that = this;
switch (_that) {
case _Load() when load != null:
return load(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( DateRange dateRange)?  load,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Load() when load != null:
return load(_that.dateRange);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( DateRange dateRange)  load,}) {final _that = this;
switch (_that) {
case _Load():
return load(_that.dateRange);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( DateRange dateRange)?  load,}) {final _that = this;
switch (_that) {
case _Load() when load != null:
return load(_that.dateRange);case _:
  return null;

}
}

}

/// @nodoc


class _Load implements WellbeingDashboardEvent {
  const _Load({required this.dateRange});
  

@override final  DateRange dateRange;

/// Create a copy of WellbeingDashboardEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadCopyWith<_Load> get copyWith => __$LoadCopyWithImpl<_Load>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Load&&(identical(other.dateRange, dateRange) || other.dateRange == dateRange));
}


@override
int get hashCode => Object.hash(runtimeType,dateRange);

@override
String toString() {
  return 'WellbeingDashboardEvent.load(dateRange: $dateRange)';
}


}

/// @nodoc
abstract mixin class _$LoadCopyWith<$Res> implements $WellbeingDashboardEventCopyWith<$Res> {
  factory _$LoadCopyWith(_Load value, $Res Function(_Load) _then) = __$LoadCopyWithImpl;
@override @useResult
$Res call({
 DateRange dateRange
});


@override $DateRangeCopyWith<$Res> get dateRange;

}
/// @nodoc
class __$LoadCopyWithImpl<$Res>
    implements _$LoadCopyWith<$Res> {
  __$LoadCopyWithImpl(this._self, this._then);

  final _Load _self;
  final $Res Function(_Load) _then;

/// Create a copy of WellbeingDashboardEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dateRange = null,}) {
  return _then(_Load(
dateRange: null == dateRange ? _self.dateRange : dateRange // ignore: cast_nullable_to_non_nullable
as DateRange,
  ));
}

/// Create a copy of WellbeingDashboardEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DateRangeCopyWith<$Res> get dateRange {
  
  return $DateRangeCopyWith<$Res>(_self.dateRange, (value) {
    return _then(_self.copyWith(dateRange: value));
  });
}
}

/// @nodoc
mixin _$WellbeingDashboardState {

 bool get isLoading; TrendData? get moodTrend; List<CorrelationResult>? get topCorrelations; String? get error;
/// Create a copy of WellbeingDashboardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WellbeingDashboardStateCopyWith<WellbeingDashboardState> get copyWith => _$WellbeingDashboardStateCopyWithImpl<WellbeingDashboardState>(this as WellbeingDashboardState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WellbeingDashboardState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.moodTrend, moodTrend) || other.moodTrend == moodTrend)&&const DeepCollectionEquality().equals(other.topCorrelations, topCorrelations)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,moodTrend,const DeepCollectionEquality().hash(topCorrelations),error);

@override
String toString() {
  return 'WellbeingDashboardState(isLoading: $isLoading, moodTrend: $moodTrend, topCorrelations: $topCorrelations, error: $error)';
}


}

/// @nodoc
abstract mixin class $WellbeingDashboardStateCopyWith<$Res>  {
  factory $WellbeingDashboardStateCopyWith(WellbeingDashboardState value, $Res Function(WellbeingDashboardState) _then) = _$WellbeingDashboardStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, TrendData? moodTrend, List<CorrelationResult>? topCorrelations, String? error
});


$TrendDataCopyWith<$Res>? get moodTrend;

}
/// @nodoc
class _$WellbeingDashboardStateCopyWithImpl<$Res>
    implements $WellbeingDashboardStateCopyWith<$Res> {
  _$WellbeingDashboardStateCopyWithImpl(this._self, this._then);

  final WellbeingDashboardState _self;
  final $Res Function(WellbeingDashboardState) _then;

/// Create a copy of WellbeingDashboardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? moodTrend = freezed,Object? topCorrelations = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,moodTrend: freezed == moodTrend ? _self.moodTrend : moodTrend // ignore: cast_nullable_to_non_nullable
as TrendData?,topCorrelations: freezed == topCorrelations ? _self.topCorrelations : topCorrelations // ignore: cast_nullable_to_non_nullable
as List<CorrelationResult>?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of WellbeingDashboardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrendDataCopyWith<$Res>? get moodTrend {
    if (_self.moodTrend == null) {
    return null;
  }

  return $TrendDataCopyWith<$Res>(_self.moodTrend!, (value) {
    return _then(_self.copyWith(moodTrend: value));
  });
}
}


/// Adds pattern-matching-related methods to [WellbeingDashboardState].
extension WellbeingDashboardStatePatterns on WellbeingDashboardState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WellbeingDashboardState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WellbeingDashboardState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WellbeingDashboardState value)  $default,){
final _that = this;
switch (_that) {
case _WellbeingDashboardState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WellbeingDashboardState value)?  $default,){
final _that = this;
switch (_that) {
case _WellbeingDashboardState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  TrendData? moodTrend,  List<CorrelationResult>? topCorrelations,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WellbeingDashboardState() when $default != null:
return $default(_that.isLoading,_that.moodTrend,_that.topCorrelations,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  TrendData? moodTrend,  List<CorrelationResult>? topCorrelations,  String? error)  $default,) {final _that = this;
switch (_that) {
case _WellbeingDashboardState():
return $default(_that.isLoading,_that.moodTrend,_that.topCorrelations,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  TrendData? moodTrend,  List<CorrelationResult>? topCorrelations,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _WellbeingDashboardState() when $default != null:
return $default(_that.isLoading,_that.moodTrend,_that.topCorrelations,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _WellbeingDashboardState implements WellbeingDashboardState {
  const _WellbeingDashboardState({this.isLoading = true, this.moodTrend, final  List<CorrelationResult>? topCorrelations, this.error}): _topCorrelations = topCorrelations;
  

@override@JsonKey() final  bool isLoading;
@override final  TrendData? moodTrend;
 final  List<CorrelationResult>? _topCorrelations;
@override List<CorrelationResult>? get topCorrelations {
  final value = _topCorrelations;
  if (value == null) return null;
  if (_topCorrelations is EqualUnmodifiableListView) return _topCorrelations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? error;

/// Create a copy of WellbeingDashboardState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WellbeingDashboardStateCopyWith<_WellbeingDashboardState> get copyWith => __$WellbeingDashboardStateCopyWithImpl<_WellbeingDashboardState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WellbeingDashboardState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.moodTrend, moodTrend) || other.moodTrend == moodTrend)&&const DeepCollectionEquality().equals(other._topCorrelations, _topCorrelations)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,moodTrend,const DeepCollectionEquality().hash(_topCorrelations),error);

@override
String toString() {
  return 'WellbeingDashboardState(isLoading: $isLoading, moodTrend: $moodTrend, topCorrelations: $topCorrelations, error: $error)';
}


}

/// @nodoc
abstract mixin class _$WellbeingDashboardStateCopyWith<$Res> implements $WellbeingDashboardStateCopyWith<$Res> {
  factory _$WellbeingDashboardStateCopyWith(_WellbeingDashboardState value, $Res Function(_WellbeingDashboardState) _then) = __$WellbeingDashboardStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, TrendData? moodTrend, List<CorrelationResult>? topCorrelations, String? error
});


@override $TrendDataCopyWith<$Res>? get moodTrend;

}
/// @nodoc
class __$WellbeingDashboardStateCopyWithImpl<$Res>
    implements _$WellbeingDashboardStateCopyWith<$Res> {
  __$WellbeingDashboardStateCopyWithImpl(this._self, this._then);

  final _WellbeingDashboardState _self;
  final $Res Function(_WellbeingDashboardState) _then;

/// Create a copy of WellbeingDashboardState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? moodTrend = freezed,Object? topCorrelations = freezed,Object? error = freezed,}) {
  return _then(_WellbeingDashboardState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,moodTrend: freezed == moodTrend ? _self.moodTrend : moodTrend // ignore: cast_nullable_to_non_nullable
as TrendData?,topCorrelations: freezed == topCorrelations ? _self._topCorrelations : topCorrelations // ignore: cast_nullable_to_non_nullable
as List<CorrelationResult>?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of WellbeingDashboardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrendDataCopyWith<$Res>? get moodTrend {
    if (_self.moodTrend == null) {
    return null;
  }

  return $TrendDataCopyWith<$Res>(_self.moodTrend!, (value) {
    return _then(_self.copyWith(moodTrend: value));
  });
}
}

// dart format on
