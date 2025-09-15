import 'package:flutter/material.dart';
import 'package:smh_front/models/user.dart';
import 'package:smh_front/pages/commercial.dashboard.page.dart';
import 'package:smh_front/pages/order.dashboard.dart';
import 'package:smh_front/pages/purshase.history.page.dart';
import 'package:smh_front/pages/settings.page.dart';
import 'package:smh_front/services/order_service.dart';
import 'package:smh_front/widgets/common/common.widget.dart';

class HomePage extends StatefulWidget {
  final OrderService orderService;

  const HomePage({super.key, required this.orderService});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<Widget> pages;

  _HomePageState() {
    pages = <Widget>[
      OrderDashboad(orderService: widget.orderService),
      CommercialDashboard(orderService: widget.orderService),
      PurchaseHistoryPage(),
      SettingPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Scaffold(
        body: pages[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(color: AppColors.bleu),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: Color(0xFFF59E0B),
            unselectedItemColor: Colors.grey[400],
            elevation: 0,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home, size: 30),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_outlined, size: 30),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history, size: 30),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings, size: 30),
                label: '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
