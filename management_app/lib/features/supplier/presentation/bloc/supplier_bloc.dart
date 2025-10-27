import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_suppliers.dart';
import '../../domain/usecases/create_supplier.dart';
import '../../domain/usecases/update_supplier.dart';
import '../../domain/usecases/delete_supplier.dart';
import 'supplier_event.dart';
import 'supplier_state.dart';

class SupplierBloc extends Bloc<SupplierEvent, SupplierState> {
  final GetSuppliers getSuppliers;
  final CreateSupplier createSupplier;
  final UpdateSupplier updateSupplier;
  final DeleteSupplier deleteSupplier;

  SupplierBloc({
    required this.getSuppliers,
    required this.createSupplier,
    required this.updateSupplier,
    required this.deleteSupplier,
  }) : super(SupplierInitial()) {
    on<LoadSuppliersEvent>(_onLoadSuppliers);
    on<CreateSupplierEvent>(_onCreateSupplier);
    on<UpdateSupplierEvent>(_onUpdateSupplier);
    on<DeleteSupplierEvent>(_onDeleteSupplier);
  }

  Future<void> _onLoadSuppliers(
    LoadSuppliersEvent event,
    Emitter<SupplierState> emit,
  ) async {
    emit(SupplierLoading());

    final result = await getSuppliers(
      searchQuery: event.searchQuery,
      isActive: event.isActive,
    );

    result.fold(
      (failure) => emit(SupplierError(failure.message)),
      (suppliers) => emit(SuppliersLoaded(suppliers)),
    );
  }

  Future<void> _onCreateSupplier(
    CreateSupplierEvent event,
    Emitter<SupplierState> emit,
  ) async {
    emit(SupplierLoading());

    final result = await createSupplier(event.supplier);

    result.fold(
      (failure) => emit(SupplierError(failure.message)),
      (_) =>
          emit(const SupplierOperationSuccess('Supplier berhasil ditambahkan')),
    );
  }

  Future<void> _onUpdateSupplier(
    UpdateSupplierEvent event,
    Emitter<SupplierState> emit,
  ) async {
    emit(SupplierLoading());

    final result = await updateSupplier(event.supplier);

    result.fold(
      (failure) => emit(SupplierError(failure.message)),
      (_) => emit(const SupplierOperationSuccess('Supplier berhasil diupdate')),
    );
  }

  Future<void> _onDeleteSupplier(
    DeleteSupplierEvent event,
    Emitter<SupplierState> emit,
  ) async {
    emit(SupplierLoading());

    final result = await deleteSupplier(event.id);

    result.fold(
      (failure) => emit(SupplierError(failure.message)),
      (_) => emit(const SupplierOperationSuccess('Supplier berhasil dihapus')),
    );
  }
}
