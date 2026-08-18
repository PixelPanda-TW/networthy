import '../../domain/model/local_date.dart';
import '../../domain/model/stock_account.dart';
import '../../domain/model/stock_trade.dart';

class ExecuteStockTradeCommand {
  const ExecuteStockTradeCommand({
    required this.stockAccountId,
    required this.cashAccountId,
    required this.side,
    required this.symbol,
    required this.name,
    required this.accountMode,
    this.quantityMicro,
    this.priceMinor,
    this.principalMinor,
    required this.tradeDate,
    this.note,
  });

  final String stockAccountId;
  final String cashAccountId;
  final StockTradeSide side;
  final String symbol;
  final String name;
  final StockAccountMode accountMode;
  final int? quantityMicro;
  final int? priceMinor;
  final int? principalMinor;
  final LocalDate tradeDate;
  final String? note;
}
