import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fake_llm_repository.dart';
import '../data/llm_repository.dart';
import '../domain/llm_models.dart';

final llmRepositoryProvider = Provider<LlmRepository>(
  (ref) => FakeLlmRepository(
    config: const FakeLlmConfig(
      maxTokens: 2048,
      tokensPerSecond: 16,
    ),
  ),
  name: 'llmRepository',
);

class CurrentLlmRequestNotifier extends Notifier<LlmRequest?> {
  @override
  LlmRequest? build() => null;

  void setRequest(LlmRequest request) {
    state = request;
  }

  void clear() {
    state = null;
  }
}

final currentLlmRequestProvider =
    NotifierProvider<CurrentLlmRequestNotifier, LlmRequest?>(
  CurrentLlmRequestNotifier.new,
  name: 'currentLlmRequest',
);

final llmCompletionProvider =
    StreamProvider.family.autoDispose<List<LlmChunk>, LlmRequest>((ref, request) {
  final repo = ref.watch(llmRepositoryProvider);
  final controller = StreamController<List<LlmChunk>>();
  final buffer = <LlmChunk>[];

  final subscription = repo.streamCompletion(request).listen(
    (chunk) {
      buffer.add(chunk);
      controller.add(List.unmodifiable(buffer));
    },
    onError: controller.addError,
    onDone: () {
      if (!controller.isClosed) {
        controller.close();
      }
    },
  );

  ref.onDispose(() async {
    await subscription.cancel();
    if (!controller.isClosed) {
      await controller.close();
    }
  });

  return controller.stream;
});
