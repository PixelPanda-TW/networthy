import '../../application/stock/stock_trade_execution.dart';
import '../../domain/ledger/ledger_transaction_builder.dart';
import '../../domain/model/stock_holding.dart' as domain_holding;
import '../../domain/model/stock_trade.dart' as domain;
import '../../domain/repository/stock_holding_repository.dart';
import '../database/networthy_database.dart';
import 'drift_ledger_repository.dart';
import 'drift_stock_holding_repository.dart';
import 'drift_stock_trade_repository.dart';

class DriftStockTradeExecutor implements StockTradeAtomicExecutor {
  DriftStockTradeExecutor(this._database)
    : _trades = DriftStockTradeRepository(_database),
      _holdings = DriftStockHoldingRepository(_database),
      _ledger = DriftLedgerRepository(_database);

  final NetworthyDatabase _database;
  final DriftStockTradeRepository _trades;
  final DriftStockHoldingRepository _holdings;
  final DriftLedgerRepository _ledger;

  @override
  Future<void> execute({
    required domain.StockTrade trade,
    required domain_holding.StockHolding? updatedHolding,
    required String? holdingToArchiveId,
    required LedgerTransactionAggregate ledger,
  }) async {
    await _database.transaction(() async {
      await _trades.save(trade);
      if (updatedHolding != null) {
        if (updatedHolding.trackingMode ==
            domain_holding.StockHoldingTrackingMode.valuation) {
          await _holdings.saveValuation(
            SaveValuationHoldingRequest(
              id: updatedHolding.id,
              accountId: updatedHolding.accountId,
              symbol: updatedHolding.symbol,
              name: updatedHolding.name,
              accountMode: updatedHolding.accountMode,
              quantityMicro: updatedHolding.quantityMicro!,
              averageCostMinor: updatedHolding.averageCostMinor!,
              currentPriceMinor: updatedHolding.currentPriceMinor!,
            ),
          );
        } else {
          await _holdings.savePrincipal(
            SavePrincipalHoldingRequest(
              id: updatedHolding.id,
              accountId: updatedHolding.accountId,
              symbol: updatedHolding.symbol,
              name: updatedHolding.name,
              accountMode: updatedHolding.accountMode,
              principalMinor: updatedHolding.principalMinor!,
            ),
          );
        }
      }
      if (holdingToArchiveId != null) {
        await _holdings.archive(holdingToArchiveId);
      }
      await _ledger.save(ledger);
    });
  }
}
