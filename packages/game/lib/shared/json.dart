import 'dart:convert';

const _jsonEncoderWithIndent = JsonEncoder.withIndent('  ');

dynamic jsonCopy(dynamic fromData) {
  dynamic copy;
  if (fromData is Map) {
    copy = {};
    fromData.forEach((key, value) {
      copy[key] = jsonCopy(value);
    });
  } else if (fromData is List) {
    copy = [];
    for (final element in fromData) {
      copy.add(jsonCopy(element));
    }
  } else {
    copy = fromData;
  }
  return copy;
}

void jsonUpdate(Map data, Map from) {
  from.forEach((key, value) {
    if (value is Map) {
      if (data[key] == null) data[key] = {};
      jsonUpdate(data[key], from[key]);
    } else if (value is List) {
      data[key] = [];
      for (final element in value) {
        data[key].add(jsonCopy(element));
      }
    } else {
      data[key] = value;
    }
  });
}

String jsonEncodeWithIndent(Object? source) =>
    _jsonEncoderWithIndent.convert(source);
