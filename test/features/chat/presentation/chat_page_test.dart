import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golem_app/app/llm_providers.dart';
import 'package:golem_app/data/fake_llm_repository.dart';
import 'package:golem_app/data/llm_repository.dart';
import 'package:golem_app/data/sources/local/fake_llm_data_source.dart';
import 'package:golem_app/data/tokenizers/llama_like_tokenizer.dart';
import 'package:golem_app/domain/llm_models.dart';
import 'package:golem_app/features/chat/application/chat_controller.dart';
import 'package:golem_app/features/chat/application/chat_service.dart';
import 'package:golem_app/features/chat/domain/chat_models.dart';
import 'package:golem_app/features/chat/presentation/chat_page.dart';
import 'package:golem_app/main.dart';

@Timeout(Duration(seconds: 1))
void main() {
  testWidgets(
    'renders hero, suggestions, and streams fake response with Apple unavailable',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fakeLlmRepositoryProvider.overrideWithValue(
              FakeLlmRepository(
                tokenizer: LlamaLikeTokenizer(),
                dataSource: _StubDataSource(const [
                  FakeLlmParagraph(id: 1, text: 'Greetings friend!'),
                ]),
                config: const FakeLlmConfig(
                  maxTokens: 32,
                  tokensPerSecond: 256,
                ),
              ),
            ),
            chatServiceProvider.overrideWith((ref) => ChatService(ref: ref)),
            appleFoundationModelRepositoryProvider.overrideWith(
              (ref) async => null,
            ),
          ],
          child: const MyApp(),
        ),
      );

      expect(find.text('What can I help with today?'), findsOneWidget);
      expect(find.text('Summarize recent updates'), findsOneWidget);
      expect(find.text('Generate release notes'), findsOneWidget);
      expect(find.text('Brainstorm new ideas'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('chat-mode-menu')));
      await tester.pumpAndSettle();
      expect(
        find.text('Requires Apple Intelligence–capable device'),
        findsOneWidget,
      );
      await tester.tap(find.text('Local Fake LLM'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('chat-input-field')),
        'Hello there',
      );
      await tester.testTextInput.receiveAction(TextInputAction.send);

      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 30));
        if (find.byType(SelectableText).evaluate().isNotEmpty) {
          break;
        }
      }

      expect(find.text('Hello there'), findsOneWidget);
      final element = tester.element(find.byType(ChatPage));
      final container = ProviderScope.containerOf(element, listen: false);
      ChatState? state;
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 30));
        final current = container.read(chatControllerProvider).value;
        if (current != null && current.messages.length >= 2) {
          state = current;
          break;
        }
      }
      expect(state, isNotNull);
      expect(state!.messages.length, 2);
      expect(state.messages.last.content, contains('Greetings friend!'));
      expect(state.mode, ChatMode.fake);
    },
  );

  testWidgets('allows switching to Apple mode when available', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fakeLlmRepositoryProvider.overrideWithValue(
            FakeLlmRepository(
              tokenizer: LlamaLikeTokenizer(),
              dataSource: _StubDataSource(const [
                FakeLlmParagraph(id: 1, text: 'Greetings friend!'),
              ]),
              config: const FakeLlmConfig(maxTokens: 32, tokensPerSecond: 256),
            ),
          ),
          chatServiceProvider.overrideWith((ref) => ChatService(ref: ref)),
          appleFoundationModelRepositoryProvider.overrideWith(
            (ref) async => _StubAppleRepository(),
          ),
        ],
        child: const MyApp(),
      ),
    );
    final element = tester.element(find.byType(ChatPage));
    final container = ProviderScope.containerOf(element, listen: false);

    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      final current = container.read(chatControllerProvider).value;
      if (current != null && current.appleModeAvailable) {
        break;
      }
    }

    final availability = container.read(chatControllerProvider).value;
    expect(availability?.appleModeAvailable, isTrue);

    await tester.tap(find.byKey(const ValueKey('chat-mode-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Apple Foundation Model'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      final current = container.read(chatControllerProvider).value;
      if (current != null && current.mode == ChatMode.apple) {
        break;
      }
    }

    await tester.enterText(
      find.byKey(const ValueKey('chat-input-field')),
      'Hello there',
    );
    await tester.testTextInput.receiveAction(TextInputAction.send);

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      if (find.byType(SelectableText).evaluate().isNotEmpty) {
        break;
      }
    }

    ChatState? state;
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      final current = container.read(chatControllerProvider).value;
      if (current != null && current.messages.length >= 2) {
        state = current;
        break;
      }
    }

    expect(state, isNotNull);
    expect(state!.mode, ChatMode.apple);
    expect(state.messages.length, 2);
    expect(state.messages.last.content, contains('Hello from Apple FM'));
  });

  testWidgets('respects fake mode selection when Apple is available', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fakeLlmRepositoryProvider.overrideWithValue(
            FakeLlmRepository(
              tokenizer: LlamaLikeTokenizer(),
              dataSource: _StubDataSource(const [
                FakeLlmParagraph(id: 1, text: 'Greetings friend!'),
              ]),
              config: const FakeLlmConfig(maxTokens: 32, tokensPerSecond: 256),
            ),
          ),
          chatServiceProvider.overrideWith((ref) => ChatService(ref: ref)),
          appleFoundationModelRepositoryProvider.overrideWith(
            (ref) async => _StubAppleRepository(),
          ),
        ],
        child: const MyApp(),
      ),
    );

    final element = tester.element(find.byType(ChatPage));
    final container = ProviderScope.containerOf(element, listen: false);

    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      final current = container.read(chatControllerProvider).value;
      if (current != null && current.mode == ChatMode.apple) {
        break;
      }
    }

    await tester.tap(find.byKey(const ValueKey('chat-mode-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Local Fake LLM'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 30));
    }

    final state = container.read(chatControllerProvider).value;
    expect(state?.mode, ChatMode.fake);
  });

  testWidgets('reset chat clears history', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fakeLlmRepositoryProvider.overrideWithValue(
            FakeLlmRepository(
              tokenizer: LlamaLikeTokenizer(),
              dataSource: _StubDataSource(const [
                FakeLlmParagraph(id: 1, text: 'Greetings friend!'),
              ]),
              config: const FakeLlmConfig(maxTokens: 32, tokensPerSecond: 256),
            ),
          ),
          chatServiceProvider.overrideWith((ref) => ChatService(ref: ref)),
          appleFoundationModelRepositoryProvider.overrideWith(
            (ref) async => null,
          ),
        ],
        child: const MyApp(),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('chat-input-field')),
      'Test reset',
    );
    await tester.testTextInput.receiveAction(TextInputAction.send);

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 30));
      if (find.byType(SelectableText).evaluate().isNotEmpty) {
        break;
      }
    }

    await tester.tap(find.byKey(const ValueKey('chat-mode-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset chat'));
    await tester.pumpAndSettle();

    expect(find.text('What can I help with today?'), findsOneWidget);
    final element = tester.element(find.byType(ChatPage));
    final container = ProviderScope.containerOf(element, listen: false);
    final state = container.read(chatControllerProvider).value;
    expect(state?.messages, isEmpty);
  });
}

class _StubDataSource implements FakeLlmDataSource {
  const _StubDataSource(this._paragraphs);

  final List<FakeLlmParagraph> _paragraphs;

  @override
  Future<List<FakeLlmParagraph>> loadParagraphs() async => _paragraphs;
}

class _StubAppleRepository implements LlmRepository {
  _StubAppleRepository();

  final LlamaLikeTokenizer _tokenizer = LlamaLikeTokenizer();

  @override
  Stream<LlmChunk> streamCompletion(LlmRequest request) async* {
    const tokens = ['Hello', '▁from', '▁Apple', '▁FM'];
    for (var i = 0; i < tokens.length; i++) {
      yield LlmChunk(token: tokens[i], index: i);
    }
  }

  @override
  LlamaLikeTokenizer get tokenizer => _tokenizer;
}
