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
