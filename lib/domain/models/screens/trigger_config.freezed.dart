// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trigger_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
TriggerConfig _$TriggerConfigFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'schedule':
          return ScheduleTrigger.fromJson(
            json
          );
                case 'notReviewedSince':
          return NotReviewedSinceTrigger.fromJson(
            json
          );
                case 'manual':
          return ManualTrigger.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'TriggerConfig',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$TriggerConfig {



  /// Serializes this TriggerConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TriggerConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TriggerConfig()';
}


}

/// @nodoc
class $TriggerConfigCopyWith<$Res>  {
$TriggerConfigCopyWith(TriggerConfig _, $Res Function(TriggerConfig) __);
}


/// Adds pattern-matching-related methods to [TriggerConfig].
extension TriggerConfigPatterns on TriggerConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ScheduleTrigger value)?  schedule,TResult Function( NotReviewedSinceTrigger value)?  notReviewedSince,TResult Function( ManualTrigger value)?  manual,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ScheduleTrigger() when schedule != null:
return schedule(_that);case NotReviewedSinceTrigger() when notReviewedSince != null:
return notReviewedSince(_that);case ManualTrigger() when manual != null:
return manual(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ScheduleTrigger value)  schedule,required TResult Function( NotReviewedSinceTrigger value)  notReviewedSince,required TResult Function( ManualTrigger value)  manual,}){
final _that = this;
switch (_that) {
case ScheduleTrigger():
return schedule(_that);case NotReviewedSinceTrigger():
return notReviewedSince(_that);case ManualTrigger():
return manual(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ScheduleTrigger value)?  schedule,TResult? Function( NotReviewedSinceTrigger value)?  notReviewedSince,TResult? Function( ManualTrigger value)?  manual,}){
final _that = this;
switch (_that) {
case ScheduleTrigger() when schedule != null:
return schedule(_that);case NotReviewedSinceTrigger() when notReviewedSince != null:
return notReviewedSince(_that);case ManualTrigger() when manual != null:
return manual(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String rrule,  DateTime? nextTriggerDate)?  schedule,TResult Function( int days)?  notReviewedSince,TResult Function()?  manual,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ScheduleTrigger() when schedule != null:
return schedule(_that.rrule,_that.nextTriggerDate);case NotReviewedSinceTrigger() when notReviewedSince != null:
return notReviewedSince(_that.days);case ManualTrigger() when manual != null:
return manual();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String rrule,  DateTime? nextTriggerDate)  schedule,required TResult Function( int days)  notReviewedSince,required TResult Function()  manual,}) {final _that = this;
switch (_that) {
case ScheduleTrigger():
return schedule(_that.rrule,_that.nextTriggerDate);case NotReviewedSinceTrigger():
return notReviewedSince(_that.days);case ManualTrigger():
return manual();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String rrule,  DateTime? nextTriggerDate)?  schedule,TResult? Function( int days)?  notReviewedSince,TResult? Function()?  manual,}) {final _that = this;
switch (_that) {
case ScheduleTrigger() when schedule != null:
return schedule(_that.rrule,_that.nextTriggerDate);case NotReviewedSinceTrigger() when notReviewedSince != null:
return notReviewedSince(_that.days);case ManualTrigger() when manual != null:
return manual();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class ScheduleTrigger implements TriggerConfig {
  const ScheduleTrigger({required this.rrule, this.nextTriggerDate, final  String? $type}): $type = $type ?? 'schedule';
  factory ScheduleTrigger.fromJson(Map<String, dynamic> json) => _$ScheduleTriggerFromJson(json);

 final  String rrule;
 final  DateTime? nextTriggerDate;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of TriggerConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduleTriggerCopyWith<ScheduleTrigger> get copyWith => _$ScheduleTriggerCopyWithImpl<ScheduleTrigger>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScheduleTriggerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduleTrigger&&(identical(other.rrule, rrule) || other.rrule == rrule)&&(identical(other.nextTriggerDate, nextTriggerDate) || other.nextTriggerDate == nextTriggerDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rrule,nextTriggerDate);

@override
String toString() {
  return 'TriggerConfig.schedule(rrule: $rrule, nextTriggerDate: $nextTriggerDate)';
}


}

/// @nodoc
abstract mixin class $ScheduleTriggerCopyWith<$Res> implements $TriggerConfigCopyWith<$Res> {
  factory $ScheduleTriggerCopyWith(ScheduleTrigger value, $Res Function(ScheduleTrigger) _then) = _$ScheduleTriggerCopyWithImpl;
@useResult
$Res call({
 String rrule, DateTime? nextTriggerDate
});




}
/// @nodoc
class _$ScheduleTriggerCopyWithImpl<$Res>
    implements $ScheduleTriggerCopyWith<$Res> {
  _$ScheduleTriggerCopyWithImpl(this._self, this._then);

  final ScheduleTrigger _self;
  final $Res Function(ScheduleTrigger) _then;

/// Create a copy of TriggerConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? rrule = null,Object? nextTriggerDate = freezed,}) {
  return _then(ScheduleTrigger(
rrule: null == rrule ? _self.rrule : rrule // ignore: cast_nullable_to_non_nullable
as String,nextTriggerDate: freezed == nextTriggerDate ? _self.nextTriggerDate : nextTriggerDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class NotReviewedSinceTrigger implements TriggerConfig {
  const NotReviewedSinceTrigger({required this.days, final  String? $type}): $type = $type ?? 'notReviewedSince';
  factory NotReviewedSinceTrigger.fromJson(Map<String, dynamic> json) => _$NotReviewedSinceTriggerFromJson(json);

 final  int days;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of TriggerConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotReviewedSinceTriggerCopyWith<NotReviewedSinceTrigger> get copyWith => _$NotReviewedSinceTriggerCopyWithImpl<NotReviewedSinceTrigger>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotReviewedSinceTriggerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotReviewedSinceTrigger&&(identical(other.days, days) || other.days == days));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,days);

@override
String toString() {
  return 'TriggerConfig.notReviewedSince(days: $days)';
}


}

/// @nodoc
abstract mixin class $NotReviewedSinceTriggerCopyWith<$Res> implements $TriggerConfigCopyWith<$Res> {
  factory $NotReviewedSinceTriggerCopyWith(NotReviewedSinceTrigger value, $Res Function(NotReviewedSinceTrigger) _then) = _$NotReviewedSinceTriggerCopyWithImpl;
@useResult
$Res call({
 int days
});




}
/// @nodoc
class _$NotReviewedSinceTriggerCopyWithImpl<$Res>
    implements $NotReviewedSinceTriggerCopyWith<$Res> {
  _$NotReviewedSinceTriggerCopyWithImpl(this._self, this._then);

  final NotReviewedSinceTrigger _self;
  final $Res Function(NotReviewedSinceTrigger) _then;

/// Create a copy of TriggerConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? days = null,}) {
  return _then(NotReviewedSinceTrigger(
days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ManualTrigger implements TriggerConfig {
  const ManualTrigger({final  String? $type}): $type = $type ?? 'manual';
  factory ManualTrigger.fromJson(Map<String, dynamic> json) => _$ManualTriggerFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$ManualTriggerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ManualTrigger);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TriggerConfig.manual()';
}


}




// dart format on
