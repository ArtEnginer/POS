import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../models/dashboard_summary_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final ApiClient apiClient;

  DashboardRepositoryImpl({required this.apiClient});

  @override
  Future<Either<Failure, DashboardSummary>> getDashboardSummary() async {
    try {
      final response = await apiClient.get(ApiConstants.dashboardOverview);

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final summary = DashboardSummaryModel.fromJson(data);
        return Right(summary);
      } else {
        return Left(
          ServerFailure(
            message: response.data['message'] ?? 'Failed to load dashboard',
          ),
        );
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
