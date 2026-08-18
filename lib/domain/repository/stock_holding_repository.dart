import '../model/stock_account.dart';
import '../model/stock_holding.dart';

abstract interface class StockHoldingRepository {
  Future<List<StockHolding>> listActiveByAccount(String accountId);

  Future<List<StockHolding>> listAllByAccount(String accountId);

  Future<List<StockHolding>> listAllActive();

  Future<StockHolding?> findById(String id);

  Future<StockHolding> saveValuation(SaveValuationHoldingRequest request);

  Future<StockHolding> savePrincipal(SavePrincipalHoldingRequest request);

  Future<void> archive(String id);
}

class SaveValuationHoldingRequest {
  const SaveValuationHoldingRequest({
    required this.id,
    required this.accountId,
    required this.symbol,
    required this.name,
    required this.accountMode,
    required this.quantityMicro,
    required this.averageCostMinor,
    required this.currentPriceMinor,
  });

  final String id;
  final String accountId;
  final String symbol;
  final String name;
  final StockAccountMode accountMode;
  final int quantityMicro;
  final int averageCostMinor;
  final int currentPriceMinor;
}

class SavePrincipalHoldingRequest {
  const SavePrincipalHoldingRequest({
    required this.id,
    required this.accountId,
    required this.symbol,
    required this.name,
    required this.accountMode,
    required this.principalMinor,
  });

  final String id;
  final String accountId;
  final String symbol;
  final String name;
  final StockAccountMode accountMode;
  final int principalMinor;
}

class StockHoldingRepositoryException implements Exception {
  const StockHoldingRepositoryException(this.safeMessage);

  final String safeMessage;

  @override
  String toString() => 'StockHoldingRepositoryException: $safeMessage';
}
