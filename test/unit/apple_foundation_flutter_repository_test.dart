import 'dart:async';

import 'package:apple_foundation_flutter/apple_foundation_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golem_app/data/apple_foundation_flutter_repository.dart';
import 'package:golem_app/data/tokenizers/llama_like_tokenizer.dart';
import 'package:golem_app/domain/llm_models.dart';

void main() {
  group('AppleFoundationFlutterRepository', () {
    test('emits incremental chunks from the underlying stream', () async {
      final fakeClient = _FakeAppleFoundationFlutter(
        events: const ['Hello', 'Hello world', 'Hello world!'],
      );
      final repository = AppleFoundationFlutterRepository(
        client: fakeClient,
        tokenizer: LlamaLikeTokenizer(),
      );

      const request = LlmRequest(
        prompt: 'Say hello',
        maxTokens: 32,
        temperature: 0.5,
        tokenDelay: Duration.zero,
      );

      final chunks = await repository.streamCompletion(request).toList();

      expect(chunks.map((c) => c.token), ['Hello', '▁world', '!']);
      expect(chunks.last.index, 2);
    });

    test('forwards stream errors', () async {
      final repository = AppleFoundationFlutterRepository(
        client: _FakeAppleFoundationFlutter(error: StateError('boom')),
        tokenizer: LlamaLikeTokenizer(),
      );

      const request = LlmRequest(
        prompt: 'This should fail',
        maxTokens: 4,
        temperature: 0.5,
        tokenDelay: Duration.zero,
      );

      await expectLater(
        repository.streamCompletion(request).first,
        throwsStateError,
      );
    });
  });
}

class _FakeAppleFoundationFlutter extends AppleFoundationFlutter {
  _FakeAppleFoundationFlutter({this.events = const [], this.error});

  final List<String> events;
  final Object? error;

  @override
  Stream<String> generateTextStream(
    String prompt, {
    String? sessionId,
    int? maxTokens,
    double? temperature,
    double? topP,
  }) {
    if (error != null) {
      return Stream<String>.error(error!);
    }
    return Stream<String>.fromIterable(events);
  }
}
