import '../../domain/ledger/ledger_transaction_builder.dart';
import '../../domain/model/stock_holding.dart';
import '../../domain/model/stock_trade.dart';

abstract interface class StockTradeAtomicExecutor {
  Future<void> execute({
    required StockTrade trade,
    required StockHolding? updatedHolding,
    required String? holdingToArchiveId,
    required LedgerTransactionAggregate ledger,
  });
}
