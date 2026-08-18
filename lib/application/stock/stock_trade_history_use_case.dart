import '../../domain/model/stock_trade.dart';
import '../../domain/repository/stock_trade_repository.dart';
import '../common/application_failure.dart';

class StockTradeHistoryResult {
  const StockTradeHistoryResult.success(this.trades) : failure = null;

  const StockTradeHistoryResult.failure(this.failure) : trades = const [];

  final List<StockTrade> trades;
  final ApplicationFailure? failure;
}

class StockTradeHistoryUseCase {
  const StockTradeHistoryUseCase(this._trades);

  final StockTradeRepository _trades;

  Future<StockTradeHistoryResult> latest({int limit = 50}) async {
    try {
      return StockTradeHistoryResult.success(
        await _trades.listLatest(limit: limit),
      );
    } on Exception catch (error) {
      return StockTradeHistoryResult.failure(
        ApplicationFailure.fromException(error),
      );
    }
  }
}
