class Resource {
  final String title;
  final String content;
  final Set<String> tags;

  Resource({
    this.title = '',
    required this.content,
    this.tags = const {},
  });
}
