// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'label_list_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LabelOverviewEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabelOverviewEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LabelOverviewEvent()';
}


}

/// @nodoc
class $LabelOverviewEventCopyWith<$Res>  {
$LabelOverviewEventCopyWith(LabelOverviewEvent _, $Res Function(LabelOverviewEvent) __);
}


/// Adds pattern-matching-related methods to [LabelOverviewEvent].
extension LabelOverviewEventPatterns on LabelOverviewEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LabelOverviewSubscriptionRequested value)?  subscriptionRequested,TResult Function( LabelsSortChanged value)?  sortChanged,TResult Function( LabelOverviewDeleteLabel value)?  deleteLabel,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LabelOverviewSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested(_that);case LabelsSortChanged() when sortChanged != null:
return sortChanged(_that);case LabelOverviewDeleteLabel() when deleteLabel != null:
return deleteLabel(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LabelOverviewSubscriptionRequested value)  subscriptionRequested,required TResult Function( LabelsSortChanged value)  sortChanged,required TResult Function( LabelOverviewDeleteLabel value)  deleteLabel,}){
final _that = this;
switch (_that) {
case LabelOverviewSubscriptionRequested():
return subscriptionRequested(_that);case LabelsSortChanged():
return sortChanged(_that);case LabelOverviewDeleteLabel():
return deleteLabel(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LabelOverviewSubscriptionRequested value)?  subscriptionRequested,TResult? Function( LabelsSortChanged value)?  sortChanged,TResult? Function( LabelOverviewDeleteLabel value)?  deleteLabel,}){
final _that = this;
switch (_that) {
case LabelOverviewSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested(_that);case LabelsSortChanged() when sortChanged != null:
return sortChanged(_that);case LabelOverviewDeleteLabel() when deleteLabel != null:
return deleteLabel(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  subscriptionRequested,TResult Function( SortPreferences preferences)?  sortChanged,TResult Function( Label label)?  deleteLabel,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LabelOverviewSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested();case LabelsSortChanged() when sortChanged != null:
return sortChanged(_that.preferences);case LabelOverviewDeleteLabel() when deleteLabel != null:
return deleteLabel(_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  subscriptionRequested,required TResult Function( SortPreferences preferences)  sortChanged,required TResult Function( Label label)  deleteLabel,}) {final _that = this;
switch (_that) {
case LabelOverviewSubscriptionRequested():
return subscriptionRequested();case LabelsSortChanged():
return sortChanged(_that.preferences);case LabelOverviewDeleteLabel():
return deleteLabel(_that.label);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  subscriptionRequested,TResult? Function( SortPreferences preferences)?  sortChanged,TResult? Function( Label label)?  deleteLabel,}) {final _that = this;
switch (_that) {
case LabelOverviewSubscriptionRequested() when subscriptionRequested != null:
return subscriptionRequested();case LabelsSortChanged() when sortChanged != null:
return sortChanged(_that.preferences);case LabelOverviewDeleteLabel() when deleteLabel != null:
return deleteLabel(_that.label);case _:
  return null;

}
}

}

/// @nodoc


class LabelOverviewSubscriptionRequested implements LabelOverviewEvent {
  const LabelOverviewSubscriptionRequested();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabelOverviewSubscriptionRequested);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LabelOverviewEvent.subscriptionRequested()';
}


}




/// @nodoc


class LabelsSortChanged implements LabelOverviewEvent {
  const LabelsSortChanged({required this.preferences});
  

 final  SortPreferences preferences;

/// Create a copy of LabelOverviewEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LabelsSortChangedCopyWith<LabelsSortChanged> get copyWith => _$LabelsSortChangedCopyWithImpl<LabelsSortChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabelsSortChanged&&(identical(other.preferences, preferences) || other.preferences == preferences));
}


@override
int get hashCode => Object.hash(runtimeType,preferences);

@override
String toString() {
  return 'LabelOverviewEvent.sortChanged(preferences: $preferences)';
}


}

/// @nodoc
abstract mixin class $LabelsSortChangedCopyWith<$Res> implements $LabelOverviewEventCopyWith<$Res> {
  factory $LabelsSortChangedCopyWith(LabelsSortChanged value, $Res Function(LabelsSortChanged) _then) = _$LabelsSortChangedCopyWithImpl;
@useResult
$Res call({
 SortPreferences preferences
});




}
/// @nodoc
class _$LabelsSortChangedCopyWithImpl<$Res>
    implements $LabelsSortChangedCopyWith<$Res> {
  _$LabelsSortChangedCopyWithImpl(this._self, this._then);

  final LabelsSortChanged _self;
  final $Res Function(LabelsSortChanged) _then;

/// Create a copy of LabelOverviewEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? preferences = null,}) {
  return _then(LabelsSortChanged(
preferences: null == preferences ? _self.preferences : preferences // ignore: cast_nullable_to_non_nullable
as SortPreferences,
  ));
}


}

/// @nodoc


class LabelOverviewDeleteLabel implements LabelOverviewEvent {
  const LabelOverviewDeleteLabel({required this.label});
  

 final  Label label;

/// Create a copy of LabelOverviewEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LabelOverviewDeleteLabelCopyWith<LabelOverviewDeleteLabel> get copyWith => _$LabelOverviewDeleteLabelCopyWithImpl<LabelOverviewDeleteLabel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabelOverviewDeleteLabel&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode => Object.hash(runtimeType,label);

@override
String toString() {
  return 'LabelOverviewEvent.deleteLabel(label: $label)';
}


}

/// @nodoc
abstract mixin class $LabelOverviewDeleteLabelCopyWith<$Res> implements $LabelOverviewEventCopyWith<$Res> {
  factory $LabelOverviewDeleteLabelCopyWith(LabelOverviewDeleteLabel value, $Res Function(LabelOverviewDeleteLabel) _then) = _$LabelOverviewDeleteLabelCopyWithImpl;
@useResult
$Res call({
 Label label
});




}
/// @nodoc
class _$LabelOverviewDeleteLabelCopyWithImpl<$Res>
    implements $LabelOverviewDeleteLabelCopyWith<$Res> {
  _$LabelOverviewDeleteLabelCopyWithImpl(this._self, this._then);

  final LabelOverviewDeleteLabel _self;
  final $Res Function(LabelOverviewDeleteLabel) _then;

/// Create a copy of LabelOverviewEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? label = null,}) {
  return _then(LabelOverviewDeleteLabel(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as Label,
  ));
}


}

/// @nodoc
mixin _$LabelOverviewState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabelOverviewState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LabelOverviewState()';
}


}

/// @nodoc
class $LabelOverviewStateCopyWith<$Res>  {
$LabelOverviewStateCopyWith(LabelOverviewState _, $Res Function(LabelOverviewState) __);
}


/// Adds pattern-matching-related methods to [LabelOverviewState].
extension LabelOverviewStatePatterns on LabelOverviewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LabelOverviewInitial value)?  initial,TResult Function( LabelOverviewLoading value)?  loading,TResult Function( LabelOverviewLoaded value)?  loaded,TResult Function( LabelOverviewError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LabelOverviewInitial() when initial != null:
return initial(_that);case LabelOverviewLoading() when loading != null:
return loading(_that);case LabelOverviewLoaded() when loaded != null:
return loaded(_that);case LabelOverviewError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LabelOverviewInitial value)  initial,required TResult Function( LabelOverviewLoading value)  loading,required TResult Function( LabelOverviewLoaded value)  loaded,required TResult Function( LabelOverviewError value)  error,}){
final _that = this;
switch (_that) {
case LabelOverviewInitial():
return initial(_that);case LabelOverviewLoading():
return loading(_that);case LabelOverviewLoaded():
return loaded(_that);case LabelOverviewError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LabelOverviewInitial value)?  initial,TResult? Function( LabelOverviewLoading value)?  loading,TResult? Function( LabelOverviewLoaded value)?  loaded,TResult? Function( LabelOverviewError value)?  error,}){
final _that = this;
switch (_that) {
case LabelOverviewInitial() when initial != null:
return initial(_that);case LabelOverviewLoading() when loading != null:
return loading(_that);case LabelOverviewLoaded() when loaded != null:
return loaded(_that);case LabelOverviewError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Label> labels)?  loaded,TResult Function( Object error)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LabelOverviewInitial() when initial != null:
return initial();case LabelOverviewLoading() when loading != null:
return loading();case LabelOverviewLoaded() when loaded != null:
return loaded(_that.labels);case LabelOverviewError() when error != null:
return error(_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Label> labels)  loaded,required TResult Function( Object error)  error,}) {final _that = this;
switch (_that) {
case LabelOverviewInitial():
return initial();case LabelOverviewLoading():
return loading();case LabelOverviewLoaded():
return loaded(_that.labels);case LabelOverviewError():
return error(_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Label> labels)?  loaded,TResult? Function( Object error)?  error,}) {final _that = this;
switch (_that) {
case LabelOverviewInitial() when initial != null:
return initial();case LabelOverviewLoading() when loading != null:
return loading();case LabelOverviewLoaded() when loaded != null:
return loaded(_that.labels);case LabelOverviewError() when error != null:
return error(_that.error);case _:
  return null;

}
}

}

/// @nodoc


class LabelOverviewInitial implements LabelOverviewState {
  const LabelOverviewInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabelOverviewInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LabelOverviewState.initial()';
}


}




/// @nodoc


class LabelOverviewLoading implements LabelOverviewState {
  const LabelOverviewLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabelOverviewLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LabelOverviewState.loading()';
}


}




/// @nodoc


class LabelOverviewLoaded implements LabelOverviewState {
  const LabelOverviewLoaded({required final  List<Label> labels}): _labels = labels;
  

 final  List<Label> _labels;
 List<Label> get labels {
  if (_labels is EqualUnmodifiableListView) return _labels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_labels);
}


/// Create a copy of LabelOverviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LabelOverviewLoadedCopyWith<LabelOverviewLoaded> get copyWith => _$LabelOverviewLoadedCopyWithImpl<LabelOverviewLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabelOverviewLoaded&&const DeepCollectionEquality().equals(other._labels, _labels));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_labels));

@override
String toString() {
  return 'LabelOverviewState.loaded(labels: $labels)';
}


}

/// @nodoc
abstract mixin class $LabelOverviewLoadedCopyWith<$Res> implements $LabelOverviewStateCopyWith<$Res> {
  factory $LabelOverviewLoadedCopyWith(LabelOverviewLoaded value, $Res Function(LabelOverviewLoaded) _then) = _$LabelOverviewLoadedCopyWithImpl;
@useResult
$Res call({
 List<Label> labels
});




}
/// @nodoc
class _$LabelOverviewLoadedCopyWithImpl<$Res>
    implements $LabelOverviewLoadedCopyWith<$Res> {
  _$LabelOverviewLoadedCopyWithImpl(this._self, this._then);

  final LabelOverviewLoaded _self;
  final $Res Function(LabelOverviewLoaded) _then;

/// Create a copy of LabelOverviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? labels = null,}) {
  return _then(LabelOverviewLoaded(
labels: null == labels ? _self._labels : labels // ignore: cast_nullable_to_non_nullable
as List<Label>,
  ));
}


}

/// @nodoc


class LabelOverviewError implements LabelOverviewState {
  const LabelOverviewError({required this.error});
  

 final  Object error;

/// Create a copy of LabelOverviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LabelOverviewErrorCopyWith<LabelOverviewError> get copyWith => _$LabelOverviewErrorCopyWithImpl<LabelOverviewError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LabelOverviewError&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error));

@override
String toString() {
  return 'LabelOverviewState.error(error: $error)';
}


}

/// @nodoc
abstract mixin class $LabelOverviewErrorCopyWith<$Res> implements $LabelOverviewStateCopyWith<$Res> {
  factory $LabelOverviewErrorCopyWith(LabelOverviewError value, $Res Function(LabelOverviewError) _then) = _$LabelOverviewErrorCopyWithImpl;
@useResult
$Res call({
 Object error
});




}
/// @nodoc
class _$LabelOverviewErrorCopyWithImpl<$Res>
    implements $LabelOverviewErrorCopyWith<$Res> {
  _$LabelOverviewErrorCopyWithImpl(this._self, this._then);

  final LabelOverviewError _self;
  final $Res Function(LabelOverviewError) _then;

/// Create a copy of LabelOverviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(LabelOverviewError(
error: null == error ? _self.error : error ,
  ));
}


}

// dart format on
