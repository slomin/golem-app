import 'package:flutter/material.dart';
import '../../domain/chat_models.dart';
import 'chat_message_pill.dart';

class ChatMessageList extends StatefulWidget {
  const ChatMessageList({super.key, required this.messages});

  final List<ChatMessage> messages;

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(covariant ChatMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final messagesChanged = widget.messages.length != oldWidget.messages.length;
    final lastMessageChanged =
        widget.messages.isNotEmpty &&
        oldWidget.messages.isNotEmpty &&
        widget.messages.last != oldWidget.messages.last;
    if (messagesChanged || lastMessageChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_controller.hasClients) {
          return;
        }
        final target = _controller.position.maxScrollExtent;
        _controller.animateTo(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.messages;
    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final previousAuthor = index > 0 ? messages[index - 1].author : null;
        final showSpacing =
            previousAuthor != null && previousAuthor != message.author;
        return Padding(
          padding: EdgeInsets.only(top: showSpacing ? 16 : 8),
          child: ChatMessagePill(message: message),
        );
      },
    );
  }
}
