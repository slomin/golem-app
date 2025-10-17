import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apple_foundation_flutter/apple_foundation_flutter.dart';

import '../data/apple_foundation_flutter_repository.dart';
import '../data/fake_llm_repository.dart';
import '../data/llm_repository.dart';
import '../domain/llm_models.dart';

final fakeLlmRepositoryProvider = Provider<FakeLlmRepository>(
  (ref) => FakeLlmRepository(
    config: const FakeLlmConfig(maxTokens: 2048, tokensPerSecond: 16),
  ),
  name: 'fakeLlmRepository',
);

final useAppleFoundationModelPreferenceProvider =
    NotifierProvider<AppleBackendPreferenceNotifier, bool>(
      AppleBackendPreferenceNotifier.new,
      name: 'useAppleFoundationModelPreference',
    );

final appleFoundationClientProvider = Provider<AppleFoundationFlutter>(
  (ref) => AppleFoundationFlutter(),
  name: 'appleFoundationClient',
);

final appleFoundationModelRepositoryProvider = FutureProvider<LlmRepository?>((
  ref,
) async {
  if (!_isIosDevice()) {
    debugPrint(
      '[AppleFM] Skipping native repository, platform=${defaultTargetPlatform}',
    );
    return null;
  }

  final client = ref.watch(appleFoundationClientProvider);
  final available = await _safeIsAvailable(client);
  if (!available) {
    debugPrint('[AppleFM] Native repository unavailable (bridge check)');
    return null;
  }

  debugPrint(
    '[AppleFM] Native repository available via apple_foundation_flutter',
  );
  return AppleFoundationFlutterRepository(client: client);
}, name: 'appleFoundationModelRepository');

final llmRepositoryProvider = Provider<LlmRepository>((ref) {
  final fallback = ref.watch(fakeLlmRepositoryProvider);
  final useApple = ref.watch(useAppleFoundationModelPreferenceProvider);
  final appleRepoAsync = ref.watch(appleFoundationModelRepositoryProvider);

  final appleRepo = appleRepoAsync.maybeWhen(
    data: (repo) => repo,
    orElse: () => null,
  );

  if (useApple) {
    if (appleRepo != null) {
      debugPrint(
        '[AppleFM] Using Apple Foundation Model repository (user enabled)',
      );
      return appleRepo;
    }
    debugPrint(
      '[AppleFM] Apple FM preferred but unavailable, falling back to fake repository',
    );
  }

  if (appleRepo != null && !useApple) {
    debugPrint(
      '[AppleFM] Apple FM available but preference disabled, using fake repository',
    );
  } else if (appleRepo == null) {
    debugPrint('[AppleFM] Using fake repository');
  }

  return fallback;
}, name: 'llmRepository');

Future<bool> _safeIsAvailable(AppleFoundationFlutter client) async {
  try {
    return await client.isAvailable();
  } catch (_) {
    return false;
  }
}

bool _isIosDevice() {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.iOS;
}

class AppleBackendPreferenceNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool isEnabled) {
    state = isEnabled;
  }
}

class CurrentLlmRequestNotifier extends Notifier<LlmRequest?> {
  @override
  LlmRequest? build() => null;

  void setRequest(LlmRequest request) {
    state = request;
  }

  void clear() {
    state = null;
  }
}

final currentLlmRequestProvider =
    NotifierProvider<CurrentLlmRequestNotifier, LlmRequest?>(
      CurrentLlmRequestNotifier.new,
      name: 'currentLlmRequest',
    );

final llmCompletionProvider = StreamProvider.family
    .autoDispose<List<LlmChunk>, LlmRequest>((ref, request) {
      final repo = ref.watch(llmRepositoryProvider);
      final controller = StreamController<List<LlmChunk>>();
      final buffer = <LlmChunk>[];

      final subscription = repo
          .streamCompletion(request)
          .listen(
            (chunk) {
              buffer.add(chunk);
              controller.add(List.unmodifiable(buffer));
            },
            onError: controller.addError,
            onDone: () {
              if (!controller.isClosed) {
                controller.close();
              }
            },
          );

      ref.onDispose(() async {
        await subscription.cancel();
        if (!controller.isClosed) {
          await controller.close();
        }
      });

      return controller.stream;
    });
