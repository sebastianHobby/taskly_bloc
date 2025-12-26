// Not using positional boolean parameters as the calling code is json_serializable generated and does not support named parameters
// ignore_for_file: avoid_positional_boolean_parameters

import 'package:uuid/uuid.dart';

bool fromJsonIntToBool(int? value) {
  return (value == 1);
}

int toJsonBooltoInt(bool value) {
  return value ? 1 : 0;
}

String getUuid() {
  const Uuid uuid = Uuid();
  return uuid.v4();
}
