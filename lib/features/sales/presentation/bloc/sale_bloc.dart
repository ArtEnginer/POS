import 'package:flutter_bloc/flutter_bloc.dart';
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
}
