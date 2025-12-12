// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskModel {

 String get id; String get name;@JsonKey(name: 'completed', fromJson: fromJsonIntToBool, toJson: toJsonBooltoInt) bool get completed; DateTime get createdAt; DateTime get updatedAt; DateTime? get startedDate; DateTime? get deadlineDate; String? get description; String? get projectId; String? get repeatId;
/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskModelCopyWith<TaskModel> get copyWith => _$TaskModelCopyWithImpl<TaskModel>(this as TaskModel, _$identity);

  /// Serializes this TaskModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.startedDate, startedDate) || other.startedDate == startedDate)&&(identical(other.deadlineDate, deadlineDate) || other.deadlineDate == deadlineDate)&&(identical(other.description, description) || other.description == description)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.repeatId, repeatId) || other.repeatId == repeatId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,completed,createdAt,updatedAt,startedDate,deadlineDate,description,projectId,repeatId);

@override
String toString() {
  return 'TaskModel(id: $id, name: $name, completed: $completed, createdAt: $createdAt, updatedAt: $updatedAt, startedDate: $startedDate, deadlineDate: $deadlineDate, description: $description, projectId: $projectId, repeatId: $repeatId)';
}


}

/// @nodoc
abstract mixin class $TaskModelCopyWith<$Res>  {
  factory $TaskModelCopyWith(TaskModel value, $Res Function(TaskModel) _then) = _$TaskModelCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'completed', fromJson: fromJsonIntToBool, toJson: toJsonBooltoInt) bool completed, DateTime createdAt, DateTime updatedAt, DateTime? startedDate, DateTime? deadlineDate, String? description, String? projectId, String? repeatId
});




}
/// @nodoc
class _$TaskModelCopyWithImpl<$Res>
    implements $TaskModelCopyWith<$Res> {
  _$TaskModelCopyWithImpl(this._self, this._then);

  final TaskModel _self;
  final $Res Function(TaskModel) _then;

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? completed = null,Object? createdAt = null,Object? updatedAt = null,Object? startedDate = freezed,Object? deadlineDate = freezed,Object? description = freezed,Object? projectId = freezed,Object? repeatId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,startedDate: freezed == startedDate ? _self.startedDate : startedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,deadlineDate: freezed == deadlineDate ? _self.deadlineDate : deadlineDate // ignore: cast_nullable_to_non_nullable
as DateTime?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,projectId: freezed == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String?,repeatId: freezed == repeatId ? _self.repeatId : repeatId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskModel].
extension TaskModelPatterns on TaskModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskModel value)  $default,){
final _that = this;
switch (_that) {
case _TaskModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskModel value)?  $default,){
final _that = this;
switch (_that) {
case _TaskModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'completed', fromJson: fromJsonIntToBool, toJson: toJsonBooltoInt)  bool completed,  DateTime createdAt,  DateTime updatedAt,  DateTime? startedDate,  DateTime? deadlineDate,  String? description,  String? projectId,  String? repeatId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskModel() when $default != null:
return $default(_that.id,_that.name,_that.completed,_that.createdAt,_that.updatedAt,_that.startedDate,_that.deadlineDate,_that.description,_that.projectId,_that.repeatId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'completed', fromJson: fromJsonIntToBool, toJson: toJsonBooltoInt)  bool completed,  DateTime createdAt,  DateTime updatedAt,  DateTime? startedDate,  DateTime? deadlineDate,  String? description,  String? projectId,  String? repeatId)  $default,) {final _that = this;
switch (_that) {
case _TaskModel():
return $default(_that.id,_that.name,_that.completed,_that.createdAt,_that.updatedAt,_that.startedDate,_that.deadlineDate,_that.description,_that.projectId,_that.repeatId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @JsonKey(name: 'completed', fromJson: fromJsonIntToBool, toJson: toJsonBooltoInt)  bool completed,  DateTime createdAt,  DateTime updatedAt,  DateTime? startedDate,  DateTime? deadlineDate,  String? description,  String? projectId,  String? repeatId)?  $default,) {final _that = this;
switch (_that) {
case _TaskModel() when $default != null:
return $default(_that.id,_that.name,_that.completed,_that.createdAt,_that.updatedAt,_that.startedDate,_that.deadlineDate,_that.description,_that.projectId,_that.repeatId);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class _TaskModel implements TaskModel {
  const _TaskModel({required this.id, required this.name, @JsonKey(name: 'completed', fromJson: fromJsonIntToBool, toJson: toJsonBooltoInt) required this.completed, required this.createdAt, required this.updatedAt, this.startedDate, this.deadlineDate, this.description, this.projectId, this.repeatId});
  factory _TaskModel.fromJson(Map<String, dynamic> json) => _$TaskModelFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey(name: 'completed', fromJson: fromJsonIntToBool, toJson: toJsonBooltoInt) final  bool completed;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  DateTime? startedDate;
@override final  DateTime? deadlineDate;
@override final  String? description;
@override final  String? projectId;
@override final  String? repeatId;

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskModelCopyWith<_TaskModel> get copyWith => __$TaskModelCopyWithImpl<_TaskModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.startedDate, startedDate) || other.startedDate == startedDate)&&(identical(other.deadlineDate, deadlineDate) || other.deadlineDate == deadlineDate)&&(identical(other.description, description) || other.description == description)&&(identical(other.projectId, projectId) || other.projectId == projectId)&&(identical(other.repeatId, repeatId) || other.repeatId == repeatId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,completed,createdAt,updatedAt,startedDate,deadlineDate,description,projectId,repeatId);

@override
String toString() {
  return 'TaskModel(id: $id, name: $name, completed: $completed, createdAt: $createdAt, updatedAt: $updatedAt, startedDate: $startedDate, deadlineDate: $deadlineDate, description: $description, projectId: $projectId, repeatId: $repeatId)';
}


}

/// @nodoc
abstract mixin class _$TaskModelCopyWith<$Res> implements $TaskModelCopyWith<$Res> {
  factory _$TaskModelCopyWith(_TaskModel value, $Res Function(_TaskModel) _then) = __$TaskModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'completed', fromJson: fromJsonIntToBool, toJson: toJsonBooltoInt) bool completed, DateTime createdAt, DateTime updatedAt, DateTime? startedDate, DateTime? deadlineDate, String? description, String? projectId, String? repeatId
});




}
/// @nodoc
class __$TaskModelCopyWithImpl<$Res>
    implements _$TaskModelCopyWith<$Res> {
  __$TaskModelCopyWithImpl(this._self, this._then);

  final _TaskModel _self;
  final $Res Function(_TaskModel) _then;

/// Create a copy of TaskModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? completed = null,Object? createdAt = null,Object? updatedAt = null,Object? startedDate = freezed,Object? deadlineDate = freezed,Object? description = freezed,Object? projectId = freezed,Object? repeatId = freezed,}) {
  return _then(_TaskModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,startedDate: freezed == startedDate ? _self.startedDate : startedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,deadlineDate: freezed == deadlineDate ? _self.deadlineDate : deadlineDate // ignore: cast_nullable_to_non_nullable
as DateTime?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,projectId: freezed == projectId ? _self.projectId : projectId // ignore: cast_nullable_to_non_nullable
as String?,repeatId: freezed == repeatId ? _self.repeatId : repeatId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
