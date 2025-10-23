import 'dart:async';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';

/// Configuration for MySQL server connection
class MySQLConfig {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final bool useSSL;

  const MySQLConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
    this.useSSL = false,
  });

  Map<String, dynamic> toJson() => {
    'host': host,
    'port': port,
    'database': database,
    'username': username,
    'password': password,
    'useSSL': useSSL,
  };

  factory MySQLConfig.fromJson(Map<String, dynamic> json) => MySQLConfig(
    host: json['host'] as String,
    port: json['port'] as int,
    database: json['database'] as String,
    username: json['username'] as String,
    password: json['password'] as String,
    useSSL: json['useSSL'] as bool? ?? false,
  );
}

/// MySQL Connector for hybrid local-online synchronization
/// Uses REST API to communicate with MySQL backend
class MySQLConnector {
  final Logger logger;
  final Dio _dio;
  MySQLConfig? _config;
  bool _isAvailable = false;
  DateTime? _lastCheck;
  Timer? _heartbeatTimer;

  static const Duration heartbeatInterval = Duration(seconds: 30);
  static const Duration checkCacheDuration = Duration(seconds: 10);
  static const Duration connectionTimeout = Duration(seconds: 5);

  MySQLConnector({required this.logger})
    : _dio = Dio(
        BaseOptions(
          connectTimeout: connectionTimeout,
          receiveTimeout: connectionTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

  /// Check if MySQL server is available
  bool get isAvailable => _isAvailable;

  /// Get current configuration
  MySQLConfig? get config => _config;

  /// Get base URL from config
  String? get baseUrl {
    if (_config == null) return null;
    final protocol = _config!.useSSL ? 'https' : 'http';
    return '$protocol://${_config!.host}:${_config!.port}/api/v1';
  }

  /// Initialize MySQL connection with configuration
  Future<bool> initialize(MySQLConfig config) async {
    _config = config;
    logger.i('Initializing MySQL connection to ${config.host}:${config.port}');

    final isConnected = await checkConnection();
    if (isConnected) {
      _startHeartbeat();
      logger.i('MySQL server connected successfully');
    } else {
      logger.w('MySQL server not available, running in local mode');
    }

    return isConnected;
  }

  /// Check if MySQL server is accessible
  Future<bool> checkConnection() async {
    // Use cache if checked recently
    if (_lastCheck != null &&
        DateTime.now().difference(_lastCheck!) < checkCacheDuration) {
      return _isAvailable;
    }

    if (_config == null) {
      _isAvailable = false;
      _lastCheck = DateTime.now();
      return false;
    }

    try {
      final response = await _dio.get(
        '$baseUrl/health',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      _isAvailable = response.statusCode == 200;
      _lastCheck = DateTime.now();

      if (_isAvailable) {
        logger.d('MySQL server health check: OK');
      }

      return _isAvailable;
    } catch (e) {
      logger.w('MySQL server health check failed: $e');
      _isAvailable = false;
      _lastCheck = DateTime.now();
      return false;
    }
  }

  /// Start heartbeat to monitor server availability
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) async {
      final wasAvailable = _isAvailable;
      await checkConnection();

      if (wasAvailable != _isAvailable) {
        if (_isAvailable) {
          logger.i('MySQL server connection restored');
        } else {
          logger.w('MySQL server connection lost');
        }
      }
    });
  }

  /// Stop heartbeat monitoring
  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Execute query on MySQL server
  Future<Map<String, dynamic>> executeQuery(
    String query,
    Map<String, dynamic>? params,
  ) async {
    if (!_isAvailable) {
      throw Exception('MySQL server not available');
    }

    try {
      final response = await _dio.post(
        '$baseUrl/query',
        data: {
          'query': query,
          'params': params,
          'auth': {
            'username': _config!.username,
            'password': _config!.password,
            'database': _config!.database,
          },
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      logger.e('MySQL query execution failed: $e');
      rethrow;
    }
  }

  /// Insert data into MySQL
  Future<Map<String, dynamic>> insert(
    String table,
    Map<String, dynamic> data,
  ) async {
    if (!_isAvailable) {
      throw Exception('MySQL server not available');
    }

    try {
      final response = await _dio.post(
        '$baseUrl/tables/$table',
        data: {
          'data': data,
          'auth': {
            'username': _config!.username,
            'password': _config!.password,
            'database': _config!.database,
          },
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      logger.e('MySQL insert failed for table $table: $e');
      rethrow;
    }
  }

  /// Update data in MySQL
  Future<Map<String, dynamic>> update(
    String table,
    Map<String, dynamic> data,
    String whereClause,
    List<dynamic>? whereArgs,
  ) async {
    if (!_isAvailable) {
      throw Exception('MySQL server not available');
    }

    try {
      final response = await _dio.put(
        '$baseUrl/tables/$table',
        data: {
          'data': data,
          'where': whereClause,
          'whereArgs': whereArgs,
          'auth': {
            'username': _config!.username,
            'password': _config!.password,
            'database': _config!.database,
          },
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      logger.e('MySQL update failed for table $table: $e');
      rethrow;
    }
  }

  /// Delete data from MySQL
  Future<Map<String, dynamic>> delete(
    String table,
    String whereClause,
    List<dynamic>? whereArgs,
  ) async {
    if (!_isAvailable) {
      throw Exception('MySQL server not available');
    }

    try {
      final response = await _dio.delete(
        '$baseUrl/tables/$table',
        data: {
          'where': whereClause,
          'whereArgs': whereArgs,
          'auth': {
            'username': _config!.username,
            'password': _config!.password,
            'database': _config!.database,
          },
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      logger.e('MySQL delete failed for table $table: $e');
      rethrow;
    }
  }

  /// Query data from MySQL
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (!_isAvailable) {
      throw Exception('MySQL server not available');
    }

    try {
      final response = await _dio.get(
        '$baseUrl/tables/$table',
        queryParameters: {
          if (columns != null) 'columns': columns.join(','),
          if (where != null) 'where': where,
          if (whereArgs != null) 'whereArgs': whereArgs.join(','),
          if (orderBy != null) 'orderBy': orderBy,
          if (limit != null) 'limit': limit.toString(),
          if (offset != null) 'offset': offset.toString(),
        },
        options: Options(
          headers: {
            'X-Auth-Username': _config!.username,
            'X-Auth-Password': _config!.password,
            'X-Auth-Database': _config!.database,
          },
        ),
      );

      final data = response.data;
      if (data is Map && data.containsKey('data')) {
        return List<Map<String, dynamic>>.from(data['data'] as List);
      }
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      logger.e('MySQL query failed for table $table: $e');
      rethrow;
    }
  }

  /// Batch insert multiple records
  Future<Map<String, dynamic>> batchInsert(
    String table,
    List<Map<String, dynamic>> dataList,
  ) async {
    if (!_isAvailable) {
      throw Exception('MySQL server not available');
    }

    try {
      final response = await _dio.post(
        '$baseUrl/tables/$table/batch',
        data: {
          'data': dataList,
          'auth': {
            'username': _config!.username,
            'password': _config!.password,
            'database': _config!.database,
          },
        },
      );

      return response.data as Map<String, dynamic>;
    } catch (e) {
      logger.e('MySQL batch insert failed for table $table: $e');
      rethrow;
    }
  }

  /// Sync data from local to MySQL
  Future<bool> syncToMySQL(
    String table,
    List<Map<String, dynamic>> records,
  ) async {
    if (!_isAvailable) {
      return false;
    }

    try {
      await batchInsert(table, records);
      logger.i('Synced ${records.length} records from $table to MySQL');
      return true;
    } catch (e) {
      logger.e('Failed to sync $table to MySQL: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    stopHeartbeat();
    _dio.close();
  }
}
