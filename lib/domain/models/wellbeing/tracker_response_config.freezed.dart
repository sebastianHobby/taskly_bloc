// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tracker_response_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
TrackerResponseConfig _$TrackerResponseConfigFromJson(
  Map<String, dynamic> json
) {
        switch (json['runtimeType']) {
                  case 'choice':
          return ChoiceConfig.fromJson(
            json
          );
                case 'scale':
          return ScaleConfig.fromJson(
            json
          );
                case 'yesNo':
          return YesNoConfig.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'TrackerResponseConfig',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$TrackerResponseConfig {



  /// Serializes this TrackerResponseConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackerResponseConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TrackerResponseConfig()';
}


}

/// @nodoc
class $TrackerResponseConfigCopyWith<$Res>  {
$TrackerResponseConfigCopyWith(TrackerResponseConfig _, $Res Function(TrackerResponseConfig) __);
}


/// Adds pattern-matching-related methods to [TrackerResponseConfig].
extension TrackerResponseConfigPatterns on TrackerResponseConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChoiceConfig value)?  choice,TResult Function( ScaleConfig value)?  scale,TResult Function( YesNoConfig value)?  yesNo,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChoiceConfig() when choice != null:
return choice(_that);case ScaleConfig() when scale != null:
return scale(_that);case YesNoConfig() when yesNo != null:
return yesNo(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChoiceConfig value)  choice,required TResult Function( ScaleConfig value)  scale,required TResult Function( YesNoConfig value)  yesNo,}){
final _that = this;
switch (_that) {
case ChoiceConfig():
return choice(_that);case ScaleConfig():
return scale(_that);case YesNoConfig():
return yesNo(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChoiceConfig value)?  choice,TResult? Function( ScaleConfig value)?  scale,TResult? Function( YesNoConfig value)?  yesNo,}){
final _that = this;
switch (_that) {
case ChoiceConfig() when choice != null:
return choice(_that);case ScaleConfig() when scale != null:
return scale(_that);case YesNoConfig() when yesNo != null:
return yesNo(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<String> options)?  choice,TResult Function( int min,  int max,  String? minLabel,  String? maxLabel)?  scale,TResult Function()?  yesNo,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChoiceConfig() when choice != null:
return choice(_that.options);case ScaleConfig() when scale != null:
return scale(_that.min,_that.max,_that.minLabel,_that.maxLabel);case YesNoConfig() when yesNo != null:
return yesNo();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<String> options)  choice,required TResult Function( int min,  int max,  String? minLabel,  String? maxLabel)  scale,required TResult Function()  yesNo,}) {final _that = this;
switch (_that) {
case ChoiceConfig():
return choice(_that.options);case ScaleConfig():
return scale(_that.min,_that.max,_that.minLabel,_that.maxLabel);case YesNoConfig():
return yesNo();case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<String> options)?  choice,TResult? Function( int min,  int max,  String? minLabel,  String? maxLabel)?  scale,TResult? Function()?  yesNo,}) {final _that = this;
switch (_that) {
case ChoiceConfig() when choice != null:
return choice(_that.options);case ScaleConfig() when scale != null:
return scale(_that.min,_that.max,_that.minLabel,_that.maxLabel);case YesNoConfig() when yesNo != null:
return yesNo();case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class ChoiceConfig implements TrackerResponseConfig {
  const ChoiceConfig({required final  List<String> options, final  String? $type}): _options = options,$type = $type ?? 'choice';
  factory ChoiceConfig.fromJson(Map<String, dynamic> json) => _$ChoiceConfigFromJson(json);

 final  List<String> _options;
 List<String> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}


@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of TrackerResponseConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChoiceConfigCopyWith<ChoiceConfig> get copyWith => _$ChoiceConfigCopyWithImpl<ChoiceConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChoiceConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChoiceConfig&&const DeepCollectionEquality().equals(other._options, _options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_options));

@override
String toString() {
  return 'TrackerResponseConfig.choice(options: $options)';
}


}

/// @nodoc
abstract mixin class $ChoiceConfigCopyWith<$Res> implements $TrackerResponseConfigCopyWith<$Res> {
  factory $ChoiceConfigCopyWith(ChoiceConfig value, $Res Function(ChoiceConfig) _then) = _$ChoiceConfigCopyWithImpl;
@useResult
$Res call({
 List<String> options
});




}
/// @nodoc
class _$ChoiceConfigCopyWithImpl<$Res>
    implements $ChoiceConfigCopyWith<$Res> {
  _$ChoiceConfigCopyWithImpl(this._self, this._then);

  final ChoiceConfig _self;
  final $Res Function(ChoiceConfig) _then;

/// Create a copy of TrackerResponseConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? options = null,}) {
  return _then(ChoiceConfig(
options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ScaleConfig implements TrackerResponseConfig {
  const ScaleConfig({this.min = 1, this.max = 5, this.minLabel, this.maxLabel, final  String? $type}): $type = $type ?? 'scale';
  factory ScaleConfig.fromJson(Map<String, dynamic> json) => _$ScaleConfigFromJson(json);

@JsonKey() final  int min;
@JsonKey() final  int max;
 final  String? minLabel;
 final  String? maxLabel;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of TrackerResponseConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScaleConfigCopyWith<ScaleConfig> get copyWith => _$ScaleConfigCopyWithImpl<ScaleConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScaleConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScaleConfig&&(identical(other.min, min) || other.min == min)&&(identical(other.max, max) || other.max == max)&&(identical(other.minLabel, minLabel) || other.minLabel == minLabel)&&(identical(other.maxLabel, maxLabel) || other.maxLabel == maxLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,min,max,minLabel,maxLabel);

@override
String toString() {
  return 'TrackerResponseConfig.scale(min: $min, max: $max, minLabel: $minLabel, maxLabel: $maxLabel)';
}


}

/// @nodoc
abstract mixin class $ScaleConfigCopyWith<$Res> implements $TrackerResponseConfigCopyWith<$Res> {
  factory $ScaleConfigCopyWith(ScaleConfig value, $Res Function(ScaleConfig) _then) = _$ScaleConfigCopyWithImpl;
@useResult
$Res call({
 int min, int max, String? minLabel, String? maxLabel
});




}
/// @nodoc
class _$ScaleConfigCopyWithImpl<$Res>
    implements $ScaleConfigCopyWith<$Res> {
  _$ScaleConfigCopyWithImpl(this._self, this._then);

  final ScaleConfig _self;
  final $Res Function(ScaleConfig) _then;

/// Create a copy of TrackerResponseConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? min = null,Object? max = null,Object? minLabel = freezed,Object? maxLabel = freezed,}) {
  return _then(ScaleConfig(
min: null == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as int,max: null == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as int,minLabel: freezed == minLabel ? _self.minLabel : minLabel // ignore: cast_nullable_to_non_nullable
as String?,maxLabel: freezed == maxLabel ? _self.maxLabel : maxLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class YesNoConfig implements TrackerResponseConfig {
  const YesNoConfig({final  String? $type}): $type = $type ?? 'yesNo';
  factory YesNoConfig.fromJson(Map<String, dynamic> json) => _$YesNoConfigFromJson(json);



@JsonKey(name: 'runtimeType')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$YesNoConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YesNoConfig);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TrackerResponseConfig.yesNo()';
}


}




// dart format on
