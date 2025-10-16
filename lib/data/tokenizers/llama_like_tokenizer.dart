class LlamaLikeTokenizer {
  static const String spaceMark = '▁';
  static const String _punctChars = r'''.,!?;:()[]{}"'`~@#%^&*+-=/\<>|''';

  List<String> encode(String text) {
    final tokens = <String>[];
    var index = 0;
    var atWordStart = false;

    while (index < text.length) {
      final char = text[index];

      if (_isWhitespace(char)) {
        atWordStart = true;
        index++;
        continue;
      }

      if (_isPunctuation(char)) {
        tokens.add((atWordStart ? spaceMark : '') + char);
        atWordStart = false;
        index++;
        continue;
      }

      final buffer = StringBuffer();
      while (index < text.length) {
        final c = text[index];
        if (_isWhitespace(c) || _isPunctuation(c)) {
          break;
        }
        buffer.write(c);
        index++;
      }

      tokens.add((atWordStart ? spaceMark : '') + buffer.toString());
      atWordStart = false;
    }

    return tokens;
  }

  String decode(Iterable<String> tokens) {
    final buffer = StringBuffer();
    for (final token in tokens) {
      if (token.startsWith(spaceMark)) {
        buffer.write(' ');
        buffer.write(token.substring(1));
      } else {
        buffer.write(token);
      }
    }
    return buffer.toString();
  }

  bool _isWhitespace(String char) => char.trim().isEmpty;

  bool _isPunctuation(String char) => _punctChars.contains(char);
}
