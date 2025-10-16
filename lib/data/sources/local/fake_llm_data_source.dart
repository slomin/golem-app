import 'dart:convert';

import 'package:flutter/services.dart';

class FakeLlmParagraph {
  const FakeLlmParagraph({required this.id, required this.text});

  final int id;
  final String text;
}

abstract class FakeLlmDataSource {
  Future<List<FakeLlmParagraph>> loadParagraphs();
}

class AssetFakeLlmDataSource implements FakeLlmDataSource {
  AssetFakeLlmDataSource({
    this.assetPath = 'assets/mock_data/llm/fake_responses.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;
  List<FakeLlmParagraph>? _cachedParagraphs;

  @override
  Future<List<FakeLlmParagraph>> loadParagraphs() async {
    final cached = _cachedParagraphs;
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final raw = await _bundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final paragraphs = (decoded['paragraphs'] as List<dynamic>? ?? [])
        .map((entry) => entry is Map<String, dynamic> ? entry : null)
        .whereType<Map<String, dynamic>>()
        .map((entry) {
          final id = entry['id'];
          final text = entry['text'] as String?;
          if (text == null) {
            return null;
          }
          final trimmed = text.trim();
          if (trimmed.isEmpty) {
            return null;
          }
          return FakeLlmParagraph(
            id: id is int ? id : int.tryParse(id?.toString() ?? '') ?? -1,
            text: trimmed,
          );
        })
        .whereType<FakeLlmParagraph>()
        .toList(growable: false);

    _cachedParagraphs = paragraphs;
    return paragraphs;
  }
}
