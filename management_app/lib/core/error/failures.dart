import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? code;
  final dynamic data;

  const Failure({required this.message, this.code, this.data});

  @override
  List<Object?> get props => [message, code, data];
}

// Server Failures
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code, super.data});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'Unauthorized access',
    super.code = 401,
  });
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure({
    super.message = 'Access forbidden',
    super.code = 403,
  });
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'Resource not found',
    super.code = 404,
  });
}

// Network Failures
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection', super.code});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message = 'Connection timeout', super.code});
}

// Database Failures
class DatabaseFailure extends Failure {
  const DatabaseFailure({required super.message, super.code, super.data});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error', super.code});
}

// Sync Failures
class SyncFailure extends Failure {
  const SyncFailure({required super.message, super.code, super.data});
}

class ConflictFailure extends Failure {
  const ConflictFailure({
    super.message = 'Data conflict detected',
    super.code = 409,
    super.data,
  });
}

// Validation Failures
class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.code, super.data});
}

// Permission Failures
class PermissionFailure extends Failure {
  const PermissionFailure({super.message = 'Permission denied', super.code});
}

// Business Logic Failures
class InsufficientStockFailure extends Failure {
  const InsufficientStockFailure({
    super.message = 'Insufficient stock',
    super.data,
  });
}

class InvalidTransactionFailure extends Failure {
  const InvalidTransactionFailure({required super.message, super.data});
}

class PaymentFailure extends Failure {
  const PaymentFailure({required super.message, super.data});
}

// General Failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unknown error occurred',
    super.code,
  });
}

class ParseFailure extends Failure {
  const ParseFailure({super.message = 'Failed to parse data', super.code});
}
