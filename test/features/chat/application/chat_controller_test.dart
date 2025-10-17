@Timeout(Duration(seconds: 1))
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golem_app/app/llm_providers.dart';
import 'package:golem_app/features/chat/application/chat_controller.dart';
import 'package:golem_app/features/chat/application/chat_service.dart';
import 'package:golem_app/features/chat/domain/chat_models.dart';

void main() {
  group('ChatController', () {
    test('adds user message and streams assistant reply', () async {
      final container = ProviderContainer(
        overrides: [
          chatServiceProvider.overrideWith((ref) => _StubChatService(ref: ref)),
          appleFoundationModelRepositoryProvider.overrideWith(
            (ref) async => null,
          ),
        ],
      );
      addTearDown(container.dispose);

      final emitted = <AsyncValue<ChatState>>[];
      final subscription = container.listen<AsyncValue<ChatState>>(
        chatControllerProvider,
        (previous, next) => emitted.add(next),
      );
      addTearDown(subscription.close);

      final controller = container.read(chatControllerProvider.notifier);

      expect(
        container
            .read(chatControllerProvider)
            .maybeWhen(data: (state) => state.messages, orElse: () => null),
        equals(const <ChatMessage>[]),
      );

      await controller.sendPrompt('Hello there');

      final dataStates = emitted.whereType<AsyncData<ChatState>>().toList();
      expect(dataStates, isNotEmpty);

      final populated = dataStates.firstWhere((entry) {
        final chatState = entry.value;
        if (chatState == null || chatState.messages.length < 2) {
          return false;
        }
        final last = chatState.messages.last;
        return last.content.contains('Greetings friend!');
      }, orElse: () => throw TestFailure('No populated chat state emitted'));

      final messages = populated.value!.messages;
      final userMessage = messages.first;
      expect(userMessage.author, ChatAuthor.user);
      expect(userMessage.content, 'Hello there');

      final assistantMessage = messages.last;
      expect(assistantMessage.author, ChatAuthor.assistant);
      expect(assistantMessage.content, contains('Greetings friend!'));
      expect(populated.value!.mode, ChatMode.fake);
    });
  });
}

class _StubChatService extends ChatService {
  _StubChatService({required super.ref});

  @override
  @override
  Stream<ChatStreamChunk> streamAssistantResponse({
    required ChatMode mode,
    required String prompt,
  }) async* {
    yield const ChatStreamChunk(content: 'Greetings friend!', totalTokens: 3);
  }
}
