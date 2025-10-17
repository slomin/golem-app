import 'package:apple_foundation_flutter/enums/styles.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'apple_foundation_flutter_method_channel.dart';

abstract class AppleFoundationFlutterPlatform extends PlatformInterface {
  AppleFoundationFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static AppleFoundationFlutterPlatform _instance =
      MethodChannelAppleFoundationFlutter();

  static AppleFoundationFlutterPlatform get instance => _instance;

  static set instance(AppleFoundationFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> ask(String prompt, {String? sessionId}) {
    throw UnimplementedError('ask() has not been implemented.');
  }

  Future<Map<String, dynamic>> getStructuredData(
    String prompt, {
    String? sessionId,
  }) {
    throw UnimplementedError('getStructuredData() has not been implemented.');
  }

  Future<List<String>> getListOfString(String prompt, {String? sessionId}) {
    throw UnimplementedError('getListOfString() has not been implemented.');
  }

  Future<String> openSession(String instructions) {
    throw UnimplementedError('openSession() has not been implemented.');
  }


  Future<void> closeSession(String sessionId) {
    throw UnimplementedError('closeSession() has not been implemented.');
  }





  Future<bool> isAvailable() {
    throw UnimplementedError('isAvailable() has not been implemented.');
  }


  Future<Map<String, dynamic>> getAvailabilityStatus() {
    throw UnimplementedError(
      'getAvailabilityStatus() has not been implemented.',
    );
  }


  Future<String?> generateText(
    String prompt, {
    String? sessionId,

  }) {
    throw UnimplementedError('generateText() has not been implemented.');
  }

  Future<List<String>> generateAlternatives(
    String prompt, {
    String? sessionId,
    int count = 3,
  }) {
    throw UnimplementedError(
      'generateAlternatives() has not been implemented.',
    );
  }

  Future<String?> summarizeText(
    String text, {
    String? sessionId,
    SummarizationStyle style = SummarizationStyle.concise,
  }) {
    throw UnimplementedError('summarizeText() has not been implemented.');
  }

  Future<Map<String, dynamic>> extractInformation(
    String text, {
    String? sessionId,
    List<String>? fields,
  }) {
    throw UnimplementedError('extractInformation() has not been implemented.');
  }

  Future<Map<String, double>> classifyText(
    String text, {
    String? sessionId,
    List<String>? categories,
  }) {
    throw UnimplementedError('classifyText() has not been implemented.');
  }

  Future<List<String>> generateSuggestions(
    String context, {
    String? sessionId,
    int maxSuggestions = 5,
  }) {
    throw UnimplementedError('generateSuggestions() has not been implemented.');
  }

  Stream<String> generateTextStream(
    String prompt, {
    String? sessionId,

  }) {
    throw UnimplementedError('generateTextStream() has not been implemented.');
  }

  Stream<String> getStructuredDataStream(String prompt, {String? sessionId}) {
    throw UnimplementedError(
      'getStructuredDataStream() has not been implemented.',
    );
  }
}
