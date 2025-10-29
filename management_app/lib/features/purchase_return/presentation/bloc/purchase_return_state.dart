import 'package:equatable/equatable.dart';
import '../../domain/entities/purchase_return.dart';

abstract class PurchaseReturnState extends Equatable {
  const PurchaseReturnState();

  @override
  List<Object?> get props => [];
}

class PurchaseReturnInitial extends PurchaseReturnState {
  const PurchaseReturnInitial();
}

class PurchaseReturnLoading extends PurchaseReturnState {
  const PurchaseReturnLoading();
}

class PurchaseReturnLoaded extends PurchaseReturnState {
  final List<PurchaseReturn> purchaseReturns;

  const PurchaseReturnLoaded(this.purchaseReturns);

  @override
  List<Object?> get props => [purchaseReturns];
}

class PurchaseReturnDetailLoaded extends PurchaseReturnState {
  final PurchaseReturn purchaseReturn;

  const PurchaseReturnDetailLoaded(this.purchaseReturn);

  @override
  List<Object?> get props => [purchaseReturn];
}

class PurchaseReturnOperationSuccess extends PurchaseReturnState {
  final String message;
  final PurchaseReturn? purchaseReturn;

  const PurchaseReturnOperationSuccess(this.message, [this.purchaseReturn]);

  @override
  List<Object?> get props => [message, purchaseReturn];
}

class ReturnNumberGenerated extends PurchaseReturnState {
  final String number;

  const ReturnNumberGenerated(this.number);

  @override
  List<Object?> get props => [number];
}

class PurchaseReturnError extends PurchaseReturnState {
  final String message;

  const PurchaseReturnError(this.message);

  @override
  List<Object?> get props => [message];
}
