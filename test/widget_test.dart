// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smh_front/models/user.dart';
import 'package:smh_front/services/auth_service.dart';
import 'package:smh_front/services/system.dart';
import 'package:smh_front/services/user_service.dart';

void main() {
  const MethodChannel channel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
    // Mock method calls for flutter_secure_storage
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'read') {
        // Return a mocked value for the 'read' method
        return 'mocked_token'; // Adjust based on what your auth service expects
      }
      if (methodCall.method == 'write') {
        // Handle 'write' if used in your auth service
        return null;
      }
      if (methodCall.method == 'delete') {
        // Handle 'delete' if used
        return null;
      }
      throw MissingPluginException(
        'No implementation for ${methodCall.method}',
      );
    });

    System.init(apiUrl: 'http://49.13.197.63:8003/api');
  });

  tearDownAll(() {
    channel.setMethodCallHandler(null);
  });

  // Common
  UserService userService = UserService();

  group('Auth service tests', () {
    AuthService authService = AuthService(userService: userService);

    test('Tesing auth service', () async {
      User user = await authService.logIn('sophie_shopper', 'Test237@');
      expect(user.username, 'sophie_shopper');
    });
  });
}
