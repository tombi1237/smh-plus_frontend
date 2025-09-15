import 'package:flutter/material.dart';
import 'package:smh_front/pages/commercial.dashboard.page.dart';
import 'package:smh_front/pages/forgot.password.page.dart';
import 'package:smh_front/pages/order.dashboard.dart';
import 'package:smh_front/pages/otp.code.page.dart';
import 'package:smh_front/pages/password.reset.page.dart';
import 'package:smh_front/pages/purshase.history.page.dart';
import 'package:smh_front/pages/settings.page.dart';
import 'package:smh_front/pages/user.profile.dart';
import 'package:smh_front/pages/welcome.page.dart';
import 'package:smh_front/services/system.dart';
import 'package:smh_front/widgets/home.page.dart';

void main() {
  System.init(apiUrl: 'http://49.13.197.63:8003/api');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMH+ Application',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro Display',
      ),
      routes: {
        '/forgot_password': (context) => ForgotPasswordPage(),
        '/reset-password': (context) => PasswordResetPage(),
        '/profile': (context) => UserProfilePage(userId: 1),
        '/otp': (context) => OTPCodePage(),
        '/home': (context) => HomePage(),
        '/settings': (context) => SettingPage(),
        '/commercials': (context) => CommercialDashboard(),
        '/orders': (context) => OrderDashboad(),
        '/history': (context) => PurchaseHistoryPage(),
      },
      home: SMHWelcomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
