import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golem_app/main.dart';

@Timeout(Duration(seconds: 1))
void main() {
  testWidgets('renders chat empty state on launch', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.text('What can I help with today?'), findsOneWidget);
    expect(find.text('Ask anything'), findsOneWidget);
  });
}
