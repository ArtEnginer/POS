class ApiConstants {
  // Base URL - Change this to your backend URL
  static const String baseUrl = 'http://localhost:3001/api/v2';

  // Socket.IO URL
  static const String socketUrl = 'http://localhost:3001';

  // API Endpoints
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

  static const String products = '/products';
  static const String sales = '/sales';
  static const String branches = '/branches';
  static const String users = '/users';
  static const String customers = '/customers';
  static const String suppliers = '/suppliers';
  static const String purchases = '/purchases';
  static const String sync = '/sync';
  static const String reports = '/reports';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Socket Events
  static const String socketConnected = 'connected';
  static const String socketDisconnected = 'disconnect';
  static const String socketError = 'error';

  static const String productUpdate = 'product:update';
  static const String stockUpdate = 'stock:update';
  static const String saleCompleted = 'sale:completed';
  static const String syncRequest = 'sync:request';
  static const String notificationSend = 'notification:send';

  // Headers
  static const String contentTypeJson = 'application/json';
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer';
}
