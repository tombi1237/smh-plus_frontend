import 'package:flutter/material.dart';
import 'package:smh_front/pages/clients/category.page.dart';
import 'package:smh_front/pages/clients/client.profile.page.dart';
import 'package:smh_front/pages/clients/pages/client.order.history.dart';
import 'package:smh_front/pages/clients/widgets/districts_widget.dart';

class ClientHome extends StatefulWidget {
  const ClientHome({super.key});

  @override
  State<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  int _currentIndex = 0;

  // Les 4 pages
  final List<Widget> _pages = [
    const CategoryPage(),
    Container(
      color: Colors.blue[50],
      child: const Center(child: Text("Cart Page")),
    ),
    ClientProfile(),
    UserOrdersHistory(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Page affichée
      floatingActionButton: GestureDetector(
        onTap: () {
          DistrictsHelper.showDistrictsDropdown(context);
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Color(0xFF1E3A5F), // orange
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.location_on, color: Colors.white, size: 30),
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // bas droite
      // 🚀 Bottom Navigation
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E3A5F),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFF1E3A5F),
            currentIndex: _currentIndex,
            selectedItemColor: const Color(0xFFF4A622),
            unselectedItemColor: Colors.white54,
            showUnselectedLabels: true,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: "Accueil",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined),
                label: "Panier",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.lock_outlined),
                label: "Profil",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                label: "Paramètres",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
