import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/user_usecases.dart';

// Events
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllUsersEvent extends UserEvent {
  final int limit;
  final int offset;
  final String? role;
  final String? status;
  final String? search;
  final int? branchId;

  const LoadAllUsersEvent({
    this.limit = 10,
    this.offset = 0,
    this.role,
    this.status,
    this.search,
    this.branchId,
  });

  @override
  List<Object?> get props => [limit, offset, role, status, search, branchId];
}

class LoadUserByIdEvent extends UserEvent {
  final int id;

  const LoadUserByIdEvent(this.id);

  @override
  List<Object> get props => [id];
}

class CreateUserEvent extends UserEvent {
  final String username;
  final String email;
  final String password;
  final String fullName;
  final String? role;
  final String? phone;
  final List<int>? branchIds;

  const CreateUserEvent({
    required this.username,
    required this.email,
    required this.password,
    required this.fullName,
    this.role,
    this.phone,
    this.branchIds,
  });

  @override
  List<Object?> get props => [
    username,
    email,
    password,
    fullName,
    role,
    phone,
    branchIds,
  ];
}

class UpdateUserEvent extends UserEvent {
  final int id;
  final String? email;
  final String? fullName;
  final String? role;
  final String? status;
  final String? phone;
  final List<int>? branchIds;

  const UpdateUserEvent({
    required this.id,
    this.email,
    this.fullName,
    this.role,
    this.status,
    this.phone,
    this.branchIds,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    role,
    status,
    phone,
    branchIds,
  ];
}

class DeleteUserEvent extends UserEvent {
  final int id;

  const DeleteUserEvent(this.id);

  @override
  List<Object> get props => [id];
}

class ChangePasswordEvent extends UserEvent {
  final int id;
  final String currentPassword;
  final String newPassword;

  const ChangePasswordEvent({
    required this.id,
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object> get props => [id, currentPassword, newPassword];
}

class ResetPasswordEvent extends UserEvent {
  final int id;
  final String newPassword;

  const ResetPasswordEvent({required this.id, required this.newPassword});

  @override
  List<Object> get props => [id, newPassword];
}

class AssignBranchesEvent extends UserEvent {
  final int id;
  final List<int> branchIds;
  final int? defaultBranchId;

  const AssignBranchesEvent({
    required this.id,
    required this.branchIds,
    this.defaultBranchId,
  });

  @override
  List<Object?> get props => [id, branchIds, defaultBranchId];
}

class LoadUserStatsEvent extends UserEvent {
  const LoadUserStatsEvent();
}

// States
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {
  const UserInitial();
}

class UserLoading extends UserState {
  const UserLoading();
}

class UsersLoaded extends UserState {
  final List<User> users;
  final int? total;
  final int? limit;
  final int? offset;

  const UsersLoaded({required this.users, this.total, this.limit, this.offset});

  @override
  List<Object?> get props => [users, total, limit, offset];
}

class UserLoaded extends UserState {
  final User user;

  const UserLoaded(this.user);

  @override
  List<Object> get props => [user];
}

class UserCreated extends UserState {
  final User user;

  const UserCreated(this.user);

  @override
  List<Object> get props => [user];
}

class UserUpdated extends UserState {
  final User user;

  const UserUpdated(this.user);

  @override
  List<Object> get props => [user];
}

class UserDeleted extends UserState {
  const UserDeleted();
}

class PasswordChanged extends UserState {
  const PasswordChanged();
}

class PasswordReset extends UserState {
  const PasswordReset();
}

class BranchesAssigned extends UserState {
  const BranchesAssigned();
}

class UserStatsLoaded extends UserState {
  final UserStats stats;

  const UserStatsLoaded(this.stats);

  @override
  List<Object> get props => [stats];
}

class UserError extends UserState {
  final String message;
  final String? code;

  const UserError({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

// BLoC
class UserBloc extends Bloc<UserEvent, UserState> {
  final GetAllUsersUseCase getAllUsersUseCase;
  final GetUserByIdUseCase getUserByIdUseCase;
  final CreateUserUseCase createUserUseCase;
  final UpdateUserUseCase updateUserUseCase;
  final DeleteUserUseCase deleteUserUseCase;
  final ChangePasswordUseCase changePasswordUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final AssignBranchesUseCase assignBranchesUseCase;
  final GetUserStatsUseCase getUserStatsUseCase;

  UserBloc({
    required this.getAllUsersUseCase,
    required this.getUserByIdUseCase,
    required this.createUserUseCase,
    required this.updateUserUseCase,
    required this.deleteUserUseCase,
    required this.changePasswordUseCase,
    required this.resetPasswordUseCase,
    required this.assignBranchesUseCase,
    required this.getUserStatsUseCase,
  }) : super(const UserInitial()) {
    on<LoadAllUsersEvent>(_onLoadAllUsers);
    on<LoadUserByIdEvent>(_onLoadUserById);
    on<CreateUserEvent>(_onCreateUser);
    on<UpdateUserEvent>(_onUpdateUser);
    on<DeleteUserEvent>(_onDeleteUser);
    on<ChangePasswordEvent>(_onChangePassword);
    on<ResetPasswordEvent>(_onResetPassword);
    on<AssignBranchesEvent>(_onAssignBranches);
    on<LoadUserStatsEvent>(_onLoadUserStats);
  }

  Future<void> _onLoadAllUsers(
    LoadAllUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(const UserLoading());
      final result = await getAllUsersUseCase(
        limit: event.limit,
        offset: event.offset,
        role: event.role,
        status: event.status,
        search: event.search,
        branchId: event.branchId,
      );
      emit(
        UsersLoaded(
          users: result.users,
          total: result.total,
          limit: event.limit,
          offset: event.offset,
        ),
      );
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  Future<void> _onLoadUserById(
    LoadUserByIdEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(const UserLoading());
      final user = await getUserByIdUseCase(event.id);
      emit(UserLoaded(user));
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  Future<void> _onCreateUser(
    CreateUserEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(const UserLoading());
      final user = await createUserUseCase(
        username: event.username,
        email: event.email,
        password: event.password,
        fullName: event.fullName,
        role: event.role,
        phone: event.phone,
        branchIds: event.branchIds,
      );
      emit(UserCreated(user));
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  Future<void> _onUpdateUser(
    UpdateUserEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(const UserLoading());
      final user = await updateUserUseCase(
        id: event.id,
        email: event.email,
        fullName: event.fullName,
        role: event.role,
        status: event.status,
        phone: event.phone,
        branchIds: event.branchIds,
      );
      emit(UserUpdated(user));
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  Future<void> _onDeleteUser(
    DeleteUserEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(const UserLoading());
      await deleteUserUseCase(event.id);
      emit(const UserDeleted());
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(const UserLoading());
      await changePasswordUseCase(
        id: event.id,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );
      emit(const PasswordChanged());
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  Future<void> _onResetPassword(
    ResetPasswordEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(const UserLoading());
      await resetPasswordUseCase(id: event.id, newPassword: event.newPassword);
      emit(const PasswordReset());
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  Future<void> _onAssignBranches(
    AssignBranchesEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(const UserLoading());
      await assignBranchesUseCase(
        id: event.id,
        branchIds: event.branchIds,
        defaultBranchId: event.defaultBranchId,
      );
      emit(const BranchesAssigned());
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  Future<void> _onLoadUserStats(
    LoadUserStatsEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(const UserLoading());
      final stats = await getUserStatsUseCase();
      emit(UserStatsLoaded(stats));
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }
}
