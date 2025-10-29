import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';

// Events
abstract class DashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDashboardSummary extends DashboardEvent {}

class RefreshDashboardSummary extends DashboardEvent {}

// States
abstract class DashboardState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardSummary summary;

  DashboardLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository repository;

  DashboardBloc({required this.repository}) : super(DashboardInitial()) {
    on<LoadDashboardSummary>(_onLoadDashboardSummary);
    on<RefreshDashboardSummary>(_onRefreshDashboardSummary);
  }

  Future<void> _onLoadDashboardSummary(
    LoadDashboardSummary event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    final result = await repository.getDashboardSummary();
    result.fold(
      (failure) => emit(DashboardError(failure.message)),
      (summary) => emit(DashboardLoaded(summary)),
    );
  }

  Future<void> _onRefreshDashboardSummary(
    RefreshDashboardSummary event,
    Emitter<DashboardState> emit,
  ) async {
    // Keep current data while refreshing
    final currentState = state;
    if (currentState is DashboardLoaded) {
      // Show current data, will update when loaded
    }

    final result = await repository.getDashboardSummary();
    result.fold((failure) {
      // If refresh fails, keep showing old data with error message
      if (currentState is DashboardLoaded) {
        emit(DashboardLoaded(currentState.summary));
      } else {
        emit(DashboardError(failure.message));
      }
    }, (summary) => emit(DashboardLoaded(summary)));
  }
}
