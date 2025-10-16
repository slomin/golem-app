import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:golem_app/app/llm_providers.dart';
import 'package:golem_app/data/fake_llm_repository.dart';
import 'package:golem_app/data/sources/local/fake_llm_data_source.dart';
import 'package:golem_app/data/tokenizers/llama_like_tokenizer.dart';
import 'package:golem_app/main.dart';

void main() {
  testWidgets('Fake LLM stream renders response', (tester) async {
    final dataSource = _StubDataSource([
      FakeLlmParagraph(
        id: 7,
        text: 'Test paragraph about adapters and quantization scaling.',
      ),
      FakeLlmParagraph(
        id: 9,
        text: 'Follow-up insight that tokens stream deterministically.',
      ),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          llmRepositoryProvider.overrideWithValue(
            FakeLlmRepository(
              dataSource: dataSource,
              tokenizer: LlamaLikeTokenizer(),
              config: const FakeLlmConfig(
                maxTokens: 4096,
                tokensPerSecond: 128,
              ),
            ),
          ),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.text('Enter a prompt to simulate LLM output.'), findsOneWidget);

    // Speed up streaming by moving the slider to its maximum value.
    await tester.drag(find.byType(Slider), const Offset(300, 0));
    await tester.pump();

    const prompt = 'Test prompt for widget streaming';
    await tester.enterText(find.byType(TextField), prompt);
    await tester.tap(find.text('Send to Fake LLM'));
    await tester.pump();

    // Advance fake time until the stream completes.
    var responsePopulated = false;
    for (var i = 0; i < 160; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      final hasResponseHeader = find
          .textContaining('Fake LLM response')
          .evaluate()
          .isNotEmpty;
      final selectableFinder = find.byType(SelectableText);
      if (hasResponseHeader && selectableFinder.evaluate().isNotEmpty) {
        final selectable = tester.widget<SelectableText>(selectableFinder);
        responsePopulated = (selectable.data ?? '').trim().isNotEmpty;
      }
    }

    expect(
      responsePopulated,
      isTrue,
      reason: 'Expected fake response to populate',
    );
    expect(find.textContaining('Paragraph #'), findsWidgets);
    final selectable = tester.widget<SelectableText>(
      find.byType(SelectableText),
    );
    final responseText = (selectable.data ?? '').trim();
    expect(responseText.contains('Paragraph #'), isTrue);
    expect(
      responseText.contains(
            'Test paragraph about adapters and quantization scaling.',
          ) ||
          responseText.contains(
            'Follow-up insight that tokens stream deterministically.',
          ),
      isTrue,
    );

    // Let remaining timers finish to avoid pending timers at test teardown.
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('Tokens per second slider updates label', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.text('16 t/s'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('tokens-per-second-slider')),
      const Offset(200, 0),
    );
    await tester.pumpAndSettle();

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('tokens-per-second-slider')),
    );

    expect(slider.value, greaterThan(16));
    final updatedLabel = '${slider.value.toStringAsFixed(0)} t/s';
    expect(find.text(updatedLabel), findsOneWidget);
    expect(find.text('16 t/s'), findsNothing);
  });
}

class _StubDataSource implements FakeLlmDataSource {
  _StubDataSource(this._paragraphs);

  final List<FakeLlmParagraph> _paragraphs;

  @override
  Future<List<FakeLlmParagraph>> loadParagraphs() async => _paragraphs;
}
