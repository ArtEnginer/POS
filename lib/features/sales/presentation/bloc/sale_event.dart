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
