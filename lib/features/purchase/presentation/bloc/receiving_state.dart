import 'package:equatable/equatable.dart';
import '../../domain/entities/receiving.dart';

abstract class ReceivingState extends Equatable {
  const ReceivingState();

  @override
  List<Object?> get props => [];
}

class ReceivingInitial extends ReceivingState {
  const ReceivingInitial();
}

class ReceivingLoading extends ReceivingState {
  const ReceivingLoading();
}

class ReceivingLoaded extends ReceivingState {
  final List<Receiving> receivings;

  const ReceivingLoaded(this.receivings);

  @override
  List<Object?> get props => [receivings];
}

class ReceivingDetailLoaded extends ReceivingState {
  final Receiving receiving;

  const ReceivingDetailLoaded(this.receiving);

  @override
  List<Object?> get props => [receiving];
}

class ReceivingOperationSuccess extends ReceivingState {
  final String message;
  final Receiving? receiving;

  const ReceivingOperationSuccess(this.message, [this.receiving]);

  @override
  List<Object?> get props => [message, receiving];
}

class ReceivingNumberGenerated extends ReceivingState {
  final String number;

  const ReceivingNumberGenerated(this.number);

  @override
  List<Object?> get props => [number];
}

class ReceivingError extends ReceivingState {
  final String message;

  const ReceivingError(this.message);

  @override
  List<Object?> get props => [message];
}
