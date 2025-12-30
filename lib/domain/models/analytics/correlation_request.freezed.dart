// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'correlation_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
CorrelationRequest _$CorrelationRequestFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'moodVsTracker':
          return MoodVsTrackerCorrelation.fromJson(
            json
          );
                case 'moodVsEntity':
          return MoodVsEntityCorrelation.fromJson(
            json
          );
                case 'trackerVsTracker':
          return TrackerVsTrackerCorrelation.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'CorrelationRequest',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$CorrelationRequest {

 DateRange get range;
/// Create a copy of CorrelationRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CorrelationRequestCopyWith<CorrelationRequest> get copyWith => _$CorrelationRequestCopyWithImpl<CorrelationRequest>(this as CorrelationRequest, _$identity);

  /// Serializes this CorrelationRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CorrelationRequest&&(identical(other.range, range) || other.range == range));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,range);

@override
String toString() {
  return 'CorrelationRequest(range: $range)';
}


}

/// @nodoc
abstract mixin class $CorrelationRequestCopyWith<$Res>  {
  factory $CorrelationRequestCopyWith(CorrelationRequest value, $Res Function(CorrelationRequest) _then) = _$CorrelationRequestCopyWithImpl;
@useResult
$Res call({
 DateRange range
});


$DateRangeCopyWith<$Res> get range;

}
/// @nodoc
class _$CorrelationRequestCopyWithImpl<$Res>
    implements $CorrelationRequestCopyWith<$Res> {
  _$CorrelationRequestCopyWithImpl(this._self, this._then);

  final CorrelationRequest _self;
  final $Res Function(CorrelationRequest) _then;

/// Create a copy of CorrelationRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? range = null,}) {
  return _then(_self.copyWith(
range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as DateRange,
  ));
}
/// Create a copy of CorrelationRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DateRangeCopyWith<$Res> get range {
  
  return $DateRangeCopyWith<$Res>(_self.range, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}


/// Adds pattern-matching-related methods to [CorrelationRequest].
extension CorrelationRequestPatterns on CorrelationRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MoodVsTrackerCorrelation value)?  moodVsTracker,TResult Function( MoodVsEntityCorrelation value)?  moodVsEntity,TResult Function( TrackerVsTrackerCorrelation value)?  trackerVsTracker,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MoodVsTrackerCorrelation() when moodVsTracker != null:
return moodVsTracker(_that);case MoodVsEntityCorrelation() when moodVsEntity != null:
return moodVsEntity(_that);case TrackerVsTrackerCorrelation() when trackerVsTracker != null:
return trackerVsTracker(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MoodVsTrackerCorrelation value)  moodVsTracker,required TResult Function( MoodVsEntityCorrelation value)  moodVsEntity,required TResult Function( TrackerVsTrackerCorrelation value)  trackerVsTracker,}){
final _that = this;
switch (_that) {
case MoodVsTrackerCorrelation():
return moodVsTracker(_that);case MoodVsEntityCorrelation():
return moodVsEntity(_that);case TrackerVsTrackerCorrelation():
return trackerVsTracker(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MoodVsTrackerCorrelation value)?  moodVsTracker,TResult? Function( MoodVsEntityCorrelation value)?  moodVsEntity,TResult? Function( TrackerVsTrackerCorrelation value)?  trackerVsTracker,}){
final _that = this;
switch (_that) {
case MoodVsTrackerCorrelation() when moodVsTracker != null:
return moodVsTracker(_that);case MoodVsEntityCorrelation() when moodVsEntity != null:
return moodVsEntity(_that);case TrackerVsTrackerCorrelation() when trackerVsTracker != null:
return trackerVsTracker(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String trackerId,  DateRange range)?  moodVsTracker,TResult Function( String entityId,  EntityType entityType,  DateRange range)?  moodVsEntity,TResult Function( String trackerId1,  String trackerId2,  DateRange range)?  trackerVsTracker,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MoodVsTrackerCorrelation() when moodVsTracker != null:
return moodVsTracker(_that.trackerId,_that.range);case MoodVsEntityCorrelation() when moodVsEntity != null:
return moodVsEntity(_that.entityId,_that.entityType,_that.range);case TrackerVsTrackerCorrelation() when trackerVsTracker != null:
return trackerVsTracker(_that.trackerId1,_that.trackerId2,_that.range);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String trackerId,  DateRange range)  moodVsTracker,required TResult Function( String entityId,  EntityType entityType,  DateRange range)  moodVsEntity,required TResult Function( String trackerId1,  String trackerId2,  DateRange range)  trackerVsTracker,}) {final _that = this;
switch (_that) {
case MoodVsTrackerCorrelation():
return moodVsTracker(_that.trackerId,_that.range);case MoodVsEntityCorrelation():
return moodVsEntity(_that.entityId,_that.entityType,_that.range);case TrackerVsTrackerCorrelation():
return trackerVsTracker(_that.trackerId1,_that.trackerId2,_that.range);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String trackerId,  DateRange range)?  moodVsTracker,TResult? Function( String entityId,  EntityType entityType,  DateRange range)?  moodVsEntity,TResult? Function( String trackerId1,  String trackerId2,  DateRange range)?  trackerVsTracker,}) {final _that = this;
switch (_that) {
case MoodVsTrackerCorrelation() when moodVsTracker != null:
return moodVsTracker(_that.trackerId,_that.range);case MoodVsEntityCorrelation() when moodVsEntity != null:
return moodVsEntity(_that.entityId,_that.entityType,_that.range);case TrackerVsTrackerCorrelation() when trackerVsTracker != null:
return trackerVsTracker(_that.trackerId1,_that.trackerId2,_that.range);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class MoodVsTrackerCorrelation implements CorrelationRequest {
  const MoodVsTrackerCorrelation({required this.trackerId, required this.range, final  String? $type}): $type = $type ?? 'moodVsTracker';
  factory MoodVsTrackerCorrelation.fromJson(Map<String, dynamic> json) => _$MoodVsTrackerCorrelationFromJson(json);

 final  String trackerId;
@override final  DateRange range;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CorrelationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoodVsTrackerCorrelationCopyWith<MoodVsTrackerCorrelation> get copyWith => _$MoodVsTrackerCorrelationCopyWithImpl<MoodVsTrackerCorrelation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MoodVsTrackerCorrelationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoodVsTrackerCorrelation&&(identical(other.trackerId, trackerId) || other.trackerId == trackerId)&&(identical(other.range, range) || other.range == range));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trackerId,range);

@override
String toString() {
  return 'CorrelationRequest.moodVsTracker(trackerId: $trackerId, range: $range)';
}


}

/// @nodoc
abstract mixin class $MoodVsTrackerCorrelationCopyWith<$Res> implements $CorrelationRequestCopyWith<$Res> {
  factory $MoodVsTrackerCorrelationCopyWith(MoodVsTrackerCorrelation value, $Res Function(MoodVsTrackerCorrelation) _then) = _$MoodVsTrackerCorrelationCopyWithImpl;
@override @useResult
$Res call({
 String trackerId, DateRange range
});


@override $DateRangeCopyWith<$Res> get range;

}
/// @nodoc
class _$MoodVsTrackerCorrelationCopyWithImpl<$Res>
    implements $MoodVsTrackerCorrelationCopyWith<$Res> {
  _$MoodVsTrackerCorrelationCopyWithImpl(this._self, this._then);

  final MoodVsTrackerCorrelation _self;
  final $Res Function(MoodVsTrackerCorrelation) _then;

/// Create a copy of CorrelationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trackerId = null,Object? range = null,}) {
  return _then(MoodVsTrackerCorrelation(
trackerId: null == trackerId ? _self.trackerId : trackerId // ignore: cast_nullable_to_non_nullable
as String,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as DateRange,
  ));
}

/// Create a copy of CorrelationRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DateRangeCopyWith<$Res> get range {
  
  return $DateRangeCopyWith<$Res>(_self.range, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class MoodVsEntityCorrelation implements CorrelationRequest {
  const MoodVsEntityCorrelation({required this.entityId, required this.entityType, required this.range, final  String? $type}): $type = $type ?? 'moodVsEntity';
  factory MoodVsEntityCorrelation.fromJson(Map<String, dynamic> json) => _$MoodVsEntityCorrelationFromJson(json);

 final  String entityId;
 final  EntityType entityType;
@override final  DateRange range;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CorrelationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoodVsEntityCorrelationCopyWith<MoodVsEntityCorrelation> get copyWith => _$MoodVsEntityCorrelationCopyWithImpl<MoodVsEntityCorrelation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MoodVsEntityCorrelationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoodVsEntityCorrelation&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.entityType, entityType) || other.entityType == entityType)&&(identical(other.range, range) || other.range == range));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,entityId,entityType,range);

@override
String toString() {
  return 'CorrelationRequest.moodVsEntity(entityId: $entityId, entityType: $entityType, range: $range)';
}


}

/// @nodoc
abstract mixin class $MoodVsEntityCorrelationCopyWith<$Res> implements $CorrelationRequestCopyWith<$Res> {
  factory $MoodVsEntityCorrelationCopyWith(MoodVsEntityCorrelation value, $Res Function(MoodVsEntityCorrelation) _then) = _$MoodVsEntityCorrelationCopyWithImpl;
@override @useResult
$Res call({
 String entityId, EntityType entityType, DateRange range
});


@override $DateRangeCopyWith<$Res> get range;

}
/// @nodoc
class _$MoodVsEntityCorrelationCopyWithImpl<$Res>
    implements $MoodVsEntityCorrelationCopyWith<$Res> {
  _$MoodVsEntityCorrelationCopyWithImpl(this._self, this._then);

  final MoodVsEntityCorrelation _self;
  final $Res Function(MoodVsEntityCorrelation) _then;

/// Create a copy of CorrelationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entityId = null,Object? entityType = null,Object? range = null,}) {
  return _then(MoodVsEntityCorrelation(
entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,entityType: null == entityType ? _self.entityType : entityType // ignore: cast_nullable_to_non_nullable
as EntityType,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as DateRange,
  ));
}

/// Create a copy of CorrelationRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DateRangeCopyWith<$Res> get range {
  
  return $DateRangeCopyWith<$Res>(_self.range, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class TrackerVsTrackerCorrelation implements CorrelationRequest {
  const TrackerVsTrackerCorrelation({required this.trackerId1, required this.trackerId2, required this.range, final  String? $type}): $type = $type ?? 'trackerVsTracker';
  factory TrackerVsTrackerCorrelation.fromJson(Map<String, dynamic> json) => _$TrackerVsTrackerCorrelationFromJson(json);

 final  String trackerId1;
 final  String trackerId2;
@override final  DateRange range;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CorrelationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackerVsTrackerCorrelationCopyWith<TrackerVsTrackerCorrelation> get copyWith => _$TrackerVsTrackerCorrelationCopyWithImpl<TrackerVsTrackerCorrelation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackerVsTrackerCorrelationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackerVsTrackerCorrelation&&(identical(other.trackerId1, trackerId1) || other.trackerId1 == trackerId1)&&(identical(other.trackerId2, trackerId2) || other.trackerId2 == trackerId2)&&(identical(other.range, range) || other.range == range));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trackerId1,trackerId2,range);

@override
String toString() {
  return 'CorrelationRequest.trackerVsTracker(trackerId1: $trackerId1, trackerId2: $trackerId2, range: $range)';
}


}

/// @nodoc
abstract mixin class $TrackerVsTrackerCorrelationCopyWith<$Res> implements $CorrelationRequestCopyWith<$Res> {
  factory $TrackerVsTrackerCorrelationCopyWith(TrackerVsTrackerCorrelation value, $Res Function(TrackerVsTrackerCorrelation) _then) = _$TrackerVsTrackerCorrelationCopyWithImpl;
@override @useResult
$Res call({
 String trackerId1, String trackerId2, DateRange range
});


@override $DateRangeCopyWith<$Res> get range;

}
/// @nodoc
class _$TrackerVsTrackerCorrelationCopyWithImpl<$Res>
    implements $TrackerVsTrackerCorrelationCopyWith<$Res> {
  _$TrackerVsTrackerCorrelationCopyWithImpl(this._self, this._then);

  final TrackerVsTrackerCorrelation _self;
  final $Res Function(TrackerVsTrackerCorrelation) _then;

/// Create a copy of CorrelationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trackerId1 = null,Object? trackerId2 = null,Object? range = null,}) {
  return _then(TrackerVsTrackerCorrelation(
trackerId1: null == trackerId1 ? _self.trackerId1 : trackerId1 // ignore: cast_nullable_to_non_nullable
as String,trackerId2: null == trackerId2 ? _self.trackerId2 : trackerId2 // ignore: cast_nullable_to_non_nullable
as String,range: null == range ? _self.range : range // ignore: cast_nullable_to_non_nullable
as DateRange,
  ));
}

/// Create a copy of CorrelationRequest
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DateRangeCopyWith<$Res> get range {
  
  return $DateRangeCopyWith<$Res>(_self.range, (value) {
    return _then(_self.copyWith(range: value));
  });
}
}

// dart format on
