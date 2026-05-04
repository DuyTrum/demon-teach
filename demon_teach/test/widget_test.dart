import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:demon_teach/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demon_teach/core/di/injection_container.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    // Build our app with overridden provider
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const DemonTeachApp(),
      ),
    );

    // Verify that splash screen is shown
    expect(find.text('Demon Teach'), findsOneWidget);
  });
}
