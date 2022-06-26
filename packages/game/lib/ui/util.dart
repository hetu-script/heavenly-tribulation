import 'dart:math' as math;

import '../global.dart';

String getNameFromId(String? id) {
  if (id != null) {
    final l = id.split('_');
    return l.last;
  } else {
    return engine.locale['none'];
  }
}

Iterable<String> getNamesFromEntityIds(Iterable ids) {
  if (ids.isNotEmpty) {
    return ids.map((id) => getNameFromId(id));
  } else {
    return [engine.locale['none']];
  }
}

/// Constant factor to convert and angle from degrees to radians.
const double kDegrees2Radians = math.pi / 180.0;

/// Constant factor to convert and angle from radians to degrees.
const double kRadians2Degrees = 180.0 / math.pi;

/// Convert [radians] to degrees.
double degrees(double radians) => radians * kRadians2Degrees;

/// Convert [degrees] to radians.
double radians(double degrees) => degrees * kDegrees2Radians;
