import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/purchase_usecases.dart';
import 'purchase_event.dart' as event;
import 'purchase_state.dart';

class PurchaseBloc extends Bloc<event.PurchaseEvent, PurchaseState> {
  final GetAllPurchases getAllPurchases;
  final GetPurchaseById getPurchaseById;
  final GetPurchasesByDateRange getPurchasesByDateRange;
  final SearchPurchases searchPurchases;
  final CreatePurchase createPurchase;
  final UpdatePurchase updatePurchase;
  final DeletePurchase deletePurchase;
  final GeneratePurchaseNumber generatePurchaseNumber;
  final ReceivePurchase receivePurchase;

  PurchaseBloc({
    required this.getAllPurchases,
    required this.getPurchaseById,
    required this.getPurchasesByDateRange,
    required this.searchPurchases,
    required this.createPurchase,
    required this.updatePurchase,
    required this.deletePurchase,
    required this.generatePurchaseNumber,
    required this.receivePurchase,
  }) : super(const PurchaseInitial()) {
    on<event.LoadPurchases>(_onLoadPurchases);
    on<event.LoadPurchaseById>(_onLoadPurchaseById);
    on<event.LoadPurchasesByDateRange>(_onLoadPurchasesByDateRange);
    on<event.SearchPurchases>(_onSearchPurchases);
    on<event.CreatePurchase>(_onCreatePurchase);
    on<event.UpdatePurchase>(_onUpdatePurchase);
    on<event.DeletePurchase>(_onDeletePurchase);
    on<event.GeneratePurchaseNumber>(_onGeneratePurchaseNumber);
    on<event.ReceivePurchaseEvent>(_onReceivePurchase);
  }

  Future<void> _onLoadPurchases(
    event.LoadPurchases ev,
    Emitter<PurchaseState> emit,
  ) async {
    emit(const PurchaseLoading());

    final result = await getAllPurchases();

    result.fold(
      (failure) => emit(PurchaseError(failure.message)),
      (purchases) => emit(PurchaseLoaded(purchases)),
    );
  }

  Future<void> _onLoadPurchaseById(
    event.LoadPurchaseById ev,
    Emitter<PurchaseState> emit,
  ) async {
    emit(const PurchaseLoading());

    final result = await getPurchaseById(ev.id);

    result.fold(
      (failure) => emit(PurchaseError(failure.message)),
      (purchase) => emit(PurchaseDetailLoaded(purchase)),
    );
  }

  Future<void> _onLoadPurchasesByDateRange(
    event.LoadPurchasesByDateRange ev,
    Emitter<PurchaseState> emit,
  ) async {
    emit(const PurchaseLoading());

    final result = await getPurchasesByDateRange(ev.startDate, ev.endDate);

    result.fold(
      (failure) => emit(PurchaseError(failure.message)),
      (purchases) => emit(PurchaseLoaded(purchases)),
    );
  }

  Future<void> _onSearchPurchases(
    event.SearchPurchases ev,
    Emitter<PurchaseState> emit,
  ) async {
    emit(const PurchaseLoading());

    final result = await searchPurchases(ev.query);

    result.fold(
      (failure) => emit(PurchaseError(failure.message)),
      (purchases) => emit(PurchaseLoaded(purchases)),
    );
  }

  Future<void> _onCreatePurchase(
    event.CreatePurchase ev,
    Emitter<PurchaseState> emit,
  ) async {
    emit(const PurchaseLoading());

    final result = await createPurchase(ev.purchase);

    result.fold(
      (failure) => emit(PurchaseError(failure.message)),
      (purchase) =>
          emit(PurchaseOperationSuccess('Pembelian berhasil dibuat', purchase)),
    );
  }

  Future<void> _onUpdatePurchase(
    event.UpdatePurchase ev,
    Emitter<PurchaseState> emit,
  ) async {
    emit(const PurchaseLoading());

    final result = await updatePurchase(ev.purchase);

    result.fold(
      (failure) => emit(PurchaseError(failure.message)),
      (purchase) => emit(
        PurchaseOperationSuccess('Pembelian berhasil diupdate', purchase),
      ),
    );
  }

  Future<void> _onDeletePurchase(
    event.DeletePurchase ev,
    Emitter<PurchaseState> emit,
  ) async {
    emit(const PurchaseLoading());

    final result = await deletePurchase(ev.id);

    result.fold(
      (failure) => emit(PurchaseError(failure.message)),
      (_) => emit(const PurchaseOperationSuccess('Pembelian berhasil dihapus')),
    );
  }

  Future<void> _onGeneratePurchaseNumber(
    event.GeneratePurchaseNumber ev,
    Emitter<PurchaseState> emit,
  ) async {
    final result = await generatePurchaseNumber();

    result.fold(
      (failure) => emit(PurchaseError(failure.message)),
      (number) => emit(PurchaseNumberGenerated(number)),
    );
  }

  Future<void> _onReceivePurchase(
    event.ReceivePurchaseEvent ev,
    Emitter<PurchaseState> emit,
  ) async {
    emit(const PurchaseLoading());

    final result = await receivePurchase(ev.id);

    result.fold(
      (failure) => emit(PurchaseError(failure.message)),
      (_) => emit(
        const PurchaseOperationSuccess('Penerimaan barang berhasil diproses'),
      ),
    );
  }
}
