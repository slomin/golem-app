import 'dart:math';

/// Snapshot of the current token streaming statistics.
class TokenRateSnapshot {
  const TokenRateSnapshot({
    required this.totalTokens,
    required this.elapsed,
    required this.tokensPerSecond,
  });

  final int totalTokens;
  final Duration elapsed;
  final double tokensPerSecond;
}

/// Tracks running token throughput for streaming LLM responses.
///
/// Call [record] each time the cumulative token count increases. The tracker
/// computes a rolling tokens-per-second rate based on wall-clock time between
/// the first and latest chunks.
class TokenRateTracker {
  DateTime? _firstTokenAt;
  DateTime? _lastTokenAt;
  int _recordedTokens = 0;

  /// Resets the tracker to its initial state.
  void reset() {
    _firstTokenAt = null;
    _lastTokenAt = null;
    _recordedTokens = 0;
  }

  /// Records the latest cumulative token count and returns updated metrics.
  ///
  /// The [totalTokens] parameter should represent the number of chunks received
  /// so far in the stream. The optional [timestamp] allows callers to supply a
  /// consistent clock source (defaults to [DateTime.now]).
  TokenRateSnapshot record({required int totalTokens, DateTime? timestamp}) {
    final now = timestamp ?? DateTime.now();

    if (totalTokens <= 0) {
      return const TokenRateSnapshot(
        totalTokens: 0,
        elapsed: Duration.zero,
        tokensPerSecond: 0,
      );
    }

    final int newTokens = max(0, totalTokens - _recordedTokens);
    if (_firstTokenAt == null && newTokens > 0) {
      _firstTokenAt = now;
    }
    if (newTokens > 0) {
      _recordedTokens = totalTokens;
      _lastTokenAt = now;
    }

    if (_firstTokenAt == null) {
      return const TokenRateSnapshot(
        totalTokens: 0,
        elapsed: Duration.zero,
        tokensPerSecond: 0,
      );
    }

    final Duration elapsed = now.difference(_firstTokenAt!);
    final bool hasElapsed = elapsed.inMicroseconds > 0;
    final double tokensPerSecond = hasElapsed
        ? totalTokens / (elapsed.inMicroseconds / 1e6)
        : 0;

    return TokenRateSnapshot(
      totalTokens: totalTokens,
      elapsed: elapsed.isNegative ? Duration.zero : elapsed,
      tokensPerSecond: tokensPerSecond.isFinite ? tokensPerSecond : 0,
    );
  }
}
