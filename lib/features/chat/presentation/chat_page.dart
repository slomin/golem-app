import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golem_app/features/chat/application/chat_controller.dart';
import 'package:golem_app/features/chat/domain/chat_models.dart';
import 'widgets/chat_empty_state.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/chat_message_list.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendPrompt(String value) async {
    final controller = ref.read(chatControllerProvider.notifier);
    await controller.sendPrompt(value);
  }

  Future<void> _handleSubmit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      return;
    }
    final activeState = ref.read(chatControllerProvider).value;
    if (activeState != null && _isStreaming(activeState)) {
      return;
    }
    final pending = text;
    _textController.clear();
    await _sendPrompt(pending);
    _focusNode.requestFocus();
  }

  bool _isStreaming(ChatState state) {
    return state.messages.any((message) => message.isStreaming);
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatControllerProvider);
    final chatState =
        chatAsync.value ??
        ChatState.initial(mode: ChatMode.fake, appleModeAvailable: false);
    final isStreaming = _isStreaming(chatState);
    final controller = ref.read(chatControllerProvider.notifier);
    final hasHistory = chatState.messages.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const _StubHistoryButton(),
                  const Spacer(),
                  _ChatModeMenu(
                    mode: chatState.mode,
                    appleAvailable: chatState.appleModeAvailable,
                    hasHistory: hasHistory,
                    onSelect: controller.selectMode,
                    onReset: () {
                      controller.clearConversation();
                      _textController.clear();
                      _focusNode.unfocus();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_focusNode.hasFocus) {
                      _focusNode.unfocus();
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: chatState.messages.isEmpty
                        ? ChatEmptyState(
                            key: const ValueKey('chat-empty-state'),
                            suggestions: chatState.suggestions,
                            onSuggestionSelected: (suggestion) {
                              _textController.text = suggestion.label;
                              _handleSubmit();
                            },
                          )
                        : ChatMessageList(
                            key: const ValueKey('chat-message-list'),
                            messages: chatState.messages,
                          ),
                  ),
                ),
              ),
              if (chatAsync.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ChatErrorBanner(message: chatAsync.error.toString()),
                ),
              ChatInputBar(
                controller: _textController,
                focusNode: _focusNode,
                onSend: _handleSubmit,
                isBusy: isStreaming,
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.center,
                child: Text(
                  'AI can make mistakes. Please double-check responses.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6F6F73)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatErrorBanner extends StatelessWidget {
  const _ChatErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFD14343)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFD14343), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatModeMenu extends StatelessWidget {
  const _ChatModeMenu({
    required this.mode,
    required this.appleAvailable,
    required this.hasHistory,
    required this.onSelect,
    required this.onReset,
  });

  final ChatMode mode;
  final bool appleAvailable;
  final bool hasHistory;
  final void Function(ChatMode mode) onSelect;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_ChatMenuAction>(
      key: const ValueKey('chat-mode-menu'),
      tooltip: 'Chat options',
      offset: const Offset(0, 12),
      onSelected: (action) {
        switch (action) {
          case _ChatMenuAction.apple:
            if (appleAvailable) {
              onSelect(ChatMode.apple);
            }
            break;
          case _ChatMenuAction.fake:
            onSelect(ChatMode.fake);
            break;
          case _ChatMenuAction.reset:
            onReset();
            break;
        }
      },
      itemBuilder: (context) {
        final entries = <PopupMenuEntry<_ChatMenuAction>>[];
        entries.add(
          PopupMenuItem<_ChatMenuAction>(
            value: _ChatMenuAction.apple,
            enabled: appleAvailable,
            child: _MenuItemTile(
              title: appleAvailable
                  ? 'Apple Foundation Model (default)'
                  : 'Apple Foundation Model',
              subtitle: appleAvailable
                  ? 'Runs on-device with Apple Intelligence'
                  : 'Requires Apple Intelligence–capable device',
              selected: mode == ChatMode.apple,
            ),
          ),
        );
        entries.add(
          PopupMenuItem<_ChatMenuAction>(
            value: _ChatMenuAction.fake,
            child: _MenuItemTile(
              title: 'Local Fake LLM',
              subtitle: appleAvailable
                  ? 'Switch to deterministic demo'
                  : 'Deterministic demo responses',
              selected: mode == ChatMode.fake,
            ),
          ),
        );
        entries.add(const PopupMenuDivider());
        entries.add(
          PopupMenuItem<_ChatMenuAction>(
            value: _ChatMenuAction.reset,
            enabled: hasHistory,
            child: const _MenuItemTile(
              title: 'Reset chat',
              subtitle: 'Clear conversation history',
              selected: false,
            ),
          ),
        );
        return entries;
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: const Icon(Icons.more_horiz, color: Color(0xFF1C1C1E)),
      ),
    );
  }
}

enum _ChatMenuAction { apple, fake, reset }

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6F6F73),
                ),
              ),
            ],
          ),
        ),
        if (selected) const Icon(Icons.check, color: Color(0xFF1C1C1E)),
      ],
    );
  }
}

class _StubHistoryButton extends StatelessWidget {
  const _StubHistoryButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.view_day_outlined, color: Color(0xFF1C1C1E)),
    );
  }
}
