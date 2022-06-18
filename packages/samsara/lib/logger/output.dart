import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class CustomLoggerOutput extends LogOutput {
  final List<String> log = [];
  @override
  void output(OutputEvent event) {
    log.addAll(event.lines);
    if (kDebugMode) {
      for (var line in event.lines) {
        print(line);
      }
    }
  }
}
