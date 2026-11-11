import 'dart:math' as math;

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

const _kUint32Mask = 0xFFFFFFFF;
const _kUint32Range = 0x100000000;

class SerializableRandom implements math.Random {
  int _state;

  SerializableRandom([int? seed])
      : _state = _normalizeSeed(seed ?? DateTime.now().microsecondsSinceEpoch);

  static int _normalizeSeed(int seed) {
    final normalized = seed & _kUint32Mask;
    return normalized == 0 ? 0x6D2B79F5 : normalized;
  }

  int get state => _state;

  set state(int value) {
    _state = _normalizeSeed(value);
  }

  int _nextUint32() {
    var value = _state;
    value ^= (value << 13) & _kUint32Mask;
    value &= _kUint32Mask;
    value ^= value >> 17;
    value ^= (value << 5) & _kUint32Mask;
    _state = value & _kUint32Mask;
    return _state;
  }

  @override
  int nextInt(int max) {
    if (max <= 0 || max > _kUint32Range) {
      throw RangeError.range(max, 1, _kUint32Range, 'max');
    }
    return _nextUint32() % max;
  }

  @override
  double nextDouble() => _nextUint32() / _kUint32Range;

  @override
  bool nextBool() => (_nextUint32() & 1) == 0;

  bool nextBoolBiased(double input, double target) {
    if (input >= target) return true;
    final difference = (input - target).abs();
    final probability = 1 - (difference / target);
    return nextDouble() <= probability;
  }

  int nearInt(int max, {double bias = 1.0}) {
    if (max <= 1) return 0;
    final result = (max * math.pow(nextDouble(), 1 / (1 + bias))).toInt();
    return result.clamp(0, max - 1);
  }

  int distantInt(int max, {double bias = 1.0}) {
    if (max <= 1) return 0;
    final result = (max * (1 - math.pow(nextDouble(), 1 / (1 + bias)))).toInt();
    return result.clamp(0, max - 1);
  }

  String nextColorHex({bool hasAlpha = false}) {
    final prefix = hasAlpha ? '#ff' : '#';
    return prefix +
        (nextDouble() * 16777215).truncate().toRadixString(16).padLeft(6, '0');
  }

  String nextBrightColorHex({bool hasAlpha = false}) {
    final prefix = hasAlpha ? '#ff' : '#';
    return prefix +
        (nextDouble() * 5592405 + 11184810)
            .truncate()
            .toRadixString(16)
            .padLeft(6, '0');
  }

  dynamic nextIterable(Iterable iterable) {
    if (iterable.isEmpty) return null;
    return iterable.elementAt(nextInt(iterable.length));
  }

  List<dynamic> shuffle(Iterable iterable) {
    final result = iterable.toList();
    for (var i = result.length - 1; i > 0; --i) {
      final j = nextInt(i + 1);
      final value = result[i];
      result[i] = result[j];
      result[j] = value;
    }
    return result;
  }
}

class GameRandomClassBinding extends HTExternalClass {
  GameRandomClassBinding() : super('Random');

  @override
  dynamic memberGet(String id,
      {String? from, bool isRecursive = false, bool ignoreUndefined = false}) {
    if (id == 'Random') {
      return ({positionalArgs, namedArgs}) => SerializableRandom(
            positionalArgs.isEmpty ? null : positionalArgs.first,
          );
    }
    if (!ignoreUndefined) throw HTError.undefined(id);
  }

  @override
  dynamic instanceMemberGet(dynamic instance, String id,
      {bool ignoreUndefined = false}) {
    final random = instance as SerializableRandom;
    switch (id) {
      case 'state':
        return random.state;
      case 'nextBool':
        return ({object, positionalArgs, namedArgs}) => random.nextBool();
      case 'nextBoolBiased':
        return ({object, positionalArgs, namedArgs}) => random.nextBoolBiased(
              (positionalArgs[0] as num).toDouble(),
              (positionalArgs[1] as num).toDouble(),
            );
      case 'nextDouble':
        return ({object, positionalArgs, namedArgs}) => random.nextDouble();
      case 'nearInt':
        return ({object, positionalArgs, namedArgs}) => random.nearInt(
              positionalArgs.first,
              bias: (namedArgs['bias'] as num?)?.toDouble() ?? 1.0,
            );
      case 'distantInt':
        return ({object, positionalArgs, namedArgs}) => random.distantInt(
              positionalArgs.first,
              bias: (namedArgs['bias'] as num?)?.toDouble() ?? 1.0,
            );
      case 'nextInt':
        return ({object, positionalArgs, namedArgs}) =>
            random.nextInt(positionalArgs[0].toInt());
      case 'nextColorHex':
        return ({object, positionalArgs, namedArgs}) => random.nextColorHex(
              hasAlpha: namedArgs['hasAlpha'] ?? false,
            );
      case 'nextBrightColorHex':
        return ({object, positionalArgs, namedArgs}) =>
            random.nextBrightColorHex(
              hasAlpha: namedArgs['hasAlpha'] ?? false,
            );
      case 'nextIterable':
        return ({object, positionalArgs, namedArgs}) =>
            random.nextIterable(positionalArgs.first);
      case 'shuffle':
        return ({object, positionalArgs, namedArgs}) =>
            random.shuffle(positionalArgs.first);
      default:
        if (!ignoreUndefined) throw HTError.undefined(id);
    }
  }

  @override
  void instanceMemberSet(dynamic instance, String id, dynamic value,
      {bool ignoreUndefined = false}) {
    if (id == 'state') {
      (instance as SerializableRandom).state = (value as num).toInt();
      return;
    }
    if (!ignoreUndefined) throw HTError.undefined(id);
  }
}
