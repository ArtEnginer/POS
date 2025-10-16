import 'package:equatable/equatable.dart';
import '../../domain/entities/receiving.dart';

abstract class ReceivingEvent extends Equatable {
  const ReceivingEvent();

  @override
  List<Object?> get props => [];
}

class LoadReceivings extends ReceivingEvent {
  const LoadReceivings();
}

class LoadReceivingById extends ReceivingEvent {
  final String id;

  const LoadReceivingById(this.id);

  @override
  List<Object?> get props => [id];
}

class LoadReceivingsByPurchaseId extends ReceivingEvent {
  final String purchaseId;

  const LoadReceivingsByPurchaseId(this.purchaseId);

  @override
  List<Object?> get props => [purchaseId];
}

class SearchReceivingsEvent extends ReceivingEvent {
  final String query;

  const SearchReceivingsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class CreateReceivingEvent extends ReceivingEvent {
  final Receiving receiving;

  const CreateReceivingEvent(this.receiving);

  @override
  List<Object?> get props => [receiving];
}

class UpdateReceivingEvent extends ReceivingEvent {
  final Receiving receiving;

  const UpdateReceivingEvent(this.receiving);

  @override
  List<Object?> get props => [receiving];
}

class DeleteReceivingEvent extends ReceivingEvent {
  final String id;

  const DeleteReceivingEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class GenerateReceivingNumberEvent extends ReceivingEvent {
  const GenerateReceivingNumberEvent();
}
