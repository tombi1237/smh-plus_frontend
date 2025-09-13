import 'package:flutter/material.dart';
import 'package:smh_front/models/order_models.dart';
import 'package:smh_front/services/orders_service.dart';

// Page des commandes
class OrderDashboad extends StatefulWidget {
  final String? userToken;

  const OrderDashboad({Key? key, this.userToken}) : super(key: key);

  @override
  State<OrderDashboad> createState() => _CommandesPageState();
}

class _CommandesPageState extends State<OrderDashboad> {
  List<Order> orders = [];
  bool isLoading = true;
  String errorMessage = '';
  String selectedFilter = 'Toutes';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Utilisation du service commun
      final response = await OrdersService.getOrders();

      setState(() {
        orders = response.orders;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  List<Order> get filteredOrders {
    switch (selectedFilter) {
      case 'Non traitées':
        return orders.where((order) => order.status == 'PENDING').toList();
      case 'En cours':
        return orders.where((order) => order.status == 'PROCESSING').toList();
      case 'Complétées':
        return orders.where((order) => order.status == 'PAID').toList();
      default:
        return orders;
    }
  }

  int get nonTraiteesCount =>
      orders.where((order) => order.status == 'PENDING').length;
  int get enCoursCount =>
      orders.where((order) => order.status == 'PROCESSING').length;
  int get completeesCount =>
      orders.where((order) => order.status == 'PAID').length;

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.red;
      case 'PROCESSING':
        return Colors.orange;
      case 'PAID':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING':
        return 'Non traitée';
      case 'PROCESSING':
        return 'En cours';
      case 'PAID':
        return 'Complétée';
      default:
        return status;
    }
  }

  String _formatAmount(double amount) {
    return '${amount.toStringAsFixed(0)} F';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Commandes',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                ),
                onPressed: () {},
              ),
              if (orders.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${orders.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Erreur: $errorMessage',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadOrders,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Cards de statistiques
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          nonTraiteesCount.toString(),
                          'Non traitées',
                          Colors.blue[50]!,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          enCoursCount.toString(),
                          'En cours',
                          Colors.orange[50]!,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          completeesCount.toString(),
                          'Complétées',
                          Colors.green[50]!,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                // Filtres
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterButton('Toutes'),
                        const SizedBox(width: 8),
                        _buildFilterButton('Non traitées'),
                        const SizedBox(width: 8),
                        _buildFilterButton('En cours'),
                        const SizedBox(width: 8),
                        _buildFilterButton('Complétées'),
                      ],
                    ),
                  ),
                ),

                // Liste des commandes
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadOrders,
                    child: orders.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucune commande trouvée',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = filteredOrders[index];
                              return _buildOrderCard(
                                context,
                                order,
                              ); // Passez le context ici
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(
    String number,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: textColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text) {
    final isSelected = selectedFilter == text;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = text;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return GestureDetector(
      onTap: () {
        // Navigation vers la page TransmissionLivreurPage
        Navigator.pushNamed(
          context,
          '/transmission',
          arguments: {'orderId': 1},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... le reste du contenu existant de la carte ...
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order N°${order.id.toString().padLeft(3, '0')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      order.recipientName,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _formatAmount(order.total),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${order.items.length} produit${order.items.length > 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${DateTime.now().hour}:00',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Livraison: ${_getDeliveryLocation(order.neighborhoodId)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [Icon(Icons.chevron_right, color: Colors.grey[400])],
            ),
          ],
        ),
      ),
    );
  }

  String _getDeliveryLocation(int neighborhoodId) {
    // Mapper les IDs de quartier aux noms réels
    switch (neighborhoodId) {
      case 789:
        return 'Cité de la Paix';
      case 2:
        return 'Ekounou';
      case 8:
        return 'Mvan';
      default:
        return 'Quartier $neighborhoodId';
    }
  }
}
