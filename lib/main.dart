import 'package:flutter/material.dart';
import 'package:smh_front/pages/clients/panier.page.dart';
import 'package:smh_front/pages/clients/confirm.payement.page.dart';
import 'package:smh_front/pages/clients/client.home.dart';
import 'package:smh_front/pages/clients/client.profile.page.dart';
import 'package:smh_front/pages/clients/client.welcome.page.dart';
import 'package:smh_front/pages/clients/pages/client.order.history.dart';
import 'package:smh_front/pages/clients/widgets/districts_widget.dart';
import 'package:smh_front/pages/clients/category.page.dart';
import 'package:smh_front/pages/forgot.password.page.dart';
import 'package:smh_front/pages/login.page.dart';
import 'package:smh_front/pages/otp.code.page.dart';
import 'package:smh_front/pages/password.reset.page.dart';
import 'package:smh_front/pages/purshase.history.page.dart';
import 'package:smh_front/pages/user.profile.dart';

import 'package:smh_front/pages/welcome.page.dart';
import 'package:smh_front/pages/clients/auth/client.register.dart';
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
        '/reset-password': (context) => ResetPasswordPage(),
        '/login': (context) => const UserLogin(), //
        '/register': (context) => ClientRegister(),
        '/profile': (context) => ProfilePage(),
        '/otp': (context) => OTPCodePage(),
        '/home': (context) => HomePage(),
        '/history': (context) => PurchaseHistoryPage(),
        '/order_history': (context) => UserOrdersHistory(),
        '/client_page': (context) => const SMHClientHome(),
        '/client_home': (context) => const ClientHome(),
        '/districts': (context) => DistrictsWidget(),
      },
      home: SMHWelcomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
