# Apple Foundation Flutter

A Flutter plugin that provides access to Apple's on-device Foundation Models framework, available on iOS 26.0 and above. This plugin allows you to integrate Apple Intelligence features directly into your Flutter applications, offering powerful, private, and efficient AI capabilities, currently on ios only but foundations model does work on macos so this will be added in a later update.

## Features

- **On-Device & Private**: All processing happens locally, ensuring user data remains private.
- **Text Generation**: Create rich, context-aware text content.
- **Streaming Support**: Stream text and structured JSON responses in real-time for a dynamic UX.
- **Structured Data**: Generate structured data (e.g., JSON) from natural language prompts.
- **Session Management**: Maintain conversation history and context with sessions.
- **Advanced Control**: Fine-tune model output with parameters like temperature, token limits, and more.
- **Helper Functions**: Includes specialized methods for summarization, classification, alternative generation, and information extraction.
- **Availability Checks**: Gracefully check if Apple Intelligence is available on the user's device.

## Requirements

- **Platform**: iOS 26.0+
- **IDE**: Xcode 26.0+
- **Flutter**: 3.0+

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  apple_foundation_flutter: ^0.1.1
```

Then run:

```bash
flutter pub get
```

## Usage

You can use this plugin in two ways:

### 1. Using AppleIntelligenceSession (Recommended)

The session class provides a more object-oriented approach with automatic session management:

```dart
import 'package:apple_foundation_flutter/apple_foundation_flutter.dart';

// Create a new session
final session = await AppleIntelligenceSession.create(
  'You are a helpful AI assistant that provides concise responses.',
);

try {

  final response = await session.ask('What is quantum computing?');
  print(response);

  // Generate structured data
  final data = await session.getStructuredData(
    'Create a profile for a quantum computer scientist',
  );
  print(data);

  // Stream responses
  await for (final chunk in session.generateTextStream('Tell me a story')) {
    print(chunk); // Process each chunk as it arrives
  }
} finally {
  // Always close the session when done
  await session.close();
}
```

You can create multiple independent sessions:

```dart
// Create two sessions with different contexts
final techSession = await AppleIntelligenceSession.create(
  'You are a technical expert in computer science.',
);
final storySession = await AppleIntelligenceSession.create(
  'You are a creative storyteller.',
);

// Use them independently
final techResponse = await techSession.ask('Explain APIs');
final storyResponse = await storySession.ask('Tell me a short story');

// Close both sessions when done
await techSession.close();
await storySession.close();
```

### 2. Using the Plugin Directly

If you prefer to manage sessions yourself or need more direct control:

```dart
import 'package:apple_foundation_flutter/apple_foundation_flutter.dart';

final plugin = AppleFoundationFlutter();

// Check availability
final bool isAvailable = await plugin.isAvailable();
if (!isAvailable) {
  final status = await plugin.getAvailabilityStatus();
  print('Apple Intelligence is not available: ${status['reason']}');
  return;
}

// Create a session manually
final sessionId = await plugin.openSession(
  'You are a helpful assistant.',
);

try {
  // Use the session ID in calls
  final response = await plugin.generateText(
    'What is machine learning?',
    sessionId: sessionId,
  );
  print(response);

  // Stream responses
  String streamedResponse = '';
  final textStream = plugin.generateTextStream(
    'Tell me a story about AI',
    sessionId: sessionId,
  );

  await for (final chunk in textStream) {
    streamedResponse += chunk;
  }
} finally {
  // Clean up the session
  await plugin.closeSession(sessionId);
}
```

## API Reference

### Core Methods

- **`Future<bool> isAvailable()`**: Checks if Apple Intelligence is supported and enabled.
- **`Future<Map<String, dynamic>> getAvailabilityStatus()`**: Gets a detailed status, including a reason if unavailable.
- **`Future<String?> getPlatformVersion()`**: Gets the underlying iOS version.

### Session Management

- **`Future<String> openSession(String instructions)`**: Creates a new session with system-level instructions and returns a unique session ID.
- **`Future<void> closeSession(String sessionId)`**: Closes and cleans up a session.

### Generation Methods (Single Response)

These methods return a complete response after generation is finished.

- **`Future<String?> ask(String prompt, {String? sessionId})`**: A simple method for a single question-and-answer interaction.
- **`Future<String?> generateText(String prompt, {String? sessionId, int? maxTokens, double? temperature, double? topP})`**: Generates text with advanced options.
- **`Future<Map<String, dynamic>> getStructuredData(String prompt, {String? sessionId})`**: Generates a JSON object from a prompt.
- **`Future<List<String>> getListOfString(String prompt, {String? sessionId})`**: Generates a list of strings, where each item is on a new line.
- **`Future<List<String>> generateAlternatives(String prompt, {String? sessionId, int count})`**: Generates a specified number of variations for a given text.
- **`Future<String?> summarizeText(String text, {String? sessionId, SummarizationStyle style})`**: Summarizes a piece of text in a specific style.
- **`Future<Map<String, dynamic>> extractInformation(String text, {String? sessionId, List<String>? fields})`**: Extracts specific fields from text into a JSON object.
- **`Future<Map<String, double>> classifyText(String text, {String? sessionId, List<String>? categories})`**: Classifies text against a list of categories and returns confidence scores.
- **`Future<List<String>> generateSuggestions(String context, {String? sessionId, int maxSuggestions})`**: Provides contextual suggestions.

### Generation Methods (Streaming)

- **`Stream<String> generateTextStream(String prompt, {String? sessionId, ...})`**: Streams generated text as a series of chunks.
- **`Stream<String> getStructuredDataStream(String prompt, {String? sessionId})`**: Streams a complete JSON object as a raw string. The stream will emit the full string in one or more chunks.

## Error Handling

The plugin uses `AppleFoundationException` for errors. It's best to wrap API calls in a `try-catch` block.

```dart
try {
  final session = await AppleIntelligenceSession.create('You are a helpful assistant');
  final result = await session.generateText('Hello!');
} on AppleFoundationException catch (e) {
  print('Error Code: ${e.code}');
  print('Message: ${e.message}');
  // e.g., 'UNSUPPORTED_OS_VERSION', 'MODEL_NOT_READY', etc.
  switch (e.code) {
    case 'UNSUPPORTED_OS_VERSION':
      // Handle OS not supported
      break;
    case 'MODEL_NOT_READY':
      // Inform user the model is downloading
      break;
    // ... handle other specific error codes
  }
}
```

### Common Error Codes

- **`UNSUPPORTED_OS_VERSION`**: The iOS version is below 26.0.
- **`DEVICE_NOT_ELIGIBLE`**: The device hardware does not support Apple Intelligence.
- **`APPLE_INTELLIGENCE_NOT_ENABLED`**: The user has not enabled Apple Intelligence in Settings.
- **`MODEL_NOT_READY`**: The language model is still downloading or is otherwise not ready.
- **`TIMEOUT_ERROR`**: The request to the native side timed out.
- **`GENERATION_ERROR`**: An error occurred within the native model during generation.
- **`INVALID_ARGUMENTS`**: One of the arguments passed to the method was invalid (e.g., empty prompt).
- **`RUN_ERROR`**: Failed to run the prompt, often due to missing resources. This commonly occurs when:
  - The model resources are still downloading
  - The Local Sanitizer Asset is not yet available
  - Incompatible Verions of xcode
  - The device is low on storage space
  - The model was recently installed and is still initializing

### Handling Resource Availability

When you first install the app or update to a new iOS version, Apple's Foundation Models framework may need to download additional resources, if you have MacOS 26 beta 2, make sure you are using Xcode 26 beta 2 aswell. If not you might encounter `RUN_ERROR` or `MODEL_NOT_READY` errors.

## Privacy

This plugin processes all data locally on the device using Apple's Foundation Models framework. **No data is transmitted to external servers**, ensuring complete privacy and compliance with data protection regulations.

## Contributing

We welcome contributions! Please see our Contributing Guide for more details.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## References

- [Apple Foundation Models Documentation](https://developer.apple.com/documentation/foundationmodels)
- [Flutter Plugin Development](https://docs.flutter.dev/packages-and-plugins/developing-packages)
