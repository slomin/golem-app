import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golem_app/app/llm_providers.dart';
import 'package:golem_app/data/llm_repository.dart';
import 'package:golem_app/features/chat/application/chat_service.dart';
import 'package:golem_app/features/chat/domain/chat_models.dart';
import 'package:golem_app/utils/token_rate_tracker.dart';

final chatControllerProvider =
    AsyncNotifierProvider.autoDispose<ChatController, ChatState>(
      ChatController.new,
      name: 'chatController',
    );

class ChatController extends AsyncNotifier<ChatState> {
  final TokenRateTracker _tracker = TokenRateTracker();
  bool _autoSwitchedToApple = false;
  bool _userDisabledApple = false;

  @override
  FutureOr<ChatState> build() {
    ref.listen<AsyncValue<LlmRepository?>>(
      appleFoundationModelRepositoryProvider,
      (previous, next) {
        final available = next.maybeWhen(
          data: (repo) => repo != null,
          orElse: () => false,
        );
        _handleAppleAvailabilityChange(available);
      },
    );

    ref.listen<bool>(
      useAppleFoundationModelPreferenceProvider,
      (previous, next) => _handlePreferenceChange(next),
    );

    final appleRepoAsync = ref.watch(appleFoundationModelRepositoryProvider);
    final appleAvailable = appleRepoAsync.maybeWhen(
      data: (repo) => repo != null,
      orElse: () => false,
    );
    final prefersApple = ref.watch(useAppleFoundationModelPreferenceProvider);

    if (!appleAvailable) {
      _autoSwitchedToApple = false;
    } else if (!_autoSwitchedToApple && !_userDisabledApple && !prefersApple) {
      _autoSwitchedToApple = true;
      Future.microtask(() {
        if (ref.mounted) {
          ref
              .read(useAppleFoundationModelPreferenceProvider.notifier)
              .set(true);
        }
      });
    }

    final useApple =
        appleAvailable &&
        (prefersApple || (_autoSwitchedToApple && !_userDisabledApple));
    final initialMode = useApple ? ChatMode.apple : ChatMode.fake;

    return ChatState.initial(
      mode: initialMode,
      appleModeAvailable: appleAvailable,
    );
  }

  Future<void> sendPrompt(String rawInput) async {
    final prompt = rawInput.trim();
    if (prompt.isEmpty) {
      return;
    }

    final currentState =
        state.value ??
        ChatState.initial(mode: ChatMode.fake, appleModeAvailable: false);
    _tracker.reset();
    final userMessage = ChatMessage(author: ChatAuthor.user, content: prompt);
    final assistantPlaceholder = const ChatMessage(
      author: ChatAuthor.assistant,
      content: '',
      isStreaming: true,
    );

    var workingState = currentState.addMessages(<ChatMessage>[
      userMessage,
      assistantPlaceholder,
    ]);
    state = AsyncValue.data(workingState);

    final service = ref.read(chatServiceProvider);
    final stream = service.streamAssistantResponse(
      mode: currentState.mode,
      prompt: prompt,
    );

    try {
      await for (final chunk in stream) {
        final snapshot = _tracker.record(totalTokens: chunk.totalTokens);
        workingState = workingState.updateLatestAssistant(
          content: chunk.content,
          isStreaming: true,
          tokenCount: chunk.totalTokens,
          tokensPerSecond: snapshot.tokensPerSecond,
        );
        state = AsyncValue.data(workingState);
      }

      if (workingState.messages.isNotEmpty) {
        workingState = workingState.updateLatestAssistant(
          content: workingState.messages.last.content,
          isStreaming: false,
          tokenCount: workingState.messages.last.tokenCount,
          tokensPerSecond: workingState.messages.last.tokensPerSecond,
        );
        state = AsyncValue.data(workingState);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void selectMode(ChatMode mode) {
    final current = state.value;
    if (current == null) {
      ref
          .read(useAppleFoundationModelPreferenceProvider.notifier)
          .set(mode == ChatMode.apple);
      return;
    }
    if (mode == ChatMode.apple && !current.appleModeAvailable) {
      return;
    }
    if (mode == current.mode) {
      return;
    }

    state = AsyncValue.data(
      ChatState.initial(
        mode: mode,
        appleModeAvailable: current.appleModeAvailable,
      ),
    );
    if (mode == ChatMode.fake) {
      _userDisabledApple = true;
      _autoSwitchedToApple = false;
    } else {
      _userDisabledApple = false;
      _autoSwitchedToApple = false;
    }
    ref
        .read(useAppleFoundationModelPreferenceProvider.notifier)
        .set(mode == ChatMode.apple);
  }

  void clearConversation() {
    final current = state.value;
    final mode = current?.mode ?? ChatMode.fake;
    final appleAvailable = current?.appleModeAvailable ?? false;
    _tracker.reset();
    state = AsyncValue.data(
      ChatState.initial(mode: mode, appleModeAvailable: appleAvailable),
    );
  }

  void _handleAppleAvailabilityChange(bool available) {
    final current = state.value;
    if (current == null) {
      state = AsyncValue.data(
        ChatState.initial(mode: ChatMode.fake, appleModeAvailable: available),
      );
      return;
    }

    final shouldDowngrade = current.mode == ChatMode.apple && !available;
    final nextMode = shouldDowngrade ? ChatMode.fake : current.mode;
    final updatedState = shouldDowngrade
        ? ChatState.initial(mode: nextMode, appleModeAvailable: available)
        : current.copyWith(appleModeAvailable: available);

    if (shouldDowngrade) {
      ref.read(useAppleFoundationModelPreferenceProvider.notifier).set(false);
      _autoSwitchedToApple = false;
    }

    state = AsyncValue.data(updatedState);
  }

  void _handlePreferenceChange(bool prefersApple) {
    final current = state.value;
    if (current == null) {
      return;
    }
    final desiredMode = prefersApple && current.appleModeAvailable
        ? ChatMode.apple
        : ChatMode.fake;
    if (desiredMode == current.mode) {
      if (!prefersApple) {
        _autoSwitchedToApple = false;
        _userDisabledApple = true;
      }
      return;
    }
    if (!prefersApple) {
      _autoSwitchedToApple = false;
      _userDisabledApple = true;
    } else {
      _userDisabledApple = false;
    }
    state = AsyncValue.data(
      ChatState.initial(
        mode: desiredMode,
        appleModeAvailable: current.appleModeAvailable,
      ),
    );
  }
}
