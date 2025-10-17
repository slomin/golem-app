enum ChatAuthor { user, assistant }

enum ChatMode { fake, apple }

class ChatMessage {
  const ChatMessage({
    required this.author,
    required this.content,
    this.isStreaming = false,
    this.tokenCount = 0,
    this.tokensPerSecond,
  });

  final ChatAuthor author;
  final String content;
  final bool isStreaming;
  final int tokenCount;
  final double? tokensPerSecond;

  ChatMessage copyWith({
    ChatAuthor? author,
    String? content,
    bool? isStreaming,
    int? tokenCount,
    double? tokensPerSecond,
  }) {
    return ChatMessage(
      author: author ?? this.author,
      content: content ?? this.content,
      isStreaming: isStreaming ?? this.isStreaming,
      tokenCount: tokenCount ?? this.tokenCount,
      tokensPerSecond: tokensPerSecond ?? this.tokensPerSecond,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        other.author == author &&
        other.content == content &&
        other.isStreaming == isStreaming &&
        other.tokenCount == tokenCount &&
        other.tokensPerSecond == tokensPerSecond;
  }

  @override
  int get hashCode =>
      Object.hash(author, content, isStreaming, tokenCount, tokensPerSecond);
}

class ChatSuggestion {
  const ChatSuggestion({required this.label});

  final String label;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatSuggestion && other.label == label;
  }

  @override
  int get hashCode => label.hashCode;
}

class ChatState {
  const ChatState({
    required this.messages,
    required this.suggestions,
    required this.mode,
    required this.appleModeAvailable,
  });

  final List<ChatMessage> messages;
  final List<ChatSuggestion> suggestions;
  final ChatMode mode;
  final bool appleModeAvailable;

  factory ChatState.initial({
    ChatMode mode = ChatMode.fake,
    bool appleModeAvailable = false,
  }) => ChatState(
    messages: const <ChatMessage>[],
    suggestions: const <ChatSuggestion>[
      ChatSuggestion(label: 'Summarize recent updates'),
      ChatSuggestion(label: 'Generate release notes'),
      ChatSuggestion(label: 'Brainstorm new ideas'),
    ],
    mode: mode,
    appleModeAvailable: appleModeAvailable,
  );

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<ChatSuggestion>? suggestions,
    ChatMode? mode,
    bool? appleModeAvailable,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      suggestions: suggestions ?? this.suggestions,
      mode: mode ?? this.mode,
      appleModeAvailable: appleModeAvailable ?? this.appleModeAvailable,
    );
  }

  ChatState addMessages(List<ChatMessage> newMessages) {
    return copyWith(
      messages: List<ChatMessage>.unmodifiable(
        List<ChatMessage>.from(messages)..addAll(newMessages),
      ),
    );
  }

  ChatState updateLatestAssistant({
    required String content,
    required bool isStreaming,
    int? tokenCount,
    double? tokensPerSecond,
  }) {
    final index = messages.lastIndexWhere(
      (message) => message.author == ChatAuthor.assistant,
    );
    if (index == -1) {
      return this;
    }
    final updated = List<ChatMessage>.from(messages);
    updated[index] = updated[index].copyWith(
      content: content,
      isStreaming: isStreaming,
      tokenCount: tokenCount,
      tokensPerSecond: tokensPerSecond,
    );
    return copyWith(messages: List<ChatMessage>.unmodifiable(updated));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatState &&
        _listEquals(other.messages, messages) &&
        _listEquals(other.suggestions, suggestions) &&
        other.mode == mode &&
        other.appleModeAvailable == appleModeAvailable;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(messages),
    Object.hashAll(suggestions),
    mode,
    appleModeAvailable,
  );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
