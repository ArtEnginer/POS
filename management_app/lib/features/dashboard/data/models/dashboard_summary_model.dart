import '../../domain/entities/dashboard_summary.dart';

class DashboardSummaryModel extends DashboardSummary {
  const DashboardSummaryModel({
    required super.totalProducts,
    required super.lowStockProducts,
    required super.totalCustomers,
    required super.totalSuppliers,
    required super.totalPurchases,
    required super.pendingPurchases,
    required super.totalPurchaseAmount,
    required super.totalSales,
    required super.totalSalesAmount,
    required super.lastUpdated,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      totalProducts: json['total_products'] ?? json['totalProducts'] ?? 0,
      lowStockProducts:
          json['low_stock_products'] ?? json['lowStockProducts'] ?? 0,
      totalCustomers: json['total_customers'] ?? json['totalCustomers'] ?? 0,
      totalSuppliers: json['total_suppliers'] ?? json['totalSuppliers'] ?? 0,
      totalPurchases: json['total_purchases'] ?? json['totalPurchases'] ?? 0,
      pendingPurchases:
          json['pending_purchases'] ?? json['pendingPurchases'] ?? 0,
      totalPurchaseAmount:
          ((json['total_purchase_amount'] ?? json['totalPurchaseAmount']) ?? 0)
              .toDouble(),
      totalSales: json['total_sales'] ?? json['totalSales'] ?? 0,
      totalSalesAmount:
          ((json['total_sales_amount'] ?? json['totalSalesAmount']) ?? 0)
              .toDouble(),
      lastUpdated: DateTime.parse(
        json['last_updated'] ??
            json['lastUpdated'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalProducts': totalProducts,
      'lowStockProducts': lowStockProducts,
      'totalCustomers': totalCustomers,
      'totalSuppliers': totalSuppliers,
      'totalPurchases': totalPurchases,
      'pendingPurchases': pendingPurchases,
      'totalPurchaseAmount': totalPurchaseAmount,
      'totalSales': totalSales,
      'totalSalesAmount': totalSalesAmount,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
