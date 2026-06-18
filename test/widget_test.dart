import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pomodoro/main.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('FocusTime app opens and loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for the async loading of settings/tasks/stats to complete
    // (using pump with duration since AvatarWidget contains infinite repeating animations)
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify that the title 'FocusTime' is displayed in the AppBar.
    expect(find.text('FocusTime'), findsOneWidget);

    // Verify that the Timer tab and Voortgang tab are present.
    expect(find.text('Timer'), findsOneWidget);
    expect(find.text('Voortgang'), findsOneWidget);
  });
}
