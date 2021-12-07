import 'time.dart';

class HistoryFeed {
  final String entityId;
  final GameDateTime timestamp;
  final String text;

  final List<String>? mentioned;

  HistoryFeed(
      {required this.entityId,
      required this.timestamp,
      required this.text,
      this.mentioned});
}
