import '../../domain/model/stock_holding.dart';
import '../common/application_failure.dart';

class SaveValuationStockHoldingCommand {
  const SaveValuationStockHoldingCommand({
    required this.accountId,
    required this.symbol,
    required this.name,
    required this.quantityMicro,
    required this.averageCostMinor,
    required this.currentPriceMinor,
  });

  final String accountId;
  final String symbol;
  final String name;
  final int quantityMicro;
  final int averageCostMinor;
  final int currentPriceMinor;
}

class SavePrincipalStockHoldingCommand {
  const SavePrincipalStockHoldingCommand({
    required this.accountId,
    required this.symbol,
    required this.name,
    required this.principalMinor,
  });

  final String accountId;
  final String symbol;
  final String name;
  final int principalMinor;
}

class ArchiveStockHoldingCommand {
  const ArchiveStockHoldingCommand({required this.id});

  final String id;
}

class StockHoldingCommandResult {
  const StockHoldingCommandResult.success(this.holding) : failure = null;

  const StockHoldingCommandResult.failure(this.failure) : holding = null;

  final StockHolding? holding;
  final ApplicationFailure? failure;
}
