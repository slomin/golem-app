import 'package:flutter_test/flutter_test.dart';
import 'package:golem_app/data/tokenizers/llama_like_tokenizer.dart';

@Timeout(Duration(seconds: 1))
void main() {
  group('LlamaLikeTokenizer', () {
    test('encodes words with ▁ on word boundaries', () {
      final tokenizer = LlamaLikeTokenizer();

      expect(tokenizer.encode('Hello world'), ['Hello', '▁world']);
      expect(tokenizer.encode('  multiple   spaces'), ['▁multiple', '▁spaces']);
    });

    test('encodes punctuation as standalone tokens', () {
      final tokenizer = LlamaLikeTokenizer();

      expect(tokenizer.encode('Hi, world!'), ['Hi', ',', '▁world', '!']);
    });

    test('round trips through decode', () {
      final tokenizer = LlamaLikeTokenizer();
      const sentence = 'Model streaming feels real.';

      final tokens = tokenizer.encode(sentence);
      final decoded = tokenizer.decode(tokens);

      expect(decoded.trim(), sentence);
    });
  });
}
