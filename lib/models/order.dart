

import 'package:smh_front/models/model.dart';
import 'package:smh_front/models/neighborhood.dart';
import 'package:smh_front/models/user.dart';

class Order extends Model {
  final int? id;
  final User? user;
  final String? status;
  final String? recipientName;
  final String? recipientPhone;
  final Neighborhood? neighborhood;
  final List<OrderItem>? items;
  final double? total;
  final double? subTotal;

  const Order({
    this.id,
    this.user,
    this.status,
    this.recipientName,
    this.recipientPhone,
    this.neighborhood,
    this.items,
    this.total,
    this.subTotal,
  });

  factory Order.fromJson(Map<String, dynamic> json, {User ?user, Neighborhood ?neighborhood}) {
    return Order(
      id: json['id'] as int?,
      user: user ?? User(id: json['userId'] as int?, role: json['userType'] as String?),
      status: json['status'] as String?,
      recipientName: json['recipientName'] as String?,
      recipientPhone: json['recipientPhone'] as String?,
      neighborhood: neighborhood ?? Neighborhood(id: json['neighborhoodId'] as int?),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toDouble(),
      subTotal: (json['subTotal'] as num?)?.toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': user?.id,
      'userType': user?.role,
      'status': status,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'neighborhoodId': neighborhood?.id,
      'items': items?.map((e) => e.toJson()).toList(),
      'total': total,
      'subTotal': subTotal,
    };
  }
}

enum OrderStatus {
  pending,
  inProgress,
  completed,
}

class OrderItem {
  final int? id;
  final String? productName;
  final double? estimatedQuantity;
  final double? unit;
  final double? estimatedUnitPrice;

  const OrderItem({this.id, this.productName, this.estimatedQuantity, this.unit, this.estimatedUnitPrice});

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int?,
      productName: json['productName'] as String?,
      estimatedQuantity: (json['estimatedQuantity'] as num?)?.toDouble(),
      unit: (json['unit'] as num?)?.toDouble(),
      estimatedUnitPrice: (json['estimatedUnitPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'estimatedQuantity': estimatedQuantity,
      'unit': unit,
      'estimatedUnitPrice': estimatedUnitPrice,
    };
  }
}
