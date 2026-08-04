import 'package:flutter_test/flutter_test.dart';
import 'package:Kelivo/core/providers/settings_provider.dart';

void main() {
  group('DeepSeek V4 defaults', () {
    test('ships the official V4 models in speed-first order', () {
      final config = ProviderConfig.defaultsFor('DeepSeek');

      expect(config.enabled, isTrue);
      expect(config.baseUrl, 'https://api.deepseek.com/v1');
      expect(
        config.models,
        const ['deepseek-v4-flash', 'deepseek-v4-pro'],
      );
    });

    test('marks both V4 models as reasoning and tool capable', () {
      final config = ProviderConfig.defaultsFor('DeepSeek');

      for (final model in config.models) {
        final abilities = config.modelOverrides[model]?['abilities'];
        expect(abilities, containsAll(const ['tool', 'reasoning']));
      }
    });
  });
}
