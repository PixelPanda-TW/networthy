import '../model/stock_trade.dart';

abstract interface class StockTradeRepository {
  Future<void> save(StockTrade trade);

  Future<StockTrade?> findById(String id);

  Future<List<StockTrade>> listByStockAccount(String stockAccountId);

  Future<List<StockTrade>> listLatest({required int limit});
}

class SaveStockTradeRequest {
  const SaveStockTradeRequest({required this.trade});

  final StockTrade trade;
}

class StockTradeRepositoryException implements Exception {
  const StockTradeRepositoryException(this.safeMessage);

  final String safeMessage;

  @override
  String toString() => 'StockTradeRepositoryException: $safeMessage';
}
