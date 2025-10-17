import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/chat/presentation/chat_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1C1C1E),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F2EE),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16, height: 1.4),
      ),
    );

    return MaterialApp(
      title: 'Golem Dev Chat',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const ChatPage(),
    );
  }
}
