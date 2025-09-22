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
