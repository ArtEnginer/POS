class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ServerException({required this.message, this.statusCode, this.data});

  @override
  String toString() => 'ServerException: $message (Code: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  NetworkException({this.message = 'No internet connection'});

  @override
  String toString() => 'NetworkException: $message';
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException({this.message = 'Connection timeout'});

  @override
  String toString() => 'TimeoutException: $message';
}

class DatabaseException implements Exception {
  final String message;
  final dynamic error;

  DatabaseException({required this.message, this.error});

  @override
  String toString() => 'DatabaseException: $message';
}

class CacheException implements Exception {
  final String message;

  CacheException({this.message = 'Cache error'});

  @override
  String toString() => 'CacheException: $message';
}

class SyncException implements Exception {
  final String message;
  final dynamic data;

  SyncException({required this.message, this.data});

  @override
  String toString() => 'SyncException: $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;

  ValidationException({required this.message, this.errors});

  @override
  String toString() => 'ValidationException: $message';
}

class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException({this.message = 'Unauthorized access'});

  @override
  String toString() => 'UnauthorizedException: $message';
}

class PermissionException implements Exception {
  final String message;

  PermissionException({required this.message});

  @override
  String toString() => 'PermissionException: $message';
}

class ParseException implements Exception {
  final String message;
  final dynamic error;

  ParseException({this.message = 'Failed to parse data', this.error});

  @override
  String toString() => 'ParseException: $message';
}

class OfflineOperationException implements Exception {
  final String message;
  final String feature;

  OfflineOperationException({required this.message, required this.feature});

  @override
  String toString() =>
      'OfflineOperationException: $message (Feature: $feature)';
}
