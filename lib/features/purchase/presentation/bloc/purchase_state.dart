import 'package:equatable/equatable.dart';
import '../../domain/entities/purchase.dart';

abstract class PurchaseState extends Equatable {
  const PurchaseState();

  @override
  List<Object?> get props => [];
}

class PurchaseInitial extends PurchaseState {
  const PurchaseInitial();
}

class PurchaseLoading extends PurchaseState {
  const PurchaseLoading();
}

class PurchaseLoaded extends PurchaseState {
  final List<Purchase> purchases;

  const PurchaseLoaded(this.purchases);

  @override
  List<Object?> get props => [purchases];
}

class PurchaseDetailLoaded extends PurchaseState {
  final Purchase purchase;

  const PurchaseDetailLoaded(this.purchase);

  @override
  List<Object?> get props => [purchase];
}

class PurchaseNumberGenerated extends PurchaseState {
  final String purchaseNumber;

  const PurchaseNumberGenerated(this.purchaseNumber);

  @override
  List<Object?> get props => [purchaseNumber];
}

class PurchaseOperationSuccess extends PurchaseState {
  final String message;
  final Purchase? purchase;

  const PurchaseOperationSuccess(this.message, [this.purchase]);

  @override
  List<Object?> get props => [message, purchase];
}

class PurchaseError extends PurchaseState {
  final String message;

  const PurchaseError(this.message);

  @override
  List<Object?> get props => [message];
}
