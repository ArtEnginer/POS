import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

// Core
import 'core/database/database_helper.dart';
import 'core/network/api_client.dart';
import 'core/network/network_info.dart';
import 'core/sync/sync_manager.dart';

// Features - Product
import 'features/product/data/datasources/product_local_data_source.dart';
import 'features/product/data/repositories/product_repository_impl.dart';
import 'features/product/domain/repositories/product_repository.dart';
import 'features/product/domain/usecases/product_usecases.dart';
import 'features/product/presentation/bloc/product_bloc.dart';

// Features - Purchase
import 'features/purchase/data/datasources/purchase_local_data_source.dart';
import 'features/purchase/data/repositories/purchase_repository_impl.dart';
import 'features/purchase/domain/repositories/purchase_repository.dart';
import 'features/purchase/domain/usecases/purchase_usecases.dart';
import 'features/purchase/presentation/bloc/purchase_bloc.dart';

// Features - Supplier
import 'features/supplier/data/datasources/supplier_local_data_source.dart';
import 'features/supplier/data/repositories/supplier_repository_impl.dart';
import 'features/supplier/domain/repositories/supplier_repository.dart';
import 'features/supplier/domain/usecases/get_suppliers.dart';
import 'features/supplier/domain/usecases/create_supplier.dart';
import 'features/supplier/domain/usecases/update_supplier.dart';
import 'features/supplier/domain/usecases/delete_supplier.dart';
import 'features/supplier/presentation/bloc/supplier_bloc.dart';

// Features - Receiving
import 'features/purchase/data/datasources/receiving_local_data_source.dart';
import 'features/purchase/data/repositories/receiving_repository_impl.dart';
import 'features/purchase/domain/repositories/receiving_repository.dart';
import 'features/purchase/domain/usecases/receiving_usecases.dart';
import 'features/purchase/presentation/bloc/receiving_bloc.dart';

// Features - Purchase Return
import 'features/purchase/data/datasources/purchase_return_local_data_source.dart';
import 'features/purchase/data/repositories/purchase_return_repository_impl.dart';
import 'features/purchase/domain/repositories/purchase_return_repository.dart';
import 'features/purchase/domain/usecases/purchase_return_usecases.dart';
import 'features/purchase/presentation/bloc/purchase_return_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
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

  // Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(localDataSource: sl(), syncManager: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(databaseHelper: sl()),
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
    () => PurchaseRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<PurchaseLocalDataSource>(
    () => PurchaseLocalDataSourceImpl(databaseHelper: sl()),
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
    () => SupplierRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<SupplierLocalDataSource>(
    () => SupplierLocalDataSourceImpl(databaseHelper: sl()),
  );

  // ========== Features - Receiving ==========

  // Bloc
  sl.registerFactory(
    () => ReceivingBloc(
      getAllReceivings: sl(),
      getReceivingById: sl(),
      getReceivingsByPurchaseId: sl(),
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
  sl.registerLazySingleton(() => GetReceivingsByPurchaseId(sl()));
  sl.registerLazySingleton(() => SearchReceivings(sl()));
  sl.registerLazySingleton(() => CreateReceiving(sl()));
  sl.registerLazySingleton(() => UpdateReceiving(sl()));
  sl.registerLazySingleton(() => DeleteReceiving(sl()));
  sl.registerLazySingleton(() => GenerateReceivingNumber(sl()));

  // Repository
  sl.registerLazySingleton<ReceivingRepository>(
    () => ReceivingRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<ReceivingLocalDataSource>(
    () => ReceivingLocalDataSourceImpl(databaseHelper: sl()),
  );

  // ========== Features - Purchase Return ==========

  // Bloc
  sl.registerFactory(
    () => PurchaseReturnBloc(
      getAllPurchaseReturns: sl(),
      getPurchaseReturnById: sl(),
      getPurchaseReturnsByReceivingId: sl(),
      searchPurchaseReturns: sl(),
      createPurchaseReturn: sl(),
      updatePurchaseReturn: sl(),
      deletePurchaseReturn: sl(),
      generateReturnNumber: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetAllPurchaseReturns(sl()));
  sl.registerLazySingleton(() => GetPurchaseReturnById(sl()));
  sl.registerLazySingleton(() => GetPurchaseReturnsByReceivingId(sl()));
  sl.registerLazySingleton(() => SearchPurchaseReturns(sl()));
  sl.registerLazySingleton(() => CreatePurchaseReturn(sl()));
  sl.registerLazySingleton(() => UpdatePurchaseReturn(sl()));
  sl.registerLazySingleton(() => DeletePurchaseReturn(sl()));
  sl.registerLazySingleton(() => GenerateReturnNumber(sl()));

  // Repository
  sl.registerLazySingleton<PurchaseReturnRepository>(
    () => PurchaseReturnRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<PurchaseReturnLocalDataSource>(
    () => PurchaseReturnLocalDataSourceImpl(databaseHelper: sl()),
  );

  // ========== Core ==========

  // Sync Manager
  sl.registerLazySingleton(
    () => SyncManager(
      apiClient: sl(),
      networkInfo: sl(),
      databaseHelper: sl(),
      logger: sl(),
    ),
  );

  // Network
  sl.registerLazySingleton(() => ApiClient());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // Database
  sl.registerLazySingleton(() => DatabaseHelper.instance);

  // External
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton(
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
}
