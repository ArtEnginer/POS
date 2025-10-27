class ApiConstants {
  // Base URL - Backend V2 uses port 3001
  static const String baseUrl = 'http://localhost:3001/api/v2';
  static const String socketUrl = 'http://localhost:3001';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Headers
  static const String contentTypeJson = 'application/json';
  static const String contentTypeFormData = 'multipart/form-data';
  static const String bearerPrefix = 'Bearer';
  static const String appTypeHeader = 'X-App-Type';
  static const String appTypeValue = 'MANAGEMENT';

  // ========== AUTH ENDPOINTS ==========
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authRefresh = '/auth/refresh';
  static const String authProfile = '/auth/profile';
  static const String authChangePassword = '/auth/change-password';
  static const String authResetPassword = '/auth/reset-password';

  // ========== USER ENDPOINTS ==========
  static const String users = '/users';
  static const String usersById = '/users/:id';
  static const String usersCreate = '/users';
  static const String usersUpdate = '/users/:id';
  static const String usersDelete = '/users/:id';
  static const String usersSearch = '/users/search';
  static const String usersRoles = '/users/roles';

  // ========== BRANCH ENDPOINTS ==========
  static const String branches = '/branches';
  static const String branchesById = '/branches/:id';
  static const String branchesCreate = '/branches';
  static const String branchesUpdate = '/branches/:id';
  static const String branchesDelete = '/branches/:id';
  static const String branchesSearch = '/branches/search';
  static const String branchesCurrent = '/branches/current';

  // ========== PRODUCT ENDPOINTS ==========
  static const String products = '/products';
  static const String productsById = '/products/:id';
  static const String productsByBarcode = '/products/barcode/:barcode';
  static const String productsCreate = '/products';
  static const String productsUpdate = '/products/:id';
  static const String productsDelete = '/products/:id';
  static const String productsSearch = '/products/search';
  static const String productsLowStock = '/products/low-stock';
  static const String productsUpdateStock = '/products/:id/stock';
  static const String productsBulkImport = '/products/bulk-import';
  static const String productsBulkExport = '/products/bulk-export';
  static const String productsUploadImage = '/products/:id/image';

  // ========== CATEGORY ENDPOINTS ==========
  static const String categories = '/categories';
  static const String categoriesById = '/categories/:id';
  static const String categoriesCreate = '/categories';
  static const String categoriesUpdate = '/categories/:id';
  static const String categoriesDelete = '/categories/:id';

  // ========== SUPPLIER ENDPOINTS ==========
  static const String suppliers = '/suppliers';
  static const String suppliersById = '/suppliers/:id';
  static const String suppliersCreate = '/suppliers';
  static const String suppliersUpdate = '/suppliers/:id';
  static const String suppliersDelete = '/suppliers/:id';
  static const String suppliersSearch = '/suppliers/search';

  // ========== PURCHASE ENDPOINTS ==========
  static const String purchases = '/purchases';
  static const String purchasesById = '/purchases/:id';
  static const String purchasesCreate = '/purchases';
  static const String purchasesUpdate = '/purchases/:id';
  static const String purchasesDelete = '/purchases/:id';
  static const String purchasesSearch = '/purchases/search';
  static const String purchasesByDateRange = '/purchases/date-range';
  static const String purchasesGenerateNumber = '/purchases/generate-number';
  static const String purchasesReceive = '/purchases/:id/receive';
  static const String purchasesApprove = '/purchases/:id/approve';
  static const String purchasesCancel = '/purchases/:id/cancel';

  // ========== RECEIVING ENDPOINTS ==========
  static const String receivings = '/receivings';
  static const String receivingsById = '/receivings/:id';
  static const String receivingsByPurchase = '/receivings/purchase/:purchaseId';
  static const String receivingsCreate = '/receivings';
  static const String receivingsUpdate = '/receivings/:id';
  static const String receivingsDelete = '/receivings/:id';
  static const String receivingsGenerateNumber = '/receivings/generate-number';

  // ========== PURCHASE RETURN ENDPOINTS ==========
  static const String purchaseReturns = '/purchase-returns';
  static const String purchaseReturnsById = '/purchase-returns/:id';
  static const String purchaseReturnsByReceiving =
      '/purchase-returns/receiving/:receivingId';
  static const String purchaseReturnsCreate = '/purchase-returns';
  static const String purchaseReturnsUpdate = '/purchase-returns/:id';
  static const String purchaseReturnsDelete = '/purchase-returns/:id';
  static const String purchaseReturnsGenerateNumber =
      '/purchase-returns/generate-number';

  // ========== SALES ENDPOINTS ==========
  static const String sales = '/sales';
  static const String salesById = '/sales/:id';
  static const String salesCreate = '/sales';
  static const String salesUpdate = '/sales/:id';
  static const String salesDelete = '/sales/:id';
  static const String salesSearch = '/sales/search';
  static const String salesByDateRange = '/sales/date-range';
  static const String salesGenerateNumber = '/sales/generate-number';
  static const String salesDailySummary = '/sales/daily-summary';
  static const String salesRefund = '/sales/:id/refund';

  // ========== CUSTOMER ENDPOINTS ==========
  static const String customers = '/customers';
  static const String customersById = '/customers/:id';
  static const String customersCreate = '/customers';
  static const String customersUpdate = '/customers/:id';
  static const String customersDelete = '/customers/:id';
  static const String customersSearch = '/customers/search';
  static const String customersGenerateCode = '/customers/generate-code';

  // ========== REPORT ENDPOINTS ==========
  static const String reportsSales = '/reports/sales';
  static const String reportsSalesDaily = '/reports/sales/daily';
  static const String reportsSalesMonthly = '/reports/sales/monthly';
  static const String reportsProducts = '/reports/products';
  static const String reportsProductPerformance =
      '/reports/products/performance';
  static const String reportsInventory = '/reports/inventory';
  static const String reportsInventoryValue = '/reports/inventory/value';
  static const String reportsPurchases = '/reports/purchases';
  static const String reportsCustomers = '/reports/customers';
  static const String reportsProfit = '/reports/profit';

  // ========== DASHBOARD ENDPOINTS ==========
  static const String dashboard = '/dashboard';
  static const String dashboardOverview = '/dashboard/overview';
  static const String dashboardSalesChart = '/dashboard/sales-chart';
  static const String dashboardTopProducts = '/dashboard/top-products';
  static const String dashboardLowStock = '/dashboard/low-stock';
  static const String dashboardRecentTransactions =
      '/dashboard/recent-transactions';

  // ========== EXPORT ENDPOINTS ==========
  static const String exportProducts = '/export/products';
  static const String exportSales = '/export/sales';
  static const String exportPurchases = '/export/purchases';
  static const String exportInventory = '/export/inventory';
  static const String exportCustomers = '/export/customers';

  // ========== IMPORT ENDPOINTS ==========
  static const String importProducts = '/import/products';
  static const String importCustomers = '/import/customers';
  static const String importSuppliers = '/import/suppliers';

  // ========== AUDIT LOG ENDPOINTS ==========
  static const String auditLogs = '/audit-logs';
  static const String auditLogsByEntity =
      '/audit-logs/entity/:entityType/:entityId';
  static const String auditLogsByUser = '/audit-logs/user/:userId';

  // ========== BACKUP ENDPOINTS ==========
  static const String backupCreate = '/backup/create';
  static const String backupList = '/backup/list';
  static const String backupRestore = '/backup/restore';
  static const String backupDownload = '/backup/download/:filename';

  // ========== SOCKET EVENTS ==========
  static const String productUpdate = 'product:update';
  static const String stockUpdate = 'stock:update';
  static const String saleCompleted = 'sale:completed';
  static const String notificationSend = 'notification:send';
  static const String syncRequest = 'sync:request';

  // Helper method to replace path parameters
  static String replacePathParams(String path, Map<String, dynamic> params) {
    String result = path;
    params.forEach((key, value) {
      result = result.replaceAll(':$key', value.toString());
    });
    return result;
  }
}
