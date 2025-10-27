import 'package:equatable/equatable.dart';
import '../../domain/entities/sale.dart';

abstract class SaleEvent extends Equatable {
  const SaleEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllSales extends SaleEvent {
  const LoadAllSales();
}

class LoadSaleById extends SaleEvent {
  final String id;

  const LoadSaleById(this.id);

  @override
  List<Object> get props => [id];
}

class LoadSalesByDateRange extends SaleEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadSalesByDateRange(this.startDate, this.endDate);

  @override
  List<Object> get props => [startDate, endDate];
}

class SearchSales extends SaleEvent {
  final String query;

  const SearchSales(this.query);

  @override
  List<Object> get props => [query];
}

class CreateSale extends SaleEvent {
  final Sale sale;

  const CreateSale(this.sale);

  @override
  List<Object> get props => [sale];
}

class UpdateSale extends SaleEvent {
  final Sale sale;

  const UpdateSale(this.sale);

  @override
  List<Object> get props => [sale];
}

class DeleteSale extends SaleEvent {
  final String id;

  const DeleteSale(this.id);

  @override
  List<Object> get props => [id];
}

class GenerateSaleNumber extends SaleEvent {
  const GenerateSaleNumber();
}

class LoadDailySummary extends SaleEvent {
  final DateTime date;

  const LoadDailySummary(this.date);

  @override
  List<Object> get props => [date];
}

// Pending Sale Events
class SavePendingSale extends SaleEvent {
  final String pendingNumber;
  final String? customerId;
  final String? customerName;
  final String savedBy;
  final String? notes;
  final List<dynamic> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;

  const SavePendingSale({
    required this.pendingNumber,
    this.customerId,
    this.customerName,
    required this.savedBy,
    this.notes,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
  });

  @override
  List<Object?> get props => [
    pendingNumber,
    customerId,
    customerName,
    savedBy,
    notes,
    items,
    subtotal,
    tax,
    discount,
    total,
  ];
}

class LoadPendingSales extends SaleEvent {
  const LoadPendingSales();
}

class LoadPendingSaleById extends SaleEvent {
  final String id;

  const LoadPendingSaleById(this.id);

  @override
  List<Object> get props => [id];
}

class DeletePendingSale extends SaleEvent {
  final String id;

  const DeletePendingSale(this.id);

  @override
  List<Object> get props => [id];
}

class GeneratePendingNumber extends SaleEvent {
  const GeneratePendingNumber();
}
