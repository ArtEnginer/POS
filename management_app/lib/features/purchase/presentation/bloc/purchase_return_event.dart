import 'package:equatable/equatable.dart';
import '../../domain/entities/purchase_return.dart';

abstract class PurchaseReturnEvent extends Equatable {
  const PurchaseReturnEvent();

  @override
  List<Object?> get props => [];
}

class LoadPurchaseReturns extends PurchaseReturnEvent {
  const LoadPurchaseReturns();
}

class LoadPurchaseReturnById extends PurchaseReturnEvent {
  final String id;

  const LoadPurchaseReturnById(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadPurchaseReturnsByReceivingId extends PurchaseReturnEvent {
  final String receivingId;

  const LoadPurchaseReturnsByReceivingId(this.receivingId);

  @override
  List<Object?> get props => [receivingId];
}

class SearchPurchaseReturnsEvent extends PurchaseReturnEvent {
  final String query;

  const SearchPurchaseReturnsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class CreatePurchaseReturnEvent extends PurchaseReturnEvent {
  final PurchaseReturn purchaseReturn;

  const CreatePurchaseReturnEvent(this.purchaseReturn);

  @override
  List<Object?> get props => [purchaseReturn];
}

class UpdatePurchaseReturnEvent extends PurchaseReturnEvent {
  final PurchaseReturn purchaseReturn;

  const UpdatePurchaseReturnEvent(this.purchaseReturn);

  @override
  List<Object?> get props => [purchaseReturn];
}

class DeletePurchaseReturnEvent extends PurchaseReturnEvent {
  final String id;

  const DeletePurchaseReturnEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class GenerateReturnNumberEvent extends PurchaseReturnEvent {
  const GenerateReturnNumberEvent();
}
