import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:apple_foundation_flutter/enums/styles.dart';
import 'package:apple_foundation_flutter/exception/apple_foundation_flutter_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'apple_foundation_flutter_platform_interface.dart';

class MethodChannelAppleFoundationFlutter
    extends AppleFoundationFlutterPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('apple_foundation_flutter');

  @visibleForTesting
  final streamChannel = const EventChannel('apple_foundation_flutter_stream');

  static const Duration _defaultTimeout = Duration(seconds: 30);

  static const int _maxRetryAttempts = 3;

  @override
  Future<String?> getPlatformVersion() async {
    try {
      final String? version = await _invokeMethodWithTimeout<String>(
        'getPlatformVersion',
      );
      return version;
    } catch (e) {
      _logError('getPlatformVersion', e);
      rethrow;
    }
  }

  @override
  Future<String?> ask(String prompt, {String? sessionId}) async {
    if (prompt.trim().isEmpty) {
      throw AppleFoundationException(
        'Prompt cannot be empty',
        code: 'INVALID_PROMPT',
      );
    }

    try {
      final String? response = await _invokeMethodWithTimeout<String>('ask', {
        'prompt': prompt,
        if (sessionId != null) 'sessionId': sessionId,
      });
      return response;
    } catch (e) {
      _logError('ask', e);
      throw AppleFoundationException(
        'Failed to process prompt: ${e.toString()}',
        code: 'ASK_FAILED',
        details: {'prompt': prompt, 'sessionId': sessionId},
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getStructuredData(
    String prompt, {
    String? sessionId,
  }) async {
    if (prompt.trim().isEmpty) {
      throw AppleFoundationException(
        'Prompt cannot be empty',
        code: 'INVALID_PROMPT',
      );
    }

    try {
      final String? jsonString = await _invokeMethodWithTimeout<String>(
        'getStructuredData',
        {'prompt': prompt, if (sessionId != null) 'sessionId': sessionId},
      );

      if (jsonString == null || jsonString.isEmpty) {
        throw AppleFoundationException(
          'Received empty response from native layer',
          code: 'EMPTY_RESPONSE',
        );
      }

      final Map<String, dynamic> decodedData =
          json.decode(jsonString) as Map<String, dynamic>;
      return decodedData;
    } on FormatException catch (e) {
      _logError('getStructuredData - JSON decode', e);
      throw AppleFoundationException(
        'Failed to parse structured data response',
        code: 'JSON_PARSE_ERROR',
        details: e.toString(),
      );
    } catch (e) {
      _logError('getStructuredData', e);
      throw AppleFoundationException(
        'Failed to get structured data: ${e.toString()}',
        code: 'STRUCTURED_DATA_FAILED',
        details: {'prompt': prompt, 'sessionId': sessionId},
      );
    }
  }

  @override
  Future<List<String>> getListOfString(
    String prompt, {
    String? sessionId,
  }) async {
    if (prompt.trim().isEmpty) {
      throw AppleFoundationException(
        'Prompt cannot be empty',
        code: 'INVALID_PROMPT',
      );
    }

    try {
      final List<dynamic>? result =
          await _invokeMethodWithTimeout<List<dynamic>>('getListOfString', {
            'prompt': prompt,
            if (sessionId != null) 'sessionId': sessionId,
          });

      if (result == null) {
        throw AppleFoundationException(
          'Received null response from native layer',
          code: 'NULL_RESPONSE',
        );
      }

      return result.cast<String>();
    } catch (e) {
      _logError('getListOfString', e);
      throw AppleFoundationException(
        'Failed to get list of strings: ${e.toString()}',
        code: 'LIST_STRING_FAILED',
        details: {'prompt': prompt, 'sessionId': sessionId},
      );
    }
  }

  @override
  Future<String> openSession(String instructions) async {
    if (instructions.trim().isEmpty) {
      throw AppleFoundationException(
        'Instructions cannot be empty',
        code: 'INVALID_INSTRUCTIONS',
      );
    }

    try {
      final String? sessionId = await _invokeMethodWithTimeout<String>(
        'openSession',
        {'instructions': instructions},
      );

      if (sessionId == null || sessionId.isEmpty) {
        throw AppleFoundationException(
          'Failed to create session - received empty session ID',
          code: 'SESSION_CREATION_FAILED',
        );
      }

      return sessionId;
    } catch (e) {
      _logError('openSession', e);
      throw AppleFoundationException(
        'Failed to open session: ${e.toString()}',
        code: 'OPEN_SESSION_FAILED',
        details: {'instructions': instructions},
      );
    }
  }

  @override
  Future<void> closeSession(String sessionId) async {
    if (sessionId.trim().isEmpty) {
      throw AppleFoundationException(
        'Session ID cannot be empty',
        code: 'INVALID_SESSION_ID',
      );
    }

    try {
      await _invokeMethodWithTimeout<void>('closeSession', {
        'sessionId': sessionId,
      });
    } catch (e) {
      _logError('closeSession', e);
      throw AppleFoundationException(
        'Failed to close session: ${e.toString()}',
        code: 'CLOSE_SESSION_FAILED',
        details: {'sessionId': sessionId},
      );
    }
  }

  @override
  Future<Map<String, dynamic>> getModelCapabilities() async {
    try {
      final Map<dynamic, dynamic>? result =
          await _invokeMethodWithTimeout<Map<dynamic, dynamic>>(
            'getModelCapabilities',
          );

      if (result == null) {
        throw AppleFoundationException(
          'Received null response from native layer',
          code: 'NULL_RESPONSE',
        );
      }

      return Map<String, dynamic>.from(result);
    } catch (e) {
      _logError('getModelCapabilities', e);
      throw AppleFoundationException(
        'Failed to get model capabilities: ${e.toString()}',
        code: 'MODEL_CAPABILITIES_FAILED',
      );
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final bool? result = await _invokeMethodWithTimeout<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      _logError('isAvailable', e);
      // Return false instead of throwing for availability check
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getAvailabilityStatus() async {
    try {
      final Map<dynamic, dynamic>? result =
          await _invokeMethodWithTimeout<Map<dynamic, dynamic>>(
            'getAvailabilityStatus',
          );

      if (result == null) {
        throw AppleFoundationException(
          'Received null response from native layer',
          code: 'NULL_RESPONSE',
        );
      }

      return Map<String, dynamic>.from(result);
    } catch (e) {
      _logError('getAvailabilityStatus', e);
      throw AppleFoundationException(
        'Failed to get availability status: ${e.toString()}',
        code: 'AVAILABILITY_STATUS_FAILED',
      );
    }
  }

  @override
  Future<String?> generateText(
    String prompt, {
    String? sessionId,
    int? maxTokens,
    double? temperature,
    double? topP,
  }) async {
    if (prompt.trim().isEmpty) {
      throw AppleFoundationException(
        'Prompt cannot be empty',
        code: 'INVALID_PROMPT',
      );
    }

    if (maxTokens != null && maxTokens <= 0) {
      throw AppleFoundationException(
        'maxTokens must be greater than 0',
        code: 'INVALID_MAX_TOKENS',
      );
    }

    if (temperature != null && (temperature < 0.0 || temperature > 2.0)) {
      throw AppleFoundationException(
        'temperature must be between 0.0 and 2.0',
        code: 'INVALID_TEMPERATURE',
      );
    }

    if (topP != null && (topP < 0.0 || topP > 1.0)) {
      throw AppleFoundationException(
        'topP must be between 0.0 and 1.0',
        code: 'INVALID_TOP_P',
      );
    }

    try {
      final String? response =
          await _invokeMethodWithTimeout<String>('generateText', {
            'prompt': prompt,
            if (sessionId != null) 'sessionId': sessionId,
            if (maxTokens != null) 'maxTokens': maxTokens,
            if (temperature != null) 'temperature': temperature,
            if (topP != null) 'topP': topP,
          });
      return response;
    } catch (e) {
      _logError('generateText', e);
      throw AppleFoundationException(
        'Failed to generate text: ${e.toString()}',
        code: 'GENERATE_TEXT_FAILED',
        details: {
          'prompt': prompt,
          'sessionId': sessionId,
          'maxTokens': maxTokens,
          'temperature': temperature,
          'topP': topP,
        },
      );
    }
  }

  @override
  Future<List<String>> generateAlternatives(
    String prompt, {
    String? sessionId,
    int count = 3,
  }) async {
    if (prompt.trim().isEmpty) {
      throw AppleFoundationException(
        'Prompt cannot be empty',
        code: 'INVALID_PROMPT',
      );
    }

    if (count <= 0 || count > 10) {
      throw AppleFoundationException(
        'count must be between 1 and 10',
        code: 'INVALID_COUNT',
      );
    }

    try {
      final List<dynamic>? result =
          await _invokeMethodWithTimeout<List<dynamic>>(
            'generateAlternatives',
            {
              'prompt': prompt,
              if (sessionId != null) 'sessionId': sessionId,
              'count': count,
            },
          );

      if (result == null) {
        throw AppleFoundationException(
          'Received null response from native layer',
          code: 'NULL_RESPONSE',
        );
      }

      return result.cast<String>();
    } catch (e) {
      _logError('generateAlternatives', e);
      throw AppleFoundationException(
        'Failed to generate alternatives: ${e.toString()}',
        code: 'GENERATE_ALTERNATIVES_FAILED',
        details: {'prompt': prompt, 'sessionId': sessionId, 'count': count},
      );
    }
  }

  @override
  Future<String?> summarizeText(
    String text, {
    String? sessionId,
    SummarizationStyle style = SummarizationStyle.concise,
  }) async {
    if (text.trim().isEmpty) {
      throw AppleFoundationException(
        'Text cannot be empty',
        code: 'INVALID_TEXT',
      );
    }

    try {
      final String? response = await _invokeMethodWithTimeout<String>(
        'summarizeText',
        {
          'text': text,
          if (sessionId != null) 'sessionId': sessionId,
          'style': style.key,
        },
      );
      return response;
    } catch (e) {
      _logError('summarizeText', e);
      throw AppleFoundationException(
        'Failed to summarize text: ${e.toString()}',
        code: 'SUMMARIZE_TEXT_FAILED',
        details: {'sessionId': sessionId, 'style': style.key},
      );
    }
  }

  @override
  Future<Map<String, dynamic>> extractInformation(
    String text, {
    String? sessionId,
    List<String>? fields,
  }) async {
    if (text.trim().isEmpty) {
      throw AppleFoundationException(
        'Text cannot be empty',
        code: 'INVALID_TEXT',
      );
    }

    try {
      final Map<dynamic, dynamic>? result =
          await _invokeMethodWithTimeout<Map<dynamic, dynamic>>(
            'extractInformation',
            {
              'text': text,
              if (sessionId != null) 'sessionId': sessionId,
              if (fields != null && fields.isNotEmpty) 'fields': fields,
            },
          );

      if (result == null) {
        throw AppleFoundationException(
          'Received null response from native layer',
          code: 'NULL_RESPONSE',
        );
      }

      return Map<String, dynamic>.from(result);
    } catch (e) {
      _logError('extractInformation', e);
      throw AppleFoundationException(
        'Failed to extract information: ${e.toString()}',
        code: 'EXTRACT_INFORMATION_FAILED',
        details: {'sessionId': sessionId, 'fields': fields},
      );
    }
  }

  @override
  Future<Map<String, double>> classifyText(
    String text, {
    String? sessionId,
    List<String>? categories,
  }) async {
    if (text.trim().isEmpty) {
      throw AppleFoundationException(
        'Text cannot be empty',
        code: 'INVALID_TEXT',
      );
    }

    try {
      final Map<dynamic, dynamic>? result =
          await _invokeMethodWithTimeout<Map<dynamic, dynamic>>(
            'classifyText',
            {
              'text': text,
              if (sessionId != null) 'sessionId': sessionId,
              if (categories != null && categories.isNotEmpty)
                'categories': categories,
            },
          );

      if (result == null) {
        throw AppleFoundationException(
          'Received null response from native layer',
          code: 'NULL_RESPONSE',
        );
      }

      return Map<String, double>.from(result);
    } catch (e) {
      _logError('classifyText', e);
      throw AppleFoundationException(
        'Failed to classify text: ${e.toString()}',
        code: 'CLASSIFY_TEXT_FAILED',
        details: {'sessionId': sessionId, 'categories': categories},
      );
    }
  }

  @override
  Future<List<String>> generateSuggestions(
    String context, {
    String? sessionId,
    int maxSuggestions = 5,
  }) async {
    if (context.trim().isEmpty) {
      throw AppleFoundationException(
        'Context cannot be empty',
        code: 'INVALID_CONTEXT',
      );
    }

    if (maxSuggestions <= 0 || maxSuggestions > 20) {
      throw AppleFoundationException(
        'maxSuggestions must be between 1 and 20',
        code: 'INVALID_MAX_SUGGESTIONS',
      );
    }

    try {
      final List<dynamic>? result =
          await _invokeMethodWithTimeout<List<dynamic>>('generateSuggestions', {
            'context': context,
            if (sessionId != null) 'sessionId': sessionId,
            'maxSuggestions': maxSuggestions,
          });

      if (result == null) {
        throw AppleFoundationException(
          'Received null response from native layer',
          code: 'NULL_RESPONSE',
        );
      }

      return result.cast<String>();
    } catch (e) {
      _logError('generateSuggestions', e);
      throw AppleFoundationException(
        'Failed to generate suggestions: ${e.toString()}',
        code: 'GENERATE_SUGGESTIONS_FAILED',
        details: {
          'context': context,
          'sessionId': sessionId,
          'maxSuggestions': maxSuggestions,
        },
      );
    }
  }

  /// Helper method to invoke method channel calls with timeout and retry logic
  Future<T?> _invokeMethodWithTimeout<T>(
    String method, [
    Map<String, dynamic>? arguments,
    Duration? timeout,
  ]) async {
    final Duration effectiveTimeout = timeout ?? _defaultTimeout;

    for (int attempt = 1; attempt <= _maxRetryAttempts; attempt++) {
      try {
        final Future<T?> methodCall = methodChannel.invokeMethod<T>(
          method,
          arguments,
        );
        return await methodCall.timeout(effectiveTimeout);
      } on TimeoutException {
        if (attempt == _maxRetryAttempts) {
          throw AppleFoundationException(
            'Method $method timed out after ${effectiveTimeout.inSeconds} seconds',
            code: 'TIMEOUT_ERROR',
            details: {'method': method, 'attempt': attempt},
          );
        }
        // Wait before retry with exponential backoff
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      } on PlatformException catch (e) {
        throw AppleFoundationException(
          'Platform error in $method: ${e.message}',
          code: e.code,
          details: e.details,
        );
      } catch (e) {
        if (attempt == _maxRetryAttempts) {
          rethrow;
        }
        // Wait before retry
        await Future.delayed(Duration(milliseconds: 200 * attempt));
      }
    }
    return null;
  }

  /// Helper method to log errors consistently
  void _logError(String methodName, dynamic error) {
    if (kDebugMode) {
      developer.log(
        'AppleFoundationFlutter Error in $methodName: $error',
        name: 'AppleFoundationFlutter',
        error: error,
      );
    }
  }

  @override
  Stream<String> generateTextStream(
    String prompt, {
    String? sessionId,
    int? maxTokens,
    double? temperature,
    double? topP,
  }) {
    final args = <String, dynamic>{
      'prompt': prompt,
      'dataType': 'text',
      if (sessionId != null) 'sessionId': sessionId,
      if (maxTokens != null) 'maxTokens': maxTokens,
      if (temperature != null) 'temperature': temperature,
      if (topP != null) 'topP': topP,
    };

    return streamChannel
        .receiveBroadcastStream(args)
        .map((event) => event as String);
  }

  @override
  Stream<String> getStructuredDataStream(String prompt, {String? sessionId}) {
    final args = <String, dynamic>{
      'prompt': prompt,
      'dataType': 'json',
      if (sessionId != null) 'sessionId': sessionId,
    };

    return streamChannel
        .receiveBroadcastStream(args)
        .map((event) => event as String);
  }
}
