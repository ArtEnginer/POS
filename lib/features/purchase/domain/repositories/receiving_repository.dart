import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/receiving.dart';

abstract class ReceivingRepository {
  /// Get all receivings
  Future<Either<Failure, List<Receiving>>> getAllReceivings();

  /// Get receiving by ID
  Future<Either<Failure, Receiving>> getReceivingById(String id);

  /// Get receivings by purchase ID (bisa multiple receiving dari 1 PO)
  Future<Either<Failure, List<Receiving>>> getReceivingsByPurchaseId(
    String purchaseId,
  );

  /// Search receivings by keyword
  Future<Either<Failure, List<Receiving>>> searchReceivings(String query);

  /// Create new receiving (dari PO)
  /// NOTE: PO data tidak berubah, hanya status PO yang di-update
  Future<Either<Failure, Receiving>> createReceiving(Receiving receiving);

  /// Update existing receiving
  /// NOTE: Stock adjustment akan di-handle (delta calculation)
  Future<Either<Failure, Receiving>> updateReceiving(Receiving receiving);

  /// Delete receiving
  /// NOTE: Stock akan di-reverse (dikurangi kembali)
  Future<Either<Failure, void>> deleteReceiving(String id);

  /// Generate receiving number (RCV-YYYYMMDD-HHMMSS)
  Future<Either<Failure, String>> generateReceivingNumber();
}
