import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'product.detail.page.dart';

// ===============================
// MODÈLES ADDITIONNELS
// ===============================

class Neighborhood {
  final int id;
  final String name;
  final int arrondissementId;

  Neighborhood({
    required this.id,
    required this.name,
    required this.arrondissementId,
  });

  factory Neighborhood.fromJson(Map<String, dynamic> json) {
    return Neighborhood(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      arrondissementId: json['arrondissementId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'arrondissementId': arrondissementId};
  }
}

// ===============================
// SERVICES
// ===============================

// Service mis à jour pour la gestion des commandes
class PaymentService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String baseUrl = 'http://49.13.197.63:8006';

  // Récupérer les informations utilisateur du stockage local
  static Future<UserInfo?> getUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInfoData = prefs.getString('user_info');
      if (userInfoData != null) {
        return UserInfo.fromJson(jsonDecode(userInfoData));
      }
    } catch (e) {
      print("Erreur lors de la récupération des infos utilisateur: $e");
    }
    return null;
  }

  // Sauvegarder les informations utilisateur
  static Future<void> saveUserInfo(UserInfo userInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_info', jsonEncode(userInfo.toJson()));
    } catch (e) {
      throw Exception("Erreur lors de la sauvegarde des infos utilisateur: $e");
    }
  }

  // Récupérer les modes de paiement
  static Future<List<PaymentFee>> getPaymentMethods() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception("Token non trouvé. Veuillez vous connecter.");
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/api/orders/fees/'),
            headers: {
              "Accept": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return (data['data'] as List)
              .map((fee) => PaymentFee.fromJson(fee))
              .where((fee) => fee.active)
              .toList();
        }
      }
      throw Exception("Erreur ${response.statusCode}");
    } catch (e) {
      throw Exception("Erreur lors du chargement des modes de paiement: $e");
    }
  }
}

// Service intégré pour la gestion des commandes avec quartiers
class IntegratedOrderService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String baseUrl = 'http://49.13.197.63';

  // Récupérer les quartiers d'un district
  // Récupérer les quartiers d'un district
  static Future<List<Neighborhood>> getNeighborhoods(int districtId) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception("Token non trouvé. Veuillez vous connecter.");
      }

      final response = await http
          .get(
            Uri.parse(
              '$baseUrl:8002/api/geography/districts/$districtId/neighborhoods',
            ),
            headers: {
              "Accept": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null) {
          return (data['data'] as List)
              .map((neighborhood) => Neighborhood.fromJson(neighborhood))
              .toList();
        }
      }

      throw Exception("Erreur ${response.statusCode}: ${response.body}");
    } catch (e) {
      throw Exception("Erreur lors du chargement des quartiers: $e");
    }
  }

  // Récupérer les informations utilisateur depuis SharedPreferences
  static Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      // Récupérer directement depuis FlutterSecureStorage
      final userId = await _storage.read(key: 'user_id');
      final userRole = await _storage.read(key: 'user_role');

      if (userId != null) {
        print("=== DONNÉES UTILISATEUR TROUVÉES ===");
        print("User ID: $userId");
        print("User Role: $userRole");

        return {
          'id': int.tryParse(userId) ?? 0,
          'userId': int.tryParse(userId) ?? 0,
          'role': userRole ?? 'CLIENT',
        };
      }

      print("Aucune donnée utilisateur trouvée dans SecureStorage");
      return null;
    } catch (e) {
      print("Erreur lors de la récupération de l'utilisateur: $e");
      return null;
    }
  }

  // Méthode de debug pour voir tout le contenu de SharedPreferences
  static Future<void> debugSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      print("=== DEBUG SHARED PREFERENCES ===");
      for (String key in keys) {
        final value = prefs.getString(key);
        print("$key: $value");
      }
      print("=== FIN DEBUG ===");
    } catch (e) {
      print("Erreur debug SharedPreferences: $e");
    }
  }

  // Créer une commande avec les informations de livraison et quartier
  static Future<bool> createOrderWithDeliveryInfo({
    required List<CartItem> cartItems,
    required String recipientName,
    required String recipientPhone,
    required int neighborhoodId,
    required String deliveryType,
    required double totalAmount,
  }) async {
    try {
      await debugSharedPreferences();

      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception("Token non trouvé. Veuillez vous connecter.");
      }

      // Récupérer les informations utilisateur
      final userInfo = await getCurrentUserInfo();
      if (userInfo == null) {
        throw Exception("Informations utilisateur non trouvées");
      }

      // Validation des données obligatoires
      if (cartItems.isEmpty) {
        throw Exception("Le panier est vide");
      }

      if (recipientName.isEmpty || recipientPhone.isEmpty) {
        throw Exception("Les informations du destinataire sont obligatoires");
      }

      if (neighborhoodId <= 0) {
        throw Exception("Le quartier de livraison est obligatoire");
      }

      // Conversion du type de livraison
      String apiDeliveryType = 'INTERNAL'; // Valeur par défaut

      // Préparation des items de commande
      final orderItems = cartItems.map((cartItem) {
        return {
          'productId': cartItem.productId,
          'quantity': cartItem.quantity,
          'amountToSpend':
              cartItem.totalPrice, // Utiliser le prix de l'item, pas le total
        };
      }).toList();

      // Construction de la requête avec toutes les validations
      final orderRequest = {
        'userId': userInfo['id'] ?? userInfo['userId'] ?? 0,
        'deliveryType': apiDeliveryType,
        'userType': userInfo['role'] ?? 'CLIENT',
        'recipientName': recipientName,
        'recipientPhone': recipientPhone,
        'neighborhoodId': neighborhoodId,
        'items': orderItems,
      };

      // Vérification finale des données
      print("=== VÉRIFICATION DES DONNÉES ===");
      print("User ID: ${orderRequest['userId']}");
      print("Delivery Type: ${orderRequest['deliveryType']}");
      print("User Type: ${orderRequest['userType']}");
      print("Recipient Name: ${orderRequest['recipientName']}");
      print("Recipient Phone: ${orderRequest['recipientPhone']}");
      print("Neighborhood ID: ${orderRequest['neighborhoodId']}");
      print("Number of items: ${orderItems.length}");
      print("Items details: $orderItems");
      print("=== FIN VÉRIFICATION ===");

      final response = await http
          .post(
            Uri.parse('$baseUrl:8006/api/orders/'),
            headers: {
              "Accept": "application/json",
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(orderRequest),
          )
          .timeout(const Duration(seconds: 30));

      print("Réponse API commande: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // Analyser la réponse d'erreur
        try {
          final errorData = jsonDecode(response.body);
          throw Exception("Erreur API: ${errorData['text'] ?? response.body}");
        } catch (e) {
          throw Exception("Erreur ${response.statusCode}: ${response.body}");
        }
      }
    } catch (e) {
      print("Erreur détaillée lors de la création de la commande: $e");
      throw Exception("Erreur lors de la création de la commande: $e");
    }
  }
}

// Service pour la gestion du panier (mis à jour)
class CartService {
  static Future<List<CartItem>> getCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString('cart_items') ?? '[]';
      final List<dynamic> cartList = jsonDecode(cartData);
      return cartList.map((item) => CartItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart_items');
  }

  // Supprimer un article du panier
  static Future<void> removeFromCart(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString('cart_items') ?? '[]';
      List<dynamic> cartList = jsonDecode(cartData);

      // Retirer le produit de la liste
      cartList.removeWhere((item) => item['productId'] == productId);

      await prefs.setString('cart_items', jsonEncode(cartList));
    } catch (e) {
      throw Exception("Erreur lors de la suppression du panier: $e");
    }
  }

  // Mettre à jour la quantité d'un article
  static Future<void> updateCartItemQuantity(
    String productId,
    double newQuantity,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString('cart_items') ?? '[]';
      List<dynamic> cartList = jsonDecode(cartData);

      // Trouver et mettre à jour la quantité
      int index = cartList.indexWhere((item) => item['productId'] == productId);
      if (index >= 0) {
        if (newQuantity <= 0) {
          // Si quantité <= 0, supprimer l'article
          cartList.removeAt(index);
        } else {
          cartList[index]['quantity'] = newQuantity;
        }
        await prefs.setString('cart_items', jsonEncode(cartList));
      }
    } catch (e) {
      throw Exception("Erreur lors de la mise à jour: $e");
    }
  }

  static Future<DeliveryInfo?> getDeliveryInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deliveryData = prefs.getString('delivery_info');
      if (deliveryData != null) {
        return DeliveryInfo.fromJson(jsonDecode(deliveryData));
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  // Sauvegarder les informations de livraison
  static Future<void> saveDeliveryInfo(DeliveryInfo deliveryInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('delivery_info', jsonEncode(deliveryInfo.toJson()));
    } catch (e) {
      throw Exception(
        "Erreur lors de la sauvegarde des infos de livraison: $e",
      );
    }
  }

  // Ajouter un produit au panier (à partir de ProductDetailPage)
  static Future<void> addToCart(Product product, double quantity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString('cart_items') ?? '[]';
      List<dynamic> cartList = jsonDecode(cartData);

      // Créer l'item à partir du produit
      final cartItem = CartItem(
        productId: product.id,
        name: product.name,
        imageUrl: product.imageUrl,
        pricePerUnit: product.pricePerUnit,
        quantity: quantity,
        unit: product.unit,
        districtId: product.districtId, // Ajout du districtId
      );

      // Vérifier si le produit existe déjà dans le panier
      int existingIndex = cartList.indexWhere(
        (item) => item['productId'] == product.id,
      );

      if (existingIndex >= 0) {
        // Mettre à jour la quantité
        cartList[existingIndex]['quantity'] =
            (cartList[existingIndex]['quantity'] as num).toDouble() + quantity;
      } else {
        // Ajouter un nouveau produit
        cartList.add(cartItem.toJson());
      }

      await prefs.setString('cart_items', jsonEncode(cartList));
    } catch (e) {
      throw Exception("Erreur lors de l'ajout au panier: $e");
    }
  }
}

// ===============================
// MODAL DE FINALISATION DE COMMANDE
// ===============================

class OrderFinalizationModal extends StatefulWidget {
  final List<CartItem> cartItems;
  final VoidCallback onOrderSuccess;
  final String deliveryType;
  final double totalAmount;

  const OrderFinalizationModal({
    Key? key,
    required this.cartItems,
    required this.onOrderSuccess,
    required this.deliveryType,
    required this.totalAmount,
  }) : super(key: key);

  @override
  _OrderFinalizationModalState createState() => _OrderFinalizationModalState();
}

class _OrderFinalizationModalState extends State<OrderFinalizationModal> {
  final _formKey = GlobalKey<FormState>();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();

  List<Neighborhood> neighborhoods = [];
  Neighborhood? selectedNeighborhood;
  int? districtId;

  bool isLoadingNeighborhoods = false;
  bool isSubmittingOrder = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeDistrictAndLoadNeighborhoods();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await PaymentService.getUserInfo();
      if (userInfo != null) {
        setState(() {
          _recipientNameController.text = userInfo.recipientName;
          _recipientPhoneController.text = userInfo.recipientPhone;
        });
      }
    } catch (e) {
      print("Erreur lors du chargement des infos utilisateur: $e");
    }
  }

  @override
  void dispose() {
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    super.dispose();
  }

  Future<void> _initializeDistrictAndLoadNeighborhoods() async {
    // Récupérer le districtId du premier produit du panier
    if (widget.cartItems.isNotEmpty) {
      final firstItem = widget.cartItems.first;

      if (firstItem.districtId != 0) {
        districtId = firstItem.districtId;
        await _loadNeighborhoods();
      } else {
        setState(() {
          errorMessage = 'Impossible de déterminer la zone de livraison';
        });
      }
    }
  }

  Future<void> _loadNeighborhoods() async {
    if (districtId == null) return;

    setState(() {
      isLoadingNeighborhoods = true;
      errorMessage = '';
    });

    try {
      final neighborhoodList = await IntegratedOrderService.getNeighborhoods(
        districtId!,
      );
      if (mounted) {
        setState(() {
          neighborhoods = neighborhoodList;
          isLoadingNeighborhoods = false;

          // Sélectionner automatiquement le premier quartier s'il n'y en a qu'un
          if (neighborhoods.length == 1) {
            selectedNeighborhood = neighborhoods.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingNeighborhoods = false;
          errorMessage = 'Erreur lors du chargement des quartiers';
        });
      }
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedNeighborhood == null) {
      _showSnackBar('Veuillez sélectionner un quartier', Colors.red);
      return;
    }

    setState(() {
      isSubmittingOrder = true;
    });

    try {
      // Sauvegarder les informations utilisateur pour les prochaines commandes
      final userInfo = UserInfo(
        userId: 0, // Serait récupéré de l'API
        recipientName: _recipientNameController.text.trim(),
        recipientPhone: _recipientPhoneController.text.trim(),
        neighborhoodId: selectedNeighborhood!.id,
      );
      await PaymentService.saveUserInfo(userInfo);

      final success = await IntegratedOrderService.createOrderWithDeliveryInfo(
        cartItems: widget.cartItems,
        recipientName: _recipientNameController.text.trim(),
        recipientPhone: _recipientPhoneController.text.trim(),
        neighborhoodId: selectedNeighborhood!.id,
        deliveryType: widget.deliveryType,
        totalAmount: widget.totalAmount,
      );

      if (success) {
        // Vider le panier
        await CartService.clearCart();

        if (mounted) {
          Navigator.of(context).pop(); // Fermer le modal
          widget.onOrderSuccess(); // Callback de succès
          _showSuccessDialog();
        }
      } else {
        _showSnackBar('Erreur lors de la création de la commande', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          isSubmittingOrder = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Commande créée'),
          ],
        ),
        content: const Text(
          'Votre commande a été créée avec succès. Vous recevrez une confirmation.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer le dialog de succès
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Finaliser la commande',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Résumé de la commande
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Résumé de la commande:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...widget.cartItems
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.name} (${item.quantity} ${item.unit})',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    '${item.totalPrice.toInt()} FCFA',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total avec commissions:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${widget.totalAmount.toInt()} FCFA',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A90E2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Nom du destinataire
                TextFormField(
                  controller: _recipientNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du destinataire *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est obligatoire';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Téléphone du destinataire
                TextFormField(
                  controller: _recipientPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone du destinataire *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le téléphone est obligatoire';
                    }
                    if (!RegExp(r'^[0-9]{9,15}$').hasMatch(value)) {
                      return 'Numéro de téléphone invalide';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Sélection du quartier
                if (isLoadingNeighborhoods)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (neighborhoods.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Text(
                      errorMessage.isNotEmpty
                          ? errorMessage
                          : 'Aucun quartier disponible pour cette zone',
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                else
                  DropdownButtonFormField<Neighborhood>(
                    value: selectedNeighborhood,
                    decoration: const InputDecoration(
                      labelText: 'Quartier de livraison *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    items: neighborhoods.map((neighborhood) {
                      return DropdownMenuItem<Neighborhood>(
                        value: neighborhood,
                        child: Text(neighborhood.name),
                      );
                    }).toList(),
                    onChanged: (Neighborhood? value) {
                      setState(() {
                        selectedNeighborhood = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner un quartier';
                      }
                      return null;
                    },
                  ),

                const SizedBox(height: 12),

                // Mode de livraison (information seulement)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF4A90E2).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.deliveryType == 'instant'
                            ? Icons.flash_on
                            : Icons.schedule,
                        color: const Color(0xFF4A90E2),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.deliveryType == 'instant'
                            ? 'Livraison instantanée (moins de 60 minutes)'
                            : 'Livraison programmée (plus de 60 minutes)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmittingOrder ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: isSubmittingOrder ? null : _submitOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A90E2),
            foregroundColor: Colors.white,
          ),
          child: isSubmittingOrder
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Confirmer'),
        ),
      ],
    );
  }
}

// ===============================
// PAGE PRINCIPALE
// ===============================

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  List<CartItem> cartItems = [];
  List<PaymentFee> paymentMethods = [];
  DeliveryInfo? deliveryInfo;

  bool isLoadingPaymentMethods = true;
  bool isLoadingCart = true;
  bool isSubmittingOrder = false;
  String errorMessage = '';

  double subtotal = 0.0;
  double totalFees = 0.0;
  double total = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCartItems(),
      _loadPaymentMethods(),
      _loadDeliveryInfo(),
    ]);
    _calculateTotals();
  }

  Future<void> _loadCartItems() async {
    try {
      final items = await CartService.getCartItems();
      if (mounted) {
        setState(() {
          cartItems = items;
          isLoadingCart = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingCart = false;
          errorMessage = "Erreur lors du chargement du panier";
        });
      }
    }
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await PaymentService.getPaymentMethods();
      if (mounted) {
        setState(() {
          paymentMethods = methods;
          isLoadingPaymentMethods = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingPaymentMethods = false;
          errorMessage = "Erreur lors du chargement des modes de paiement";
        });
      }
    }
  }

  Future<void> _loadDeliveryInfo() async {
    try {
      final info = await CartService.getDeliveryInfo();
      if (mounted) {
        setState(() {
          deliveryInfo = info ?? DeliveryInfo(type: 'instant');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          deliveryInfo = DeliveryInfo(type: 'instant');
        });
      }
    }
  }

  void _calculateTotals() {
    subtotal = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

    // Calculer les frais de TOUS les modes de paiement automatiquement
    totalFees = 0.0;
    for (final method in paymentMethods) {
      if (method.type == 'PERCENTAGE') {
        totalFees += subtotal * method.value;
      } else if (method.type == 'FIXED_AMOUNT') {
        totalFees += method.value;
      }
    }

    total = subtotal + totalFees;

    if (mounted) {
      setState(() {});
    }
  }

  void _onDeliveryTypeChanged(String? type) {
    if (type != null) {
      setState(() {
        if (type == 'instant') {
          deliveryInfo = DeliveryInfo(type: type);
        } else {
          deliveryInfo = DeliveryInfo(
            type: type,
            scheduledDate: DateTime.now().add(const Duration(days: 1)),
            scheduledTime: '15:30',
          );
        }
      });

      // Sauvegarder les nouvelles informations de livraison
      CartService.saveDeliveryInfo(deliveryInfo!);
    }
  }

  void _showDateTimePicker() async {
    // Sélection de la date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          deliveryInfo?.scheduledDate ??
          DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4A90E2)),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Sélection de l'heure
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          DateTime.tryParse(
                "2023-01-01 ${deliveryInfo?.scheduledTime ?? '15:30'}:00",
              ) ??
              DateTime(2023, 1, 1, 15, 30),
        ),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFF4A90E2)),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          deliveryInfo = DeliveryInfo(
            type: 'scheduled',
            scheduledDate: pickedDate,
            scheduledTime:
                '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}',
          );
        });

        // Sauvegarder les nouvelles informations
        CartService.saveDeliveryInfo(deliveryInfo!);
      }
    }
  }

  Future<void> _removeCartItem(String productId) async {
    try {
      await CartService.removeFromCart(productId);
      await _loadCartItems(); // Recharger les données du panier
      _calculateTotals();

      _showSnackBar("Produit supprimé du panier", Colors.orange);
    } catch (e) {
      _showSnackBar("Erreur lors de la suppression: $e", Colors.red);
    }
  }

  Future<void> _showEditQuantityDialog(CartItem item) async {
    double newQuantity = item.quantity;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Modifier la quantité'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (newQuantity > 0.25) {
                        setDialogState(() {
                          newQuantity -= (item.unit.toUpperCase() == 'KG'
                              ? 0.25
                              : item.unit.toUpperCase() == 'G'
                              ? 250
                              : 0.5);
                          if (newQuantity < 0) newQuantity = 0.25;
                        });
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    color: const Color(0xFF4A90E2),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${newQuantity} ${item.unit}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setDialogState(() {
                        newQuantity += (item.unit.toUpperCase() == 'KG'
                            ? 0.25
                            : item.unit.toUpperCase() == 'G'
                            ? 250
                            : 0.5);
                      });
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    color: const Color(0xFF4A90E2),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Prix: ${(item.pricePerUnit * newQuantity).toInt()} FCFA',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4A90E2),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await CartService.updateCartItemQuantity(
                    item.productId,
                    newQuantity,
                  );
                  await _loadCartItems(); // Recharger les données
                  _calculateTotals();
                  Navigator.pop(context);
                  _showSnackBar("Quantité mise à jour", Colors.green);
                } catch (e) {
                  _showSnackBar(
                    "Erreur lors de la mise à jour: $e",
                    Colors.red,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  // Méthode mise à jour pour confirmer la commande
  Future<void> _confirmOrder() async {
    if (cartItems.isEmpty) {
      _showSnackBar("Votre panier est vide", Colors.red);
      return;
    }

    // Déterminer le type de livraison selon le timing
    String deliveryType = deliveryInfo?.type == 'scheduled'
        ? 'scheduled'
        : 'instant';

    // Afficher le modal de finalisation de commande
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OrderFinalizationModal(
        cartItems: cartItems,
        deliveryType: deliveryType,
        totalAmount: total,
        onOrderSuccess: () {
          // Callback après succès de la commande
          setState(() {
            cartItems = [];
          });
          _calculateTotals();
        },
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDeleteConfirmation(CartItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text(
              'Confirmer la suppression',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${item.name}" de votre panier ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeCartItem(item.productId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary() {
    if (isLoadingCart) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
        ),
      );
    }

    if (cartItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Votre panier est vide',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Liste des produits',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        ...cartItems.map((item) => _buildCartItem(item)).toList(),
      ],
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Image du produit
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: item.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image, color: Colors.grey);
                      },
                    ),
                  )
                : const Icon(Icons.image, color: Colors.grey),
          ),
          const SizedBox(width: 12),

          // Informations du produit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} ${item.unit}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Prix
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.totalPrice.toInt()} FCFA',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              // Icônes d'action (modifier, supprimer)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _showEditQuantityDialog(item),
                    icon: const Icon(
                      Icons.edit,
                      size: 20,
                      color: Color(0xFF4A90E2),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    onPressed: () => _showDeleteConfirmation(item),
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    if (deliveryInfo == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mode de livraison',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),

        // Livraison instantanée
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: deliveryInfo!.type == 'instant'
                  ? const Color(0xFF4A90E2)
                  : Colors.grey[300]!,
              width: deliveryInfo!.type == 'instant' ? 2 : 1,
            ),
          ),
          child: RadioListTile<String>(
            title: const Text(
              'Livraison instantanée',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Moins de 60 Minutes'),
            value: 'instant',
            groupValue: deliveryInfo!.type,
            activeColor: const Color(0xFF4A90E2),
            onChanged: _onDeliveryTypeChanged,
          ),
        ),

        // Livraison programmée
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: deliveryInfo!.type == 'scheduled'
                  ? const Color(0xFF4A90E2)
                  : Colors.grey[300]!,
              width: deliveryInfo!.type == 'scheduled' ? 2 : 1,
            ),
          ),
          child: RadioListTile<String>(
            title: const Text(
              'Livraison programmée',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text('Plus de 60 Minutes'),
            value: 'scheduled',
            groupValue: deliveryInfo!.type,
            activeColor: const Color(0xFF4A90E2),
            onChanged: _onDeliveryTypeChanged,
          ),
        ),

        // Options pour livraison programmée
        if (deliveryInfo!.type == 'scheduled') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4A90E2).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choisissez les modalités de livraison',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 12),

                // Date sélectionnée
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: InkWell(
                    onTap: _showDateTimePicker,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF4A90E2),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              deliveryInfo!.scheduledDate != null
                                  ? '${deliveryInfo!.scheduledDate!.day.toString().padLeft(2, '0')}-${deliveryInfo!.scheduledDate!.month.toString().padLeft(2, '0')}-${deliveryInfo!.scheduledDate!.year}'
                                  : '20-09-2025',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Heure sélectionnée
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: InkWell(
                    onTap: _showDateTimePicker,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Color(0xFF4A90E2),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Heure',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              deliveryInfo!.scheduledTime ?? '15:30',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentMethods() {
    if (isLoadingPaymentMethods) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
        ),
      );
    }

    if (paymentMethods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Aucun mode de paiement disponible',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modes de paiement applicables',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const Text(
          'Toutes les commissions sont automatiquement appliquées',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        ...paymentMethods
            .map((method) => _buildPaymentMethodTile(method))
            .toList(),
      ],
    );
  }

  Widget _buildPaymentMethodTile(PaymentFee method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF4A90E2).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(Icons.payment, color: const Color(0xFF4A90E2)),
        title: Text(
          method.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(method.description),
            const SizedBox(height: 4),
            Text(
              method.type == 'PERCENTAGE'
                  ? '${(method.value * 100).toStringAsFixed(1)}% du sous-total = ${(subtotal * method.value).toInt()} FCFA'
                  : '${method.value.toInt()} FCFA',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4A90E2),
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.check_circle, color: Colors.green, size: 20),
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4A90E2).withOpacity(0.1),
            const Color(0xFF4A90E2).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sous-total produits:'),
              Text('${subtotal.toInt()} FCFA'),
            ],
          ),
          if (paymentMethods.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...paymentMethods.map((method) {
              double fee = method.type == 'PERCENTAGE'
                  ? subtotal * method.value
                  : method.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${method.name}:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                    Text(
                      '${fee.toInt()} FCFA',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total commissions:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                Text(
                  '${totalFees.toInt()} FCFA',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total à payer:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${total.toInt()} FCFA',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A90E2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erreur'),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      errorMessage = '';
                      isLoadingCart = true;
                      isLoadingPaymentMethods = true;
                    });
                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                  ),
                  child: const Text(
                    'Réessayer',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mon Panier',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé du panier
            _buildCartSummary(),

            const SizedBox(height: 24),

            // Informations de livraison
            _buildDeliveryInfo(),

            const SizedBox(height: 24),

            // Modes de paiement
            _buildPaymentMethods(),

            // Résumé des prix
            _buildPriceSummary(),

            const SizedBox(height: 100), // Espace pour le bouton
          ],
        ),
      ),

      // Bouton de confirmation
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: 45,
          child: FloatingActionButton.extended(
            onPressed: isSubmittingOrder ? null : _confirmOrder,
            backgroundColor: const Color(0xFFFFB347),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(40),
            ),
            label: isSubmittingOrder
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Confirmation...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF2C3E50),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Valider la commande',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class PaymentFee {
  final int id;
  final String name;
  final String description;
  final String type; // "PERCENTAGE" ou "FIXED_AMOUNT"
  final double value;
  final String? feeCode;
  final bool active;

  PaymentFee({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    this.feeCode,
    required this.active,
  });

  factory PaymentFee.fromJson(Map<String, dynamic> json) {
    return PaymentFee(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      value: (json['value'] is num) ? (json['value'] as num).toDouble() : 0.0,
      feeCode: json['feeCode'],
      active: json['active'] ?? false,
    );
  }
}

// Modèle pour les éléments du panier
class CartItem {
  final String productId;
  final String name;
  final String imageUrl;
  final double pricePerUnit;
  final double quantity;
  final String unit;
  final int districtId; // Ajouté pour récupérer les quartiers

  CartItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.pricePerUnit,
    required this.quantity,
    required this.unit,
    this.districtId = 0, // Valeur par défaut
  });

  double get totalPrice => pricePerUnit * quantity;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'pricePerUnit': pricePerUnit,
      'quantity': quantity,
      'unit': unit,
      'districtId': districtId,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      pricePerUnit: (json['pricePerUnit'] is num)
          ? (json['pricePerUnit'] as num).toDouble()
          : 0.0,
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toDouble()
          : 0.0,
      unit: json['unit'] ?? '',
      districtId: json['districtId'] ?? 0,
    );
  }
}

// Modèle pour les informations de livraison
class DeliveryInfo {
  final String type; // "instant" ou "scheduled"
  final DateTime? scheduledDate;
  final String? scheduledTime;

  DeliveryInfo({required this.type, this.scheduledDate, this.scheduledTime});

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'scheduledTime': scheduledTime,
    };
  }

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryInfo(
      type: json['type'] ?? 'instant',
      scheduledDate: json['scheduledDate'] != null
          ? DateTime.parse(json['scheduledDate'])
          : null,
      scheduledTime: json['scheduledTime'],
    );
  }
}

// Modèle pour la commande complète
class Order {
  final List<CartItem> items;
  final DeliveryInfo deliveryInfo;
  final PaymentFee? selectedPaymentMethod;
  final double subtotal;
  final double totalFees;
  final double total;

  Order({
    required this.items,
    required this.deliveryInfo,
    this.selectedPaymentMethod,
    required this.subtotal,
    required this.totalFees,
    required this.total,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'deliveryInfo': deliveryInfo.toJson(),
      'selectedPaymentMethod': selectedPaymentMethod?.id,
      'subtotal': subtotal,
      'totalFees': totalFees,
      'total': total,
    };
  }
}

// Modèles de données pour les commandes

// Modèle pour les items de commande (format API)
class OrderItem {
  final String productId;
  final double quantity;
  final double amountToSpend;

  OrderItem({
    required this.productId,
    required this.quantity,
    required this.amountToSpend,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'amountToSpend': amountToSpend,
    };
  }
}

// Modèle pour une commande (format API)
class OrderRequest {
  final int userId;
  final String deliveryType;
  final String userType;
  final String recipientName;
  final String recipientPhone;
  final int neighborhoodId;
  final List<OrderItem> items;

  OrderRequest({
    required this.userId,
    required this.deliveryType,
    required this.userType,
    required this.recipientName,
    required this.recipientPhone,
    required this.neighborhoodId,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'deliveryType': deliveryType,
      'userType': userType,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'neighborhoodId': neighborhoodId,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

// Modèle pour les informations utilisateur (à récupérer du stockage local)
class UserInfo {
  final int userId;
  final String recipientName;
  final String recipientPhone;
  final int neighborhoodId;

  UserInfo({
    required this.userId,
    required this.recipientName,
    required this.recipientPhone,
    required this.neighborhoodId,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId'] ?? 0,
      recipientName: json['recipientName'] ?? '',
      recipientPhone: json['recipientPhone'] ?? '',
      neighborhoodId: json['neighborhoodId'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'neighborhoodId': neighborhoodId,
    };
  }
}
