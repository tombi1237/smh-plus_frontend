import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserOrdersHistory extends StatefulWidget {
  const UserOrdersHistory({Key? key}) : super(key: key);

  @override
  State<UserOrdersHistory> createState() => _UserOrdersHistoryState();
}

class _UserOrdersHistoryState extends State<UserOrdersHistory> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<Map<String, dynamic>> orders = [];
  bool _isLoading = true;
  int? currentUserId;

  // Couleurs du thème
  static const Color primaryBlue = Color(0xFF1E3A5F);
  static const Color accentYellow = Color(0xFFFFB800);
  static const Color lightBlue = Color(0xFF4A90E2);

  @override
  void initState() {
    super.initState();
    _loadUserOrders();
  }

  Future<void> _loadUserOrders() async {
    try {
      final userId = await _storage.read(key: 'user_id');
      final token = await _storage.read(key: 'auth_token');

      if (userId != null && token != null) {
        currentUserId = int.parse(userId);
        await _fetchUserOrders(token);
      }
    } catch (e) {
      print('Error loading user orders: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserOrders(String token) async {
    try {
      final response = await http.get(
        Uri.parse('http://49.13.197.63:8006/api/orders/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['value'] == '200') {
          final allOrders = responseData['data']['content'] as List;

          // Filtrer les commandes pour l'utilisateur connecté
          setState(() {
            orders = allOrders
                .where((order) => order['userId'] == currentUserId)
                .cast<Map<String, dynamic>>()
                .toList();

            // Trier par date (plus récent en premier)
            orders.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
          });
        }
      }
    } catch (e) {
      print('Error fetching orders: $e');
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      case 'DELIVERED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return 'Payé';
      case 'PENDING':
        return 'En attente';
      case 'CANCELLED':
        return 'Annulé';
      case 'DELIVERED':
        return 'Livré';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return Icons.payment;
      case 'PENDING':
        return Icons.hourglass_empty;
      case 'CANCELLED':
        return Icons.cancel;
      case 'DELIVERED':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? '';
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;
    final subTotal = (order['subTotal'] as num?)?.toDouble() ?? 0.0;
    final items = order['items'] as List? ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showOrderDetails(order),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête de la commande
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Commande #${order['id']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            size: 14,
                            color: _getStatusColor(status),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusText(status),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Informations de livraison
                if (order['recipientName'] != null) ...[
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order['recipientName'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                if (order['recipientPhone'] != null) ...[
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        order['recipientPhone'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Articles de la commande
                if (items.isNotEmpty) ...[
                  Text(
                    'Articles (${items.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...items
                      .take(3)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[400],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Produit ID: ${item['productId']?.toString().substring(0, 8)}...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              Text(
                                '${item['amountToSpend']?.toStringAsFixed(0)} FCFA',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),

                  if (items.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        '+${items.length - 3} autres articles',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),
                ],

                // Prix total
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sous-total: ${subTotal.toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Total: ${total.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
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

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Contenu des détails
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Détails de la commande #${order['id']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildDetailRow(
                        'Statut',
                        _getStatusText(order['status'] ?? ''),
                        color: _getStatusColor(order['status'] ?? ''),
                      ),
                      _buildDetailRow(
                        'Destinataire',
                        order['recipientName'] ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Téléphone',
                        order['recipientPhone'] ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'Type d\'utilisateur',
                        order['userType'] ?? 'N/A',
                      ),
                      _buildDetailRow(
                        'ID du quartier',
                        order['neighborhoodId']?.toString() ?? 'N/A',
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Articles commandés',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ...(order['items'] as List? ?? [])
                          .map(
                            (item) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ID Produit: ${item['productId']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Quantité: ${item['quantity']?.toString() ?? '0'}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Montant: ${item['amountToSpend']?.toStringAsFixed(0) ?? '0'} FCFA',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),

                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _buildPriceRow(
                              'Sous-total',
                              '${(order['subTotal'] as num?)?.toStringAsFixed(0) ?? '0'} FCFA',
                            ),
                            const Divider(),
                            _buildPriceRow(
                              'Total',
                              '${(order['total'] as num?)?.toStringAsFixed(0) ?? '0'} FCFA',
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: color ?? Colors.black87,
                fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? primaryBlue : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: isTotal ? primaryBlue : Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Historique des commandes',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
              ),
            )
          : orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune commande trouvée',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vos commandes apparaîtront ici',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Commencer mes achats',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Statistiques en haut
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryBlue, lightBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Total commandes',
                        orders.length.toString(),
                        Icons.shopping_cart,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildStatItem(
                        'Montant total',
                        '${orders.fold<double>(0, (sum, order) => sum + ((order['total'] as num?)?.toDouble() ?? 0)).toStringAsFixed(0)} FCFA',
                        Icons.payments,
                      ),
                    ],
                  ),
                ),

                // Filtres de statut
                Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildStatusFilter('Tous', null),
                      _buildStatusFilter('Payé', 'PAID'),
                      _buildStatusFilter('En attente', 'PENDING'),
                      _buildStatusFilter('Livré', 'DELIVERED'),
                      _buildStatusFilter('Annulé', 'CANCELLED'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Liste des commandes
                Expanded(
                  child: RefreshIndicator(
                    color: primaryBlue,
                    onRefresh: _loadUserOrders,
                    child: ListView.builder(
                      itemCount: _getFilteredOrders().length,
                      itemBuilder: (context, index) {
                        final order = _getFilteredOrders()[index];
                        return _buildOrderCard(order);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String? _selectedStatusFilter;

  List<Map<String, dynamic>> _getFilteredOrders() {
    if (_selectedStatusFilter == null) {
      return orders;
    }
    return orders
        .where((order) => order['status'] == _selectedStatusFilter)
        .toList();
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusFilter(String label, String? status) {
    final isSelected = _selectedStatusFilter == status;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : primaryBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatusFilter = selected ? status : null;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: primaryBlue,
        checkmarkColor: Colors.white,
        side: BorderSide(color: isSelected ? primaryBlue : Colors.grey[300]!),
      ),
    );
  }
}
