import 'dart:async';
import 'dart:math';

import '../domain/llm_models.dart';
import 'llm_repository.dart';
import 'sources/local/fake_llm_data_source.dart';
import 'tokenizers/llama_like_tokenizer.dart';

class FakeLlmConfig {
  const FakeLlmConfig({this.maxTokens = 256, this.tokensPerSecond = 16})
    : assert(maxTokens > 0),
      assert(tokensPerSecond > 0);

  final int maxTokens;
  final double tokensPerSecond;

  Duration get tokenDelay => Duration(
    microseconds: max(
      1,
      (Duration.microsecondsPerSecond / tokensPerSecond).round(),
    ),
  );
}

class FakeLlmRepository implements LlmRepository {
  FakeLlmRepository({
    LlamaLikeTokenizer? tokenizer,
    FakeLlmDataSource? dataSource,
    FakeLlmConfig config = const FakeLlmConfig(),
    Random? random,
  }) : _tokenizer = tokenizer ?? LlamaLikeTokenizer(),
       _dataSource = dataSource ?? AssetFakeLlmDataSource(),
       _config = config,
       _random = random ?? Random();

  final LlamaLikeTokenizer _tokenizer;
  final FakeLlmDataSource _dataSource;
  final FakeLlmConfig _config;
  final Random _random;

  @override
  Stream<LlmChunk> streamCompletion(LlmRequest request) async* {
    final random = _randomForRequest(request);
    final tokens = await _buildTokens(request, random);
    final perTokenDelay = request.tokenDelay > Duration.zero
        ? request.tokenDelay
        : _config.tokenDelay;
    final maxTokens = min(
      min(request.maxTokens, _config.maxTokens),
      tokens.length,
    );

    for (var i = 0; i < maxTokens; i++) {
      if (perTokenDelay > Duration.zero) {
        await Future<void>.delayed(perTokenDelay);
      } else {
        await Future<void>.value();
      }
      yield LlmChunk(token: tokens[i], index: i);
    }
  }

  Future<List<String>> _buildTokens(LlmRequest request, Random random) async {
    final paragraphs = await _loadParagraphs();
    final paragraph = paragraphs[random.nextInt(paragraphs.length)];

    final promptWords = request.prompt
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3)
        .toList();
    final promptSuffix = promptWords.isNotEmpty && random.nextBool()
        ? '\n\nResponding about ${promptWords[random.nextInt(promptWords.length)]}.'
        : '';

    final response =
        'Paragraph #${paragraph.id}\n${paragraph.text}$promptSuffix';

    final baseTokens = _tokenizer.encode(response);
    if (baseTokens.isEmpty) {
      throw StateError(
        'Fake LLM tokenizer produced no tokens for paragraph ${paragraph.id}.',
      );
    }

    return baseTokens.take(_config.maxTokens).toList();
  }

  Future<List<FakeLlmParagraph>> _loadParagraphs() async {
    final paragraphs = await _dataSource.loadParagraphs();
    if (paragraphs.isEmpty) {
      throw StateError(
        'Fake LLM data source returned no paragraphs. Check the bundled asset.',
      );
    }
    return paragraphs;
  }

  Random _randomForRequest(LlmRequest request) {
    final seed = request.randomSeed;
    if (seed != null) {
      return Random(seed);
    }
    return Random(_random.nextInt(0x7fffffff));
  }

  @override
  LlamaLikeTokenizer get tokenizer => _tokenizer;
}
