import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/llm_providers.dart';
import 'domain/llm_models.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Golem Dev Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }

  int? _extractParagraphId(String text) {
    final match = RegExp(r'Paragraph #(-?\d+)').firstMatch(text);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1)!);
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _promptController = TextEditingController(
    text: 'Explain on-device model quantization techniques.',
  );
  bool _submitted = false;

  static const int _maxTokens = 2048;
  static const double _minTokensPerSecond = 4;
  static const double _maxTokensPerSecond = 48;
  double _tokensPerSecond = 16;
  bool _useFixedSeed = false;
  int _seedValue = 1337;
  int? _lastLoggedParagraphId;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _submitPrompt() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      return;
    }

    final tokensPerSecond = _tokensPerSecond.clamp(
      _minTokensPerSecond,
      _maxTokensPerSecond,
    );
    final tokenDelayMicros = (Duration.microsecondsPerSecond / tokensPerSecond)
        .round();

    final request = LlmRequest(
      prompt: prompt,
      maxTokens: _maxTokens,
      temperature: 0.9,
      tokenDelay: Duration(microseconds: max(1, tokenDelayMicros)),
      randomSeed: _useFixedSeed ? _seedValue : null,
    );

    ref.read(currentLlmRequestProvider.notifier).setRequest(request);

    setState(() {
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(llmRepositoryProvider);
    final request = ref.watch(currentLlmRequestProvider);
    final AsyncValue<List<LlmChunk>> tokenStream = request == null
        ? const AsyncValue<List<LlmChunk>>.data(<LlmChunk>[])
        : ref.watch(llmCompletionProvider(request));

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Golem Fake LLM')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _promptController,
                textInputAction: TextInputAction.send,
                minLines: 1,
                maxLines: 3,
                onSubmitted: (_) => _submitPrompt(),
                decoration: const InputDecoration(
                  labelText: 'Prompt',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Tokens per second slider',
                      child: Slider(
                        key: const ValueKey('tokens-per-second-slider'),
                        value: _tokensPerSecond,
                        min: _minTokensPerSecond,
                        max: _maxTokensPerSecond,
                        divisions: (_maxTokensPerSecond - _minTokensPerSecond)
                            .round(),
                        label: '${_tokensPerSecond.toStringAsFixed(0)} t/s',
                        onChanged: (value) {
                          setState(() {
                            _tokensPerSecond = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_tokensPerSecond.toStringAsFixed(0)} t/s',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _useFixedSeed,
                title: const Text('Deterministic seed'),
                subtitle: Text(
                  _useFixedSeed
                      ? 'Seed: $_seedValue'
                      : 'Random paragraph each run',
                ),
                onChanged: (value) {
                  setState(() {
                    _useFixedSeed = value;
                  });
                },
              ),
              if (_useFixedSeed)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Decrease seed',
                      onPressed: () {
                        setState(() {
                          _seedValue = max(-999999, _seedValue - 1);
                        });
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    Text('$_seedValue', style: theme.textTheme.bodyMedium),
                    IconButton(
                      tooltip: 'Increase seed',
                      onPressed: () {
                        setState(() {
                          _seedValue = min(999999, _seedValue + 1);
                        });
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _submitPrompt,
                      icon: const Icon(Icons.send),
                      label: const Text('Send to Fake LLM'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: tokenStream.when(
                  data: (chunks) {
                    if (chunks.isEmpty) {
                      return _submitted
                          ? const _StreamingPlaceholder()
                          : const _IdlePlaceholder();
                    }
                    final decoded = repo.tokenizer
                        .decode(chunks.map((chunk) => chunk.token))
                        .trimLeft();
                    final paragraphId = _extractParagraphId(decoded);
                    if (paragraphId != null &&
                        _lastLoggedParagraphId != paragraphId) {
                      _lastLoggedParagraphId = paragraphId;
                      debugPrint('Fake LLM paragraph id: $paragraphId');
                    }
                    final header = paragraphId != null
                        ? 'Paragraph #$paragraphId • ${chunks.length} tokens'
                        : 'Fake LLM response (${chunks.length} tokens)';
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(header, style: theme.textTheme.titleSmall),
                            const SizedBox(height: 12),
                            Expanded(
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  decoded,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const _StreamingPlaceholder(),
                  error: (error, stackTrace) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Stream error: $error',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int? _extractParagraphId(String text) {
    final match = RegExp(r'Paragraph #(-?\d+)').firstMatch(text);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1)!);
  }
}

class _StreamingPlaceholder extends StatelessWidget {
  const _StreamingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            LinearProgressIndicator(),
            SizedBox(height: 12),
            Text('Streaming fake tokens...'),
          ],
        ),
      ),
    );
  }
}

class _IdlePlaceholder extends StatelessWidget {
  const _IdlePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Enter a prompt to simulate LLM output.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
