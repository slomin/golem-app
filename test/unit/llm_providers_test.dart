import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golem_app/app/llm_providers.dart';
import 'package:golem_app/data/fake_llm_repository.dart';
import 'package:golem_app/data/sources/local/fake_llm_data_source.dart';
import 'package:golem_app/data/tokenizers/llama_like_tokenizer.dart';
import 'package:golem_app/domain/llm_models.dart';

void main() {
  group('llmCompletionProvider', () {
    test('streams chunk buffers up to max tokens', () async {
      final container = ProviderContainer(
        overrides: [
          llmRepositoryProvider.overrideWithValue(
            FakeLlmRepository(
              tokenizer: LlamaLikeTokenizer(),
              dataSource: _StubDataSource([
                FakeLlmParagraph(
                  id: 1,
                  text: 'First stub paragraph for provider test.',
                ),
                FakeLlmParagraph(
                  id: 2,
                  text: 'Second stub entry for streaming.',
                ),
              ]),
              config: const FakeLlmConfig(maxTokens: 1024, tokensPerSecond: 64),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      const request = LlmRequest(
        prompt: 'Test provider stream',
        maxTokens: 4,
        temperature: 0.6,
        tokenDelay: Duration.zero,
      );

      final completer = Completer<List<LlmChunk>>();
      final sub = container.listen<AsyncValue<List<LlmChunk>>>(
        llmCompletionProvider(request),
        (prev, next) {
          next.when(
            data: (chunks) {
              if (!completer.isCompleted && chunks.isNotEmpty) {
                completer.complete(chunks);
              }
            },
            loading: () {},
            error: (error, stack) {
              if (!completer.isCompleted) {
                completer.completeError(error, stack);
              }
            },
          );
        },
        fireImmediately: true,
      );

      addTearDown(sub.close);

      final chunks = await completer.future.timeout(const Duration(seconds: 2));
      expect(chunks, isNotEmpty);
    });
  });
}

class _StubDataSource implements FakeLlmDataSource {
  _StubDataSource(this._paragraphs);

  final List<FakeLlmParagraph> _paragraphs;

  @override
  Future<List<FakeLlmParagraph>> loadParagraphs() async => _paragraphs;
}
