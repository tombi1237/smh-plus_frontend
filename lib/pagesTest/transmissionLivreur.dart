import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TransmissionLivreurPage extends StatefulWidget {
  final int orderId;
  final String authToken =
      "eyJhbGciOiJIUzM4NCJ9.eyJyb2xlcyI6WyJQUk9EVUNFUiJdLCJtb2JpbGUiOiIrMjM3NjY2NjY2NjYyIiwidXNlcklkIjo4LCJlbWFpbCI6InBhdWwucHJvZHVjdGV1ckBzbWhwbHVzLmNvbSIsInVzZXJuYW1lIjoicGF1bF9wcm9kdWN0ZXVyIiwic3ViIjoicGF1bF9wcm9kdWN0ZXVyIiwiaWF0IjoxNzU3NTc4OTIwLCJleHAiOjE3NTgwMTA5MjB9.MT76WwzAY-U7dw5QswNN7zJmG6YPSIL-HGlZjCBBJLo0bYdiYL9WLOPdpat9fnjb";

  const TransmissionLivreurPage({
    Key? key,
    required this.orderId,
    //required this.authToken,
  }) : super(key: key);

  @override
  State<TransmissionLivreurPage> createState() =>
      _TransmissionLivreurPageState();
}

class _TransmissionLivreurPageState extends State<TransmissionLivreurPage> {
  OrderDetails? orderDetails;
  List<UserData> livreurs = [];
  bool isLoading = true;
  bool isLoadingLivreurs = true;
  String? error;
  UserData? selectedLivreur;
  TextEditingController notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
    fetchLivreurs();
  }

  Future<void> fetchOrderDetails() async {
    try {
      final response = await http.get(
        Uri.parse('http://49.13.197.63:8006/api/orders/${widget.orderId}'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          orderDetails = OrderDetails.fromJson(data['data']);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Erreur lors du chargement de la commande';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Erreur de connexion: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchLivreurs() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://49.13.197.63:8006/api/users?role=SHOPPER&page=0&size=100',
        ),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> usersData = data['data']['content'];

        setState(() {
          livreurs = usersData
              .where(
                (user) => user['role'] == 'SHOPPER' && user['enabled'] == true,
              )
              .map((user) => UserData.fromJson(user))
              .toList();
          isLoadingLivreurs = false;
        });
      } else {
        setState(() {
          isLoadingLivreurs = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingLivreurs = false;
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
      // API call pour assigner la commande au livreur
      final response = await http.post(
        Uri.parse(
          'http://49.13.197.63:8006/api/orders/${widget.orderId}/assign',
        ),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'shopperId': selectedLivreur!.id,
          'notes': notesController.text.isNotEmpty
              ? notesController.text
              : null,
        }),
      );

      Navigator.of(context).pop(); // Fermer le loading

      if (response.statusCode == 200 || response.statusCode == 201) {
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

class OrderDetails {
  final int id;
  final int userId;
  final String userType;
  final String status;
  final String recipientName;
  final String recipientPhone;
  final int neighborhoodId;
  final List<OrderItem> items;
  final double total;
  final double subTotal;

  OrderDetails({
    required this.id,
    required this.userId,
    required this.userType,
    required this.status,
    required this.recipientName,
    required this.recipientPhone,
    required this.neighborhoodId,
    required this.items,
    required this.total,
    required this.subTotal,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    return OrderDetails(
      id: json['id'],
      userId: json['userId'],
      userType: json['userType'],
      status: json['status'],
      recipientName: json['recipientName'],
      recipientPhone: json['recipientPhone'],
      neighborhoodId: json['neighborhoodId'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      total: json['total'].toDouble(),
      subTotal: json['subTotal'].toDouble(),
    );
  }
}

class OrderItem {
  final int id;
  final String productId;
  final double quantity;
  final double amountToSpend;

  OrderItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.amountToSpend,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      productId: json['productId'],
      quantity: json['quantity'].toDouble(),
      amountToSpend: json['amountToSpend'].toDouble(),
    );
  }
}

class UserData {
  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String phoneNumber;
  final String gender;
  final String role;
  final String hireDate;
  final String identityDocumentType;
  final String identityDocumentNumber;
  final double shopperAverageRating;
  final String shopperStatus;
  final bool enabled;
  final Assignment? assignment;

  UserData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.gender,
    required this.role,
    required this.hireDate,
    required this.identityDocumentType,
    required this.identityDocumentNumber,
    required this.shopperAverageRating,
    required this.shopperStatus,
    required this.enabled,
    this.assignment,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      username: json['username'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      gender: json['gender'],
      role: json['role'],
      hireDate: json['hireDate'],
      identityDocumentType: json['identityDocumentType'],
      identityDocumentNumber: json['identityDocumentNumber'],
      shopperAverageRating: (json['shopperAverageRating'] ?? 0.0).toDouble(),
      shopperStatus: json['shopperStatus'] ?? 'OFFLINE',
      enabled: json['enabled'] ?? false,
      assignment: json['assignment'] != null
          ? Assignment.fromJson(json['assignment'])
          : null,
    );
  }
}

class Assignment {
  final int id;
  final int userId;
  final String location;
  final String locationType;
  final String assignedRole;
  final String startDate;
  final String? endDate;
  final String createdAt;
  final bool active;

  Assignment({
    required this.id,
    required this.userId,
    required this.location,
    required this.locationType,
    required this.assignedRole,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    required this.active,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      userId: json['userId'],
      location: json['location'],
      locationType: json['locationType'],
      assignedRole: json['assignedRole'],
      startDate: json['startDate'],
      endDate: json['endDate'],
      createdAt: json['createdAt'],
      active: json['active'],
    );
  }
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: TransmissionLivreurPage(orderId: 1));
  }
}
