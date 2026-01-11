// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journal_entry_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$JournalEntryEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalEntryEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'JournalEntryEvent()';
}


}

/// @nodoc
class $JournalEntryEventCopyWith<$Res>  {
$JournalEntryEventCopyWith(JournalEntryEvent _, $Res Function(JournalEntryEvent) __);
}


/// Adds pattern-matching-related methods to [JournalEntryEvent].
extension JournalEntryEventPatterns on JournalEntryEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Load value)?  load,TResult Function( _LoadByDate value)?  loadByDate,TResult Function( _LoadEntriesForDate value)?  loadEntriesForDate,TResult Function( _Save value)?  save,TResult Function( _SaveWithDailyResponses value)?  saveWithDailyResponses,TResult Function( _Delete value)?  delete,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Load() when load != null:
return load(_that);case _LoadByDate() when loadByDate != null:
return loadByDate(_that);case _LoadEntriesForDate() when loadEntriesForDate != null:
return loadEntriesForDate(_that);case _Save() when save != null:
return save(_that);case _SaveWithDailyResponses() when saveWithDailyResponses != null:
return saveWithDailyResponses(_that);case _Delete() when delete != null:
return delete(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Load value)  load,required TResult Function( _LoadByDate value)  loadByDate,required TResult Function( _LoadEntriesForDate value)  loadEntriesForDate,required TResult Function( _Save value)  save,required TResult Function( _SaveWithDailyResponses value)  saveWithDailyResponses,required TResult Function( _Delete value)  delete,}){
final _that = this;
switch (_that) {
case _Load():
return load(_that);case _LoadByDate():
return loadByDate(_that);case _LoadEntriesForDate():
return loadEntriesForDate(_that);case _Save():
return save(_that);case _SaveWithDailyResponses():
return saveWithDailyResponses(_that);case _Delete():
return delete(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Load value)?  load,TResult? Function( _LoadByDate value)?  loadByDate,TResult? Function( _LoadEntriesForDate value)?  loadEntriesForDate,TResult? Function( _Save value)?  save,TResult? Function( _SaveWithDailyResponses value)?  saveWithDailyResponses,TResult? Function( _Delete value)?  delete,}){
final _that = this;
switch (_that) {
case _Load() when load != null:
return load(_that);case _LoadByDate() when loadByDate != null:
return loadByDate(_that);case _LoadEntriesForDate() when loadEntriesForDate != null:
return loadEntriesForDate(_that);case _Save() when save != null:
return save(_that);case _SaveWithDailyResponses() when saveWithDailyResponses != null:
return saveWithDailyResponses(_that);case _Delete() when delete != null:
return delete(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String entryId)?  load,TResult Function( DateTime date)?  loadByDate,TResult Function( DateTime date)?  loadEntriesForDate,TResult Function( JournalEntry entry)?  save,TResult Function( JournalEntry entry,  List<DailyTrackerResponse> dailyResponses)?  saveWithDailyResponses,TResult Function( String entryId)?  delete,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Load() when load != null:
return load(_that.entryId);case _LoadByDate() when loadByDate != null:
return loadByDate(_that.date);case _LoadEntriesForDate() when loadEntriesForDate != null:
return loadEntriesForDate(_that.date);case _Save() when save != null:
return save(_that.entry);case _SaveWithDailyResponses() when saveWithDailyResponses != null:
return saveWithDailyResponses(_that.entry,_that.dailyResponses);case _Delete() when delete != null:
return delete(_that.entryId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String entryId)  load,required TResult Function( DateTime date)  loadByDate,required TResult Function( DateTime date)  loadEntriesForDate,required TResult Function( JournalEntry entry)  save,required TResult Function( JournalEntry entry,  List<DailyTrackerResponse> dailyResponses)  saveWithDailyResponses,required TResult Function( String entryId)  delete,}) {final _that = this;
switch (_that) {
case _Load():
return load(_that.entryId);case _LoadByDate():
return loadByDate(_that.date);case _LoadEntriesForDate():
return loadEntriesForDate(_that.date);case _Save():
return save(_that.entry);case _SaveWithDailyResponses():
return saveWithDailyResponses(_that.entry,_that.dailyResponses);case _Delete():
return delete(_that.entryId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String entryId)?  load,TResult? Function( DateTime date)?  loadByDate,TResult? Function( DateTime date)?  loadEntriesForDate,TResult? Function( JournalEntry entry)?  save,TResult? Function( JournalEntry entry,  List<DailyTrackerResponse> dailyResponses)?  saveWithDailyResponses,TResult? Function( String entryId)?  delete,}) {final _that = this;
switch (_that) {
case _Load() when load != null:
return load(_that.entryId);case _LoadByDate() when loadByDate != null:
return loadByDate(_that.date);case _LoadEntriesForDate() when loadEntriesForDate != null:
return loadEntriesForDate(_that.date);case _Save() when save != null:
return save(_that.entry);case _SaveWithDailyResponses() when saveWithDailyResponses != null:
return saveWithDailyResponses(_that.entry,_that.dailyResponses);case _Delete() when delete != null:
return delete(_that.entryId);case _:
  return null;

}
}

}

/// @nodoc


class _Load implements JournalEntryEvent {
  const _Load(this.entryId);
  

 final  String entryId;

/// Create a copy of JournalEntryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadCopyWith<_Load> get copyWith => __$LoadCopyWithImpl<_Load>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Load&&(identical(other.entryId, entryId) || other.entryId == entryId));
}


@override
int get hashCode => Object.hash(runtimeType,entryId);

@override
String toString() {
  return 'JournalEntryEvent.load(entryId: $entryId)';
}


}

/// @nodoc
abstract mixin class _$LoadCopyWith<$Res> implements $JournalEntryEventCopyWith<$Res> {
  factory _$LoadCopyWith(_Load value, $Res Function(_Load) _then) = __$LoadCopyWithImpl;
@useResult
$Res call({
 String entryId
});




}
/// @nodoc
class __$LoadCopyWithImpl<$Res>
    implements _$LoadCopyWith<$Res> {
  __$LoadCopyWithImpl(this._self, this._then);

  final _Load _self;
  final $Res Function(_Load) _then;

/// Create a copy of JournalEntryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entryId = null,}) {
  return _then(_Load(
null == entryId ? _self.entryId : entryId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _LoadByDate implements JournalEntryEvent {
  const _LoadByDate({required this.date});
  

 final  DateTime date;

/// Create a copy of JournalEntryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadByDateCopyWith<_LoadByDate> get copyWith => __$LoadByDateCopyWithImpl<_LoadByDate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadByDate&&(identical(other.date, date) || other.date == date));
}


@override
int get hashCode => Object.hash(runtimeType,date);

@override
String toString() {
  return 'JournalEntryEvent.loadByDate(date: $date)';
}


}

/// @nodoc
abstract mixin class _$LoadByDateCopyWith<$Res> implements $JournalEntryEventCopyWith<$Res> {
  factory _$LoadByDateCopyWith(_LoadByDate value, $Res Function(_LoadByDate) _then) = __$LoadByDateCopyWithImpl;
@useResult
$Res call({
 DateTime date
});




}
/// @nodoc
class __$LoadByDateCopyWithImpl<$Res>
    implements _$LoadByDateCopyWith<$Res> {
  __$LoadByDateCopyWithImpl(this._self, this._then);

  final _LoadByDate _self;
  final $Res Function(_LoadByDate) _then;

/// Create a copy of JournalEntryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? date = null,}) {
  return _then(_LoadByDate(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class _LoadEntriesForDate implements JournalEntryEvent {
  const _LoadEntriesForDate({required this.date});
  

 final  DateTime date;

/// Create a copy of JournalEntryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadEntriesForDateCopyWith<_LoadEntriesForDate> get copyWith => __$LoadEntriesForDateCopyWithImpl<_LoadEntriesForDate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadEntriesForDate&&(identical(other.date, date) || other.date == date));
}


@override
int get hashCode => Object.hash(runtimeType,date);

@override
String toString() {
  return 'JournalEntryEvent.loadEntriesForDate(date: $date)';
}


}

/// @nodoc
abstract mixin class _$LoadEntriesForDateCopyWith<$Res> implements $JournalEntryEventCopyWith<$Res> {
  factory _$LoadEntriesForDateCopyWith(_LoadEntriesForDate value, $Res Function(_LoadEntriesForDate) _then) = __$LoadEntriesForDateCopyWithImpl;
@useResult
$Res call({
 DateTime date
});




}
/// @nodoc
class __$LoadEntriesForDateCopyWithImpl<$Res>
    implements _$LoadEntriesForDateCopyWith<$Res> {
  __$LoadEntriesForDateCopyWithImpl(this._self, this._then);

  final _LoadEntriesForDate _self;
  final $Res Function(_LoadEntriesForDate) _then;

/// Create a copy of JournalEntryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? date = null,}) {
  return _then(_LoadEntriesForDate(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class _Save implements JournalEntryEvent {
  const _Save(this.entry);
  

 final  JournalEntry entry;

/// Create a copy of JournalEntryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SaveCopyWith<_Save> get copyWith => __$SaveCopyWithImpl<_Save>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Save&&const DeepCollectionEquality().equals(other.entry, entry));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(entry));

@override
String toString() {
  return 'JournalEntryEvent.save(entry: $entry)';
}


}

/// @nodoc
abstract mixin class _$SaveCopyWith<$Res> implements $JournalEntryEventCopyWith<$Res> {
  factory _$SaveCopyWith(_Save value, $Res Function(_Save) _then) = __$SaveCopyWithImpl;
@useResult
$Res call({
 JournalEntry entry
});




}
/// @nodoc
class __$SaveCopyWithImpl<$Res>
    implements _$SaveCopyWith<$Res> {
  __$SaveCopyWithImpl(this._self, this._then);

  final _Save _self;
  final $Res Function(_Save) _then;

/// Create a copy of JournalEntryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entry = freezed,}) {
  return _then(_Save(
freezed == entry ? _self.entry : entry // ignore: cast_nullable_to_non_nullable
as JournalEntry,
  ));
}


}

/// @nodoc


class _SaveWithDailyResponses implements JournalEntryEvent {
  const _SaveWithDailyResponses({required this.entry, required final  List<DailyTrackerResponse> dailyResponses}): _dailyResponses = dailyResponses;
  

 final  JournalEntry entry;
 final  List<DailyTrackerResponse> _dailyResponses;
 List<DailyTrackerResponse> get dailyResponses {
  if (_dailyResponses is EqualUnmodifiableListView) return _dailyResponses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dailyResponses);
}


/// Create a copy of JournalEntryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SaveWithDailyResponsesCopyWith<_SaveWithDailyResponses> get copyWith => __$SaveWithDailyResponsesCopyWithImpl<_SaveWithDailyResponses>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SaveWithDailyResponses&&const DeepCollectionEquality().equals(other.entry, entry)&&const DeepCollectionEquality().equals(other._dailyResponses, _dailyResponses));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(entry),const DeepCollectionEquality().hash(_dailyResponses));

@override
String toString() {
  return 'JournalEntryEvent.saveWithDailyResponses(entry: $entry, dailyResponses: $dailyResponses)';
}


}

/// @nodoc
abstract mixin class _$SaveWithDailyResponsesCopyWith<$Res> implements $JournalEntryEventCopyWith<$Res> {
  factory _$SaveWithDailyResponsesCopyWith(_SaveWithDailyResponses value, $Res Function(_SaveWithDailyResponses) _then) = __$SaveWithDailyResponsesCopyWithImpl;
@useResult
$Res call({
 JournalEntry entry, List<DailyTrackerResponse> dailyResponses
});




}
/// @nodoc
class __$SaveWithDailyResponsesCopyWithImpl<$Res>
    implements _$SaveWithDailyResponsesCopyWith<$Res> {
  __$SaveWithDailyResponsesCopyWithImpl(this._self, this._then);

  final _SaveWithDailyResponses _self;
  final $Res Function(_SaveWithDailyResponses) _then;

/// Create a copy of JournalEntryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entry = freezed,Object? dailyResponses = null,}) {
  return _then(_SaveWithDailyResponses(
entry: freezed == entry ? _self.entry : entry // ignore: cast_nullable_to_non_nullable
as JournalEntry,dailyResponses: null == dailyResponses ? _self._dailyResponses : dailyResponses // ignore: cast_nullable_to_non_nullable
as List<DailyTrackerResponse>,
  ));
}


}

/// @nodoc


class _Delete implements JournalEntryEvent {
  const _Delete(this.entryId);
  

 final  String entryId;

/// Create a copy of JournalEntryEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeleteCopyWith<_Delete> get copyWith => __$DeleteCopyWithImpl<_Delete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Delete&&(identical(other.entryId, entryId) || other.entryId == entryId));
}


@override
int get hashCode => Object.hash(runtimeType,entryId);

@override
String toString() {
  return 'JournalEntryEvent.delete(entryId: $entryId)';
}


}

/// @nodoc
abstract mixin class _$DeleteCopyWith<$Res> implements $JournalEntryEventCopyWith<$Res> {
  factory _$DeleteCopyWith(_Delete value, $Res Function(_Delete) _then) = __$DeleteCopyWithImpl;
@useResult
$Res call({
 String entryId
});




}
/// @nodoc
class __$DeleteCopyWithImpl<$Res>
    implements _$DeleteCopyWith<$Res> {
  __$DeleteCopyWithImpl(this._self, this._then);

  final _Delete _self;
  final $Res Function(_Delete) _then;

/// Create a copy of JournalEntryEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entryId = null,}) {
  return _then(_Delete(
null == entryId ? _self.entryId : entryId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$JournalEntryState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalEntryState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'JournalEntryState()';
}


}

/// @nodoc
class $JournalEntryStateCopyWith<$Res>  {
$JournalEntryStateCopyWith(JournalEntryState _, $Res Function(JournalEntryState) __);
}


/// Adds pattern-matching-related methods to [JournalEntryState].
extension JournalEntryStatePatterns on JournalEntryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Initial value)?  initial,TResult Function( _Loading value)?  loading,TResult Function( _Loaded value)?  loaded,TResult Function( _EntriesLoaded value)?  entriesLoaded,TResult Function( _Saved value)?  saved,TResult Function( _Error value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _EntriesLoaded() when entriesLoaded != null:
return entriesLoaded(_that);case _Saved() when saved != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Initial value)  initial,required TResult Function( _Loading value)  loading,required TResult Function( _Loaded value)  loaded,required TResult Function( _EntriesLoaded value)  entriesLoaded,required TResult Function( _Saved value)  saved,required TResult Function( _Error value)  error,}){
final _that = this;
switch (_that) {
case _Initial():
return initial(_that);case _Loading():
return loading(_that);case _Loaded():
return loaded(_that);case _EntriesLoaded():
return entriesLoaded(_that);case _Saved():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Initial value)?  initial,TResult? Function( _Loading value)?  loading,TResult? Function( _Loaded value)?  loaded,TResult? Function( _EntriesLoaded value)?  entriesLoaded,TResult? Function( _Saved value)?  saved,TResult? Function( _Error value)?  error,}){
final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial(_that);case _Loading() when loading != null:
return loading(_that);case _Loaded() when loaded != null:
return loaded(_that);case _EntriesLoaded() when entriesLoaded != null:
return entriesLoaded(_that);case _Saved() when saved != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( JournalEntry? entry)?  loaded,TResult Function( List<JournalEntry> entries,  List<DailyTrackerResponse> dailyResponses,  DateTime date)?  entriesLoaded,TResult Function()?  saved,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.entry);case _EntriesLoaded() when entriesLoaded != null:
return entriesLoaded(_that.entries,_that.dailyResponses,_that.date);case _Saved() when saved != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( JournalEntry? entry)  loaded,required TResult Function( List<JournalEntry> entries,  List<DailyTrackerResponse> dailyResponses,  DateTime date)  entriesLoaded,required TResult Function()  saved,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case _Initial():
return initial();case _Loading():
return loading();case _Loaded():
return loaded(_that.entry);case _EntriesLoaded():
return entriesLoaded(_that.entries,_that.dailyResponses,_that.date);case _Saved():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( JournalEntry? entry)?  loaded,TResult? Function( List<JournalEntry> entries,  List<DailyTrackerResponse> dailyResponses,  DateTime date)?  entriesLoaded,TResult? Function()?  saved,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case _Initial() when initial != null:
return initial();case _Loading() when loading != null:
return loading();case _Loaded() when loaded != null:
return loaded(_that.entry);case _EntriesLoaded() when entriesLoaded != null:
return entriesLoaded(_that.entries,_that.dailyResponses,_that.date);case _Saved() when saved != null:
return saved();case _Error() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _Initial implements JournalEntryState {
  const _Initial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Initial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'JournalEntryState.initial()';
}


}




/// @nodoc


class _Loading implements JournalEntryState {
  const _Loading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'JournalEntryState.loading()';
}


}




/// @nodoc


class _Loaded implements JournalEntryState {
  const _Loaded(this.entry);
  

 final  JournalEntry? entry;

/// Create a copy of JournalEntryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadedCopyWith<_Loaded> get copyWith => __$LoadedCopyWithImpl<_Loaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Loaded&&const DeepCollectionEquality().equals(other.entry, entry));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(entry));

@override
String toString() {
  return 'JournalEntryState.loaded(entry: $entry)';
}


}

/// @nodoc
abstract mixin class _$LoadedCopyWith<$Res> implements $JournalEntryStateCopyWith<$Res> {
  factory _$LoadedCopyWith(_Loaded value, $Res Function(_Loaded) _then) = __$LoadedCopyWithImpl;
@useResult
$Res call({
 JournalEntry? entry
});




}
/// @nodoc
class __$LoadedCopyWithImpl<$Res>
    implements _$LoadedCopyWith<$Res> {
  __$LoadedCopyWithImpl(this._self, this._then);

  final _Loaded _self;
  final $Res Function(_Loaded) _then;

/// Create a copy of JournalEntryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entry = freezed,}) {
  return _then(_Loaded(
freezed == entry ? _self.entry : entry // ignore: cast_nullable_to_non_nullable
as JournalEntry?,
  ));
}


}

/// @nodoc


class _EntriesLoaded implements JournalEntryState {
  const _EntriesLoaded({required final  List<JournalEntry> entries, required final  List<DailyTrackerResponse> dailyResponses, required this.date}): _entries = entries,_dailyResponses = dailyResponses;
  

 final  List<JournalEntry> _entries;
 List<JournalEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}

 final  List<DailyTrackerResponse> _dailyResponses;
 List<DailyTrackerResponse> get dailyResponses {
  if (_dailyResponses is EqualUnmodifiableListView) return _dailyResponses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dailyResponses);
}

 final  DateTime date;

/// Create a copy of JournalEntryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EntriesLoadedCopyWith<_EntriesLoaded> get copyWith => __$EntriesLoadedCopyWithImpl<_EntriesLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EntriesLoaded&&const DeepCollectionEquality().equals(other._entries, _entries)&&const DeepCollectionEquality().equals(other._dailyResponses, _dailyResponses)&&(identical(other.date, date) || other.date == date));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_entries),const DeepCollectionEquality().hash(_dailyResponses),date);

@override
String toString() {
  return 'JournalEntryState.entriesLoaded(entries: $entries, dailyResponses: $dailyResponses, date: $date)';
}


}

/// @nodoc
abstract mixin class _$EntriesLoadedCopyWith<$Res> implements $JournalEntryStateCopyWith<$Res> {
  factory _$EntriesLoadedCopyWith(_EntriesLoaded value, $Res Function(_EntriesLoaded) _then) = __$EntriesLoadedCopyWithImpl;
@useResult
$Res call({
 List<JournalEntry> entries, List<DailyTrackerResponse> dailyResponses, DateTime date
});




}
/// @nodoc
class __$EntriesLoadedCopyWithImpl<$Res>
    implements _$EntriesLoadedCopyWith<$Res> {
  __$EntriesLoadedCopyWithImpl(this._self, this._then);

  final _EntriesLoaded _self;
  final $Res Function(_EntriesLoaded) _then;

/// Create a copy of JournalEntryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entries = null,Object? dailyResponses = null,Object? date = null,}) {
  return _then(_EntriesLoaded(
entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<JournalEntry>,dailyResponses: null == dailyResponses ? _self._dailyResponses : dailyResponses // ignore: cast_nullable_to_non_nullable
as List<DailyTrackerResponse>,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc


class _Saved implements JournalEntryState {
  const _Saved();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Saved);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'JournalEntryState.saved()';
}


}




/// @nodoc


class _Error implements JournalEntryState {
  const _Error(this.message);
  

 final  String message;

/// Create a copy of JournalEntryState
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
  return 'JournalEntryState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class _$ErrorCopyWith<$Res> implements $JournalEntryStateCopyWith<$Res> {
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

/// Create a copy of JournalEntryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_Error(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
