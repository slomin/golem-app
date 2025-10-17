import 'package:flutter/material.dart';
import '../../domain/chat_models.dart';

class ChatMessagePill extends StatelessWidget {
  const ChatMessagePill({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.author == ChatAuthor.user;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final backgroundColor = isUser
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFE9E4DE);
    final textColor = isUser ? Colors.white : const Color(0xFF1C1C1E);

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
                ),
                if (!isUser && message.tokenCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _formatTokenStats(
                        message.tokenCount,
                        message.tokensPerSecond,
                      ),
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (message.isStreaming) ...[
                  const SizedBox(height: 12),
                  _TypingIndicator(
                    isDarkBackground: isUser,
                    color: isUser ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.isDarkBackground, required this.color});

  final bool isDarkBackground;
  final Color color;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final value = _controller.value;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(3, (index) {
              final opacity = (value + index / 3) % 1;
              return Opacity(
                opacity: 0.3 + 0.7 * (1 - opacity),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: CircleAvatar(radius: 3, backgroundColor: widget.color),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

String _formatTokenStats(int tokens, double? tokensPerSecond) {
  final countLabel = '$tokens token${tokens == 1 ? '' : 's'}';
  if (tokensPerSecond == null || tokensPerSecond <= 0) {
    return countLabel;
  }
  return '$countLabel • ${tokensPerSecond.toStringAsFixed(1)} t/s';
}
