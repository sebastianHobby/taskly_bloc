// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project_detail_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProjectDetailEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDetailEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectDetailEvent()';
}


}

/// @nodoc
class $ProjectDetailEventCopyWith<$Res>  {
$ProjectDetailEventCopyWith(ProjectDetailEvent _, $Res Function(ProjectDetailEvent) __);
}


/// Adds pattern-matching-related methods to [ProjectDetailEvent].
extension ProjectDetailEventPatterns on ProjectDetailEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _ProjectDetailUpdate value)?  update,TResult Function( _ProjectDetailDelete value)?  delete,TResult Function( _ProjectDetailCreate value)?  create,TResult Function( _ProjectDetailGet value)?  get,TResult Function( _ProjectDetailLoadInitialData value)?  loadInitialData,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectDetailUpdate() when update != null:
return update(_that);case _ProjectDetailDelete() when delete != null:
return delete(_that);case _ProjectDetailCreate() when create != null:
return create(_that);case _ProjectDetailGet() when get != null:
return get(_that);case _ProjectDetailLoadInitialData() when loadInitialData != null:
return loadInitialData(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _ProjectDetailUpdate value)  update,required TResult Function( _ProjectDetailDelete value)  delete,required TResult Function( _ProjectDetailCreate value)  create,required TResult Function( _ProjectDetailGet value)  get,required TResult Function( _ProjectDetailLoadInitialData value)  loadInitialData,}){
final _that = this;
switch (_that) {
case _ProjectDetailUpdate():
return update(_that);case _ProjectDetailDelete():
return delete(_that);case _ProjectDetailCreate():
return create(_that);case _ProjectDetailGet():
return get(_that);case _ProjectDetailLoadInitialData():
return loadInitialData(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _ProjectDetailUpdate value)?  update,TResult? Function( _ProjectDetailDelete value)?  delete,TResult? Function( _ProjectDetailCreate value)?  create,TResult? Function( _ProjectDetailGet value)?  get,TResult? Function( _ProjectDetailLoadInitialData value)?  loadInitialData,}){
final _that = this;
switch (_that) {
case _ProjectDetailUpdate() when update != null:
return update(_that);case _ProjectDetailDelete() when delete != null:
return delete(_that);case _ProjectDetailCreate() when create != null:
return create(_that);case _ProjectDetailGet() when get != null:
return get(_that);case _ProjectDetailLoadInitialData() when loadInitialData != null:
return loadInitialData(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String id,  String name,  bool completed,  String? description,  DateTime? startDate,  DateTime? deadlineDate,  String? repeatIcalRrule,  List<ValueModel>? values,  List<Label>? labels)?  update,TResult Function( String id)?  delete,TResult Function( String name,  String? description,  bool completed,  DateTime? startDate,  DateTime? deadlineDate,  String? repeatIcalRrule,  List<ValueModel>? values,  List<Label>? labels)?  create,TResult Function( String projectId)?  get,TResult Function()?  loadInitialData,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectDetailUpdate() when update != null:
return update(_that.id,_that.name,_that.completed,_that.description,_that.startDate,_that.deadlineDate,_that.repeatIcalRrule,_that.values,_that.labels);case _ProjectDetailDelete() when delete != null:
return delete(_that.id);case _ProjectDetailCreate() when create != null:
return create(_that.name,_that.description,_that.completed,_that.startDate,_that.deadlineDate,_that.repeatIcalRrule,_that.values,_that.labels);case _ProjectDetailGet() when get != null:
return get(_that.projectId);case _ProjectDetailLoadInitialData() when loadInitialData != null:
return loadInitialData();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String id,  String name,  bool completed,  String? description,  DateTime? startDate,  DateTime? deadlineDate,  String? repeatIcalRrule,  List<ValueModel>? values,  List<Label>? labels)  update,required TResult Function( String id)  delete,required TResult Function( String name,  String? description,  bool completed,  DateTime? startDate,  DateTime? deadlineDate,  String? repeatIcalRrule,  List<ValueModel>? values,  List<Label>? labels)  create,required TResult Function( String projectId)  get,required TResult Function()  loadInitialData,}) {final _that = this;
switch (_that) {
case _ProjectDetailUpdate():
return update(_that.id,_that.name,_that.completed,_that.description,_that.startDate,_that.deadlineDate,_that.repeatIcalRrule,_that.values,_that.labels);case _ProjectDetailDelete():
return delete(_that.id);case _ProjectDetailCreate():
return create(_that.name,_that.description,_that.completed,_that.startDate,_that.deadlineDate,_that.repeatIcalRrule,_that.values,_that.labels);case _ProjectDetailGet():
return get(_that.projectId);case _ProjectDetailLoadInitialData():
return loadInitialData();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String id,  String name,  bool completed,  String? description,  DateTime? startDate,  DateTime? deadlineDate,  String? repeatIcalRrule,  List<ValueModel>? values,  List<Label>? labels)?  update,TResult? Function( String id)?  delete,TResult? Function( String name,  String? description,  bool completed,  DateTime? startDate,  DateTime? deadlineDate,  String? repeatIcalRrule,  List<ValueModel>? values,  List<Label>? labels)?  create,TResult? Function( String projectId)?  get,TResult? Function()?  loadInitialData,}) {final _that = this;
switch (_that) {
case _ProjectDetailUpdate() when update != null:
return update(_that.id,_that.name,_that.completed,_that.description,_that.startDate,_that.deadlineDate,_that.repeatIcalRrule,_that.values,_that.labels);case _ProjectDetailDelete() when delete != null:
return delete(_that.id);case _ProjectDetailCreate() when create != null:
return create(_that.name,_that.description,_that.completed,_that.startDate,_that.deadlineDate,_that.repeatIcalRrule,_that.values,_that.labels);case _ProjectDetailGet() when get != null:
return get(_that.projectId);case _ProjectDetailLoadInitialData() when loadInitialData != null:
return loadInitialData();case _:
  return null;

}
}

}

/// @nodoc


class _ProjectDetailUpdate implements ProjectDetailEvent {
  const _ProjectDetailUpdate({required this.id, required this.name, required this.completed, this.description, this.startDate, this.deadlineDate, this.repeatIcalRrule, final  List<ValueModel>? values, final  List<Label>? labels}): _values = values,_labels = labels;
  

 final  String id;
 final  String name;
 final  bool completed;
 final  String? description;
 final  DateTime? startDate;
 final  DateTime? deadlineDate;
 final  String? repeatIcalRrule;
 final  List<ValueModel>? _values;
 List<ValueModel>? get values {
  final value = _values;
  if (value == null) return null;
  if (_values is EqualUnmodifiableListView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<Label>? _labels;
 List<Label>? get labels {
  final value = _labels;
  if (value == null) return null;
  if (_labels is EqualUnmodifiableListView) return _labels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectDetailUpdateCopyWith<_ProjectDetailUpdate> get copyWith => __$ProjectDetailUpdateCopyWithImpl<_ProjectDetailUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDetailUpdate&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.description, description) || other.description == description)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.deadlineDate, deadlineDate) || other.deadlineDate == deadlineDate)&&(identical(other.repeatIcalRrule, repeatIcalRrule) || other.repeatIcalRrule == repeatIcalRrule)&&const DeepCollectionEquality().equals(other._values, _values)&&const DeepCollectionEquality().equals(other._labels, _labels));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,completed,description,startDate,deadlineDate,repeatIcalRrule,const DeepCollectionEquality().hash(_values),const DeepCollectionEquality().hash(_labels));

@override
String toString() {
  return 'ProjectDetailEvent.update(id: $id, name: $name, completed: $completed, description: $description, startDate: $startDate, deadlineDate: $deadlineDate, repeatIcalRrule: $repeatIcalRrule, values: $values, labels: $labels)';
}


}

/// @nodoc
abstract mixin class _$ProjectDetailUpdateCopyWith<$Res> implements $ProjectDetailEventCopyWith<$Res> {
  factory _$ProjectDetailUpdateCopyWith(_ProjectDetailUpdate value, $Res Function(_ProjectDetailUpdate) _then) = __$ProjectDetailUpdateCopyWithImpl;
@useResult
$Res call({
 String id, String name, bool completed, String? description, DateTime? startDate, DateTime? deadlineDate, String? repeatIcalRrule, List<ValueModel>? values, List<Label>? labels
});




}
/// @nodoc
class __$ProjectDetailUpdateCopyWithImpl<$Res>
    implements _$ProjectDetailUpdateCopyWith<$Res> {
  __$ProjectDetailUpdateCopyWithImpl(this._self, this._then);

  final _ProjectDetailUpdate _self;
  final $Res Function(_ProjectDetailUpdate) _then;

/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? completed = null,Object? description = freezed,Object? startDate = freezed,Object? deadlineDate = freezed,Object? repeatIcalRrule = freezed,Object? values = freezed,Object? labels = freezed,}) {
  return _then(_ProjectDetailUpdate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,deadlineDate: freezed == deadlineDate ? _self.deadlineDate : deadlineDate // ignore: cast_nullable_to_non_nullable
as DateTime?,repeatIcalRrule: freezed == repeatIcalRrule ? _self.repeatIcalRrule : repeatIcalRrule // ignore: cast_nullable_to_non_nullable
as String?,values: freezed == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as List<ValueModel>?,labels: freezed == labels ? _self._labels : labels // ignore: cast_nullable_to_non_nullable
as List<Label>?,
  ));
}


}

/// @nodoc


class _ProjectDetailDelete implements ProjectDetailEvent {
  const _ProjectDetailDelete({required this.id});
  

 final  String id;

/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectDetailDeleteCopyWith<_ProjectDetailDelete> get copyWith => __$ProjectDetailDeleteCopyWithImpl<_ProjectDetailDelete>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDetailDelete&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'ProjectDetailEvent.delete(id: $id)';
}


}

/// @nodoc
abstract mixin class _$ProjectDetailDeleteCopyWith<$Res> implements $ProjectDetailEventCopyWith<$Res> {
  factory _$ProjectDetailDeleteCopyWith(_ProjectDetailDelete value, $Res Function(_ProjectDetailDelete) _then) = __$ProjectDetailDeleteCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class __$ProjectDetailDeleteCopyWithImpl<$Res>
    implements _$ProjectDetailDeleteCopyWith<$Res> {
  __$ProjectDetailDeleteCopyWithImpl(this._self, this._then);

  final _ProjectDetailDelete _self;
  final $Res Function(_ProjectDetailDelete) _then;

/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_ProjectDetailDelete(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ProjectDetailCreate implements ProjectDetailEvent {
  const _ProjectDetailCreate({required this.name, this.description, this.completed = false, this.startDate, this.deadlineDate, this.repeatIcalRrule, final  List<ValueModel>? values, final  List<Label>? labels}): _values = values,_labels = labels;
  

 final  String name;
 final  String? description;
@JsonKey() final  bool completed;
 final  DateTime? startDate;
 final  DateTime? deadlineDate;
 final  String? repeatIcalRrule;
 final  List<ValueModel>? _values;
 List<ValueModel>? get values {
  final value = _values;
  if (value == null) return null;
  if (_values is EqualUnmodifiableListView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<Label>? _labels;
 List<Label>? get labels {
  final value = _labels;
  if (value == null) return null;
  if (_labels is EqualUnmodifiableListView) return _labels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectDetailCreateCopyWith<_ProjectDetailCreate> get copyWith => __$ProjectDetailCreateCopyWithImpl<_ProjectDetailCreate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDetailCreate&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.deadlineDate, deadlineDate) || other.deadlineDate == deadlineDate)&&(identical(other.repeatIcalRrule, repeatIcalRrule) || other.repeatIcalRrule == repeatIcalRrule)&&const DeepCollectionEquality().equals(other._values, _values)&&const DeepCollectionEquality().equals(other._labels, _labels));
}


@override
int get hashCode => Object.hash(runtimeType,name,description,completed,startDate,deadlineDate,repeatIcalRrule,const DeepCollectionEquality().hash(_values),const DeepCollectionEquality().hash(_labels));

@override
String toString() {
  return 'ProjectDetailEvent.create(name: $name, description: $description, completed: $completed, startDate: $startDate, deadlineDate: $deadlineDate, repeatIcalRrule: $repeatIcalRrule, values: $values, labels: $labels)';
}


}

/// @nodoc
abstract mixin class _$ProjectDetailCreateCopyWith<$Res> implements $ProjectDetailEventCopyWith<$Res> {
  factory _$ProjectDetailCreateCopyWith(_ProjectDetailCreate value, $Res Function(_ProjectDetailCreate) _then) = __$ProjectDetailCreateCopyWithImpl;
@useResult
$Res call({
 String name, String? description, bool completed, DateTime? startDate, DateTime? deadlineDate, String? repeatIcalRrule, List<ValueModel>? values, List<Label>? labels
});




}
/// @nodoc
class __$ProjectDetailCreateCopyWithImpl<$Res>
    implements _$ProjectDetailCreateCopyWith<$Res> {
  __$ProjectDetailCreateCopyWithImpl(this._self, this._then);

  final _ProjectDetailCreate _self;
  final $Res Function(_ProjectDetailCreate) _then;

/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? description = freezed,Object? completed = null,Object? startDate = freezed,Object? deadlineDate = freezed,Object? repeatIcalRrule = freezed,Object? values = freezed,Object? labels = freezed,}) {
  return _then(_ProjectDetailCreate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,deadlineDate: freezed == deadlineDate ? _self.deadlineDate : deadlineDate // ignore: cast_nullable_to_non_nullable
as DateTime?,repeatIcalRrule: freezed == repeatIcalRrule ? _self.repeatIcalRrule : repeatIcalRrule // ignore: cast_nullable_to_non_nullable
as String?,values: freezed == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as List<ValueModel>?,labels: freezed == labels ? _self._labels : labels // ignore: cast_nullable_to_non_nullable
as List<Label>?,
  ));
}


}

/// @nodoc


class _ProjectDetailGet implements ProjectDetailEvent {
  const _ProjectDetailGet({required this.projectId});
  

 final  String projectId;

/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectDetailGetCopyWith<_ProjectDetailGet> get copyWith => __$ProjectDetailGetCopyWithImpl<_ProjectDetailGet>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDetailGet&&(identical(other.projectId, projectId) || other.projectId == projectId));
}


@override
int get hashCode => Object.hash(runtimeType,projectId);

@override
String toString() {
  return 'ProjectDetailEvent.get(projectId: $projectId)';
}


}

/// @nodoc
abstract mixin class _$ProjectDetailGetCopyWith<$Res> implements $ProjectDetailEventCopyWith<$Res> {
  factory _$ProjectDetailGetCopyWith(_ProjectDetailGet value, $Res Function(_ProjectDetailGet) _then) = __$ProjectDetailGetCopyWithImpl;
@useResult
$Res call({
 String projectId
});




}
/// @nodoc
class __$ProjectDetailGetCopyWithImpl<$Res>
    implements _$ProjectDetailGetCopyWith<$Res> {
  __$ProjectDetailGetCopyWithImpl(this._self, this._then);

  final _ProjectDetailGet _self;
  final $Res Function(_ProjectDetailGet) _then;

/// Create a copy of ProjectDetailEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? projectId = null,}) {
  return _then(_ProjectDetailGet(
projectId: null == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _ProjectDetailLoadInitialData implements ProjectDetailEvent {
  const _ProjectDetailLoadInitialData();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDetailLoadInitialData);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectDetailEvent.loadInitialData()';
}


}




/// @nodoc
mixin _$ProjectDetailError {

 Object get error; StackTrace? get stackTrace;
/// Create a copy of ProjectDetailError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectDetailErrorCopyWith<ProjectDetailError> get copyWith => _$ProjectDetailErrorCopyWithImpl<ProjectDetailError>(this as ProjectDetailError, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDetailError&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stackTrace);

@override
String toString() {
  return 'ProjectDetailError(error: $error, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class $ProjectDetailErrorCopyWith<$Res>  {
  factory $ProjectDetailErrorCopyWith(ProjectDetailError value, $Res Function(ProjectDetailError) _then) = _$ProjectDetailErrorCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace? stackTrace
});




}
/// @nodoc
class _$ProjectDetailErrorCopyWithImpl<$Res>
    implements $ProjectDetailErrorCopyWith<$Res> {
  _$ProjectDetailErrorCopyWithImpl(this._self, this._then);

  final ProjectDetailError _self;
  final $Res Function(ProjectDetailError) _then;

/// Create a copy of ProjectDetailError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? error = null,Object? stackTrace = freezed,}) {
  return _then(_self.copyWith(
error: null == error ? _self.error : error ,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProjectDetailError].
extension ProjectDetailErrorPatterns on ProjectDetailError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProjectDetailError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProjectDetailError() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProjectDetailError value)  $default,){
final _that = this;
switch (_that) {
case _ProjectDetailError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProjectDetailError value)?  $default,){
final _that = this;
switch (_that) {
case _ProjectDetailError() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Object error,  StackTrace? stackTrace)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProjectDetailError() when $default != null:
return $default(_that.error,_that.stackTrace);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Object error,  StackTrace? stackTrace)  $default,) {final _that = this;
switch (_that) {
case _ProjectDetailError():
return $default(_that.error,_that.stackTrace);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Object error,  StackTrace? stackTrace)?  $default,) {final _that = this;
switch (_that) {
case _ProjectDetailError() when $default != null:
return $default(_that.error,_that.stackTrace);case _:
  return null;

}
}

}

/// @nodoc


class _ProjectDetailError implements ProjectDetailError {
  const _ProjectDetailError({required this.error, this.stackTrace});
  

@override final  Object error;
@override final  StackTrace? stackTrace;

/// Create a copy of ProjectDetailError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProjectDetailErrorCopyWith<_ProjectDetailError> get copyWith => __$ProjectDetailErrorCopyWithImpl<_ProjectDetailError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProjectDetailError&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stackTrace);

@override
String toString() {
  return 'ProjectDetailError(error: $error, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class _$ProjectDetailErrorCopyWith<$Res> implements $ProjectDetailErrorCopyWith<$Res> {
  factory _$ProjectDetailErrorCopyWith(_ProjectDetailError value, $Res Function(_ProjectDetailError) _then) = __$ProjectDetailErrorCopyWithImpl;
@override @useResult
$Res call({
 Object error, StackTrace? stackTrace
});




}
/// @nodoc
class __$ProjectDetailErrorCopyWithImpl<$Res>
    implements _$ProjectDetailErrorCopyWith<$Res> {
  __$ProjectDetailErrorCopyWithImpl(this._self, this._then);

  final _ProjectDetailError _self;
  final $Res Function(_ProjectDetailError) _then;

/// Create a copy of ProjectDetailError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stackTrace = freezed,}) {
  return _then(_ProjectDetailError(
error: null == error ? _self.error : error ,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as StackTrace?,
  ));
}


}

/// @nodoc
mixin _$ProjectDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectDetailState()';
}


}

/// @nodoc
class $ProjectDetailStateCopyWith<$Res>  {
$ProjectDetailStateCopyWith(ProjectDetailState _, $Res Function(ProjectDetailState) __);
}


/// Adds pattern-matching-related methods to [ProjectDetailState].
extension ProjectDetailStatePatterns on ProjectDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProjectDetailInitial value)?  initial,TResult Function( ProjectDetailInitialDataLoadSuccess value)?  initialDataLoadSuccess,TResult Function( ProjectDetailOperationSuccess value)?  operationSuccess,TResult Function( ProjectDetailOperationFailure value)?  operationFailure,TResult Function( ProjectDetailLoadInProgress value)?  loadInProgress,TResult Function( ProjectDetailLoadSuccess value)?  loadSuccess,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProjectDetailInitial() when initial != null:
return initial(_that);case ProjectDetailInitialDataLoadSuccess() when initialDataLoadSuccess != null:
return initialDataLoadSuccess(_that);case ProjectDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that);case ProjectDetailOperationFailure() when operationFailure != null:
return operationFailure(_that);case ProjectDetailLoadInProgress() when loadInProgress != null:
return loadInProgress(_that);case ProjectDetailLoadSuccess() when loadSuccess != null:
return loadSuccess(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProjectDetailInitial value)  initial,required TResult Function( ProjectDetailInitialDataLoadSuccess value)  initialDataLoadSuccess,required TResult Function( ProjectDetailOperationSuccess value)  operationSuccess,required TResult Function( ProjectDetailOperationFailure value)  operationFailure,required TResult Function( ProjectDetailLoadInProgress value)  loadInProgress,required TResult Function( ProjectDetailLoadSuccess value)  loadSuccess,}){
final _that = this;
switch (_that) {
case ProjectDetailInitial():
return initial(_that);case ProjectDetailInitialDataLoadSuccess():
return initialDataLoadSuccess(_that);case ProjectDetailOperationSuccess():
return operationSuccess(_that);case ProjectDetailOperationFailure():
return operationFailure(_that);case ProjectDetailLoadInProgress():
return loadInProgress(_that);case ProjectDetailLoadSuccess():
return loadSuccess(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProjectDetailInitial value)?  initial,TResult? Function( ProjectDetailInitialDataLoadSuccess value)?  initialDataLoadSuccess,TResult? Function( ProjectDetailOperationSuccess value)?  operationSuccess,TResult? Function( ProjectDetailOperationFailure value)?  operationFailure,TResult? Function( ProjectDetailLoadInProgress value)?  loadInProgress,TResult? Function( ProjectDetailLoadSuccess value)?  loadSuccess,}){
final _that = this;
switch (_that) {
case ProjectDetailInitial() when initial != null:
return initial(_that);case ProjectDetailInitialDataLoadSuccess() when initialDataLoadSuccess != null:
return initialDataLoadSuccess(_that);case ProjectDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that);case ProjectDetailOperationFailure() when operationFailure != null:
return operationFailure(_that);case ProjectDetailLoadInProgress() when loadInProgress != null:
return loadInProgress(_that);case ProjectDetailLoadSuccess() when loadSuccess != null:
return loadSuccess(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( List<ValueModel> availableValues,  List<Label> availableLabels)?  initialDataLoadSuccess,TResult Function( EntityOperation operation)?  operationSuccess,TResult Function( ProjectDetailError errorDetails)?  operationFailure,TResult Function()?  loadInProgress,TResult Function( List<ValueModel> availableValues,  List<Label> availableLabels,  Project project)?  loadSuccess,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProjectDetailInitial() when initial != null:
return initial();case ProjectDetailInitialDataLoadSuccess() when initialDataLoadSuccess != null:
return initialDataLoadSuccess(_that.availableValues,_that.availableLabels);case ProjectDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that.operation);case ProjectDetailOperationFailure() when operationFailure != null:
return operationFailure(_that.errorDetails);case ProjectDetailLoadInProgress() when loadInProgress != null:
return loadInProgress();case ProjectDetailLoadSuccess() when loadSuccess != null:
return loadSuccess(_that.availableValues,_that.availableLabels,_that.project);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( List<ValueModel> availableValues,  List<Label> availableLabels)  initialDataLoadSuccess,required TResult Function( EntityOperation operation)  operationSuccess,required TResult Function( ProjectDetailError errorDetails)  operationFailure,required TResult Function()  loadInProgress,required TResult Function( List<ValueModel> availableValues,  List<Label> availableLabels,  Project project)  loadSuccess,}) {final _that = this;
switch (_that) {
case ProjectDetailInitial():
return initial();case ProjectDetailInitialDataLoadSuccess():
return initialDataLoadSuccess(_that.availableValues,_that.availableLabels);case ProjectDetailOperationSuccess():
return operationSuccess(_that.operation);case ProjectDetailOperationFailure():
return operationFailure(_that.errorDetails);case ProjectDetailLoadInProgress():
return loadInProgress();case ProjectDetailLoadSuccess():
return loadSuccess(_that.availableValues,_that.availableLabels,_that.project);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( List<ValueModel> availableValues,  List<Label> availableLabels)?  initialDataLoadSuccess,TResult? Function( EntityOperation operation)?  operationSuccess,TResult? Function( ProjectDetailError errorDetails)?  operationFailure,TResult? Function()?  loadInProgress,TResult? Function( List<ValueModel> availableValues,  List<Label> availableLabels,  Project project)?  loadSuccess,}) {final _that = this;
switch (_that) {
case ProjectDetailInitial() when initial != null:
return initial();case ProjectDetailInitialDataLoadSuccess() when initialDataLoadSuccess != null:
return initialDataLoadSuccess(_that.availableValues,_that.availableLabels);case ProjectDetailOperationSuccess() when operationSuccess != null:
return operationSuccess(_that.operation);case ProjectDetailOperationFailure() when operationFailure != null:
return operationFailure(_that.errorDetails);case ProjectDetailLoadInProgress() when loadInProgress != null:
return loadInProgress();case ProjectDetailLoadSuccess() when loadSuccess != null:
return loadSuccess(_that.availableValues,_that.availableLabels,_that.project);case _:
  return null;

}
}

}

/// @nodoc


class ProjectDetailInitial implements ProjectDetailState {
  const ProjectDetailInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDetailInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectDetailState.initial()';
}


}




/// @nodoc


class ProjectDetailInitialDataLoadSuccess implements ProjectDetailState {
  const ProjectDetailInitialDataLoadSuccess({required final  List<ValueModel> availableValues, required final  List<Label> availableLabels}): _availableValues = availableValues,_availableLabels = availableLabels;
  

 final  List<ValueModel> _availableValues;
 List<ValueModel> get availableValues {
  if (_availableValues is EqualUnmodifiableListView) return _availableValues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableValues);
}

 final  List<Label> _availableLabels;
 List<Label> get availableLabels {
  if (_availableLabels is EqualUnmodifiableListView) return _availableLabels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableLabels);
}


/// Create a copy of ProjectDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectDetailInitialDataLoadSuccessCopyWith<ProjectDetailInitialDataLoadSuccess> get copyWith => _$ProjectDetailInitialDataLoadSuccessCopyWithImpl<ProjectDetailInitialDataLoadSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDetailInitialDataLoadSuccess&&const DeepCollectionEquality().equals(other._availableValues, _availableValues)&&const DeepCollectionEquality().equals(other._availableLabels, _availableLabels));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_availableValues),const DeepCollectionEquality().hash(_availableLabels));

@override
String toString() {
  return 'ProjectDetailState.initialDataLoadSuccess(availableValues: $availableValues, availableLabels: $availableLabels)';
}


}

/// @nodoc
abstract mixin class $ProjectDetailInitialDataLoadSuccessCopyWith<$Res> implements $ProjectDetailStateCopyWith<$Res> {
  factory $ProjectDetailInitialDataLoadSuccessCopyWith(ProjectDetailInitialDataLoadSuccess value, $Res Function(ProjectDetailInitialDataLoadSuccess) _then) = _$ProjectDetailInitialDataLoadSuccessCopyWithImpl;
@useResult
$Res call({
 List<ValueModel> availableValues, List<Label> availableLabels
});




}
/// @nodoc
class _$ProjectDetailInitialDataLoadSuccessCopyWithImpl<$Res>
    implements $ProjectDetailInitialDataLoadSuccessCopyWith<$Res> {
  _$ProjectDetailInitialDataLoadSuccessCopyWithImpl(this._self, this._then);

  final ProjectDetailInitialDataLoadSuccess _self;
  final $Res Function(ProjectDetailInitialDataLoadSuccess) _then;

/// Create a copy of ProjectDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? availableValues = null,Object? availableLabels = null,}) {
  return _then(ProjectDetailInitialDataLoadSuccess(
availableValues: null == availableValues ? _self._availableValues : availableValues // ignore: cast_nullable_to_non_nullable
as List<ValueModel>,availableLabels: null == availableLabels ? _self._availableLabels : availableLabels // ignore: cast_nullable_to_non_nullable
as List<Label>,
  ));
}


}

/// @nodoc


class ProjectDetailOperationSuccess implements ProjectDetailState {
  const ProjectDetailOperationSuccess({required this.operation});
  

 final  EntityOperation operation;

/// Create a copy of ProjectDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectDetailOperationSuccessCopyWith<ProjectDetailOperationSuccess> get copyWith => _$ProjectDetailOperationSuccessCopyWithImpl<ProjectDetailOperationSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDetailOperationSuccess&&(identical(other.operation, operation) || other.operation == operation));
}


@override
int get hashCode => Object.hash(runtimeType,operation);

@override
String toString() {
  return 'ProjectDetailState.operationSuccess(operation: $operation)';
}


}

/// @nodoc
abstract mixin class $ProjectDetailOperationSuccessCopyWith<$Res> implements $ProjectDetailStateCopyWith<$Res> {
  factory $ProjectDetailOperationSuccessCopyWith(ProjectDetailOperationSuccess value, $Res Function(ProjectDetailOperationSuccess) _then) = _$ProjectDetailOperationSuccessCopyWithImpl;
@useResult
$Res call({
 EntityOperation operation
});




}
/// @nodoc
class _$ProjectDetailOperationSuccessCopyWithImpl<$Res>
    implements $ProjectDetailOperationSuccessCopyWith<$Res> {
  _$ProjectDetailOperationSuccessCopyWithImpl(this._self, this._then);

  final ProjectDetailOperationSuccess _self;
  final $Res Function(ProjectDetailOperationSuccess) _then;

/// Create a copy of ProjectDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? operation = null,}) {
  return _then(ProjectDetailOperationSuccess(
operation: null == operation ? _self.operation : operation // ignore: cast_nullable_to_non_nullable
as EntityOperation,
  ));
}


}

/// @nodoc


class ProjectDetailOperationFailure implements ProjectDetailState {
  const ProjectDetailOperationFailure({required this.errorDetails});
  

 final  ProjectDetailError errorDetails;

/// Create a copy of ProjectDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectDetailOperationFailureCopyWith<ProjectDetailOperationFailure> get copyWith => _$ProjectDetailOperationFailureCopyWithImpl<ProjectDetailOperationFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDetailOperationFailure&&(identical(other.errorDetails, errorDetails) || other.errorDetails == errorDetails));
}


@override
int get hashCode => Object.hash(runtimeType,errorDetails);

@override
String toString() {
  return 'ProjectDetailState.operationFailure(errorDetails: $errorDetails)';
}


}

/// @nodoc
abstract mixin class $ProjectDetailOperationFailureCopyWith<$Res> implements $ProjectDetailStateCopyWith<$Res> {
  factory $ProjectDetailOperationFailureCopyWith(ProjectDetailOperationFailure value, $Res Function(ProjectDetailOperationFailure) _then) = _$ProjectDetailOperationFailureCopyWithImpl;
@useResult
$Res call({
 ProjectDetailError errorDetails
});


$ProjectDetailErrorCopyWith<$Res> get errorDetails;

}
/// @nodoc
class _$ProjectDetailOperationFailureCopyWithImpl<$Res>
    implements $ProjectDetailOperationFailureCopyWith<$Res> {
  _$ProjectDetailOperationFailureCopyWithImpl(this._self, this._then);

  final ProjectDetailOperationFailure _self;
  final $Res Function(ProjectDetailOperationFailure) _then;

/// Create a copy of ProjectDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? errorDetails = null,}) {
  return _then(ProjectDetailOperationFailure(
errorDetails: null == errorDetails ? _self.errorDetails : errorDetails // ignore: cast_nullable_to_non_nullable
as ProjectDetailError,
  ));
}

/// Create a copy of ProjectDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProjectDetailErrorCopyWith<$Res> get errorDetails {
  
  return $ProjectDetailErrorCopyWith<$Res>(_self.errorDetails, (value) {
    return _then(_self.copyWith(errorDetails: value));
  });
}
}

/// @nodoc


class ProjectDetailLoadInProgress implements ProjectDetailState {
  const ProjectDetailLoadInProgress();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDetailLoadInProgress);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProjectDetailState.loadInProgress()';
}


}




/// @nodoc


class ProjectDetailLoadSuccess implements ProjectDetailState {
  const ProjectDetailLoadSuccess({required final  List<ValueModel> availableValues, required final  List<Label> availableLabels, required this.project}): _availableValues = availableValues,_availableLabels = availableLabels;
  

 final  List<ValueModel> _availableValues;
 List<ValueModel> get availableValues {
  if (_availableValues is EqualUnmodifiableListView) return _availableValues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableValues);
}

 final  List<Label> _availableLabels;
 List<Label> get availableLabels {
  if (_availableLabels is EqualUnmodifiableListView) return _availableLabels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableLabels);
}

 final  Project project;

/// Create a copy of ProjectDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProjectDetailLoadSuccessCopyWith<ProjectDetailLoadSuccess> get copyWith => _$ProjectDetailLoadSuccessCopyWithImpl<ProjectDetailLoadSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProjectDetailLoadSuccess&&const DeepCollectionEquality().equals(other._availableValues, _availableValues)&&const DeepCollectionEquality().equals(other._availableLabels, _availableLabels)&&(identical(other.project, project) || other.project == project));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_availableValues),const DeepCollectionEquality().hash(_availableLabels),project);

@override
String toString() {
  return 'ProjectDetailState.loadSuccess(availableValues: $availableValues, availableLabels: $availableLabels, project: $project)';
}


}

/// @nodoc
abstract mixin class $ProjectDetailLoadSuccessCopyWith<$Res> implements $ProjectDetailStateCopyWith<$Res> {
  factory $ProjectDetailLoadSuccessCopyWith(ProjectDetailLoadSuccess value, $Res Function(ProjectDetailLoadSuccess) _then) = _$ProjectDetailLoadSuccessCopyWithImpl;
@useResult
$Res call({
 List<ValueModel> availableValues, List<Label> availableLabels, Project project
});




}
/// @nodoc
class _$ProjectDetailLoadSuccessCopyWithImpl<$Res>
    implements $ProjectDetailLoadSuccessCopyWith<$Res> {
  _$ProjectDetailLoadSuccessCopyWithImpl(this._self, this._then);

  final ProjectDetailLoadSuccess _self;
  final $Res Function(ProjectDetailLoadSuccess) _then;

/// Create a copy of ProjectDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? availableValues = null,Object? availableLabels = null,Object? project = null,}) {
  return _then(ProjectDetailLoadSuccess(
availableValues: null == availableValues ? _self._availableValues : availableValues // ignore: cast_nullable_to_non_nullable
as List<ValueModel>,availableLabels: null == availableLabels ? _self._availableLabels : availableLabels // ignore: cast_nullable_to_non_nullable
as List<Label>,project: null == project ? _self.project : project // ignore: cast_nullable_to_non_nullable
as Project,
  ));
}


}

// dart format on
