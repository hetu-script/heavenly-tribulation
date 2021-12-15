class HistoryFeed {
  final String entityId;
  final int timestamp;
  final String text;

  final List<String>? mentioned;

  HistoryFeed(
      {required this.entityId,
      required this.timestamp,
      required this.text,
      this.mentioned});
}
