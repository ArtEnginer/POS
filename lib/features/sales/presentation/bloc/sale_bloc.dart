import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/pending_sale.dart';
import '../../domain/entities/sale.dart';
import '../../domain/usecases/sale_usecases.dart' as usecases;
import 'sale_event.dart';
import 'sale_state.dart';

class SaleBloc extends Bloc<SaleEvent, SaleState> {
  final usecases.GetAllSales getAllSales;
  final usecases.GetSaleById getSaleById;
  final usecases.GetSalesByDateRange getSalesByDateRange;
  final usecases.SearchSales searchSales;
  final usecases.CreateSale createSale;
  final usecases.UpdateSale updateSale;
  final usecases.DeleteSale deleteSale;
  final usecases.GenerateSaleNumber generateSaleNumber;
  final usecases.GetDailySummary getDailySummary;
  final usecases.SavePendingSale savePendingSale;
  final usecases.GetPendingSales getPendingSales;
  final usecases.GetPendingSaleById getPendingSaleById;
  final usecases.DeletePendingSale deletePendingSale;
  final usecases.GeneratePendingNumber generatePendingNumber;

  SaleBloc({
    required this.getAllSales,
    required this.getSaleById,
    required this.getSalesByDateRange,
    required this.searchSales,
    required this.createSale,
    required this.updateSale,
    required this.deleteSale,
    required this.generateSaleNumber,
    required this.getDailySummary,
    required this.savePendingSale,
    required this.getPendingSales,
    required this.getPendingSaleById,
    required this.deletePendingSale,
    required this.generatePendingNumber,
  }) : super(const SaleInitial()) {
    on<LoadAllSales>(_onLoadAllSales);
    on<LoadSaleById>(_onLoadSaleById);
    on<LoadSalesByDateRange>(_onLoadSalesByDateRange);
    on<SearchSales>(_onSearchSales);
    on<CreateSale>(_onCreateSale);
    on<UpdateSale>(_onUpdateSale);
    on<DeleteSale>(_onDeleteSale);
    on<GenerateSaleNumber>(_onGenerateSaleNumber);
    on<LoadDailySummary>(_onLoadDailySummary);
    on<SavePendingSale>(_onSavePendingSale);
    on<LoadPendingSales>(_onLoadPendingSales);
    on<LoadPendingSaleById>(_onLoadPendingSaleById);
    on<DeletePendingSale>(_onDeletePendingSale);
    on<GeneratePendingNumber>(_onGeneratePendingNumber);
  }

  Future<void> _onLoadAllSales(
    LoadAllSales event,
    Emitter<SaleState> emit,
  ) async {
    emit(const SaleLoading());

    final result = await getAllSales();

    result.fold(
      (failure) => emit(SaleError(failure.message)),
      (sales) => emit(SaleLoaded(sales)),
    );
  }

  Future<void> _onLoadSaleById(
    LoadSaleById event,
    Emitter<SaleState> emit,
  ) async {
    emit(const SaleLoading());

    final result = await getSaleById(event.id);

    result.fold(
      (failure) => emit(SaleError(failure.message)),
      (sale) => emit(SaleDetailLoaded(sale)),
    );
  }

  Future<void> _onLoadSalesByDateRange(
    LoadSalesByDateRange event,
    Emitter<SaleState> emit,
  ) async {
    emit(const SaleLoading());

    final result = await getSalesByDateRange(event.startDate, event.endDate);

    result.fold(
      (failure) => emit(SaleError(failure.message)),
      (sales) => emit(SaleLoaded(sales)),
    );
  }

  Future<void> _onSearchSales(
    SearchSales event,
    Emitter<SaleState> emit,
  ) async {
    emit(const SaleLoading());

    final result = await searchSales(event.query);

    result.fold(
      (failure) => emit(SaleError(failure.message)),
      (sales) => emit(SaleLoaded(sales)),
    );
  }

  Future<void> _onCreateSale(CreateSale event, Emitter<SaleState> emit) async {
    emit(const SaleLoading());

    final result = await createSale(event.sale);

    result.fold(
      (failure) => emit(SaleError(failure.message)),
      (sale) => emit(SaleOperationSuccess('Transaksi berhasil disimpan', sale)),
    );
  }

  Future<void> _onUpdateSale(UpdateSale event, Emitter<SaleState> emit) async {
    emit(const SaleLoading());

    final result = await updateSale(event.sale);

    result.fold(
      (failure) => emit(SaleError(failure.message)),
      (sale) => emit(SaleOperationSuccess('Transaksi berhasil diupdate', sale)),
    );
  }

  Future<void> _onDeleteSale(DeleteSale event, Emitter<SaleState> emit) async {
    emit(const SaleLoading());

    final result = await deleteSale(event.id);

    result.fold(
      (failure) => emit(SaleError(failure.message)),
      (_) => emit(const SaleOperationSuccess('Transaksi berhasil dihapus')),
    );
  }

  Future<void> _onGenerateSaleNumber(
    GenerateSaleNumber event,
    Emitter<SaleState> emit,
  ) async {
    final result = await generateSaleNumber();

    result.fold(
      (failure) => emit(SaleError(failure.message)),
      (number) => emit(SaleNumberGenerated(number)),
    );
  }

  Future<void> _onLoadDailySummary(
    LoadDailySummary event,
    Emitter<SaleState> emit,
  ) async {
    emit(const SaleLoading());

    final result = await getDailySummary(event.date);

    result.fold(
      (failure) => emit(SaleError(failure.message)),
      (summary) => emit(DailySummaryLoaded(summary)),
    );
  }

  // Pending Sale Handlers
  Future<void> _onSavePendingSale(
    SavePendingSale event,
    Emitter<SaleState> emit,
  ) async {
    emit(const SaleLoading());

    final uuid = const Uuid();
    final now = DateTime.now();

    final pendingSale = PendingSale(
      id: uuid.v4(),
      pendingNumber: event.pendingNumber,
      customerId: event.customerId,
      customerName: event.customerName,
      savedAt: now,
      savedBy: event.savedBy,
      notes: event.notes,
      items:
          event.items.map((item) {
            return SaleItem(
              id: item['id'] as String,
              saleId: '', // Will be set when converting to sale
              productId: item['productId'] as String,
              productName: item['productName'] as String,
              quantity: item['quantity'] as int,
              price: item['price'] as double,
              discount: item['discount'] as double,
              subtotal: item['subtotal'] as double,
              createdAt: now,
            );
          }).toList(),
      subtotal: event.subtotal,
      tax: event.tax,
      discount: event.discount,
      total: event.total,
    );

    final result = await savePendingSale(pendingSale);

    result.fold(
      (failure) => emit(SaleError(failure.message)),
      (saved) => emit(
        PendingSaleOperationSuccess(
          'Transaksi berhasil disimpan sebagai pending',
          saved,
        ),
      ),
    );
  }

  Future<void> _onLoadPendingSales(
    LoadPendingSales event,
    Emitter<SaleState> emit,
  ) async {
    emit(const SaleLoading());

    final result = await getPendingSales();

    result.fold(
      (failure) => emit(SaleError(failure.message)),
      (pendingSales) => emit(PendingSalesLoaded(pendingSales)),
    );
  }

  Future<void> _onLoadPendingSaleById(
    LoadPendingSaleById event,
    Emitter<SaleState> emit,
  ) async {
    emit(const SaleLoading());

    final result = await getPendingSaleById(event.id);

    result.fold(
      (failure) => emit(SaleError(failure.message)),
      (pendingSale) => emit(PendingSaleLoaded(pendingSale)),
    );
  }

  Future<void> _onDeletePendingSale(
    DeletePendingSale event,
    Emitter<SaleState> emit,
  ) async {
    emit(const SaleLoading());

    final result = await deletePendingSale(event.id);

    result.fold(
      (failure) => emit(SaleError(failure.message)),
      (_) => emit(
        const PendingSaleOperationSuccess('Transaksi pending berhasil dihapus'),
      ),
    );
  }

  Future<void> _onGeneratePendingNumber(
    GeneratePendingNumber event,
    Emitter<SaleState> emit,
  ) async {
    final result = await generatePendingNumber();

    result.fold(
      (failure) => emit(SaleError(failure.message)),
      (number) => emit(PendingNumberGenerated(number)),
    );
  }
}
