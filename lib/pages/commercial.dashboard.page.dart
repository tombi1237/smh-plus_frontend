import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smh_front/models/order.dart';
import 'package:smh_front/models/user.dart';
import 'package:smh_front/models/neighborhood.dart';
import 'package:smh_front/pages/settings.page.dart';

class CommercialDashboard extends StatefulWidget {
  const CommercialDashboard({Key? key}) : super(key: key);

  @override
  State<CommercialDashboard> createState() => _CommercialDashboard();
}

class _CommercialDashboard extends State<CommercialDashboard>
    with TickerProviderStateMixin {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<Order> _assignedOrders = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Couleurs inspirées du design
  static const Color primaryBlue = Color(0xFF1E3A5F);
  static const Color accentBlue = Color(0xFF2E5984);
  static const Color backgroundGray = Color(0xFFF5F6FA);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color orangeAccent = Color(0xFFF59E0B);
  static const Color greenAccent = Color(0xFF10B981);
  static const Color redAccent = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadOrders();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final String? token = await _storage.read(key: 'auth_token');
      final String? userId = await _storage.read(key: 'user_id');
      final String? userDataString = await _storage.read(key: 'user_data');

      if (token != null && userId != null && userDataString != null) {
        final userData = jsonDecode(userDataString);

        if (userData['role'] == 'SHOPPER') {
          final assignedResponse = await http.get(
            Uri.parse('http://49.13.197.63:8006/api/orders/commercial/$userId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (assignedResponse.statusCode == 200) {
            final assignedData = jsonDecode(assignedResponse.body);
            if (assignedData['value'] == '200') {
              List<dynamic> ordersData = assignedData['data']['content'] ?? [];
              List<Order> orders = [];

              for (var orderData in ordersData) {
                User? user = await _fetchUserDetails(
                  orderData['userId'],
                  token,
                );
                Neighborhood? neighborhood = await _fetchNeighborhoodDetails(
                  orderData['neighborhoodId'],
                  token,
                );

                Order order = Order.fromJson(
                  orderData,
                  user: user,
                  neighborhood: neighborhood,
                );
                orders.add(order);
              }

              setState(() {
                _assignedOrders = orders;
              });
              _animationController.forward();
            }
          }
        } else {
          setState(() {
            _errorMessage = 'Vous n\'êtes pas autorisé à accéder à cette page';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Utilisateur non connecté';
        });
      }
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _errorMessage = 'Erreur de chargement des commandes';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<User?> _fetchUserDetails(int? userId, String token) async {
    if (userId == null) return null;

    try {
      final response = await http.get(
        Uri.parse('http://49.13.197.63:8001/api/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        if (userData['value'] == '200') {
          return User.fromJson(userData['data']);
        }
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
    return null;
  }

  Future<Neighborhood?> _fetchNeighborhoodDetails(
    int? neighborhoodId,
    String token,
  ) async {
    if (neighborhoodId == null) return null;

    try {
      final response = await http.get(
        Uri.parse('http://49.13.197.63:8001/api/neighborhoods/$neighborhoodId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final neighborhoodData = jsonDecode(response.body);
        if (neighborhoodData['value'] == '200') {
          return Neighborhood.fromJson(neighborhoodData['data']);
        }
      }
    } catch (e) {
      print('Error fetching neighborhood details: $e');
    }
    return null;
  }

  Map<String, int> _calculateStats() {
    int pending = 0;
    int inProgress = 0;
    int completed = 0;

    for (var order in _assignedOrders) {
      String? status = order.status?.toLowerCase();
      switch (status) {
        case 'pending':
          pending++;
          break;
        case 'in_progress':
        case 'inprogress':
          inProgress++;
          break;
        case 'completed':
          completed++;
          break;
      }
    }

    return {
      'pending': pending,
      'inProgress': inProgress,
      'completed': completed,
    };
  }

  double _calculateTotalAmount() {
    return _assignedOrders.fold(
      0.0,
      (sum, order) => sum + (order.total ?? 0.0),
    );
  }

  int _calculateProductsHandled() {
    return _assignedOrders.fold(
      0,
      (sum, order) => sum + (order.items?.length ?? 0),
    );
  }

  Future<void> _refreshOrders() async {
    _animationController.reset();
    await _loadOrders();
  }

  void _navigateToOrderDetails(Order order) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SettingPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) {
      _loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();
    final totalAmount = _calculateTotalAmount();
    final productsHandled = _calculateProductsHandled();

    return Scaffold(
      backgroundColor: backgroundGray,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(fontSize: 16, color: textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header avec logo et notifications
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.of(context).padding.top + 10,
                      20,
                      20,
                    ),
                    decoration: const BoxDecoration(
                      color: cardWhite,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: primaryBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'SMH+',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Commercial SMH+',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  'Poste de Mendong',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: backgroundGray,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.notifications_outlined,
                                      color: primaryBlue,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                if (stats['pending']! > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: const BoxDecoration(
                                        color: redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${stats['pending']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: backgroundGray,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.menu,
                                  color: primaryBlue,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Vue d'ensemble
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Vue d'ensemble",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Cartes statistiques principales
                        Row(
                          children: [
                            Expanded(
                              child: _buildMainStatCard(
                                '${stats['pending']}',
                                'Commandes en attente',
                                'À traiter',
                                orangeAccent,
                                Icons.pending_actions_outlined,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildMainStatCard(
                                '${stats['completed']}',
                                'Commandes',
                                "Aujourd'hui",
                                greenAccent,
                                Icons.check_circle_outline,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),

                        // Actions rapides
                        const Text(
                          'Actions rapides',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildQuickActionCard(
                          'Commandes à traiter',
                          '${stats['pending']} factures en attente',
                          Icons.folder_outlined,
                          orangeAccent,
                          () => {},
                        ),
                        const SizedBox(height: 12),

                        _buildQuickActionCard(
                          'Commandes express',
                          'Liste des Urgences',
                          Icons.security_outlined,
                          primaryBlue,
                          () => {},
                        ),
                        const SizedBox(height: 12),

                        _buildQuickActionCard(
                          'Remise au livreur',
                          'Produits à remettre',
                          Icons.local_shipping_outlined,
                          greenAccent,
                          () => {},
                        ),

                        const SizedBox(height: 25),

                        // Résumé du jour
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardWhite,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x08000000),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Résumé du jour',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryBlue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today_outlined,
                                      color: primaryBlue,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              _buildSummaryRow(
                                'Achats déclarés',
                                '${stats['completed']}',
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                'Produits remis',
                                '$productsHandled',
                              ),
                              const SizedBox(height: 12),
                              _buildSummaryRow(
                                'Montant total',
                                '${totalAmount.toStringAsFixed(0)} F',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 100,
                        ), // Espace pour la bottom nav
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMainStatCard(
    String number,
    String title,
    String subtitle,
    Color accentColor,
    IconData icon, {
    String? subtitle2,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            number,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          if (subtitle2 != null)
            Text(
              subtitle2,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return Material(
      color: cardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 8,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: textSecondary)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ],
    );
  }
}
