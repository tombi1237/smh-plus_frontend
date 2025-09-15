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
import 'package:smh_front/services/neighborhood_service.dart';
import 'package:smh_front/services/order_service.dart';
import 'package:smh_front/services/system.dart';
import 'package:smh_front/services/user_service.dart';
import 'package:smh_front/widgets/home.page.dart';

void main() {
  System.init(apiUrl: 'http://49.13.197.63:8003/api');

  // Services initialization
  UserService userService = UserService();
  NeighborhoodService neighborhoodService = NeighborhoodService();
  OrderService orderService = OrderService(
    userService: userService,
    neighborhoodService: neighborhoodService,
  );

  runApp(MyApp(orderService: orderService));
}

class MyApp extends StatelessWidget {
  final OrderService orderService;

  const MyApp({super.key, required this.orderService});

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
        '/home': (context) => HomePage(orderService: orderService),
        '/settings': (context) => SettingPage(),
        '/commercials': (context) => CommercialDashboard(orderService: orderService),
        '/orders': (context) => OrderDashboad(orderService: orderService),
        '/history': (context) => PurchaseHistoryPage(),
      },
      home: SMHWelcomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
