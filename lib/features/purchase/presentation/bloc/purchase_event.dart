import 'package:equatable/equatable.dart';
import '../../domain/entities/purchase.dart';

abstract class PurchaseEvent extends Equatable {
  const PurchaseEvent();

  @override
  List<Object?> get props => [];
}

class LoadPurchases extends PurchaseEvent {
  const LoadPurchases();
}

class LoadPurchaseById extends PurchaseEvent {
  final String id;

  const LoadPurchaseById(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadPurchasesByDateRange extends PurchaseEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadPurchasesByDateRange(this.startDate, this.endDate);

  @override
  List<Object?> get props => [startDate, endDate];
}

class SearchPurchases extends PurchaseEvent {
  final String query;

  const SearchPurchases(this.query);

  @override
  List<Object?> get props => [query];
}

class CreatePurchase extends PurchaseEvent {
  final Purchase purchase;

  const CreatePurchase(this.purchase);

  @override
  List<Object?> get props => [purchase];
}

class UpdatePurchase extends PurchaseEvent {
  final Purchase purchase;

  const UpdatePurchase(this.purchase);

  @override
  List<Object?> get props => [purchase];
}

class DeletePurchase extends PurchaseEvent {
  final String id;

  const DeletePurchase(this.id);

  @override
  List<Object?> get props => [id];
}

class GeneratePurchaseNumber extends PurchaseEvent {
  const GeneratePurchaseNumber();
}

class ReceivePurchaseEvent extends PurchaseEvent {
  final String id;

  const ReceivePurchaseEvent(this.id);

  @override
  List<Object?> get props => [id];
}
