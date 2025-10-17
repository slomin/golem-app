import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/llm_providers.dart';
import 'domain/llm_models.dart';
import 'utils/token_rate_tracker.dart';
import 'data/apple_foundation_flutter_repository.dart';

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
  final TokenRateTracker _tokenRateTracker = TokenRateTracker();
  TokenRateSnapshot? _latestSnapshot;

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

    final usingApple =
        ref.read(llmRepositoryProvider) is AppleFoundationFlutterRepository;
    final double targetTokensPerSecond = usingApple
        ? 24 // give Apple FM a smooth "typing" cadence
        : _tokensPerSecond.clamp(_minTokensPerSecond, _maxTokensPerSecond);
    final Duration tokenDelay = Duration(
      microseconds: max(
        1,
        (Duration.microsecondsPerSecond / targetTokensPerSecond).round(),
      ),
    );

    final request = LlmRequest(
      prompt: prompt,
      maxTokens: _maxTokens,
      temperature: 0.9,
      tokenDelay: tokenDelay,
      randomSeed: usingApple ? null : (_useFixedSeed ? _seedValue : null),
    );

    ref.read(currentLlmRequestProvider.notifier).setRequest(request);

    setState(() {
      _submitted = true;
      _tokenRateTracker.reset();
      _latestSnapshot = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(llmRepositoryProvider);
    final useApplePreference = ref.watch(
      useAppleFoundationModelPreferenceProvider,
    );
    final appleRepoAsync = ref.watch(appleFoundationModelRepositoryProvider);
    final appleAvailable = appleRepoAsync.maybeWhen(
      data: (value) => value != null,
      orElse: () => false,
    );
    final appleToggleValue = appleAvailable && useApplePreference;
    final appleStatusText = appleRepoAsync.when<String>(
      data: (value) => value != null
          ? 'Apple Intelligence ready on device.'
          : 'Apple Intelligence not available on this device.',
      loading: () => 'Checking Apple Intelligence availability…',
      error: (error, _) => 'Unavailable: ${error.toString()}',
    );
    final usingApple = repo is AppleFoundationFlutterRepository;
    final request = ref.watch(currentLlmRequestProvider);
    final AsyncValue<List<LlmChunk>> tokenStream = request == null
        ? const AsyncValue<List<LlmChunk>>.data(<LlmChunk>[])
        : ref.watch(llmCompletionProvider(request));

    final theme = Theme.of(context);
    final appBarTitle = usingApple ? 'Golem Apple FM' : 'Golem Fake LLM';

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
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
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: appleToggleValue,
                title: const Text('Use Apple Foundation Model'),
                subtitle: Text(appleStatusText),
                onChanged: appleAvailable
                    ? (value) {
                        ref
                            .read(
                              useAppleFoundationModelPreferenceProvider
                                  .notifier,
                            )
                            .set(value);
                      }
                    : null,
              ),
              const SizedBox(height: 12),
              if (!usingApple) ...[
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
              ] else ...[
                Text(
                  'Apple FM streaming speed is managed by the device.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _submitPrompt,
                      icon: const Icon(Icons.send),
                      label: Text(
                        usingApple ? 'Send to Apple FM' : 'Send to Fake LLM',
                      ),
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
                          ? _StreamingPlaceholder(
                              mode: usingApple
                                  ? StreamingMode.apple
                                  : StreamingMode.fake,
                            )
                          : const _IdlePlaceholder();
                    }
                    final decoded = repo.tokenizer
                        .decode(chunks.map((chunk) => chunk.token))
                        .trimLeft();
                    final rateSnapshot = _tokenRateTracker.record(
                      totalTokens: chunks.length,
                    );
                    _latestSnapshot = rateSnapshot;
                    if (usingApple) {
                      final header =
                          'Apple Foundation Model response (${chunks.length} tokens)';
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(header, style: theme.textTheme.titleSmall),
                              if (rateSnapshot.tokensPerSecond > 0) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${rateSnapshot.tokensPerSecond.toStringAsFixed(1)} t/s',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
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
                    }
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
                            if (rateSnapshot.tokensPerSecond > 0) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${rateSnapshot.tokensPerSecond.toStringAsFixed(1)} t/s',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
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
                  loading: () => _StreamingPlaceholder(
                    mode: repo is AppleFoundationFlutterRepository
                        ? StreamingMode.apple
                        : StreamingMode.fake,
                  ),
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

enum StreamingMode { fake, apple }

class _StreamingPlaceholder extends StatelessWidget {
  const _StreamingPlaceholder({required this.mode});

  final StreamingMode mode;

  @override
  Widget build(BuildContext context) {
    final message = switch (mode) {
      StreamingMode.fake => 'Preparing fake LLM stream…',
      StreamingMode.apple => 'Contacting Apple Foundation Model…',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
            Text(message),
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
