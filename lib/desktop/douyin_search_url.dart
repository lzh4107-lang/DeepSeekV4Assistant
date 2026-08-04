Uri buildDouyinSearchUri(String query) {
  final normalized = query.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(query, 'query', 'Search query cannot be empty');
  }
  return Uri(
    scheme: 'https',
    host: 'www.douyin.com',
    pathSegments: ['search', normalized],
    queryParameters: const {'type': 'video'},
  );
}

String buildDouyinConversationText({
  required String query,
  required String url,
  required String intro,
  required String queryLabel,
  required String currentPageLabel,
  required String linkLabel,
  String? title,
}) {
  final normalizedTitle = title?.trim();
  final lines = <String>[
    intro,
    if (query.trim().isNotEmpty) '$queryLabel ${query.trim()}',
    if (normalizedTitle != null && normalizedTitle.isNotEmpty)
      '$currentPageLabel $normalizedTitle',
    '$linkLabel $url',
  ];
  return lines.join('\n');
}
