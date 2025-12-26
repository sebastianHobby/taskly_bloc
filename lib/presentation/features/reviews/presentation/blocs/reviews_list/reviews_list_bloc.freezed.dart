// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reviews_list_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReviewsListEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewsListEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReviewsListEvent()';
}


}

/// @nodoc
class $ReviewsListEventCopyWith<$Res>  {
$ReviewsListEventCopyWith(ReviewsListEvent _, $Res Function(ReviewsListEvent) __);
}


/// Adds pattern-matching-related methods to [ReviewsListEvent].
extension ReviewsListEventPatterns on ReviewsListEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _LoadAll value)?  loadAll,TResult Function( _LoadDue value)?  loadDue,TResult Function( _DeleteReview value)?  deleteReview,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoadAll() when loadAll != null:
return loadAll(_that);case _LoadDue() when loadDue != null:
return loadDue(_that);case _DeleteReview() when deleteReview != null:
return deleteReview(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _LoadAll value)  loadAll,required TResult Function( _LoadDue value)  loadDue,required TResult Function( _DeleteReview value)  deleteReview,}){
final _that = this;
switch (_that) {
case _LoadAll():
return loadAll(_that);case _LoadDue():
return loadDue(_that);case _DeleteReview():
return deleteReview(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _LoadAll value)?  loadAll,TResult? Function( _LoadDue value)?  loadDue,TResult? Function( _DeleteReview value)?  deleteReview,}){
final _that = this;
switch (_that) {
case _LoadAll() when loadAll != null:
return loadAll(_that);case _LoadDue() when loadDue != null:
return loadDue(_that);case _DeleteReview() when deleteReview != null:
return deleteReview(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadAll,TResult Function()?  loadDue,TResult Function( String reviewId)?  deleteReview,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoadAll() when loadAll != null:
return loadAll();case _LoadDue() when loadDue != null:
return loadDue();case _DeleteReview() when deleteReview != null:
return deleteReview(_that.reviewId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadAll,required TResult Function()  loadDue,required TResult Function( String reviewId)  deleteReview,}) {final _that = this;
switch (_that) {
case _LoadAll():
return loadAll();case _LoadDue():
return loadDue();case _DeleteReview():
return deleteReview(_that.reviewId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadAll,TResult? Function()?  loadDue,TResult? Function( String reviewId)?  deleteReview,}) {final _that = this;
switch (_that) {
case _LoadAll() when loadAll != null:
return loadAll();case _LoadDue() when loadDue != null:
return loadDue();case _DeleteReview() when deleteReview != null:
return deleteReview(_that.reviewId);case _:
  return null;

}
}

}

/// @nodoc


class _LoadAll implements ReviewsListEvent {
  const _LoadAll();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadAll);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReviewsListEvent.loadAll()';
}


}




/// @nodoc


class _LoadDue implements ReviewsListEvent {
  const _LoadDue();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadDue);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ReviewsListEvent.loadDue()';
}


}




/// @nodoc


class _DeleteReview implements ReviewsListEvent {
  const _DeleteReview(this.reviewId);
  

 final  String reviewId;

/// Create a copy of ReviewsListEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeleteReviewCopyWith<_DeleteReview> get copyWith => __$DeleteReviewCopyWithImpl<_DeleteReview>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeleteReview&&(identical(other.reviewId, reviewId) || other.reviewId == reviewId));
}


@override
int get hashCode => Object.hash(runtimeType,reviewId);

@override
String toString() {
  return 'ReviewsListEvent.deleteReview(reviewId: $reviewId)';
}


}

/// @nodoc
abstract mixin class _$DeleteReviewCopyWith<$Res> implements $ReviewsListEventCopyWith<$Res> {
  factory _$DeleteReviewCopyWith(_DeleteReview value, $Res Function(_DeleteReview) _then) = __$DeleteReviewCopyWithImpl;
@useResult
$Res call({
 String reviewId
});




}
/// @nodoc
class __$DeleteReviewCopyWithImpl<$Res>
    implements _$DeleteReviewCopyWith<$Res> {
  __$DeleteReviewCopyWithImpl(this._self, this._then);

  final _DeleteReview _self;
  final $Res Function(_DeleteReview) _then;

/// Create a copy of ReviewsListEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reviewId = null,}) {
  return _then(_DeleteReview(
null == reviewId ? _self.reviewId : reviewId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ReviewsListState {

 List<Review> get reviews; bool get isLoading; String? get error;
/// Create a copy of ReviewsListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewsListStateCopyWith<ReviewsListState> get copyWith => _$ReviewsListStateCopyWithImpl<ReviewsListState>(this as ReviewsListState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewsListState&&const DeepCollectionEquality().equals(other.reviews, reviews)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(reviews),isLoading,error);

@override
String toString() {
  return 'ReviewsListState(reviews: $reviews, isLoading: $isLoading, error: $error)';
}


}

/// @nodoc
abstract mixin class $ReviewsListStateCopyWith<$Res>  {
  factory $ReviewsListStateCopyWith(ReviewsListState value, $Res Function(ReviewsListState) _then) = _$ReviewsListStateCopyWithImpl;
@useResult
$Res call({
 List<Review> reviews, bool isLoading, String? error
});




}
/// @nodoc
class _$ReviewsListStateCopyWithImpl<$Res>
    implements $ReviewsListStateCopyWith<$Res> {
  _$ReviewsListStateCopyWithImpl(this._self, this._then);

  final ReviewsListState _self;
  final $Res Function(ReviewsListState) _then;

/// Create a copy of ReviewsListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reviews = null,Object? isLoading = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
reviews: null == reviews ? _self.reviews : reviews // ignore: cast_nullable_to_non_nullable
as List<Review>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReviewsListState].
extension ReviewsListStatePatterns on ReviewsListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewsListState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewsListState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewsListState value)  $default,){
final _that = this;
switch (_that) {
case _ReviewsListState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewsListState value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewsListState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Review> reviews,  bool isLoading,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewsListState() when $default != null:
return $default(_that.reviews,_that.isLoading,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Review> reviews,  bool isLoading,  String? error)  $default,) {final _that = this;
switch (_that) {
case _ReviewsListState():
return $default(_that.reviews,_that.isLoading,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Review> reviews,  bool isLoading,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _ReviewsListState() when $default != null:
return $default(_that.reviews,_that.isLoading,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _ReviewsListState implements ReviewsListState {
  const _ReviewsListState({final  List<Review> reviews = const [], this.isLoading = true, this.error}): _reviews = reviews;
  

 final  List<Review> _reviews;
@override@JsonKey() List<Review> get reviews {
  if (_reviews is EqualUnmodifiableListView) return _reviews;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reviews);
}

@override@JsonKey() final  bool isLoading;
@override final  String? error;

/// Create a copy of ReviewsListState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewsListStateCopyWith<_ReviewsListState> get copyWith => __$ReviewsListStateCopyWithImpl<_ReviewsListState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewsListState&&const DeepCollectionEquality().equals(other._reviews, _reviews)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_reviews),isLoading,error);

@override
String toString() {
  return 'ReviewsListState(reviews: $reviews, isLoading: $isLoading, error: $error)';
}


}

/// @nodoc
abstract mixin class _$ReviewsListStateCopyWith<$Res> implements $ReviewsListStateCopyWith<$Res> {
  factory _$ReviewsListStateCopyWith(_ReviewsListState value, $Res Function(_ReviewsListState) _then) = __$ReviewsListStateCopyWithImpl;
@override @useResult
$Res call({
 List<Review> reviews, bool isLoading, String? error
});




}
/// @nodoc
class __$ReviewsListStateCopyWithImpl<$Res>
    implements _$ReviewsListStateCopyWith<$Res> {
  __$ReviewsListStateCopyWithImpl(this._self, this._then);

  final _ReviewsListState _self;
  final $Res Function(_ReviewsListState) _then;

/// Create a copy of ReviewsListState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reviews = null,Object? isLoading = null,Object? error = freezed,}) {
  return _then(_ReviewsListState(
reviews: null == reviews ? _self._reviews : reviews // ignore: cast_nullable_to_non_nullable
as List<Review>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
