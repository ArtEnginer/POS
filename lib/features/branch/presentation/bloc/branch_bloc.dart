import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/branch.dart';
import '../../domain/usecases/branch_usecases.dart';

// Events
abstract class BranchEvent extends Equatable {
  const BranchEvent();

  @override
  List<Object?> get props => [];
}

class LoadBranches extends BranchEvent {}

class LoadBranchById extends BranchEvent {
  final String id;

  const LoadBranchById(this.id);

  @override
  List<Object> get props => [id];
}

class CreateBranchEvent extends BranchEvent {
  final Branch branch;

  const CreateBranchEvent(this.branch);

  @override
  List<Object> get props => [branch];
}

class UpdateBranchEvent extends BranchEvent {
  final Branch branch;

  const UpdateBranchEvent(this.branch);

  @override
  List<Object> get props => [branch];
}

class DeleteBranchEvent extends BranchEvent {
  final String id;

  const DeleteBranchEvent(this.id);

  @override
  List<Object> get props => [id];
}

class SearchBranchesEvent extends BranchEvent {
  final String query;

  const SearchBranchesEvent(this.query);

  @override
  List<Object> get props => [query];
}

class LoadCurrentBranch extends BranchEvent {}

// States
abstract class BranchState extends Equatable {
  const BranchState();

  @override
  List<Object?> get props => [];
}

class BranchInitial extends BranchState {}

class BranchLoading extends BranchState {}

class BranchesLoaded extends BranchState {
  final List<Branch> branches;

  const BranchesLoaded(this.branches);

  @override
  List<Object> get props => [branches];
}

class BranchLoaded extends BranchState {
  final Branch branch;

  const BranchLoaded(this.branch);

  @override
  List<Object> get props => [branch];
}

class BranchCreated extends BranchState {
  final Branch branch;

  const BranchCreated(this.branch);

  @override
  List<Object> get props => [branch];
}

class BranchUpdated extends BranchState {
  final Branch branch;

  const BranchUpdated(this.branch);

  @override
  List<Object> get props => [branch];
}

class BranchDeleted extends BranchState {}

class BranchError extends BranchState {
  final String message;

  const BranchError(this.message);

  @override
  List<Object> get props => [message];
}

class CurrentBranchLoaded extends BranchState {
  final Branch branch;

  const CurrentBranchLoaded(this.branch);

  @override
  List<Object> get props => [branch];
}

// BLoC
class BranchBloc extends Bloc<BranchEvent, BranchState> {
  final GetAllBranches getAllBranches;
  final GetBranchById getBranchById;
  final CreateBranch createBranch;
  final UpdateBranch updateBranch;
  final DeleteBranch deleteBranch;
  final SearchBranches searchBranches;
  final GetCurrentBranch getCurrentBranch;

  BranchBloc({
    required this.getAllBranches,
    required this.getBranchById,
    required this.createBranch,
    required this.updateBranch,
    required this.deleteBranch,
    required this.searchBranches,
    required this.getCurrentBranch,
  }) : super(BranchInitial()) {
    on<LoadBranches>(_onLoadBranches);
    on<LoadBranchById>(_onLoadBranchById);
    on<CreateBranchEvent>(_onCreateBranch);
    on<UpdateBranchEvent>(_onUpdateBranch);
    on<DeleteBranchEvent>(_onDeleteBranch);
    on<SearchBranchesEvent>(_onSearchBranches);
    on<LoadCurrentBranch>(_onLoadCurrentBranch);
  }

  Future<void> _onLoadBranches(
    LoadBranches event,
    Emitter<BranchState> emit,
  ) async {
    emit(BranchLoading());
    final result = await getAllBranches();
    result.fold(
      (failure) => emit(BranchError(failure.message)),
      (branches) => emit(BranchesLoaded(branches)),
    );
  }

  Future<void> _onLoadBranchById(
    LoadBranchById event,
    Emitter<BranchState> emit,
  ) async {
    emit(BranchLoading());
    final result = await getBranchById(event.id);
    result.fold(
      (failure) => emit(BranchError(failure.message)),
      (branch) => emit(BranchLoaded(branch)),
    );
  }

  Future<void> _onCreateBranch(
    CreateBranchEvent event,
    Emitter<BranchState> emit,
  ) async {
    emit(BranchLoading());
    final result = await createBranch(event.branch);
    result.fold(
      (failure) => emit(BranchError(failure.message)),
      (branch) => emit(BranchCreated(branch)),
    );
  }

  Future<void> _onUpdateBranch(
    UpdateBranchEvent event,
    Emitter<BranchState> emit,
  ) async {
    emit(BranchLoading());
    final result = await updateBranch(event.branch);
    result.fold(
      (failure) => emit(BranchError(failure.message)),
      (branch) => emit(BranchUpdated(branch)),
    );
  }

  Future<void> _onDeleteBranch(
    DeleteBranchEvent event,
    Emitter<BranchState> emit,
  ) async {
    emit(BranchLoading());
    final result = await deleteBranch(event.id);
    result.fold(
      (failure) => emit(BranchError(failure.message)),
      (_) => emit(BranchDeleted()),
    );
  }

  Future<void> _onSearchBranches(
    SearchBranchesEvent event,
    Emitter<BranchState> emit,
  ) async {
    emit(BranchLoading());
    final result = await searchBranches(event.query);
    result.fold(
      (failure) => emit(BranchError(failure.message)),
      (branches) => emit(BranchesLoaded(branches)),
    );
  }

  Future<void> _onLoadCurrentBranch(
    LoadCurrentBranch event,
    Emitter<BranchState> emit,
  ) async {
    emit(BranchLoading());
    final result = await getCurrentBranch();
    result.fold(
      (failure) => emit(BranchError(failure.message)),
      (branch) => emit(CurrentBranchLoaded(branch)),
    );
  }
}
