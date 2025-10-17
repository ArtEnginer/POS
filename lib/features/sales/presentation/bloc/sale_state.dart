import 'package:equatable/equatable.dart';
import '../../domain/entities/sale.dart';

abstract class SaleState extends Equatable {
  const SaleState();

  @override
  List<Object?> get props => [];
}

class SaleInitial extends SaleState {
  const SaleInitial();
}

class SaleLoading extends SaleState {
  const SaleLoading();
}

class SaleLoaded extends SaleState {
  final List<Sale> sales;

  const SaleLoaded(this.sales);

  @override
  List<Object> get props => [sales];
}

class SaleDetailLoaded extends SaleState {
  final Sale sale;

  const SaleDetailLoaded(this.sale);

  @override
  List<Object> get props => [sale];
}

class SaleOperationSuccess extends SaleState {
  final String message;
  final Sale? sale;

  const SaleOperationSuccess(this.message, [this.sale]);

  @override
  List<Object?> get props => [message, sale];
}

class SaleNumberGenerated extends SaleState {
  final String number;

  const SaleNumberGenerated(this.number);

  @override
  List<Object> get props => [number];
}

class DailySummaryLoaded extends SaleState {
  final Map<String, dynamic> summary;

  const DailySummaryLoaded(this.summary);

  @override
  List<Object> get props => [summary];
}

class SaleError extends SaleState {
  final String message;

  const SaleError(this.message);

  @override
  List<Object> get props => [message];
}
