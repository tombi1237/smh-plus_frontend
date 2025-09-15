import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//import 'package:smh_frontend/pages/orderDetail.dart';
import 'package:smh_front/models/order.dart';
import 'package:smh_front/models/user.dart';
import 'package:smh_front/models/neighborhood.dart';
import 'package:smh_front/pages/settings.page.dart';

class OrdersDashboard extends StatefulWidget {
  const OrdersDashboard({Key? key}) : super(key: key);

  @override
  State<OrdersDashboard> createState() => _OrdersDashboardState();
}

class _OrdersDashboardState extends State<OrdersDashboard>
    with TickerProviderStateMixin {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<Order> _assignedOrders = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedFilter = 'Toutes';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Couleurs du thème améliorées
  static const Color primaryBlue = Color(0xFF2C5AA0);
  static const Color accentBlue = Color(0xFF4A90E2);
  static const Color backgroundGray = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A202C);
  static const Color textSecondary = Color(0xFF718096);
  static const Color successGreen = Color(0xFF38A169);
  static const Color warningOrange = Color(0xFFED8936);
  static const Color dangerRed = Color(0xFFE53E3E);
  static const Color pendingBlue = Color(0xFF3182CE);

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

              // Convertir les données en objets Order
              for (var orderData in ordersData) {
                // Récupérer les informations du client et du quartier
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

  // Calculer les statistiques avec les nouveaux modèles
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

  // Filtrer les commandes selon le filtre sélectionné
  List<Order> _getFilteredOrders() {
    switch (_selectedFilter) {
      case 'Non traitées':
        return _assignedOrders
            .where((order) => order.status?.toLowerCase() == 'pending')
            .toList();
      case 'En cours':
        return _assignedOrders
            .where(
              (order) =>
                  order.status?.toLowerCase() == 'in_progress' ||
                  order.status?.toLowerCase() == 'inprogress',
            )
            .toList();
      case 'Complétées':
        return _assignedOrders
            .where((order) => order.status?.toLowerCase() == 'completed')
            .toList();
      default:
        return _assignedOrders;
    }
  }

  String _getStatusText(String? status) {
    if (status == null) return 'Inconnu';

    switch (status.toLowerCase()) {
      case 'pending':
        return 'Non traitée';
      case 'confirmed':
        return 'Confirmée';
      case 'in_progress':
      case 'inprogress':
        return 'En cours';
      case 'completed':
        return 'Complétée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status;
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey.withOpacity(0.1);

    switch (status.toLowerCase()) {
      case 'pending':
        return pendingBlue.withOpacity(0.1);
      case 'confirmed':
        return accentBlue.withOpacity(0.1);
      case 'in_progress':
      case 'inprogress':
        return warningOrange.withOpacity(0.1);
      case 'completed':
        return successGreen.withOpacity(0.1);
      case 'cancelled':
        return dangerRed.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  Color _getStatusTextColor(String? status) {
    if (status == null) return Colors.grey;

    switch (status.toLowerCase()) {
      case 'pending':
        return pendingBlue;
      case 'confirmed':
        return accentBlue;
      case 'in_progress':
      case 'inprogress':
        return warningOrange;
      case 'completed':
        return successGreen;
      case 'cancelled':
        return dangerRed;
      default:
        return Colors.grey;
    }
  }

  Future<void> _refreshOrders() async {
    _animationController.reset();
    await _loadOrders();
  }

  void _navigateToOrderDetails(Order order) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            //OrderDetailsPage(order: order.toJson()),
            SettingPage(),
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
    final filteredOrders = _getFilteredOrders();

    return Scaffold(
      backgroundColor: backgroundGray,
      body: CustomScrollView(
        slivers: [
          // App Bar personnalisé
          SliverAppBar(
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: cardWhite,
            foregroundColor: textPrimary,
            expandedHeight: 80,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  color: cardWhite,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mes Commandes',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  '${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year}',
                                  style: const TextStyle(
                                    color: textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: backgroundGray,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed: _refreshOrders,
                                    icon: const Icon(Icons.refresh_rounded),
                                    color: primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: backgroundGray,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        onPressed: () {},
                                        icon: const Icon(
                                          Icons.notifications_outlined,
                                        ),
                                        color: primaryBlue,
                                      ),
                                    ),
                                    if (stats['pending']! > 0)
                                      Positioned(
                                        right: 6,
                                        top: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: dangerRed,
                                            shape: BoxShape.circle,
                                          ),
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
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Contenu principal
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: primaryBlue),
              ),
            )
          else if (_errorMessage.isNotEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildListDelegate([
                // Cartes de statistiques
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            '${stats['pending']}',
                            'Non traitées',

                            pendingBlue.withOpacity(0.1),
                            pendingBlue,
                            Icons.pending_actions_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '${stats['inProgress']}',
                            'En cours',
                            warningOrange.withOpacity(0.1),
                            warningOrange,
                            Icons.hourglass_empty_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '${stats['completed']}',
                            'Complétées',
                            successGreen.withOpacity(0.1),
                            successGreen,
                            Icons.check_circle_outline_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Filtres
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Toutes', _assignedOrders.length),
                        const SizedBox(width: 12),
                        _buildFilterChip('Non traitées', stats['pending']!),
                        const SizedBox(width: 12),
                        _buildFilterChip('En cours', stats['inProgress']!),
                        const SizedBox(width: 12),
                        _buildFilterChip('Complétées', stats['completed']!),
                      ],
                    ),
                  ),
                ),

                // Liste des commandes
                if (filteredOrders.isEmpty)
                  Container(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Aucune commande trouvée',
                            style: TextStyle(
                              fontSize: 16,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filteredOrders
                      .map(
                        (order) => FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildOrderCard(order),
                        ),
                      )
                      .toList(),

                const SizedBox(height: 20),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String number,
    String label,
    Color backgroundColor,
    Color accentColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: backgroundColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            number,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, int count) {
    bool isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : cardWhite,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? primaryBlue : Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              filter,
              style: TextStyle(
                color: isSelected ? Colors.white : textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final String orderId = order.id?.toString() ?? '0';
    final String status = order.status ?? 'INCONNU';
    final double total = order.total ?? 0.0;
    final String clientName =
        order.user?.firstName != null && order.user?.lastName != null
        ? '${order.user!.firstName} ${order.user!.lastName}'.trim()
        : order.recipientName ?? 'Client inconnu';
    final String clientPhone =
        order.user?.phoneNumber ?? order.recipientPhone ?? '';
    final String neighborhood =
        order.neighborhood?.name ?? 'Quartier non spécifié';
    final int itemCount = order.items?.length ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Material(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: () => _navigateToOrderDetails(order),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade100),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CMD-${orderId.padLeft(4, '0')}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              clientName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusTextColor(status).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusTextColor(status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Informations principales
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${total.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 14,
                                    color: Colors.grey[500],
                                  ),
                                  SizedBox(width: 2),
                                  Text(
                                    '$itemCount produit${itemCount > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Adresse de livraison
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: backgroundGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          neighborhood,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '',
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return months[month];
  }
}
