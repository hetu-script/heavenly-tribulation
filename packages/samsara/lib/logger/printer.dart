import 'package:logger/logger.dart';

class CustomLoggerPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    return [event.message];
  }
}
