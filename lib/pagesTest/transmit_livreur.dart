import 'package:flutter/material.dart';
import 'package:smh_front/models/order.dart';
import 'package:smh_front/models/user.dart';
import 'package:smh_front/services/order_service.dart';

class TransmitLivreurPage extends StatefulWidget {
  final int orderId;
  final OrderService orderService;

  const TransmitLivreurPage({Key? key, required this.orderId, required this.orderService})
    : super(key: key);

  @override
  State<TransmitLivreurPage> createState() => _TransmissionLivreurPageState();
}

class _TransmissionLivreurPageState extends State<TransmitLivreurPage> {
  Order? orderDetails;
  List<User> livreurs = [];
  bool isLoading = true;
  bool isLoadingLivreurs = true;
  String? error;
  User? selectedLivreur;
  TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
  }

  Future<void> fetchOrderDetails() async {
    try {
      final order = await widget.orderService.getOrder(id: widget.orderId);
      setState(() {
        orderDetails = order;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Erreur lors du chargement de la commande: $e';
        isLoading = false;
      });
    }
  }

  Future<void> confirmTransmission() async {
    if (selectedLivreur == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un livreur'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final order = await widget.orderService.assignOrderToShopper(
        orderId: widget.orderId,
        shopperId: selectedLivreur!.id!,
      );

      Navigator.of(context).pop(); // Fermer le loading

      if (true) { // si il y a erreur, une exception est levée et le block 'catch' est exécuté
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600]),
                const SizedBox(width: 8),
                const Text('Transmission confirmée'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'La commande #COM-${orderDetails!.id} a été assignée avec succès à :',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selectedLivreur!.firstName} ${selectedLivreur!.lastName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text('📱 ${selectedLivreur!.phoneNumber}'),
                      Text(
                        '⭐ Note: ${selectedLivreur!.shopperAverageRating}/5',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '📧 Une notification a été envoyée au livreur.',
                  style: TextStyle(
                    color: Colors.green,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la transmission'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Fermer le loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Transmission Livreur',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    error!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isLoading = true;
                        error = null;
                      });
                      fetchOrderDetails();
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête de la commande
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Commande #COM-${orderDetails!.id}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(orderDetails!.status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 14,
                                    color: _getStatusTextColor(
                                      orderDetails!.status,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getStatusText(orderDetails!.status),
                                    style: TextStyle(
                                      color: _getStatusTextColor(
                                        orderDetails!.status,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Achat terminé • Prêt pour transmission',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Client: ${orderDetails!.recipientName} • ${orderDetails!.recipientPhone}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Résumé de la commande
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total produits',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${orderDetails!.items.length} articles',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Montant total',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${orderDetails!.total.toStringAsFixed(0)} F',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Produits à transmettre
                  const Text(
                    'Produits à transmettre',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Liste des produits groupés par catégorie
                  ..._buildProductCategories(),

                  const SizedBox(height: 24),

                  // Sélection du livreur
                  const Text(
                    'Sélectionner le livreur',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  isLoadingLivreurs
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : livreurs.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Aucun livreur disponible pour le moment',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonFormField<UserData>(
                            value: selectedLivreur,
                            hint: const Text('Sélectionner un livreur'),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: livreurs.map((livreur) {
                              return DropdownMenuItem(
                                value: livreur,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${livreur.firstName} ${livreur.lastName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '📱 ${livreur.phoneNumber}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getShopperStatusColor(
                                              livreur.shopperStatus,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Text(
                                            _getShopperStatusText(
                                              livreur.shopperStatus,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        ...List.generate(5, (index) {
                                          return Icon(
                                            index <
                                                    livreur.shopperAverageRating
                                                        .floor()
                                                ? Icons.star
                                                : Icons.star_outline,
                                            size: 12,
                                            color: Colors.amber,
                                          );
                                        }),
                                        const SizedBox(width: 4),
                                        Text(
                                          '(${livreur.shopperAverageRating.toStringAsFixed(1)})',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedLivreur = value;
                              });
                            },
                          ),
                        ),

                  const SizedBox(height: 24),

                  // Notes
                  const Text(
                    'Notes (optionnel)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Ajouter des notes sur la transmission...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Bouton de confirmation
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: livreurs.isEmpty ? null : confirmTransmission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B365D),
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.send,
                            color: livreurs.isEmpty
                                ? Colors.grey[600]
                                : Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Confirmer la transmission',
                            style: TextStyle(
                              color: livreurs.isEmpty
                                  ? Colors.grey[600]
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Le livreur recevra une notification instantanée',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Color(0xFF1B365D)),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF1B365D),
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          currentIndex: 1,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProductCategories() {
    Map<String, List<OrderItem>> categorizedItems = {};

    for (var item in orderDetails!.items) {
      String categoryName = _getCategoryName(item.productId);
      if (categorizedItems[categoryName] == null) {
        categorizedItems[categoryName] = [];
      }
      categorizedItems[categoryName]!.add(item);
    }

    return categorizedItems.entries.map((entry) {
      String categoryName = entry.key;
      List<OrderItem> items = entry.value;
      double totalAmount = items.fold(
        0.0,
        (sum, item) => sum + item.amountToSpend,
      );

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getCategoryColor(items.first.productId),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(items.first.productId),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${items.length} article${items.length > 1 ? 's' : ''} • ${totalAmount.toStringAsFixed(0)} F',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange[100]!;
      case 'paid':
        return Colors.green[100]!;
      case 'cancelled':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange[800]!;
      case 'paid':
        return Colors.green[800]!;
      case 'cancelled':
        return Colors.red[800]!;
      default:
        return Colors.grey[800]!;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'paid':
        return 'Payé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  Color _getShopperStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'busy':
        return Colors.orange;
      case 'offline':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getShopperStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'DISPONIBLE';
      case 'busy':
        return 'OCCUPÉ';
      case 'offline':
        return 'HORS LIGNE';
      default:
        return status.toUpperCase();
    }
  }

  Color _getCategoryColor(String productId) {
    int hash = productId.hashCode;
    List<Color> colors = [
      Colors.blue[300]!,
      Colors.green[300]!,
      Colors.purple[300]!,
      Colors.orange[300]!,
      Colors.teal[300]!,
      Colors.pink[300]!,
    ];
    return colors[hash.abs() % colors.length];
  }

  IconData _getCategoryIcon(String productId) {
    int hash = productId.hashCode;
    List<IconData> icons = [
      Icons.shopping_basket,
      Icons.eco,
      Icons.local_drink,
      Icons.bakery_dining,
      Icons.local_grocery_store,
      Icons.restaurant,
    ];
    return icons[hash.abs() % icons.length];
  }

  String _getCategoryName(String productId) {
    int hash = productId.hashCode;
    List<String> names = [
      'Produits frais',
      'Légumes bio',
      'Boissons',
      'Boulangerie',
      'Épicerie',
      'Restauration',
    ];
    return names[hash.abs() % names.length];
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }
}
