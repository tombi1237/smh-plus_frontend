// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smh_front/main.dart';
import 'package:smh_front/models/user.dart';
import 'package:smh_front/services/auth_service.dart';
import 'package:smh_front/services/system.dart';
import 'package:smh_front/services/user_service.dart';

void main() {
  System.init(apiUrl: 'http://49.13.197.63:8003/api');

  test('Tesing auth service', () async {
    UserService userService = UserService();
    AuthService authService = AuthService(userService: userService);

    User user = await authService.logIn('sophie_shopper', 'Test237@');
    expect(user.username, 'sophie_shopper');
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  }, skip: true);
}
