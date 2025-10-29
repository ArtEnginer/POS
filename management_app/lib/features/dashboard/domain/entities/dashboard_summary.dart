import 'package:equatable/equatable.dart';

class DashboardSummary extends Equatable {
  final int totalProducts;
  final int lowStockProducts;
  final int totalCustomers;
  final int totalSuppliers;
  final int totalPurchases;
  final int pendingPurchases;
  final double totalPurchaseAmount;
  final int totalSales;
  final double totalSalesAmount;
  final DateTime lastUpdated;

  const DashboardSummary({
    required this.totalProducts,
    required this.lowStockProducts,
    required this.totalCustomers,
    required this.totalSuppliers,
    required this.totalPurchases,
    required this.pendingPurchases,
    required this.totalPurchaseAmount,
    required this.totalSales,
    required this.totalSalesAmount,
    required this.lastUpdated,
  });

  @override
  List<Object?> get props => [
    totalProducts,
    lowStockProducts,
    totalCustomers,
    totalSuppliers,
    totalPurchases,
    pendingPurchases,
    totalPurchaseAmount,
    totalSales,
    totalSalesAmount,
    lastUpdated,
  ];
}
