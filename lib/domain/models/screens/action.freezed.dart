// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'action.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
Action _$ActionFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'markReviewed':
          return MarkReviewedAction.fromJson(
            json
          );
                case 'skip':
          return SkipAction.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'Action',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$Action {



  /// Serializes this Action to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Action);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Action()';
}


}

/// @nodoc
class $ActionCopyWith<$Res>  {
$ActionCopyWith(Action _, $Res Function(Action) __);
}


/// Adds pattern-matching-related methods to [Action].
extension ActionPatterns on Action {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MarkReviewedAction value)?  markReviewed,TResult Function( SkipAction value)?  skip,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MarkReviewedAction() when markReviewed != null:
return markReviewed(_that);case SkipAction() when skip != null:
return skip(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MarkReviewedAction value)  markReviewed,required TResult Function( SkipAction value)  skip,}){
final _that = this;
switch (_that) {
case MarkReviewedAction():
return markReviewed(_that);case SkipAction():
return skip(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MarkReviewedAction value)?  markReviewed,TResult? Function( SkipAction value)?  skip,}){
final _that = this;
switch (_that) {
case MarkReviewedAction() when markReviewed != null:
return markReviewed(_that);case SkipAction() when skip != null:
return skip(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String? notes)?  markReviewed,TResult Function( String? reason)?  skip,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MarkReviewedAction() when markReviewed != null:
return markReviewed(_that.notes);case SkipAction() when skip != null:
return skip(_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String? notes)  markReviewed,required TResult Function( String? reason)  skip,}) {final _that = this;
switch (_that) {
case MarkReviewedAction():
return markReviewed(_that.notes);case SkipAction():
return skip(_that.reason);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String? notes)?  markReviewed,TResult? Function( String? reason)?  skip,}) {final _that = this;
switch (_that) {
case MarkReviewedAction() when markReviewed != null:
return markReviewed(_that.notes);case SkipAction() when skip != null:
return skip(_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class MarkReviewedAction implements Action {
  const MarkReviewedAction({this.notes, final  String? $type}): $type = $type ?? 'markReviewed';
  factory MarkReviewedAction.fromJson(Map<String, dynamic> json) => _$MarkReviewedActionFromJson(json);

 final  String? notes;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Action
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MarkReviewedActionCopyWith<MarkReviewedAction> get copyWith => _$MarkReviewedActionCopyWithImpl<MarkReviewedAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MarkReviewedActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MarkReviewedAction&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notes);

@override
String toString() {
  return 'Action.markReviewed(notes: $notes)';
}


}

/// @nodoc
abstract mixin class $MarkReviewedActionCopyWith<$Res> implements $ActionCopyWith<$Res> {
  factory $MarkReviewedActionCopyWith(MarkReviewedAction value, $Res Function(MarkReviewedAction) _then) = _$MarkReviewedActionCopyWithImpl;
@useResult
$Res call({
 String? notes
});




}
/// @nodoc
class _$MarkReviewedActionCopyWithImpl<$Res>
    implements $MarkReviewedActionCopyWith<$Res> {
  _$MarkReviewedActionCopyWithImpl(this._self, this._then);

  final MarkReviewedAction _self;
  final $Res Function(MarkReviewedAction) _then;

/// Create a copy of Action
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? notes = freezed,}) {
  return _then(MarkReviewedAction(
notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SkipAction implements Action {
  const SkipAction({this.reason, final  String? $type}): $type = $type ?? 'skip';
  factory SkipAction.fromJson(Map<String, dynamic> json) => _$SkipActionFromJson(json);

 final  String? reason;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of Action
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkipActionCopyWith<SkipAction> get copyWith => _$SkipActionCopyWithImpl<SkipAction>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SkipActionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SkipAction&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reason);

@override
String toString() {
  return 'Action.skip(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $SkipActionCopyWith<$Res> implements $ActionCopyWith<$Res> {
  factory $SkipActionCopyWith(SkipAction value, $Res Function(SkipAction) _then) = _$SkipActionCopyWithImpl;
@useResult
$Res call({
 String? reason
});




}
/// @nodoc
class _$SkipActionCopyWithImpl<$Res>
    implements $SkipActionCopyWith<$Res> {
  _$SkipActionCopyWithImpl(this._self, this._then);

  final SkipAction _self;
  final $Res Function(SkipAction) _then;

/// Create a copy of Action
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = freezed,}) {
  return _then(SkipAction(
reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
