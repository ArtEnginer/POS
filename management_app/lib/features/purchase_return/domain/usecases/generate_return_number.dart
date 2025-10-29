import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/purchase_return_repository.dart';

class GenerateReturnNumber {
  final PurchaseReturnRepository repository;

  GenerateReturnNumber(this.repository);

  Future<Either<Failure, String>> call() async {
    return await repository.generateReturnNumber();
  }
}
