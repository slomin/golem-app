import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golem_app/data/fake_llm_repository.dart';
import 'package:golem_app/data/llm_repository.dart';
import 'package:golem_app/data/sources/local/fake_llm_data_source.dart';
import 'package:golem_app/data/tokenizers/llama_like_tokenizer.dart';
import 'package:golem_app/domain/llm_models.dart';

void main() {
  group('FakeLlmRepository', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const assetPath = 'assets/mock_data/llm/fake_responses.json';
      final data = await rootBundle.loadString(assetPath);
      final byteData = ByteData.view(Uint8List.fromList(data.codeUnits).buffer);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (message) async {
            final String? key = const StringCodec().decodeMessage(message);
            if (key == assetPath) {
              return byteData;
            }
            return null;
          });
    });

    test('streams tokens respecting maxTokens', () async {
      final repo = FakeLlmRepository();
      const request = LlmRequest(
        prompt: 'Summarise quantization tricks',
        maxTokens: 12,
        temperature: 0.8,
        tokenDelay: Duration(milliseconds: 5),
      );

      final tokens = await repo
          .streamCompletion(request)
          .take(request.maxTokens)
          .toList();

      expect(tokens.length, inInclusiveRange(1, request.maxTokens));
      expect(tokens.first.index, 0);
      expect(tokens.last.index, tokens.length - 1);
    });

    test('produces reproducible output when randomSeed is supplied', () async {
      final repo = FakeLlmRepository();
      const request = LlmRequest(
        prompt: 'Explain adapters',
        maxTokens: 8,
        temperature: 0.5,
        tokenDelay: Duration(milliseconds: 1),
        randomSeed: 1337,
      );

      final streamA = await repo
          .streamCompletion(request)
          .map((c) => c.token)
          .toList();
      final streamB = await repo
          .streamCompletion(request)
          .map((c) => c.token)
          .toList();

      expect(streamA, streamB);
    });

    test('tokenizer decode reconstructs human readable text', () async {
      final repo = FakeLlmRepository();
      const request = LlmRequest(
        prompt: 'Test streaming personality',
        maxTokens: 6,
        temperature: 1.2,
        tokenDelay: Duration.zero,
      );

      final chunks = await repo.streamCompletion(request).take(6).toList();
      final decoded = repo.tokenizer.decode(chunks.map((c) => c.token));

      // Should not produce empty string or raw ▁ markers (trim to ignore leading space)
      expect(decoded.trim().isNotEmpty, isTrue);
      expect(decoded.contains('▁'), isFalse);
    });

    test('uses paragraphs provided by data source', () async {
      final paragraph = FakeLlmParagraph(
        id: 42,
        text:
            'Synthetic paragraph about deterministic output that should be emitted in full.',
      );
      final dataSource = _TestFakeDataSource([paragraph]);
      final repo = FakeLlmRepository(
        tokenizer: LlamaLikeTokenizer(),
        dataSource: dataSource,
        config: const FakeLlmConfig(maxTokens: 4096),
      );

      const request = LlmRequest(
        prompt: 'Check custom data source usage',
        maxTokens: 200,
        temperature: 0.3,
        tokenDelay: Duration.zero,
      );

      final chunks = await repo.streamCompletion(request).toList();

      expect(dataSource.loadCalls, 1);
      final decoded = repo.tokenizer.decode(chunks.map((c) => c.token)).trim();
      expect(decoded.contains('Paragraph #42'), isTrue);
      expect(decoded.contains(paragraph.text), isTrue);
    });

    test('throws when data source yields no paragraphs', () async {
      final repo = FakeLlmRepository(
        dataSource: _TestFakeDataSource(const []),
      );

      const request = LlmRequest(
        prompt: 'Expect failure when data is missing',
        maxTokens: 10,
        tokenDelay: Duration.zero,
      );

      await expectLater(
        repo.streamCompletion(request).first,
        throwsStateError,
      );
    });

    test('throws when tokenizer emits no tokens', () async {
      final paragraph = FakeLlmParagraph(
        id: 7,
        text: 'This text will be ignored by the empty tokenizer.',
      );
      final repo = FakeLlmRepository(
        tokenizer: _EmptyTokenizer(),
        dataSource: _TestFakeDataSource([paragraph]),
      );

      const request = LlmRequest(
        prompt: 'Trigger empty tokenizer guard',
        maxTokens: 5,
        tokenDelay: Duration.zero,
      );

      await expectLater(
        repo.streamCompletion(request).first,
        throwsStateError,
      );
    });
  });
}

class _TestFakeDataSource implements FakeLlmDataSource {
  _TestFakeDataSource(this._paragraphs);

  final List<FakeLlmParagraph> _paragraphs;
  int loadCalls = 0;

  @override
  Future<List<FakeLlmParagraph>> loadParagraphs() async {
    loadCalls++;
    return _paragraphs;
  }
}

class _EmptyTokenizer extends LlamaLikeTokenizer {
  @override
  List<String> encode(String text) => const [];
}
