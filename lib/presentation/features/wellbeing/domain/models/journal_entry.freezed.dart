// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journal_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JournalEntry {

 String get id; String get userId; DateTime get entryDate; DateTime get entryTime; DateTime get createdAt; DateTime get updatedAt; MoodRating? get moodRating; String? get journalText; List<TrackerResponse> get trackerResponses;
/// Create a copy of JournalEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalEntryCopyWith<JournalEntry> get copyWith => _$JournalEntryCopyWithImpl<JournalEntry>(this as JournalEntry, _$identity);

  /// Serializes this JournalEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.entryDate, entryDate) || other.entryDate == entryDate)&&(identical(other.entryTime, entryTime) || other.entryTime == entryTime)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.moodRating, moodRating) || other.moodRating == moodRating)&&(identical(other.journalText, journalText) || other.journalText == journalText)&&const DeepCollectionEquality().equals(other.trackerResponses, trackerResponses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,entryDate,entryTime,createdAt,updatedAt,moodRating,journalText,const DeepCollectionEquality().hash(trackerResponses));

@override
String toString() {
  return 'JournalEntry(id: $id, userId: $userId, entryDate: $entryDate, entryTime: $entryTime, createdAt: $createdAt, updatedAt: $updatedAt, moodRating: $moodRating, journalText: $journalText, trackerResponses: $trackerResponses)';
}


}

/// @nodoc
abstract mixin class $JournalEntryCopyWith<$Res>  {
  factory $JournalEntryCopyWith(JournalEntry value, $Res Function(JournalEntry) _then) = _$JournalEntryCopyWithImpl;
@useResult
$Res call({
 String id, String userId, DateTime entryDate, DateTime entryTime, DateTime createdAt, DateTime updatedAt, MoodRating? moodRating, String? journalText, List<TrackerResponse> trackerResponses
});




}
/// @nodoc
class _$JournalEntryCopyWithImpl<$Res>
    implements $JournalEntryCopyWith<$Res> {
  _$JournalEntryCopyWithImpl(this._self, this._then);

  final JournalEntry _self;
  final $Res Function(JournalEntry) _then;

/// Create a copy of JournalEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? entryDate = null,Object? entryTime = null,Object? createdAt = null,Object? updatedAt = null,Object? moodRating = freezed,Object? journalText = freezed,Object? trackerResponses = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,entryDate: null == entryDate ? _self.entryDate : entryDate // ignore: cast_nullable_to_non_nullable
as DateTime,entryTime: null == entryTime ? _self.entryTime : entryTime // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,moodRating: freezed == moodRating ? _self.moodRating : moodRating // ignore: cast_nullable_to_non_nullable
as MoodRating?,journalText: freezed == journalText ? _self.journalText : journalText // ignore: cast_nullable_to_non_nullable
as String?,trackerResponses: null == trackerResponses ? _self.trackerResponses : trackerResponses // ignore: cast_nullable_to_non_nullable
as List<TrackerResponse>,
  ));
}

}


/// Adds pattern-matching-related methods to [JournalEntry].
extension JournalEntryPatterns on JournalEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JournalEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JournalEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JournalEntry value)  $default,){
final _that = this;
switch (_that) {
case _JournalEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JournalEntry value)?  $default,){
final _that = this;
switch (_that) {
case _JournalEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  DateTime entryDate,  DateTime entryTime,  DateTime createdAt,  DateTime updatedAt,  MoodRating? moodRating,  String? journalText,  List<TrackerResponse> trackerResponses)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JournalEntry() when $default != null:
return $default(_that.id,_that.userId,_that.entryDate,_that.entryTime,_that.createdAt,_that.updatedAt,_that.moodRating,_that.journalText,_that.trackerResponses);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  DateTime entryDate,  DateTime entryTime,  DateTime createdAt,  DateTime updatedAt,  MoodRating? moodRating,  String? journalText,  List<TrackerResponse> trackerResponses)  $default,) {final _that = this;
switch (_that) {
case _JournalEntry():
return $default(_that.id,_that.userId,_that.entryDate,_that.entryTime,_that.createdAt,_that.updatedAt,_that.moodRating,_that.journalText,_that.trackerResponses);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  DateTime entryDate,  DateTime entryTime,  DateTime createdAt,  DateTime updatedAt,  MoodRating? moodRating,  String? journalText,  List<TrackerResponse> trackerResponses)?  $default,) {final _that = this;
switch (_that) {
case _JournalEntry() when $default != null:
return $default(_that.id,_that.userId,_that.entryDate,_that.entryTime,_that.createdAt,_that.updatedAt,_that.moodRating,_that.journalText,_that.trackerResponses);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JournalEntry implements JournalEntry {
  const _JournalEntry({required this.id, required this.userId, required this.entryDate, required this.entryTime, required this.createdAt, required this.updatedAt, this.moodRating, this.journalText, final  List<TrackerResponse> trackerResponses = const []}): _trackerResponses = trackerResponses;
  factory _JournalEntry.fromJson(Map<String, dynamic> json) => _$JournalEntryFromJson(json);

@override final  String id;
@override final  String userId;
@override final  DateTime entryDate;
@override final  DateTime entryTime;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  MoodRating? moodRating;
@override final  String? journalText;
 final  List<TrackerResponse> _trackerResponses;
@override@JsonKey() List<TrackerResponse> get trackerResponses {
  if (_trackerResponses is EqualUnmodifiableListView) return _trackerResponses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_trackerResponses);
}


/// Create a copy of JournalEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JournalEntryCopyWith<_JournalEntry> get copyWith => __$JournalEntryCopyWithImpl<_JournalEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JournalEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JournalEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.entryDate, entryDate) || other.entryDate == entryDate)&&(identical(other.entryTime, entryTime) || other.entryTime == entryTime)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.moodRating, moodRating) || other.moodRating == moodRating)&&(identical(other.journalText, journalText) || other.journalText == journalText)&&const DeepCollectionEquality().equals(other._trackerResponses, _trackerResponses));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,entryDate,entryTime,createdAt,updatedAt,moodRating,journalText,const DeepCollectionEquality().hash(_trackerResponses));

@override
String toString() {
  return 'JournalEntry(id: $id, userId: $userId, entryDate: $entryDate, entryTime: $entryTime, createdAt: $createdAt, updatedAt: $updatedAt, moodRating: $moodRating, journalText: $journalText, trackerResponses: $trackerResponses)';
}


}

/// @nodoc
abstract mixin class _$JournalEntryCopyWith<$Res> implements $JournalEntryCopyWith<$Res> {
  factory _$JournalEntryCopyWith(_JournalEntry value, $Res Function(_JournalEntry) _then) = __$JournalEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, DateTime entryDate, DateTime entryTime, DateTime createdAt, DateTime updatedAt, MoodRating? moodRating, String? journalText, List<TrackerResponse> trackerResponses
});




}
/// @nodoc
class __$JournalEntryCopyWithImpl<$Res>
    implements _$JournalEntryCopyWith<$Res> {
  __$JournalEntryCopyWithImpl(this._self, this._then);

  final _JournalEntry _self;
  final $Res Function(_JournalEntry) _then;

/// Create a copy of JournalEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? entryDate = null,Object? entryTime = null,Object? createdAt = null,Object? updatedAt = null,Object? moodRating = freezed,Object? journalText = freezed,Object? trackerResponses = null,}) {
  return _then(_JournalEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,entryDate: null == entryDate ? _self.entryDate : entryDate // ignore: cast_nullable_to_non_nullable
as DateTime,entryTime: null == entryTime ? _self.entryTime : entryTime // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,moodRating: freezed == moodRating ? _self.moodRating : moodRating // ignore: cast_nullable_to_non_nullable
as MoodRating?,journalText: freezed == journalText ? _self.journalText : journalText // ignore: cast_nullable_to_non_nullable
as String?,trackerResponses: null == trackerResponses ? _self._trackerResponses : trackerResponses // ignore: cast_nullable_to_non_nullable
as List<TrackerResponse>,
  ));
}


}

// dart format on
