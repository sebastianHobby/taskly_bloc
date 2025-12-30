// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'completion_criteria.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
CompletionCriteria _$CompletionCriteriaFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'allItemsReviewed':
          return AllItemsReviewed.fromJson(
            json
          );
                case 'timeElapsed':
          return TimeElapsed.fromJson(
            json
          );
                case 'percentageReviewed':
          return PercentageReviewed.fromJson(
            json
          );
                case 'manual':
          return ManualCompletion.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'CompletionCriteria',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$CompletionCriteria {



  /// Serializes this CompletionCriteria to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompletionCriteria);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CompletionCriteria()';
}


}

/// @nodoc
class $CompletionCriteriaCopyWith<$Res>  {
$CompletionCriteriaCopyWith(CompletionCriteria _, $Res Function(CompletionCriteria) __);
}


/// Adds pattern-matching-related methods to [CompletionCriteria].
extension CompletionCriteriaPatterns on CompletionCriteria {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AllItemsReviewed value)?  allItemsReviewed,TResult Function( TimeElapsed value)?  timeElapsed,TResult Function( PercentageReviewed value)?  percentageReviewed,TResult Function( ManualCompletion value)?  manual,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AllItemsReviewed() when allItemsReviewed != null:
return allItemsReviewed(_that);case TimeElapsed() when timeElapsed != null:
return timeElapsed(_that);case PercentageReviewed() when percentageReviewed != null:
return percentageReviewed(_that);case ManualCompletion() when manual != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AllItemsReviewed value)  allItemsReviewed,required TResult Function( TimeElapsed value)  timeElapsed,required TResult Function( PercentageReviewed value)  percentageReviewed,required TResult Function( ManualCompletion value)  manual,}){
final _that = this;
switch (_that) {
case AllItemsReviewed():
return allItemsReviewed(_that);case TimeElapsed():
return timeElapsed(_that);case PercentageReviewed():
return percentageReviewed(_that);case ManualCompletion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AllItemsReviewed value)?  allItemsReviewed,TResult? Function( TimeElapsed value)?  timeElapsed,TResult? Function( PercentageReviewed value)?  percentageReviewed,TResult? Function( ManualCompletion value)?  manual,}){
final _that = this;
switch (_that) {
case AllItemsReviewed() when allItemsReviewed != null:
return allItemsReviewed(_that);case TimeElapsed() when timeElapsed != null:
return timeElapsed(_that);case PercentageReviewed() when percentageReviewed != null:
return percentageReviewed(_that);case ManualCompletion() when manual != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  allItemsReviewed,TResult Function( int minutes)?  timeElapsed,TResult Function(@IntRange(1, 100)  int percentage)?  percentageReviewed,TResult Function()?  manual,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AllItemsReviewed() when allItemsReviewed != null:
return allItemsReviewed();case TimeElapsed() when timeElapsed != null:
return timeElapsed(_that.minutes);case PercentageReviewed() when percentageReviewed != null:
return percentageReviewed(_that.percentage);case ManualCompletion() when manual != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  allItemsReviewed,required TResult Function( int minutes)  timeElapsed,required TResult Function(@IntRange(1, 100)  int percentage)  percentageReviewed,required TResult Function()  manual,}) {final _that = this;
switch (_that) {
case AllItemsReviewed():
return allItemsReviewed();case TimeElapsed():
return timeElapsed(_that.minutes);case PercentageReviewed():
return percentageReviewed(_that.percentage);case ManualCompletion():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  allItemsReviewed,TResult? Function( int minutes)?  timeElapsed,TResult? Function(@IntRange(1, 100)  int percentage)?  percentageReviewed,TResult? Function()?  manual,}) {final _that = this;
switch (_that) {
case AllItemsReviewed() when allItemsReviewed != null:
return allItemsReviewed();case TimeElapsed() when timeElapsed != null:
return timeElapsed(_that.minutes);case PercentageReviewed() when percentageReviewed != null:
return percentageReviewed(_that.percentage);case ManualCompletion() when manual != null:
return manual();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class AllItemsReviewed implements CompletionCriteria {
  const AllItemsReviewed({final  String? $type}): $type = $type ?? 'allItemsReviewed';
  factory AllItemsReviewed.fromJson(Map<String, dynamic> json) => _$AllItemsReviewedFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$AllItemsReviewedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AllItemsReviewed);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CompletionCriteria.allItemsReviewed()';
}


}




/// @nodoc
@JsonSerializable()

class TimeElapsed implements CompletionCriteria {
  const TimeElapsed({required this.minutes, final  String? $type}): $type = $type ?? 'timeElapsed';
  factory TimeElapsed.fromJson(Map<String, dynamic> json) => _$TimeElapsedFromJson(json);

 final  int minutes;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CompletionCriteria
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeElapsedCopyWith<TimeElapsed> get copyWith => _$TimeElapsedCopyWithImpl<TimeElapsed>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TimeElapsedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeElapsed&&(identical(other.minutes, minutes) || other.minutes == minutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minutes);

@override
String toString() {
  return 'CompletionCriteria.timeElapsed(minutes: $minutes)';
}


}

/// @nodoc
abstract mixin class $TimeElapsedCopyWith<$Res> implements $CompletionCriteriaCopyWith<$Res> {
  factory $TimeElapsedCopyWith(TimeElapsed value, $Res Function(TimeElapsed) _then) = _$TimeElapsedCopyWithImpl;
@useResult
$Res call({
 int minutes
});




}
/// @nodoc
class _$TimeElapsedCopyWithImpl<$Res>
    implements $TimeElapsedCopyWith<$Res> {
  _$TimeElapsedCopyWithImpl(this._self, this._then);

  final TimeElapsed _self;
  final $Res Function(TimeElapsed) _then;

/// Create a copy of CompletionCriteria
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? minutes = null,}) {
  return _then(TimeElapsed(
minutes: null == minutes ? _self.minutes : minutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class PercentageReviewed implements CompletionCriteria {
  const PercentageReviewed({@IntRange(1, 100) required this.percentage, final  String? $type}): $type = $type ?? 'percentageReviewed';
  factory PercentageReviewed.fromJson(Map<String, dynamic> json) => _$PercentageReviewedFromJson(json);

@IntRange(1, 100) final  int percentage;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of CompletionCriteria
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PercentageReviewedCopyWith<PercentageReviewed> get copyWith => _$PercentageReviewedCopyWithImpl<PercentageReviewed>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PercentageReviewedToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PercentageReviewed&&(identical(other.percentage, percentage) || other.percentage == percentage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,percentage);

@override
String toString() {
  return 'CompletionCriteria.percentageReviewed(percentage: $percentage)';
}


}

/// @nodoc
abstract mixin class $PercentageReviewedCopyWith<$Res> implements $CompletionCriteriaCopyWith<$Res> {
  factory $PercentageReviewedCopyWith(PercentageReviewed value, $Res Function(PercentageReviewed) _then) = _$PercentageReviewedCopyWithImpl;
@useResult
$Res call({
@IntRange(1, 100) int percentage
});




}
/// @nodoc
class _$PercentageReviewedCopyWithImpl<$Res>
    implements $PercentageReviewedCopyWith<$Res> {
  _$PercentageReviewedCopyWithImpl(this._self, this._then);

  final PercentageReviewed _self;
  final $Res Function(PercentageReviewed) _then;

/// Create a copy of CompletionCriteria
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? percentage = null,}) {
  return _then(PercentageReviewed(
percentage: null == percentage ? _self.percentage : percentage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ManualCompletion implements CompletionCriteria {
  const ManualCompletion({final  String? $type}): $type = $type ?? 'manual';
  factory ManualCompletion.fromJson(Map<String, dynamic> json) => _$ManualCompletionFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$ManualCompletionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ManualCompletion);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CompletionCriteria.manual()';
}


}




// dart format on
