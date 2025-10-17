import 'package:flutter_test/flutter_test.dart';
import 'package:golem_app/utils/token_rate_tracker.dart';

@Timeout(Duration(seconds: 1))
void main() {
  group('TokenRateTracker', () {
    test('returns zero snapshot when no tokens recorded', () {
      final tracker = TokenRateTracker();
      final snapshot = tracker.record(totalTokens: 0);

      expect(snapshot.totalTokens, 0);
      expect(snapshot.tokensPerSecond, 0);
      expect(snapshot.elapsed, Duration.zero);
    });

    test('computes tokens per second over elapsed duration', () {
      final tracker = TokenRateTracker();
      final start = DateTime(2024, 1, 1, 12, 0, 0);
      final mid = start.add(const Duration(milliseconds: 500));
      final end = start.add(const Duration(seconds: 2));

      tracker.record(totalTokens: 1, timestamp: start);
      final midSnapshot = tracker.record(totalTokens: 5, timestamp: mid);
      final endSnapshot = tracker.record(totalTokens: 10, timestamp: end);

      expect(midSnapshot.totalTokens, 5);
      expect(midSnapshot.elapsed, const Duration(milliseconds: 500));
      expect(midSnapshot.tokensPerSecond, closeTo(10, 0.1));

      expect(endSnapshot.totalTokens, 10);
      expect(endSnapshot.elapsed, const Duration(seconds: 2));
      expect(endSnapshot.tokensPerSecond, closeTo(5, 0.1));
    });

    test('ignores duplicate token counts without resetting state', () {
      final tracker = TokenRateTracker();
      final start = DateTime(2024, 1, 1, 12, 0, 0);
      final later = start.add(const Duration(seconds: 1));

      tracker.record(totalTokens: 5, timestamp: start);
      final snapshot = tracker.record(totalTokens: 5, timestamp: later);

      expect(snapshot.totalTokens, 5);
      expect(snapshot.tokensPerSecond, closeTo(5, 0.1));
    });

    test('reset clears tracker state', () {
      final tracker = TokenRateTracker();
      tracker.record(totalTokens: 5);
      tracker.reset();

      final snapshot = tracker.record(totalTokens: 2);

      expect(snapshot.totalTokens, 2);
      expect(snapshot.tokensPerSecond, greaterThanOrEqualTo(0));
    });
  });
}
