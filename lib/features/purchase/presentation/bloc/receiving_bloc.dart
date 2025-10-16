import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/receiving_usecases.dart';
import 'receiving_event.dart' as event;
import 'receiving_state.dart';

class ReceivingBloc extends Bloc<event.ReceivingEvent, ReceivingState> {
  final GetAllReceivings getAllReceivings;
  final GetReceivingById getReceivingById;
  final GetReceivingsByPurchaseId getReceivingsByPurchaseId;
  final SearchReceivings searchReceivings;
  final CreateReceiving createReceiving;
  final UpdateReceiving updateReceiving;
  final DeleteReceiving deleteReceiving;
  final GenerateReceivingNumber generateReceivingNumber;

  ReceivingBloc({
    required this.getAllReceivings,
    required this.getReceivingById,
    required this.getReceivingsByPurchaseId,
    required this.searchReceivings,
    required this.createReceiving,
    required this.updateReceiving,
    required this.deleteReceiving,
    required this.generateReceivingNumber,
  }) : super(const ReceivingInitial()) {
    on<event.LoadReceivings>(_onLoadReceivings);
    on<event.LoadReceivingById>(_onLoadReceivingById);
    on<event.LoadReceivingsByPurchaseId>(_onLoadReceivingsByPurchaseId);
    on<event.SearchReceivingsEvent>(_onSearchReceivings);
    on<event.CreateReceivingEvent>(_onCreateReceiving);
    on<event.UpdateReceivingEvent>(_onUpdateReceiving);
    on<event.DeleteReceivingEvent>(_onDeleteReceiving);
    on<event.GenerateReceivingNumberEvent>(_onGenerateReceivingNumber);
  }

  Future<void> _onLoadReceivings(
    event.LoadReceivings ev,
    Emitter<ReceivingState> emit,
  ) async {
    emit(const ReceivingLoading());

    final result = await getAllReceivings();

    result.fold(
      (failure) => emit(ReceivingError(failure.message)),
      (receivings) => emit(ReceivingLoaded(receivings)),
    );
  }

  Future<void> _onLoadReceivingById(
    event.LoadReceivingById ev,
    Emitter<ReceivingState> emit,
  ) async {
    emit(const ReceivingLoading());

    final result = await getReceivingById(ev.id);

    result.fold(
      (failure) => emit(ReceivingError(failure.message)),
      (receiving) => emit(ReceivingDetailLoaded(receiving)),
    );
  }

  Future<void> _onLoadReceivingsByPurchaseId(
    event.LoadReceivingsByPurchaseId ev,
    Emitter<ReceivingState> emit,
  ) async {
    emit(const ReceivingLoading());

    final result = await getReceivingsByPurchaseId(ev.purchaseId);

    result.fold(
      (failure) => emit(ReceivingError(failure.message)),
      (receivings) => emit(ReceivingLoaded(receivings)),
    );
  }

  Future<void> _onSearchReceivings(
    event.SearchReceivingsEvent ev,
    Emitter<ReceivingState> emit,
  ) async {
    emit(const ReceivingLoading());

    final result = await searchReceivings(ev.query);

    result.fold(
      (failure) => emit(ReceivingError(failure.message)),
      (receivings) => emit(ReceivingLoaded(receivings)),
    );
  }

  Future<void> _onCreateReceiving(
    event.CreateReceivingEvent ev,
    Emitter<ReceivingState> emit,
  ) async {
    emit(const ReceivingLoading());

    final result = await createReceiving(ev.receiving);

    result.fold(
      (failure) => emit(ReceivingError(failure.message)),
      (receiving) => emit(
        ReceivingOperationSuccess(
          'Penerimaan barang berhasil dibuat',
          receiving,
        ),
      ),
    );
  }

  Future<void> _onUpdateReceiving(
    event.UpdateReceivingEvent ev,
    Emitter<ReceivingState> emit,
  ) async {
    emit(const ReceivingLoading());

    final result = await updateReceiving(ev.receiving);

    result.fold(
      (failure) => emit(ReceivingError(failure.message)),
      (receiving) => emit(
        ReceivingOperationSuccess(
          'Penerimaan barang berhasil diupdate',
          receiving,
        ),
      ),
    );
  }

  Future<void> _onDeleteReceiving(
    event.DeleteReceivingEvent ev,
    Emitter<ReceivingState> emit,
  ) async {
    emit(const ReceivingLoading());

    final result = await deleteReceiving(ev.id);

    result.fold(
      (failure) => emit(ReceivingError(failure.message)),
      (_) => emit(
        const ReceivingOperationSuccess('Penerimaan barang berhasil dihapus'),
      ),
    );
  }

  Future<void> _onGenerateReceivingNumber(
    event.GenerateReceivingNumberEvent ev,
    Emitter<ReceivingState> emit,
  ) async {
    final result = await generateReceivingNumber();

    result.fold(
      (failure) => emit(ReceivingError(failure.message)),
      (number) => emit(ReceivingNumberGenerated(number)),
    );
  }
}
