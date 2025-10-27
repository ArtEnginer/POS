import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/receiving_usecases.dart';
import 'receiving_event.dart';
import 'receiving_state.dart';

class ReceivingBloc extends Bloc<ReceivingEvent, ReceivingState> {
  final GetAllReceivings getAllReceivings;
  final GetReceivingById getReceivingById;
  final SearchReceivings searchReceivings;
  final CreateReceiving createReceiving;
  final UpdateReceiving updateReceiving;
  final DeleteReceiving deleteReceiving;
  final GenerateReceivingNumber generateReceivingNumber;

  ReceivingBloc({
    required this.getAllReceivings,
    required this.getReceivingById,
    required this.searchReceivings,
    required this.createReceiving,
    required this.updateReceiving,
    required this.deleteReceiving,
    required this.generateReceivingNumber,
  }) : super(const ReceivingInitial()) {
    on<LoadReceivings>(_onLoadReceivings);
    on<LoadReceivingById>(_onLoadReceivingById);
    on<SearchReceivingsEvent>(_onSearchReceivings);
    on<CreateReceivingEvent>(_onCreateReceiving);
    on<UpdateReceivingEvent>(_onUpdateReceiving);
    on<DeleteReceivingEvent>(_onDeleteReceiving);
    on<GenerateReceivingNumberEvent>(_onGenerateReceivingNumber);
  }

  Future<void> _onLoadReceivings(
    LoadReceivings event,
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
    LoadReceivingById event,
    Emitter<ReceivingState> emit,
  ) async {
    emit(const ReceivingLoading());

    final result = await getReceivingById(event.id);

    result.fold(
      (failure) => emit(ReceivingError(failure.message)),
      (receiving) => emit(ReceivingDetailLoaded(receiving)),
    );
  }

  Future<void> _onSearchReceivings(
    SearchReceivingsEvent event,
    Emitter<ReceivingState> emit,
  ) async {
    emit(const ReceivingLoading());

    final result = await searchReceivings(event.query);

    result.fold(
      (failure) => emit(ReceivingError(failure.message)),
      (receivings) => emit(ReceivingLoaded(receivings)),
    );
  }

  Future<void> _onCreateReceiving(
    CreateReceivingEvent event,
    Emitter<ReceivingState> emit,
  ) async {
    emit(const ReceivingLoading());

    final result = await createReceiving(event.receiving);

    result.fold(
      (failure) => emit(ReceivingError(failure.message)),
      (receiving) => emit(
        ReceivingOperationSuccess('Penerimaan berhasil dibuat', receiving),
      ),
    );
  }

  Future<void> _onUpdateReceiving(
    UpdateReceivingEvent event,
    Emitter<ReceivingState> emit,
  ) async {
    emit(const ReceivingLoading());

    final result = await updateReceiving(event.receiving);

    result.fold(
      (failure) => emit(ReceivingError(failure.message)),
      (receiving) => emit(
        ReceivingOperationSuccess('Penerimaan berhasil diupdate', receiving),
      ),
    );
  }

  Future<void> _onDeleteReceiving(
    DeleteReceivingEvent event,
    Emitter<ReceivingState> emit,
  ) async {
    emit(const ReceivingLoading());

    final result = await deleteReceiving(event.id);

    result.fold(
      (failure) => emit(ReceivingError(failure.message)),
      (_) =>
          emit(const ReceivingOperationSuccess('Penerimaan berhasil dihapus')),
    );
  }

  Future<void> _onGenerateReceivingNumber(
    GenerateReceivingNumberEvent event,
    Emitter<ReceivingState> emit,
  ) async {
    final result = await generateReceivingNumber();

    result.fold(
      (failure) => emit(ReceivingError(failure.message)),
      (number) => emit(ReceivingNumberGenerated(number)),
    );
  }
}
