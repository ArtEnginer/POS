import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

// Core - Backend V2 (Node.js + PostgreSQL + Socket.IO)
import 'core/network/api_client.dart';
import 'core/network/network_info.dart';
import 'core/auth/auth_service.dart';
import 'core/socket/socket_service.dart';

// Features - Product
import 'features/product/data/datasources/product_remote_data_source.dart';
import 'features/product/data/repositories/product_repository_impl.dart';
import 'features/product/domain/repositories/product_repository.dart';
import 'features/product/domain/usecases/product_usecases.dart';
import 'features/product/presentation/bloc/product_bloc.dart';

// Features - Customer
import 'features/customer/data/datasources/customer_remote_data_source.dart';
import 'features/customer/data/repositories/customer_repository_impl.dart';
import 'features/customer/domain/repositories/customer_repository.dart';
import 'features/customer/domain/usecases/customer_usecases.dart';
import 'features/customer/presentation/bloc/customer_bloc.dart';

// Features - Supplier
import 'features/supplier/data/datasources/supplier_remote_data_source.dart';
import 'features/supplier/data/repositories/supplier_repository_impl.dart';
import 'features/supplier/domain/repositories/supplier_repository.dart';
import 'features/supplier/domain/usecases/get_suppliers.dart';
import 'features/supplier/domain/usecases/create_supplier.dart';
import 'features/supplier/domain/usecases/update_supplier.dart';
import 'features/supplier/domain/usecases/delete_supplier.dart';
import 'features/supplier/presentation/bloc/supplier_bloc.dart';

// Features - Purchase
import 'features/purchase/data/datasources/purchase_remote_data_source.dart';
import 'features/purchase/data/repositories/purchase_repository_impl.dart';
import 'features/purchase/domain/repositories/purchase_repository.dart';
import 'features/purchase/domain/usecases/purchase_usecases.dart';
import 'features/purchase/presentation/bloc/purchase_bloc.dart';

// Features - Receiving
import 'features/receiving/data/datasources/receiving_remote_data_source.dart';
import 'features/receiving/data/repositories/receiving_repository_impl.dart';
import 'features/receiving/domain/repositories/receiving_repository.dart';
import 'features/receiving/domain/usecases/receiving_usecases.dart';
import 'features/receiving/presentation/bloc/receiving_bloc.dart';

// Features - Branch
import 'features/branch/data/datasources/branch_remote_data_source.dart';
import 'features/branch/data/repositories/branch_repository_impl.dart';
import 'features/branch/domain/repositories/branch_repository.dart';
import 'features/branch/domain/usecases/branch_usecases.dart';
import 'features/branch/presentation/bloc/branch_bloc.dart';

// Core - Network Connectivity
import 'core/network/connectivity_manager.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ========== Core Services (Initialize First) ==========

  // External
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<Logger>(
    () => Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    ),
  );

  // Shared Preferences
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  // NO LOCAL DATABASE - Management App is ONLINE-ONLY
  // All data operations go through API

  // Network
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // Auth Service (MUST be initialized before ApiClient)
  sl.registerLazySingleton<AuthService>(() => AuthService(sl(), Dio()));

  // API Client (Backend V2 - Node.js + PostgreSQL)
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));

  // Socket Service (Real-time sync with Socket.IO)
  sl.registerLazySingleton<SocketService>(() => SocketService(sl(), sl()));

  // ========== Network Connectivity Manager ==========

  // Connectivity Manager (for online-only validation)
  sl.registerLazySingleton<ConnectivityManager>(
    () => ConnectivityManager(
      connectivity: sl<Connectivity>(),
      logger: sl<Logger>(),
    ),
  );

  // ========== Features - Branch ==========

  // Bloc
  sl.registerFactory(
    () => BranchBloc(
      getAllBranches: sl(),
      getBranchById: sl(),
      createBranch: sl(),
      updateBranch: sl(),
      deleteBranch: sl(),
      searchBranches: sl(),
      getCurrentBranch: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllBranches(sl()));
  sl.registerLazySingleton(() => GetBranchById(sl()));
  sl.registerLazySingleton(() => CreateBranch(sl()));
  sl.registerLazySingleton(() => UpdateBranch(sl()));
  sl.registerLazySingleton(() => DeleteBranch(sl()));
  sl.registerLazySingleton(() => SearchBranches(sl()));
  sl.registerLazySingleton(() => GetCurrentBranch(sl()));

  // Repository (Online-only)
  sl.registerLazySingleton<BranchRepository>(
    () => BranchRepositoryImpl(remoteDataSource: sl<BranchRemoteDataSource>()),
  );

  // Data sources (Remote only)
  sl.registerLazySingleton<BranchRemoteDataSource>(
    () => BranchRemoteDataSourceImpl(apiClient: sl<ApiClient>()),
  );

  // ========== Features - Product ==========

  // Bloc
  sl.registerFactory(
    () => ProductBloc(
      getAllProducts: sl(),
      getProductById: sl(),
      getProductByBarcode: sl(),
      searchProducts: sl(),
      getLowStockProducts: sl(),
      createProduct: sl(),
      updateProduct: sl(),
      deleteProduct: sl(),
      updateProductStock: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllProducts(sl()));
  sl.registerLazySingleton(() => GetProductById(sl()));
  sl.registerLazySingleton(() => GetProductByBarcode(sl()));
  sl.registerLazySingleton(() => SearchProducts(sl()));
  sl.registerLazySingleton(() => GetLowStockProducts(sl()));
  sl.registerLazySingleton(() => CreateProduct(sl()));
  sl.registerLazySingleton(() => UpdateProduct(sl()));
  sl.registerLazySingleton(() => DeleteProduct(sl()));
  sl.registerLazySingleton(() => UpdateProductStock(sl()));

  // Repository (Online-only with real-time Socket.IO)
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: sl<ProductRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      socketService: sl<SocketService>(),
    ),
  );

  // Data sources (Remote only)
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(
      apiClient: sl<ApiClient>(),
      socketService: sl<SocketService>(),
      authService: sl<AuthService>(),
    ),
  );

  // ========== Features - Customer ==========

  // Bloc
  sl.registerFactory(
    () => CustomerBloc(
      getAllCustomers: sl(),
      getCustomerById: sl(),
      searchCustomers: sl(),
      createCustomer: sl(),
      updateCustomer: sl(),
      deleteCustomer: sl(),
      generateCustomerCode: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllCustomers(sl()));
  sl.registerLazySingleton(() => GetCustomerById(sl()));
  sl.registerLazySingleton(() => SearchCustomers(sl()));
  sl.registerLazySingleton(() => CreateCustomer(sl()));
  sl.registerLazySingleton(() => UpdateCustomer(sl()));
  sl.registerLazySingleton(() => DeleteCustomer(sl()));
  sl.registerLazySingleton(() => GenerateCustomerCode(sl()));

  // Repository (Online-only with real-time Socket.IO)
  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(
      remoteDataSource: sl<CustomerRemoteDataSource>(),
    ),
  );

  // Data sources (Remote only)
  sl.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerRemoteDataSourceImpl(
      apiClient: sl<ApiClient>(),
      socketService: sl<SocketService>(),
      authService: sl<AuthService>(),
    ),
  );

  // ========== Features - Supplier ==========

  // Bloc
  sl.registerFactory(
    () => SupplierBloc(
      getSuppliers: sl(),
      createSupplier: sl(),
      updateSupplier: sl(),
      deleteSupplier: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetSuppliers(sl()));
  sl.registerLazySingleton(() => CreateSupplier(sl()));
  sl.registerLazySingleton(() => UpdateSupplier(sl()));
  sl.registerLazySingleton(() => DeleteSupplier(sl()));

  // Repository
  sl.registerLazySingleton<SupplierRepository>(
    () => SupplierRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<SupplierRemoteDataSource>(
    () => SupplierRemoteDataSourceImpl(
      apiClient: sl<ApiClient>(),
      socketService: sl<SocketService>(),
      authService: sl<AuthService>(),
    ),
  );

  // ========== Features - Purchase ==========

  // Bloc
  sl.registerFactory(
    () => PurchaseBloc(
      getAllPurchases: sl(),
      getPurchaseById: sl(),
      getPurchasesByDateRange: sl(),
      searchPurchases: sl(),
      createPurchase: sl(),
      updatePurchase: sl(),
      deletePurchase: sl(),
      generatePurchaseNumber: sl(),
      receivePurchase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllPurchases(sl()));
  sl.registerLazySingleton(() => GetPurchaseById(sl()));
  sl.registerLazySingleton(() => GetPurchasesByDateRange(sl()));
  sl.registerLazySingleton(() => SearchPurchases(sl()));
  sl.registerLazySingleton(() => CreatePurchase(sl()));
  sl.registerLazySingleton(() => UpdatePurchase(sl()));
  sl.registerLazySingleton(() => DeletePurchase(sl()));
  sl.registerLazySingleton(() => GeneratePurchaseNumber(sl()));
  sl.registerLazySingleton(() => ReceivePurchase(sl()));

  // Repository
  sl.registerLazySingleton<PurchaseRepository>(
    () => PurchaseRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<PurchaseRemoteDataSource>(
    () => PurchaseRemoteDataSourceImpl(
      apiClient: sl<ApiClient>(),
      socketService: sl<SocketService>(),
      authService: sl<AuthService>(),
    ),
  );

  // ========== Features - Receiving (ONLINE-ONLY) ==========

  // Bloc
  sl.registerFactory(
    () => ReceivingBloc(
      getAllReceivings: sl(),
      getReceivingById: sl(),
      searchReceivings: sl(),
      createReceiving: sl(),
      updateReceiving: sl(),
      deleteReceiving: sl(),
      generateReceivingNumber: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllReceivings(sl()));
  sl.registerLazySingleton(() => GetReceivingById(sl()));
  sl.registerLazySingleton(() => SearchReceivings(sl()));
  sl.registerLazySingleton(() => CreateReceiving(sl()));
  sl.registerLazySingleton(() => UpdateReceiving(sl()));
  sl.registerLazySingleton(() => DeleteReceiving(sl()));
  sl.registerLazySingleton(() => GenerateReceivingNumber(sl()));

  // Repository
  sl.registerLazySingleton<ReceivingRepository>(
    () => ReceivingRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ReceivingRemoteDataSource>(
    () => ReceivingRemoteDataSourceImpl(
      apiClient: sl<ApiClient>(),
      socketService: sl<SocketService>(),
      authService: sl<AuthService>(),
    ),
  );

  // ========== TODO: Features - Sales ==========
  // These features require remote data sources to be created
  // See IMPLEMENTATION_GUIDE.md for creating remote data sources
}
