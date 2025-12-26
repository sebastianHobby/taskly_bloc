// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_editor_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReviewEditorEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewEditorEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReviewEditorEvent()';
}


}

/// @nodoc
class $ReviewEditorEventCopyWith<$Res>  {
$ReviewEditorEventCopyWith(ReviewEditorEvent _, $Res Function(ReviewEditorEvent) __);
}


/// Adds pattern-matching-related methods to [ReviewEditorEvent].
extension ReviewEditorEventPatterns on ReviewEditorEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Load value)?  load,TResult Function( _UpdateReview value)?  updateReview,TResult Function( _Save value)?  save,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Load() when load != null:
return load(_that);case _UpdateReview() when updateReview != null:
return updateReview(_that);case _Save() when save != null:
return save(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Load value)  load,required TResult Function( _UpdateReview value)  updateReview,required TResult Function( _Save value)  save,}){
final _that = this;
switch (_that) {
case _Load():
return load(_that);case _UpdateReview():
return updateReview(_that);case _Save():
return save(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Load value)?  load,TResult? Function( _UpdateReview value)?  updateReview,TResult? Function( _Save value)?  save,}){
final _that = this;
switch (_that) {
case _Load() when load != null:
return load(_that);case _UpdateReview() when updateReview != null:
return updateReview(_that);case _Save() when save != null:
return save(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String reviewId)?  load,TResult Function( Review review)?  updateReview,TResult Function()?  save,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Load() when load != null:
return load(_that.reviewId);case _UpdateReview() when updateReview != null:
return updateReview(_that.review);case _Save() when save != null:
return save();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String reviewId)  load,required TResult Function( Review review)  updateReview,required TResult Function()  save,}) {final _that = this;
switch (_that) {
case _Load():
return load(_that.reviewId);case _UpdateReview():
return updateReview(_that.review);case _Save():
return save();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String reviewId)?  load,TResult? Function( Review review)?  updateReview,TResult? Function()?  save,}) {final _that = this;
switch (_that) {
case _Load() when load != null:
return load(_that.reviewId);case _UpdateReview() when updateReview != null:
return updateReview(_that.review);case _Save() when save != null:
return save();case _:
  return null;

}
}

}

/// @nodoc


class _Load implements ReviewEditorEvent {
  const _Load(this.reviewId);
  

 final  String reviewId;

/// Create a copy of ReviewEditorEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LoadCopyWith<_Load> get copyWith => __$LoadCopyWithImpl<_Load>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Load&&(identical(other.reviewId, reviewId) || other.reviewId == reviewId));
}


@override
int get hashCode => Object.hash(runtimeType,reviewId);

@override
String toString() {
  return 'ReviewEditorEvent.load(reviewId: $reviewId)';
}


}

/// @nodoc
abstract mixin class _$LoadCopyWith<$Res> implements $ReviewEditorEventCopyWith<$Res> {
  factory _$LoadCopyWith(_Load value, $Res Function(_Load) _then) = __$LoadCopyWithImpl;
@useResult
$Res call({
 String reviewId
});




}
/// @nodoc
class __$LoadCopyWithImpl<$Res>
    implements _$LoadCopyWith<$Res> {
  __$LoadCopyWithImpl(this._self, this._then);

  final _Load _self;
  final $Res Function(_Load) _then;

/// Create a copy of ReviewEditorEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reviewId = null,}) {
  return _then(_Load(
null == reviewId ? _self.reviewId : reviewId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _UpdateReview implements ReviewEditorEvent {
  const _UpdateReview(this.review);
  

 final  Review review;

/// Create a copy of ReviewEditorEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateReviewCopyWith<_UpdateReview> get copyWith => __$UpdateReviewCopyWithImpl<_UpdateReview>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateReview&&(identical(other.review, review) || other.review == review));
}


@override
int get hashCode => Object.hash(runtimeType,review);

@override
String toString() {
  return 'ReviewEditorEvent.updateReview(review: $review)';
}


}

/// @nodoc
abstract mixin class _$UpdateReviewCopyWith<$Res> implements $ReviewEditorEventCopyWith<$Res> {
  factory _$UpdateReviewCopyWith(_UpdateReview value, $Res Function(_UpdateReview) _then) = __$UpdateReviewCopyWithImpl;
@useResult
$Res call({
 Review review
});


$ReviewCopyWith<$Res> get review;

}
/// @nodoc
class __$UpdateReviewCopyWithImpl<$Res>
    implements _$UpdateReviewCopyWith<$Res> {
  __$UpdateReviewCopyWithImpl(this._self, this._then);

  final _UpdateReview _self;
  final $Res Function(_UpdateReview) _then;

/// Create a copy of ReviewEditorEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? review = null,}) {
  return _then(_UpdateReview(
null == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as Review,
  ));
}

/// Create a copy of ReviewEditorEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewCopyWith<$Res> get review {
  
  return $ReviewCopyWith<$Res>(_self.review, (value) {
    return _then(_self.copyWith(review: value));
  });
}
}

/// @nodoc


class _Save implements ReviewEditorEvent {
  const _Save();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Save);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReviewEditorEvent.save()';
}


}




/// @nodoc
mixin _$ReviewEditorState {

 Review? get review; bool get isLoading; bool get isSaving; bool get isSaved; String? get error;
/// Create a copy of ReviewEditorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewEditorStateCopyWith<ReviewEditorState> get copyWith => _$ReviewEditorStateCopyWithImpl<ReviewEditorState>(this as ReviewEditorState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewEditorState&&(identical(other.review, review) || other.review == review)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.isSaved, isSaved) || other.isSaved == isSaved)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,review,isLoading,isSaving,isSaved,error);

@override
String toString() {
  return 'ReviewEditorState(review: $review, isLoading: $isLoading, isSaving: $isSaving, isSaved: $isSaved, error: $error)';
}


}

/// @nodoc
abstract mixin class $ReviewEditorStateCopyWith<$Res>  {
  factory $ReviewEditorStateCopyWith(ReviewEditorState value, $Res Function(ReviewEditorState) _then) = _$ReviewEditorStateCopyWithImpl;
@useResult
$Res call({
 Review? review, bool isLoading, bool isSaving, bool isSaved, String? error
});


$ReviewCopyWith<$Res>? get review;

}
/// @nodoc
class _$ReviewEditorStateCopyWithImpl<$Res>
    implements $ReviewEditorStateCopyWith<$Res> {
  _$ReviewEditorStateCopyWithImpl(this._self, this._then);

  final ReviewEditorState _self;
  final $Res Function(ReviewEditorState) _then;

/// Create a copy of ReviewEditorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? review = freezed,Object? isLoading = null,Object? isSaving = null,Object? isSaved = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
review: freezed == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as Review?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,isSaved: null == isSaved ? _self.isSaved : isSaved // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ReviewEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewCopyWith<$Res>? get review {
    if (_self.review == null) {
    return null;
  }

  return $ReviewCopyWith<$Res>(_self.review!, (value) {
    return _then(_self.copyWith(review: value));
  });
}
}


/// Adds pattern-matching-related methods to [ReviewEditorState].
extension ReviewEditorStatePatterns on ReviewEditorState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewEditorState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewEditorState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewEditorState value)  $default,){
final _that = this;
switch (_that) {
case _ReviewEditorState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewEditorState value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewEditorState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Review? review,  bool isLoading,  bool isSaving,  bool isSaved,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewEditorState() when $default != null:
return $default(_that.review,_that.isLoading,_that.isSaving,_that.isSaved,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Review? review,  bool isLoading,  bool isSaving,  bool isSaved,  String? error)  $default,) {final _that = this;
switch (_that) {
case _ReviewEditorState():
return $default(_that.review,_that.isLoading,_that.isSaving,_that.isSaved,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Review? review,  bool isLoading,  bool isSaving,  bool isSaved,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _ReviewEditorState() when $default != null:
return $default(_that.review,_that.isLoading,_that.isSaving,_that.isSaved,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _ReviewEditorState implements ReviewEditorState {
  const _ReviewEditorState({this.review, this.isLoading = false, this.isSaving = false, this.isSaved = false, this.error});
  

@override final  Review? review;
@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isSaving;
@override@JsonKey() final  bool isSaved;
@override final  String? error;

/// Create a copy of ReviewEditorState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewEditorStateCopyWith<_ReviewEditorState> get copyWith => __$ReviewEditorStateCopyWithImpl<_ReviewEditorState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewEditorState&&(identical(other.review, review) || other.review == review)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.isSaved, isSaved) || other.isSaved == isSaved)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,review,isLoading,isSaving,isSaved,error);

@override
String toString() {
  return 'ReviewEditorState(review: $review, isLoading: $isLoading, isSaving: $isSaving, isSaved: $isSaved, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ReviewEditorStateCopyWith<$Res> implements $ReviewEditorStateCopyWith<$Res> {
  factory _$ReviewEditorStateCopyWith(_ReviewEditorState value, $Res Function(_ReviewEditorState) _then) = __$ReviewEditorStateCopyWithImpl;
@override @useResult
$Res call({
 Review? review, bool isLoading, bool isSaving, bool isSaved, String? error
});


@override $ReviewCopyWith<$Res>? get review;

}
/// @nodoc
class __$ReviewEditorStateCopyWithImpl<$Res>
    implements _$ReviewEditorStateCopyWith<$Res> {
  __$ReviewEditorStateCopyWithImpl(this._self, this._then);

  final _ReviewEditorState _self;
  final $Res Function(_ReviewEditorState) _then;

/// Create a copy of ReviewEditorState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? review = freezed,Object? isLoading = null,Object? isSaving = null,Object? isSaved = null,Object? error = freezed,}) {
  return _then(_ReviewEditorState(
review: freezed == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as Review?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,isSaved: null == isSaved ? _self.isSaved : isSaved // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ReviewEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewCopyWith<$Res>? get review {
    if (_self.review == null) {
    return null;
  }

  return $ReviewCopyWith<$Res>(_self.review!, (value) {
    return _then(_self.copyWith(review: value));
  });
}
}

// dart format on
