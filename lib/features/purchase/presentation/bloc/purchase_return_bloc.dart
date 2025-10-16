import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/purchase_return_usecases.dart';
import 'purchase_return_event.dart' as event;
import 'purchase_return_state.dart';

class PurchaseReturnBloc
    extends Bloc<event.PurchaseReturnEvent, PurchaseReturnState> {
  final GetAllPurchaseReturns getAllPurchaseReturns;
  final GetPurchaseReturnById getPurchaseReturnById;
  final GetPurchaseReturnsByReceivingId getPurchaseReturnsByReceivingId;
  final SearchPurchaseReturns searchPurchaseReturns;
  final CreatePurchaseReturn createPurchaseReturn;
  final UpdatePurchaseReturn updatePurchaseReturn;
  final DeletePurchaseReturn deletePurchaseReturn;
  final GenerateReturnNumber generateReturnNumber;

  PurchaseReturnBloc({
    required this.getAllPurchaseReturns,
    required this.getPurchaseReturnById,
    required this.getPurchaseReturnsByReceivingId,
    required this.searchPurchaseReturns,
    required this.createPurchaseReturn,
    required this.updatePurchaseReturn,
    required this.deletePurchaseReturn,
    required this.generateReturnNumber,
  }) : super(const PurchaseReturnInitial()) {
    on<event.LoadPurchaseReturns>(_onLoadPurchaseReturns);
    on<event.LoadPurchaseReturnById>(_onLoadPurchaseReturnById);
    on<event.LoadPurchaseReturnsByReceivingId>(
      _onLoadPurchaseReturnsByReceivingId,
    );
    on<event.SearchPurchaseReturnsEvent>(_onSearchPurchaseReturns);
    on<event.CreatePurchaseReturnEvent>(_onCreatePurchaseReturn);
    on<event.UpdatePurchaseReturnEvent>(_onUpdatePurchaseReturn);
    on<event.DeletePurchaseReturnEvent>(_onDeletePurchaseReturn);
    on<event.GenerateReturnNumberEvent>(_onGenerateReturnNumber);
  }

  Future<void> _onLoadPurchaseReturns(
    event.LoadPurchaseReturns ev,
    Emitter<PurchaseReturnState> emit,
  ) async {
    emit(const PurchaseReturnLoading());

    final result = await getAllPurchaseReturns();

    result.fold(
      (failure) => emit(PurchaseReturnError(failure.message)),
      (purchaseReturns) => emit(PurchaseReturnLoaded(purchaseReturns)),
    );
  }

  Future<void> _onLoadPurchaseReturnById(
    event.LoadPurchaseReturnById ev,
    Emitter<PurchaseReturnState> emit,
  ) async {
    emit(const PurchaseReturnLoading());

    final result = await getPurchaseReturnById(ev.id);

    result.fold(
      (failure) => emit(PurchaseReturnError(failure.message)),
      (purchaseReturn) => emit(PurchaseReturnDetailLoaded(purchaseReturn)),
    );
  }

  Future<void> _onLoadPurchaseReturnsByReceivingId(
    event.LoadPurchaseReturnsByReceivingId ev,
    Emitter<PurchaseReturnState> emit,
  ) async {
    emit(const PurchaseReturnLoading());

    final result = await getPurchaseReturnsByReceivingId(ev.receivingId);

    result.fold(
      (failure) => emit(PurchaseReturnError(failure.message)),
      (purchaseReturns) => emit(PurchaseReturnLoaded(purchaseReturns)),
    );
  }

  Future<void> _onSearchPurchaseReturns(
    event.SearchPurchaseReturnsEvent ev,
    Emitter<PurchaseReturnState> emit,
  ) async {
    emit(const PurchaseReturnLoading());

    final result = await searchPurchaseReturns(ev.query);

    result.fold(
      (failure) => emit(PurchaseReturnError(failure.message)),
      (purchaseReturns) => emit(PurchaseReturnLoaded(purchaseReturns)),
    );
  }

  Future<void> _onCreatePurchaseReturn(
    event.CreatePurchaseReturnEvent ev,
    Emitter<PurchaseReturnState> emit,
  ) async {
    emit(const PurchaseReturnLoading());

    final result = await createPurchaseReturn(ev.purchaseReturn);

    result.fold(
      (failure) => emit(PurchaseReturnError(failure.message)),
      (purchaseReturn) => emit(
        PurchaseReturnOperationSuccess(
          'Return pembelian berhasil dibuat',
          purchaseReturn,
        ),
      ),
    );
  }

  Future<void> _onUpdatePurchaseReturn(
    event.UpdatePurchaseReturnEvent ev,
    Emitter<PurchaseReturnState> emit,
  ) async {
    emit(const PurchaseReturnLoading());

    final result = await updatePurchaseReturn(ev.purchaseReturn);

    result.fold(
      (failure) => emit(PurchaseReturnError(failure.message)),
      (purchaseReturn) => emit(
        PurchaseReturnOperationSuccess(
          'Return pembelian berhasil diupdate',
          purchaseReturn,
        ),
      ),
    );
  }

  Future<void> _onDeletePurchaseReturn(
    event.DeletePurchaseReturnEvent ev,
    Emitter<PurchaseReturnState> emit,
  ) async {
    emit(const PurchaseReturnLoading());

    final result = await deletePurchaseReturn(ev.id);

    result.fold(
      (failure) => emit(PurchaseReturnError(failure.message)),
      (_) => emit(
        const PurchaseReturnOperationSuccess(
          'Return pembelian berhasil dihapus',
        ),
      ),
    );
  }

  Future<void> _onGenerateReturnNumber(
    event.GenerateReturnNumberEvent ev,
    Emitter<PurchaseReturnState> emit,
  ) async {
    final result = await generateReturnNumber();

    result.fold(
      (failure) => emit(PurchaseReturnError(failure.message)),
      (number) => emit(ReturnNumberGenerated(number)),
    );
  }
}
