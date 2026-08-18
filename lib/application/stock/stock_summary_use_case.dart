import '../../domain/repository/stock_holding_repository.dart';
import '../../domain/summary/stock_asset_summary.dart';
import '../common/application_failure.dart';

class StockAssetSummaryResult {
  const StockAssetSummaryResult.success(this.summary) : failure = null;

  const StockAssetSummaryResult.failure(this.failure) : summary = null;

  final StockAssetSummary? summary;
  final ApplicationFailure? failure;
}

class LoadStockAssetSummaryUseCase {
  const LoadStockAssetSummaryUseCase(this._holdings);

  final StockHoldingRepository _holdings;

  Future<StockAssetSummaryResult> execute() async {
    try {
      final holdings = await _holdings.listAllActive();
      return StockAssetSummaryResult.success(
        StockAssetSummary.calculate(holdings),
      );
    } on Exception catch (exception) {
      return StockAssetSummaryResult.failure(
        ApplicationFailure.fromException(exception),
      );
    }
  }
}
