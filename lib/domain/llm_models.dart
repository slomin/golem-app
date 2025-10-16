class LlmChunk {
  final String token;
  final int index;

  const LlmChunk({
    required this.token,
    required this.index,
  });
}

class LlmRequest {
  final String prompt;
  final int maxTokens;
  final double temperature;
  final Duration tokenDelay;
  final int? randomSeed;

  const LlmRequest({
    required this.prompt,
    this.maxTokens = 200,
    this.temperature = 0.7,
    this.tokenDelay = const Duration(milliseconds: 24),
    this.randomSeed,
  });
}
