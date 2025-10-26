#!/bin/bash
# Script untuk generate repository dengan offline-first support

# Warna output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fungsi untuk print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Template untuk RepositoryImpl
generate_repository_impl() {
    local feature=$1
    local entity=$2
    local local_source=$3
    local remote_source=$4

    cat > "lib/features/${feature}/data/repositories/${entity,,}_repository_impl.dart" << 'EOF'
import 'package:dartz/dartz.dart';
import '../../domain/repositories/ENTITY_repository.dart';
import '../../domain/entities/ENTITY.dart';
import '../datasources/ENTITY_local_data_source.dart';
import '../datasources/ENTITY_remote_data_source.dart';
import '../../../core/error/failures.dart';
import '../../../core/repositories/base_repository.dart';
import '../../../core/sync/sync_manager.dart';
import '../../../core/network/connectivity_manager.dart';

class ENTITY_RepositoryImpl extends BaseRepository
    implements ENTITY_Repository {
  final ENTITY_LocalDataSource _localDataSource;
  final ENTITY_RemoteDataSource _remoteDataSource;

  ENTITY_RepositoryImpl({
    required ENTITY_LocalDataSource localDataSource,
    required ENTITY_RemoteDataSource remoteDataSource,
    required SyncManager syncManager,
    required ConnectivityManager connectivityManager,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        super(
          syncManager: syncManager,
          connectivityManager: connectivityManager,
        );

  @override
  Future<Either<Failure, ENTITY>> create(ENTITY entity) async {
    return await createWithSync(
      localOperation: () => _localDataSource.create(entity),
      remoteOperation: () => _remoteDataSource.create(entity),
      entityType: 'ENTITY_TYPE',
      data: entity.toMap(),
      operationType: 'create',
    );
  }

  @override
  Future<Either<Failure, ENTITY>> update(ENTITY entity) async {
    return await updateWithSync(
      localOperation: () => _localDataSource.update(entity),
      remoteOperation: () => _remoteDataSource.update(entity),
      entityType: 'ENTITY_TYPE',
      data: entity.toMap(),
      operationType: 'update',
    );
  }

  @override
  Future<Either<Failure, void>> delete(String id) async {
    return await deleteWithSync(
      localOperation: () => _localDataSource.delete(id),
      remoteOperation: () => _remoteDataSource.delete(id),
      entityType: 'ENTITY_TYPE',
      data: {'id': id},
      operationType: 'delete',
    );
  }

  @override
  Future<Either<Failure, List<ENTITY>>> getAll() async {
    return await getWithFallback(
      remoteOperation: () => _remoteDataSource.getAll(),
      localOperation: () => _localDataSource.getAll(),
      operationType: 'getAll',
    );
  }

  @override
  Future<Either<Failure, ENTITY>> getById(String id) async {
    return await getWithFallback(
      remoteOperation: () => _remoteDataSource.getById(id),
      localOperation: () => _localDataSource.getById(id),
      operationType: 'getById',
    );
  }
}
EOF

    print_status "Generated ${entity}_repository_impl.dart"
}

# Template untuk BLoC dengan offline support
generate_bloc() {
    local feature=$1
    local entity=$2

    cat > "lib/features/${feature}/presentation/bloc/${entity,,}_bloc.dart.template" << 'EOF'
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/ENTITY_repository.dart';
import '../../domain/entities/ENTITY.dart';
import '../../../core/network/connectivity_manager.dart';

// ============== EVENTS ==============
abstract class ENTITY_Event extends Equatable {
  const ENTITY_Event();
  @override
  List<Object?> get props => [];
}

class GetAll_ENTITY_Event extends ENTITY_Event {
  const GetAll_ENTITY_Event();
}

class Create_ENTITY_Event extends ENTITY_Event {
  final ENTITY entity;
  const Create_ENTITY_Event({required this.entity});
  @override
  List<Object?> get props => [entity];
}

class Update_ENTITY_Event extends ENTITY_Event {
  final ENTITY entity;
  const Update_ENTITY_Event({required this.entity});
  @override
  List<Object?> get props => [entity];
}

class Delete_ENTITY_Event extends ENTITY_Event {
  final String id;
  const Delete_ENTITY_Event({required this.id});
  @override
  List<Object?> get props => [id];
}

class ConnectivityChanged_ENTITY_Event extends ENTITY_Event {
  final bool isOnline;
  const ConnectivityChanged_ENTITY_Event({required this.isOnline});
  @override
  List<Object?> get props => [isOnline];
}

// ============== STATES ==============
abstract class ENTITY_State extends Equatable {
  const ENTITY_State();
  @override
  List<Object?> get props => [];
}

class ENTITY_Initial extends ENTITY_State {
  const ENTITY_Initial();
}

class ENTITY_Loading extends ENTITY_State {
  const ENTITY_Loading();
}

class ENTITY_Loaded extends ENTITY_State {
  final List<ENTITY> items;
  final bool isOnline;
  const ENTITY_Loaded({required this.items, required this.isOnline});
  @override
  List<Object?> get props => [items, isOnline];
}

class ENTITY_Created extends ENTITY_State {
  final ENTITY entity;
  final bool isOnline;
  const ENTITY_Created({required this.entity, required this.isOnline});
  @override
  List<Object?> get props => [entity, isOnline];
}

class ENTITY_Error extends ENTITY_State {
  final String message;
  const ENTITY_Error({required this.message});
  @override
  List<Object?> get props => [message];
}

// ============== BLOC ==============
class ENTITY_Bloc extends Bloc<ENTITY_Event, ENTITY_State> {
  final ENTITY_Repository _repository;
  final ConnectivityManager _connectivityManager;

  ENTITY_Bloc({
    required ENTITY_Repository repository,
    required ConnectivityManager connectivityManager,
  })  : _repository = repository,
        _connectivityManager = connectivityManager,
        super(const ENTITY_Initial()) {
    
    on<GetAll_ENTITY_Event>(_onGetAll);
    on<Create_ENTITY_Event>(_onCreate);
    on<ConnectivityChanged_ENTITY_Event>(_onConnectivityChanged);

    _connectivityManager.statusStream.listen((status) {
      add(ConnectivityChanged_ENTITY_Event(
        isOnline: status.name == 'online',
      ));
    });
  }

  Future<void> _onGetAll(
    GetAll_ENTITY_Event event,
    Emitter<ENTITY_State> emit,
  ) async {
    emit(const ENTITY_Loading());
    final result = await _repository.getAll();
    result.fold(
      (failure) => emit(ENTITY_Error(message: failure.message)),
      (items) => emit(ENTITY_Loaded(
        items: items,
        isOnline: _connectivityManager.isOnline,
      )),
    );
  }

  Future<void> _onCreate(
    Create_ENTITY_Event event,
    Emitter<ENTITY_State> emit,
  ) async {
    final result = await _repository.create(event.entity);
    result.fold(
      (failure) => emit(ENTITY_Error(message: failure.message)),
      (entity) => emit(ENTITY_Created(
        entity: entity,
        isOnline: _connectivityManager.isOnline,
      )),
    );
  }

  Future<void> _onConnectivityChanged(
    ConnectivityChanged_ENTITY_Event event,
    Emitter<ENTITY_State> emit,
  ) async {
    // Handle connectivity changes
  }
}
EOF

    print_status "Generated ${entity}_bloc.dart template"
}

# Main script
print_info "Repository Generator - Offline-First Support"
echo ""

# Contoh penggunaan
if [ $# -lt 2 ]; then
    print_error "Usage: ./generate_repository.sh <feature> <entity>"
    echo ""
    echo "Examples:"
    echo "  ./generate_repository.sh sales sale"
    echo "  ./generate_repository.sh product product"
    echo "  ./generate_repository.sh customer customer"
    exit 1
fi

feature=$1
entity=$2

print_info "Generating repository for: $feature / $entity"
echo ""

# Generate files
generate_repository_impl "$feature" "$entity"
generate_bloc "$feature" "$entity"

echo ""
print_status "Generated files in:"
echo "  - lib/features/${feature}/data/repositories/${entity,,}_repository_impl.dart"
echo "  - lib/features/${feature}/presentation/bloc/${entity,,}_bloc.dart.template"
echo ""
print_info "Manual steps required:"
echo "  1. Replace 'ENTITY' with '${entity}' in generated files"
echo "  2. Add LocalDataSource & RemoteDataSource imports"
echo "  3. Implement additional methods from interface"
echo "  4. Update injection_container.dart"
echo ""
