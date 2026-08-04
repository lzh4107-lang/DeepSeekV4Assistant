import 'package:flutter_test/flutter_test.dart';
import 'package:Kelivo/desktop/douyin_search_url.dart';

void main() {
  group('Douyin search URL', () {
    test('encodes Chinese queries and requests video results', () {
      final uri = buildDouyinSearchUri('AI 视频');

      expect(uri.scheme, 'https');
      expect(uri.host, 'www.douyin.com');
      expect(uri.pathSegments, const ['search', 'AI 视频']);
      expect(uri.queryParameters['type'], 'video');
    });

    test('rejects an empty query', () {
      expect(() => buildDouyinSearchUri('   '), throwsArgumentError);
    });

    test('builds a complete handoff message for chat', () {
      final text = buildDouyinConversationText(
        query: 'DeepSeek V4',
        title: '搜索结果页',
        url: 'https://www.douyin.com/search/example',
        intro: '请结合当前结果继续对话。',
        queryLabel: '搜索词：',
        currentPageLabel: '当前页面：',
        linkLabel: '链接：',
      );

      expect(text, contains('DeepSeek V4'));
      expect(text, contains('搜索结果页'));
      expect(text, contains('https://www.douyin.com/search/example'));
    });
  });
}
