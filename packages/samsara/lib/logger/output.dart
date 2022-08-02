import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

const kConsoleColorBlack = '\x1B[30m';
const kConsoleColorRed = '\x1B[31m';
const kConsoleColorGreen = '\x1B[32m';
const kConsoleColorYellow = '\x1B[33m';
const kConsoleColorBlue = '\x1B[34m';
const kConsoleColorMagenta = '\x1B[35m';
const kConsoleColorCyan = '\x1B[36m';
const kConsoleColorWhite = '\x1B[37m';
const kConsoleColorReset = '\x1B[0m';

class CustomLoggerOutput extends LogOutput {
  final List<String> log = [];
  @override
  void output(OutputEvent event) {
    for (final message in event.lines) {
      final lines = message.split('\n');
      if (kDebugMode) {
        log.addAll(event.lines);
        if (lines.length > 1) {
          if (event.level == Level.warning) {
            print(
                '${kConsoleColorYellow}samsara engine - ${event.level.name}:$kConsoleColorReset');
          } else if (event.level == Level.error) {
            print(
                '${kConsoleColorRed}samsara engine - ${event.level.name}:$kConsoleColorReset');
          } else {
            print('samsara engine - ${event.level.name}:');
          }
          for (final line in lines) {
            if (event.level == Level.warning) {
              print('$kConsoleColorYellow$line$kConsoleColorReset');
            } else if (event.level == Level.error) {
              print('$kConsoleColorRed$line$kConsoleColorReset');
            } else {
              print(line);
            }
          }
        } else {
          if (event.level == Level.warning) {
            print(
                '${kConsoleColorYellow}samsara engine - ${event.level.name}: $message$kConsoleColorReset');
          } else if (event.level == Level.error) {
            print(
                '${kConsoleColorRed}samsara engine - ${event.level.name}: $message$kConsoleColorReset');
          } else {
            print('samsara engine - ${event.level.name}: $message');
          }
        }
      } else {
        for (final line in lines) {
          if (event.level == Level.warning || event.level == Level.error) {
            log.add(line);
          }
        }
      }
    }
  }
}
