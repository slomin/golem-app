import 'package:apple_foundation_flutter/apple_foundation_flutter.dart';
import 'package:apple_foundation_flutter/enums/styles.dart';

class AppleIntelligenceSession {
  static final AppleFoundationFlutter _foundation = AppleFoundationFlutter();

  final String _sessionId;

  bool _isActive = true;

  static Future<AppleIntelligenceSession> create(String instructions) async {
    final sessionId = await _foundation.openSession(instructions);
    return AppleIntelligenceSession._(sessionId);
  }

  AppleIntelligenceSession._(this._sessionId);

  Future<void> close() async {
    if (!_isActive) return;
    await _foundation.closeSession(_sessionId);
    _isActive = false;
  }

  bool get isActive => _isActive;

  String get sessionId => _sessionId;

  Future<String?> ask(String prompt) {
    _checkActive();
    return _foundation.ask(prompt, sessionId: _sessionId);
  }

  Future<Map<String, dynamic>> getStructuredData(String prompt) {
    _checkActive();
    return _foundation.getStructuredData(prompt, sessionId: _sessionId);
  }

  Future<List<String>> getListOfString(String prompt) {
    _checkActive();
    return _foundation.getListOfString(prompt, sessionId: _sessionId);
  }

  Future<String?> generateText(String prompt) {
    _checkActive();
    return _foundation.generateText(prompt, sessionId: _sessionId);
  }

  Future<List<String>> generateAlternatives(String prompt, {int count = 3}) {
    _checkActive();
    return _foundation.generateAlternatives(
      prompt,
      sessionId: _sessionId,
      count: count,
    );
  }

  Future<String?> summarizeText(
    String text, {
    SummarizationStyle style = SummarizationStyle.concise,
  }) {
    _checkActive();
    return _foundation.summarizeText(text, sessionId: _sessionId, style: style);
  }

  Future<Map<String, dynamic>> extractInformation(
    String text, {
    List<String>? fields,
  }) {
    _checkActive();
    return _foundation.extractInformation(
      text,
      sessionId: _sessionId,
      fields: fields,
    );
  }

  Future<Map<String, double>> classifyText(
    String text, {
    List<String>? categories,
  }) {
    _checkActive();
    return _foundation.classifyText(
      text,
      sessionId: _sessionId,
      categories: categories,
    );
  }

  Future<List<String>> generateSuggestions(
    String context, {
    int maxSuggestions = 5,
  }) {
    _checkActive();
    return _foundation.generateSuggestions(
      context,
      sessionId: _sessionId,
      maxSuggestions: maxSuggestions,
    );
  }

  Stream<String> generateTextStream(String prompt) {
    _checkActive();
    return _foundation.generateTextStream(prompt, sessionId: _sessionId);
  }

  Stream<String> getStructuredDataStream(String prompt) {
    _checkActive();
    return _foundation.getStructuredDataStream(prompt, sessionId: _sessionId);
  }

  void _checkActive() {
    if (!_isActive) {
      throw StateError(
        'This session has been closed and cannot be used anymore.',
      );
    }
  }
}
