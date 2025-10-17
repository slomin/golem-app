import 'dart:async';

import 'package:apple_foundation_flutter/apple_foundation_flutter.dart';

import '../domain/llm_models.dart';
import 'llm_repository.dart';
import 'tokenizers/llama_like_tokenizer.dart';

/// Repository that proxies text generation requests to the
/// `apple_foundation_flutter` package.
class AppleFoundationFlutterRepository implements LlmRepository {
  AppleFoundationFlutterRepository({
    AppleFoundationFlutter? client,
    LlamaLikeTokenizer? tokenizer,
  }) : _client = client ?? AppleFoundationFlutter(),
       _tokenizer = tokenizer ?? LlamaLikeTokenizer();

  final AppleFoundationFlutter _client;
  final LlamaLikeTokenizer _tokenizer;

  @override
  Stream<LlmChunk> streamCompletion(LlmRequest request) {
    final controller = StreamController<LlmChunk>();
    int index = 0;
    String accumulated = '';

    final subscription = _client
        .generateTextStream(request.prompt)
        .listen(
          (partial) {
            if (partial.isEmpty) {
              return;
            }

            if (partial.length < accumulated.length) {
              accumulated = partial;
              index = _tokenizer.encode(accumulated).length;
              return;
            }

            final newText = partial.substring(accumulated.length);
            if (newText.isEmpty) {
              return;
            }
            accumulated = partial;

            final tokens = _tokenizer.encode(newText);
            for (final token in tokens) {
              controller.add(LlmChunk(token: token, index: index++));
            }
          },
          onError: controller.addError,
          onDone: () {
            if (!controller.isClosed) {
              controller.close();
            }
          },
        );

    controller.onCancel = () async {
      await subscription.cancel();
      if (!controller.isClosed) {
        await controller.close();
      }
    };

    return controller.stream;
  }

  @override
  LlamaLikeTokenizer get tokenizer => _tokenizer;
}
