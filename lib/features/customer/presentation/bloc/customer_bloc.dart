import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/customer_usecases.dart' as usecases;
import 'customer_event.dart';
import 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final usecases.GetAllCustomers getAllCustomers;
  final usecases.GetCustomerById getCustomerById;
  final usecases.SearchCustomers searchCustomers;
  final usecases.CreateCustomer createCustomer;
  final usecases.UpdateCustomer updateCustomer;
  final usecases.DeleteCustomer deleteCustomer;
  final usecases.GenerateCustomerCode generateCustomerCode;

  CustomerBloc({
    required this.getAllCustomers,
    required this.getCustomerById,
    required this.searchCustomers,
    required this.createCustomer,
    required this.updateCustomer,
    required this.deleteCustomer,
    required this.generateCustomerCode,
  }) : super(CustomerInitial()) {
    on<LoadAllCustomers>(_onLoadAllCustomers);
    on<LoadCustomerById>(_onLoadCustomerById);
    on<SearchCustomersEvent>(_onSearchCustomers);
    on<CreateCustomerEvent>(_onCreateCustomer);
    on<UpdateCustomerEvent>(_onUpdateCustomer);
    on<DeleteCustomerEvent>(_onDeleteCustomer);
    on<GenerateCustomerCodeEvent>(_onGenerateCustomerCode);
  }

  Future<void> _onLoadAllCustomers(
    LoadAllCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await getAllCustomers();
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (customers) => emit(CustomerLoaded(customers)),
    );
  }

  Future<void> _onLoadCustomerById(
    LoadCustomerById event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await getCustomerById(event.id);
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (customer) => emit(CustomerDetailLoaded(customer)),
    );
  }

  Future<void> _onSearchCustomers(
    SearchCustomersEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await searchCustomers(event.query);
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (customers) => emit(CustomerLoaded(customers)),
    );
  }

  Future<void> _onCreateCustomer(
    CreateCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await createCustomer(event.customer);
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (customer) =>
          emit(const CustomerOperationSuccess('Customer berhasil ditambahkan')),
    );
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await updateCustomer(event.customer);
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (customer) =>
          emit(const CustomerOperationSuccess('Customer berhasil diupdate')),
    );
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await deleteCustomer(event.id);
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (_) => emit(const CustomerOperationSuccess('Customer berhasil dihapus')),
    );
  }

  Future<void> _onGenerateCustomerCode(
    GenerateCustomerCodeEvent event,
    Emitter<CustomerState> emit,
  ) async {
    final result = await generateCustomerCode();
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (code) => emit(CustomerCodeGenerated(code)),
    );
  }
}
