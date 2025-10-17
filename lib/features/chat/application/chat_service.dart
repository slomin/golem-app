import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golem_app/app/llm_providers.dart';
import 'package:golem_app/data/llm_repository.dart';
import 'package:golem_app/domain/llm_models.dart';
import 'package:golem_app/features/chat/domain/chat_models.dart';

final chatServiceProvider = Provider<ChatService>(
  (ref) => ChatService(ref: ref),
  name: 'chatService',
);

class ChatService {
  ChatService({required this.ref});

  final Ref ref;

  Future<LlmRepository> _resolveRepository(ChatMode mode) async {
    if (mode == ChatMode.apple) {
      final appleRepoAsync = ref.read(appleFoundationModelRepositoryProvider);
      final appleRepo = appleRepoAsync.maybeWhen(
        data: (repo) => repo,
        orElse: () => null,
      );
      if (appleRepo != null) {
        return appleRepo;
      }
      final resolved = await ref.read(
        appleFoundationModelRepositoryProvider.future,
      );
      if (resolved != null) {
        return resolved;
      }
    }
    return ref.read(fakeLlmRepositoryProvider);
  }

  Stream<ChatStreamChunk> streamAssistantResponse({
    required ChatMode mode,
    required String prompt,
  }) async* {
    final repository = await _resolveRepository(mode);
    final request = LlmRequest(
      prompt: prompt,
      maxTokens: 512,
      temperature: 0.8,
      tokenDelay: Duration.zero,
    );

    final tokens = <String>[];
    await for (final chunk in repository.streamCompletion(request)) {
      tokens.add(chunk.token);
      final decoded = repository.tokenizer.decode(tokens).trimLeft();
      yield ChatStreamChunk(content: decoded, totalTokens: tokens.length);
    }
  }
}

class ChatStreamChunk {
  const ChatStreamChunk({required this.content, required this.totalTokens});

  final String content;
  final int totalTokens;
}
