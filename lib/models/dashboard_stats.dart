class DashboardStats {
  final int pendingOrders;
  final int completedOrders;
  final int declaredPurchases;
  final int deliveredProducts;
  final String totalAmount;

  DashboardStats({
    required this.pendingOrders,
    required this.completedOrders,
    required this.declaredPurchases,
    required this.deliveredProducts,
    required this.totalAmount,
  });
}
