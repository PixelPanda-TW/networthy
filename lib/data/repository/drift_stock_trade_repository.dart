import 'package:drift/drift.dart';

import '../../domain/model/local_date.dart';
import '../../domain/model/stock_account.dart';
import '../../domain/model/stock_trade.dart' as domain;
import '../../domain/repository/stock_trade_repository.dart';
import '../database/networthy_database.dart';

class DriftStockTradeRepository implements StockTradeRepository {
  const DriftStockTradeRepository(this._database);

  final NetworthyDatabase _database;

  @override
  Future<void> save(domain.StockTrade trade) async {
    await _database
        .into(_database.stockTrades)
        .insert(_toCompanion(trade), mode: InsertMode.insertOrReplace);
  }

  @override
  Future<domain.StockTrade?> findById(String id) async {
    final row = await (_database.select(
      _database.stockTrades,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<List<domain.StockTrade>> listByStockAccount(
    String stockAccountId,
  ) async {
    final rows =
        await (_database.select(_database.stockTrades)
              ..where((table) => table.stockAccountId.equals(stockAccountId))
              ..orderBy([
                (table) => OrderingTerm.desc(table.tradeYear),
                (table) => OrderingTerm.desc(table.tradeMonth),
                (table) => OrderingTerm.desc(table.tradeDay),
                (table) => OrderingTerm.desc(table.createdAtUtc),
              ]))
            .get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<domain.StockTrade>> listLatest({required int limit}) async {
    if (limit <= 0) {
      return const [];
    }
    final rows =
        await (_database.select(_database.stockTrades)
              ..orderBy([
                (table) => OrderingTerm.desc(table.tradeYear),
                (table) => OrderingTerm.desc(table.tradeMonth),
                (table) => OrderingTerm.desc(table.tradeDay),
                (table) => OrderingTerm.desc(table.createdAtUtc),
              ])
              ..limit(limit))
            .get();
    return rows.map(_toDomain).toList(growable: false);
  }

  StockTradesCompanion _toCompanion(domain.StockTrade trade) {
    return StockTradesCompanion.insert(
      id: trade.id,
      stockAccountId: trade.stockAccountId,
      cashAccountId: trade.cashAccountId,
      side: trade.side.wireValue,
      symbol: trade.symbol,
      name: trade.name,
      mode: trade.accountMode.wireValue,
      currencyCode: trade.currencyCode.wireValue,
      quantityMicro: Value(trade.quantityMicro),
      priceMinor: Value(trade.priceMinor),
      principalMinor: Value(trade.principalMinor),
      tradeYear: trade.tradeDate.year,
      tradeMonth: trade.tradeDate.month,
      tradeDay: trade.tradeDate.day,
      note: Value(trade.note),
      createdAtUtc: trade.createdAtUtc,
      updatedAtUtc: trade.updatedAtUtc,
    );
  }

  domain.StockTrade _toDomain(StockTrade row) {
    final mode = StockAccountMode.fromWireValue(row.mode);
    final side = domain.StockTradeSide.values.firstWhere(
      (value) => value.wireValue == row.side,
      orElse: () => throw const StockTradeRepositoryException('交易方向無效。'),
    );
    final common = _CommonTradeFields(
      id: row.id,
      stockAccountId: row.stockAccountId,
      cashAccountId: row.cashAccountId,
      side: side,
      symbol: row.symbol,
      name: row.name,
      tradeDate: LocalDate(row.tradeYear, row.tradeMonth, row.tradeDay),
      note: row.note,
      createdAtUtc: row.createdAtUtc.toUtc(),
      updatedAtUtc: row.updatedAtUtc.toUtc(),
    );
    try {
      if (mode == StockAccountMode.taiwanStock) {
        return domain.StockTrade.valuation(
          id: common.id,
          stockAccountId: common.stockAccountId,
          cashAccountId: common.cashAccountId,
          side: common.side,
          symbol: common.symbol,
          name: common.name,
          quantityMicro: row.quantityMicro!,
          priceMinor: row.priceMinor!,
          tradeDate: common.tradeDate,
          note: common.note,
          createdAtUtc: common.createdAtUtc,
          updatedAtUtc: common.updatedAtUtc,
        );
      }
      return domain.StockTrade.principal(
        id: common.id,
        stockAccountId: common.stockAccountId,
        cashAccountId: common.cashAccountId,
        side: common.side,
        accountMode: mode,
        symbol: common.symbol,
        name: common.name,
        principalMinor: row.principalMinor!,
        tradeDate: common.tradeDate,
        note: common.note,
        createdAtUtc: common.createdAtUtc,
        updatedAtUtc: common.updatedAtUtc,
      );
    } on Exception catch (error) {
      throw StockTradeRepositoryException('股票交易資料無效：$error');
    }
  }
}

class _CommonTradeFields {
  const _CommonTradeFields({
    required this.id,
    required this.stockAccountId,
    required this.cashAccountId,
    required this.side,
    required this.symbol,
    required this.name,
    required this.tradeDate,
    required this.note,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  final String id;
  final String stockAccountId;
  final String cashAccountId;
  final domain.StockTradeSide side;
  final String symbol;
  final String name;
  final LocalDate tradeDate;
  final String? note;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
}
